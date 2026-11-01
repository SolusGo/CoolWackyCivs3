-- BNW + Community Patch 151; single-player gameplay context.
-- No research-completion callback: the tier is frozen until the next owner boundary.
if MapModData.CWC3_AlmostRegistered then return end
include('CWC3_Runtime')
include('CWC3_Diagnostics')
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
local settledTurn, snapshotGap, warned = {}, {}, {}
local watchedCities, veterans = {}, {}
local function WarnOnce(key, message)
    if warned[key] then return end
    warned[key] = true
    print('CWC3 Almost: ' .. message)
end

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
    if gap >= 6 then return 2, gap end
    if gap >= 3 then return 1, gap end
    return 0, gap
end

local function ApplyCity(city, savedTier)
    if not city then return end
    local player = Players[city:GetOwner()]
    local tier = 0
    if IsMinistry(player) then
        if savedTier == nil then
            local _, loadedTier = CWC3.LoadSnapshot(player)
            savedTier = loadedTier
        end
        tier = savedTier or 0
    end
    local x, y = city:GetX(), city:GetY()
    local key = x .. ':' .. y
    watchedCities[key] = IsMinistry(player) and {x=x, y=y} or nil
    CWC3.SetBuilding(city, S1, tier >= 1)
    CWC3.SetBuilding(city, S2, tier >= 2)
    CWC3.SetBuilding(city, CULTURE, tier >= 1)
    CWC3.SetBuilding(city, PRODUCTION, tier >= 2 and city:GetNumBuilding(ACADEMY) > 0)
end

-- Own the whole reconciliation transaction, not just individual building writes:
-- SetNumRealBuilding may itself generate a city-info dirty notification.
local reconciling = false
local function Reconcile(work)
    if reconciling then return end
    reconciling = true
    local ok, err = pcall(work)
    reconciling = false
    if not ok then error(err) end
end
local function ReconcileOwner(iPlayer)
    local player = Players[iPlayer]
    if not player then return end
    Reconcile(function()
        local _, tier = CWC3.LoadSnapshot(player)
        for city in player:Cities() do ApplyCity(city, tier or 0) end
    end)
end
local function ReconcileCity(city)
    Reconcile(function() ApplyCity(city) end)
end
local function ReconcileTracked()
    Reconcile(function()
        for key, coord in pairs(watchedCities) do
            local plot = Map.GetPlot(coord.x, coord.y)
            local city = plot and plot:GetPlotCity()
            if city then ApplyCity(city) else watchedCities[key] = nil end
        end
    end)
end

local function Snapshot(iPlayer, event, counts)
    local player = Players[iPlayer]
    if not IsMinistry(player) then return end
    local turn = Game.GetGameTurn()
    local savedTurn = CWC3.LoadSnapshot(player)
    if savedTurn and savedTurn >= turn then return end
    if settledTurn[iPlayer] == turn then
        WarnOnce('late:' .. iPlayer, 'Rejected late ' .. event .. ' for player ' .. iPlayer
            .. '; economic settlement already observed. Pre-economy timing is NOT accepted.')
        CWC3.AlmostTrace(event, iPlayer, nil, 'rejected-after-PlayerDoTurn')
        return
    end
    local tier, gap = TierFor(player, counts or {})
    CWC3.AlmostTrace(event .. ':before', iPlayer, gap, 'snapshot-boundary-candidate')
    CWC3.SaveSnapshot(player, turn, tier)
    snapshotGap[iPlayer] = {turn=turn, gap=gap}
    ReconcileOwner(iPlayer)
    CWC3.AlmostTrace(event .. ':after', iPlayer, gap, 'city-counts-installed; dispatch-order-needs-runtime-proof')
end

-- CP151 publishes NewGameTurn before activating the first sequential player.
-- Normal single-player uses the human in the first living slot. This pre-economy
-- hook avoids PlayerDoTurn, which is AFTER production, Culture and research.
-- TURN_START publication does not establish how AIProcessingStartedForPlayer is
-- delivered to humans. That event is diagnostic ONLY, never a snapshot fallback.
-- Native UI dispatch synchrony remains an explicit manual acceptance test.
local function OnNewGameTurn(eventTurn)
    if eventTurn ~= nil and eventTurn ~= Game.GetGameTurn() then return end
    local firstAlive
    for i = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
        local player = Players[i]
        if player and player:IsAlive() then
            firstAlive = i
            break
        end
    end
    -- Find actual owners; never move a later-slot human's snapshot to an earlier
    -- rival's boundary. Eliminated earlier slots do not block a valid owner.
    for i = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        if IsMinistry(Players[i]) then
            if i == firstAlive then
                Snapshot(i, 'NewGameTurn')
            else
                WarnOnce('slot:' .. i, 'Player ' .. i .. ' is not the first living sequential player. '
                    .. 'No valid pre-economy owner hook is established for this setup; UA snapshots are suspended.')
                CWC3.AlmostTrace('NewGameTurn', i, nil, 'unsupported-later-slot; saved-snapshot-preserved')
            end
        end
    end
