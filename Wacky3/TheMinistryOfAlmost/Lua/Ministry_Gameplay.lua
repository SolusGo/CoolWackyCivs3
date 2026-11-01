-- BNW + Community Patch 151; single-player gameplay context.
-- No research-completion callback: the tier is frozen until the next owner boundary.
if MapModData.CWC3_AlmostRegistered then return end
include('CWC3_Runtime')
local CIV = GameInfoTypes.CIVILIZATION_CWC3_ALMOST
local ACADEMY = GameInfoTypes.BUILDING_CWC3_RUNNER_UP_ACADEMY
local S1 = GameInfoTypes.BUILDING_CWC3_ALMOST_SCIENCE_1
local S2 = GameInfoTypes.BUILDING_CWC3_ALMOST_SCIENCE_2
local CULTURE = GameInfoTypes.BUILDING_CWC3_ALMOST_CULTURE
local PRODUCTION = GameInfoTypes.BUILDING_CWC3_ALMOST_ACADEMY_PRODUCTION
local IDENTITY = GameInfoTypes.PROMOTION_CWC3_SECOND_WIND
local DEFENSE = GameInfoTypes.PROMOTION_CWC3_HOME_DEFENSE
assert(CIV and ACADEMY and S1 and S2 and CULTURE and PRODUCTION and IDENTITY and DEFENSE,
       'CWC3: database registration failed; check Database.log')
MapModData.CWC3_AlmostRegistered = true

local function IsMinistry(player)
    return player and player:IsAlive() and player:IsHuman() and player:GetCivilizationType() == CIV
end

