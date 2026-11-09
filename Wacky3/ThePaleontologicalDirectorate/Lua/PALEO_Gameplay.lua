-- BNW + standalone CP151. Source evidence and timing contract: README.md.
if MapModData.PALEO_Registered then return end
include('CWC3_Runtime')
local CIV = GameInfoTypes.CIVILIZATION_PALEO_DIRECTORATE
local UNIT = GameInfoTypes.UNIT_PALEO_FOSSIL_EXPEDITION
local SCIENCE = GameInfoTypes.BUILDING_PALEO_LIBRARY_SCIENCE
local CULTURE = GameInfoTypes.BUILDING_PALEO_UNIVERSITY_CULTURE
local DIG = GameInfoTypes.BUILD_ARCHAEOLOGY_DIG
local DIG_IMPROVEMENT = GameInfoTypes.IMPROVEMENT_ARCHAEOLOGICAL_DIG
assert(CIV and UNIT and SCIENCE and CULTURE and DIG and DIG_IMPROVEMENT,
       'PALEO: database registration failed; check Database.log')
MapModData.PALEO_Registered = true
local library, university, qualifying = {}, {}, {}
for building in GameInfo.Buildings() do
    if building.BuildingClass == 'BUILDINGCLASS_LIBRARY' then
        library[#library+1] = building.ID; qualifying[building.ID] = true
    elseif building.BuildingClass == 'BUILDINGCLASS_UNIVERSITY' then
        university[#university+1] = building.ID; qualifying[building.ID] = true
    end
end
local rewards = {GAMESPEED_QUICK=17, GAMESPEED_STANDARD=25, GAMESPEED_EPIC=38, GAMESPEED_MARATHON=75}
local speed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
local reward = speed and rewards[speed.Type]
if not reward then print('PALEO: unsupported custom game speed; Field Discovery disabled') end
local watched, reconciling, awarding = {}, false, false

local function IsDirectorate(player)
    return player and player:IsAlive() and player:GetCivilizationType() == CIV
end

local function HasRealClass(city, buildings)
    for _, id in ipairs(buildings) do
        if city:GetNumRealBuilding(id) > 0 then return true end
    end
    return false
end

local function ReconcileCity(city)
    if not city then return end
    local eligible = IsDirectorate(Players[city:GetOwner()])
    local x, y = city:GetX(), city:GetY()
    watched[x .. ':' .. y] = eligible and {x=x, y=y} or nil
    -- Absolute 0/1 real count; shared helper also strips every free dummy copy.
    CWC3.SetBuilding(city, SCIENCE, eligible and HasRealClass(city, library))
    CWC3.SetBuilding(city, CULTURE, eligible and HasRealClass(city, university))
end

local function ReconcilePlayer(id)
    local player = Players[id]
    if player then for city in player:Cities() do ReconcileCity(city) end end
end

local function Reconcile(work)
    if reconciling then return end
    reconciling = true
    local ok, err = pcall(work)
    reconciling = false
    if not ok then error(err) end
end

local function RepairWatched()
    Reconcile(function()
        for key, coord in pairs(watched) do
            local plot = Map.GetPlot(coord.x, coord.y)
            local city = plot and plot:GetPlotCity()
            if city then ReconcileCity(city) else watched[key] = nil end
        end
    end)
end

local function RepairDirectorate()
    Reconcile(function()
        for id = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
            if IsDirectorate(Players[id]) then ReconcilePlayer(id) end
        end
    end)
    RepairWatched()
end

GameEvents.PlayerCityFounded.Add(function(_, x, y)
    Reconcile(function()
        local plot = Map.GetPlot(x, y)
        ReconcileCity(plot and plot:GetPlotCity())
    end)
end)
GameEvents.CityCaptureComplete.Add(function(_, _, x, y)
    Reconcile(function()
        local plot = Map.GetPlot(x, y)
        ReconcileCity(plot and plot:GetPlotCity())
    end)
end)
GameEvents.PlayerLiberated.Add(function(_, id)
    Reconcile(function() ReconcilePlayer(id) end)
    RepairWatched()
end)
local function OnBuilding(id, cityID, building)
    if not qualifying[building] then return end
    Reconcile(function()
        local player = Players[id]
        ReconcileCity(player and player:GetCityByID(cityID))
    end)
end
GameEvents.CityConstructed.Add(OnBuilding)
GameEvents.CitySoldBuilding.Add(OnBuilding)
-- Dirty events recover script-based building changes. Guard prevents recursion.
Events.SerialEventCityInfoDirty.Add(RepairWatched)
Events.NewGameTurn.Add(RepairDirectorate)
Events.ActivePlayerTurnStart.Add(RepairDirectorate)
GameEvents.PlayerDoTurn.Add(function(id)
    -- CP151 calls this after economic collection: recovery for the next payout.
    Reconcile(function() ReconcilePlayer(id) end)
    RepairWatched()
end)
GameEvents.CityCanConstruct.Add(function(_, _, building)
    return building ~= SCIENCE and building ~= CULTURE
end)

local function AwardScience(player, id)
    local research = player:GetCurrentResearch()
    if research and research >= 0 then
        -- Native method completes technology and transfers excess to overflow.
        -- Never clamp to remaining cost, SetHasTech, or clear existing overflow.
        Teams[player:GetTeam()]:GetTeamTechs():ChangeResearchProgress(research, reward, id)
        return true
    end
    -- No selected tech (including an exhausted custom tech tree): bank exactly
    -- this many beakers until native research resumes. No free tech selection.
    local before = player:GetOverflowResearchTimes100()
    player:ChangeOverflowResearch(reward)
    return player:GetOverflowResearchTimes100() == before + reward * 100
end

GameEvents.PlayerBuilt.Add(function(id, unitID, x, y, build)
    if build ~= DIG or not reward or awarding then return end
    local player = Players[id]
    if not IsDirectorate(player) or not player:IsHuman() then return end
    local unit = player:GetUnitByID(unitID)
    if not unit or unit:GetOwner() ~= id or unit:GetUnitType() ~= UNIT
       or unit:GetX() ~= x or unit:GetY() ~= y then return end
    local plot = Map.GetPlot(x, y)
    -- PlayerBuilt is authoritative (CvUnit::build's bFinished branch). These
    -- are additional native-data checks, never an improvement-only detector.
    -- Human archaeology choices occur later, so the record is still available.
    if not plot or plot:GetImprovementType() ~= DIG_IMPROVEMENT
       or plot:GetArchaeologyArtifactType() < 0 then return end
    local marker = '[PALEO_SITE_V1:' .. x .. ':' .. y .. ']'
    if (player:GetScriptData() or ''):find(marker, 1, true) then return end
    awarding = true
    local ok, err = pcall(function()
        if AwardScience(player, id) then
            -- Save-safe append preserves every unrelated mod's ScriptData.
            -- Read again after the research callback; only commit a paid site.
            player:SetScriptData((player:GetScriptData() or '') .. marker)
        end
    end)
    awarding = false
    if not ok then error(err) end
end)

-- Bootstrap/load: bounded city scan, no full-map scan or per-frame polling.
Reconcile(function()
    for id = 0, GameDefines.MAX_CIV_PLAYERS - 1 do ReconcilePlayer(id) end
end)