end
local function OnProcessingStarted(iPlayer)
    if IsMinistry(Players[iPlayer]) then
        CWC3.AlmostTrace('AIProcessingStartedForPlayer', iPlayer, nil, 'observation-only; never-resnapshots')
    end
end
Events.NewGameTurn.Add(OnNewGameTurn)
Events.AIProcessingStartedForPlayer.Add(OnProcessingStarted)

-- Own/team-owned territory qualifies. Open Borders with a foreign civilization
-- deliberately does not: Plot:IsFriendlyTerritory includes foreign OB territory.
local function ReconcileUnit(unit)
    if not unit then return end
    local active = false
    local identity = unit:IsHasPromotion(IDENTITY)
    local ownerID, unitID = unit:GetOwner(), unit:GetID()
    veterans[ownerID] = veterans[ownerID] or {}
    veterans[ownerID][unitID] = identity and true or nil
    if identity then
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
-- UnitUpgraded is BEFORE convert(): the new unit need not have its identity yet.
-- UnitConverted is the authoritative post-promotion-transfer reconciliation.
GameEvents.UnitUpgraded.Add(function(iPlayer, _, iNewUnit) OnUnit(iPlayer, iNewUnit) end)
GameEvents.UnitConverted.Add(function(iOldPlayer, iNewPlayer, iOldUnit, iNewUnit)
    if veterans[iOldPlayer] then veterans[iOldPlayer][iOldUnit] = nil end
    OnUnit(iNewPlayer, iNewUnit)
end)
GameEvents.TileOwnershipChanged.Add(OnTileOwnership)

local function OnCityAt(_, x, y)
    local plot = Map.GetPlot(x, y)
    ReconcileCity(plot and plot:GetPlotCity())
end
GameEvents.PlayerCityFounded.Add(OnCityAt)
GameEvents.CityCaptureComplete.Add(function(_, _, x, y) OnCityAt(nil, x, y) end)
GameEvents.PlayerLiberated.Add(function(_, iPlayer, iCity)
    local player = Players[iPlayer]
    if player then ReconcileCity(player:GetCityByID(iCity)) end
end)
local function OnBuilding(iPlayer, iCity, iBuilding)
    if iBuilding ~= ACADEMY then return end
    local player = Players[iPlayer]
    if player then ReconcileCity(player:GetCityByID(iCity)) end
end
GameEvents.CityConstructed.Add(OnBuilding)
GameEvents.CitySoldBuilding.Add(OnBuilding)

-- Dirty notifications visit known Ministry coordinates, including former cities
-- whose acquisition hook was missed. No global/per-frame city or unit scan.
Events.SerialEventCityInfoDirty.Add(ReconcileTracked)
GameEvents.PlayerDoTurn.Add(function(iPlayer)
    -- Reconciliation only. NEVER take the technology snapshot at this late event.
    settledTurn[iPlayer] = Game.GetGameTurn()
    local player = Players[iPlayer]
    local sampled = snapshotGap[iPlayer]
    if IsMinistry(player) then
        CWC3.AlmostTrace('PlayerDoTurn:post-economy', iPlayer,
            sampled and sampled.turn == Game.GetGameTurn() and sampled.gap or nil,
            'observed-stored-progress; changes-can-have-other-causes')
    end
    if player then
        for id in pairs(veterans[iPlayer] or {}) do
            local unit = player:GetUnitByID(id)
            if unit then ReconcileUnit(unit) else veterans[iPlayer][id] = nil end
        end
        -- One owner-local recovery pass also clears illegal foreign dummies and
        -- discovers acquisitions missed by an event. Saved tier is authoritative.
        ReconcileOwner(iPlayer)
    end
    ReconcileTracked()
end)
Events.ActivePlayerTurnStart.Add(function()
    local iPlayer = Game.GetActivePlayer()
    settledTurn[iPlayer] = Game.GetGameTurn()
    if IsMinistry(Players[iPlayer]) then
        CWC3.AlmostTrace('ActivePlayerTurnStart:post-economy', iPlayer, nil, 'observation-only')
    end
end)
-- Restrict dummy construction even if another mod bypasses ordinary costs.
GameEvents.CityCanConstruct.Add(function(_, _, iBuilding)
    return iBuilding ~= S1 and iBuilding ~= S2 and iBuilding ~= CULTURE and iBuilding ~= PRODUCTION
end)

-- Bootstrap/reload repairs all four real/free controller counts from the SAVED
-- tier, never technologies. This also cleans foreign cities and seeds tracking.
for i = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
    local player = Players[i]
    if player and player:IsAlive() then
        ReconcileOwner(i)
        for unit in player:Units() do ReconcileUnit(unit) end
    end
end