-- Enumerate real technology state through the verified Team:IsHasTech binding.
-- TeamTechs is exposed, but no unverified count method is assumed here.
local technologies = {}
for tech in GameInfo.Technologies() do technologies[#technologies+1] = tech.ID end
local function TechCount(teamID, counts)
    if counts[teamID] ~= nil then return counts[teamID] end
    local count, team = 0, Teams[teamID]
    if team then
        for _, tech in ipairs(technologies) do
            if team:IsHasTech(tech) then count = count + 1 end
        end
    end
    counts[teamID] = count
    return count
end

local function TierFor(player, counts)
    local ownTeam = player:GetTeam()
    local own = TechCount(ownTeam, counts)
    local best = own
    for i = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local rival = Players[i]
        if rival and rival:IsAlive() and not rival:IsMinorCiv() and not rival:IsBarbarian()
           and rival:GetTeam() ~= ownTeam then
            best = math.max(best, TechCount(rival:GetTeam(), counts))
        end
    end
    local gap = math.max(0, best - own)
    if gap >= 6 then return 2 end
    if gap >= 3 then return 1 end
    return 0
end

local function ApplyCity(city)
    if not city then return end
    local player = Players[city:GetOwner()]
    local tier = 0
    if IsMinistry(player) then
        local _, savedTier = CWC3.LoadSnapshot(player)
        tier = savedTier or 0
    end
    CWC3.SetBuilding(city, S1, tier >= 1)
    CWC3.SetBuilding(city, S2, tier >= 2)
    CWC3.SetBuilding(city, CULTURE, tier >= 1)
    CWC3.SetBuilding(city, PRODUCTION, tier >= 2 and city:GetNumBuilding(ACADEMY) > 0)
end

local function Snapshot(iPlayer, counts)
    local player = Players[iPlayer]
    if not IsMinistry(player) then return end
    local turn = Game.GetGameTurn()
    local savedTurn = CWC3.LoadSnapshot(player)
    if savedTurn == turn then return end
    local tier = TierFor(player, counts or {})
    CWC3.SaveSnapshot(player, turn, tier)
    for city in player:Cities() do ApplyCity(city) end
end

-- CP151 publishes NewGameTurn before activating the first sequential player.
-- Normal single-player uses the human in the first living slot. This pre-economy
-- hook avoids PlayerDoTurn, which is AFTER production, Culture and research.
-- The turn-status event handles an owner in a later slot when the engine emits it.
-- Native UI dispatch synchrony is an explicit manual acceptance test (docs/Testing.md).
local function OnNewGameTurn()
    for i = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
        local player = Players[i]
        if player and player:IsAlive() then
            Snapshot(i)
            break
        end
    end
end
local function OnProcessingStarted(iPlayer)
    local player = Players[iPlayer]
    if player and player:IsTurnActive() then Snapshot(iPlayer) end
end
Events.NewGameTurn.Add(OnNewGameTurn)
Events.AIProcessingStartedForPlayer.Add(OnProcessingStarted)

-- Own/team-owned territory qualifies. Open Borders with a foreign civilization
-- deliberately does not: Plot:IsFriendlyTerritory includes foreign OB territory.
local function ReconcileUnit(unit)
    if not unit then return end
    local active = false
    if unit:IsHasPromotion(IDENTITY) then
        local plot, player = unit:GetPlot(), Players[unit:GetOwner()]
        local owner = plot and Players[plot:GetOwner()]
        active = player and owner and player:GetTeam() == owner:GetTeam() or false
    end
    if unit:IsHasPromotion(DEFENSE) ~= active then unit:SetHasPromotion(DEFENSE, active) end
end
local function OnUnit(iPlayer, iUnit)
    local player = Players[iPlayer]
    if player then ReconcileUnit(player:GetUnitByID(iUnit)) end
end
local function OnTileOwnership(x, y)
    local plot = Map.GetPlot(x, y)
    if plot then
        for i = 0, plot:GetNumUnits()-1 do ReconcileUnit(plot:GetUnit(i)) end
    end
end
GameEvents.UnitSetXY.Add(OnUnit)
GameEvents.UnitCreated.Add(OnUnit)
GameEvents.UnitUpgraded.Add(function(iPlayer, _, iNewUnit) OnUnit(iPlayer, iNewUnit) end)
GameEvents.UnitConverted.Add(function(_, iPlayer, _, iNewUnit) OnUnit(iPlayer, iNewUnit) end)
GameEvents.TileOwnershipChanged.Add(OnTileOwnership)

local function OnCityAt(_, x, y)
    local plot = Map.GetPlot(x, y)
    ApplyCity(plot and plot:GetPlotCity())
end
GameEvents.PlayerCityFounded.Add(OnCityAt)
GameEvents.CityCaptureComplete.Add(function(_, _, x, y) OnCityAt(nil, x, y) end)
GameEvents.PlayerLiberated.Add(function(_, iPlayer, iCity)
    local player = Players[iPlayer]
    if player then ApplyCity(player:GetCityByID(iCity)) end
end)
local function OnBuilding(iPlayer, iCity, iBuilding)
    if iBuilding ~= ACADEMY then return end
    local player = Players[iPlayer]
    if player then ApplyCity(player:GetCityByID(iCity)) end
end
GameEvents.CityConstructed.Add(OnBuilding)
GameEvents.CitySoldBuilding.Add(OnBuilding)

-- UI dirtiness also covers direct Lua/IGE building removal. No technology reads
-- and no yield awards occur here; writes are idempotent and recursion-guarded.
local reconciling = false
local function ReconcileCities()
    if reconciling then return end
    reconciling = true
    for i = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
        local player = Players[i]
        if IsMinistry(player) then
            for city in player:Cities() do
                -- Keep saved UA counts intact on reload; only dependent
                -- Academy Production is repaired without taking a new snapshot.
                local _, tier = CWC3.LoadSnapshot(player)
                CWC3.SetBuilding(city, PRODUCTION, (tier or 0) >= 2 and city:GetNumBuilding(ACADEMY) > 0)
            end
        end
    end
    reconciling = false
end
Events.SerialEventCityInfoDirty.Add(ReconcileCities)
GameEvents.PlayerDoTurn.Add(function(iPlayer)
    -- Reconciliation only. NEVER take the technology snapshot at this late event.
    local player = Players[iPlayer]
    if player then
        for unit in player:Units() do ReconcileUnit(unit) end
    end
    ReconcileCities()
end)
-- Restrict dummy construction even if another mod bypasses ordinary costs.
GameEvents.CityCanConstruct.Add(function(_, _, iBuilding)
    return iBuilding ~= S1 and iBuilding ~= S2 and iBuilding ~= CULTURE and iBuilding ~= PRODUCTION
end)

-- Reload preserves both the saved tier and existing UA buildings, including
-- mid-turn saves made after research or rival elimination.
ReconcileCities()
for i = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
    local player = Players[i]
    if player and player:IsAlive() then
        if not IsMinistry(player) then
            for city in player:Cities() do ApplyCity(city) end
        end
        for unit in player:Units() do ReconcileUnit(unit) end
    end
end
