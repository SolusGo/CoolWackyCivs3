-- BNW + standalone CP151. All yields are derived from current map/building state.
if MapModData.CWC3_ChoirRegistered then return end
include('CWC3_Runtime')
local CIV = GameInfoTypes.CIVILIZATION_CWC3_HOLLOW_CHOIR
local HALL = GameInfoTypes.BUILDING_CWC3_RESONANCE_HALL
local HILL = GameInfoTypes.BUILDING_CWC3_CHOIR_HILL_PRODUCTION
local F1 = GameInfoTypes.BUILDING_CWC3_CHOIR_MOUNTAIN_FAITH_1
local F2 = GameInfoTypes.BUILDING_CWC3_CHOIR_MOUNTAIN_FAITH_2
local S1 = GameInfoTypes.BUILDING_CWC3_CHOIR_RESONANCE_SCIENCE_1
local S2 = GameInfoTypes.BUILDING_CWC3_CHOIR_RESONANCE_SCIENCE_2
assert(CIV and HALL and HILL and F1 and F2 and S1 and S2,
       'CWC3 Choir: database registration failed; check Database.log')
MapModData.CWC3_ChoirRegistered = true
local dummies = {HILL, F1, F2, S1, S2}
local watchedCities = {}
local reconciling = false

local function IsHollowChoirPlayer(player)
    return player and player:IsAlive() and player:GetCivilizationType() == CIV
end

local function CountAdjacentMountains(city)
    local count, seen = 0, {}
    for direction = 0, 5 do
        local plot = Map.PlotDirection(city:GetX(), city:GetY(), direction)
        if plot then
            local key = plot:GetX() .. ':' .. plot:GetY()
            if not seen[key] and plot:IsMountain() then count = count + 1 end
            seen[key] = true
        end
    end
    return count
end

local function CountOwnedMountainsWithinRadius(city, radius)
    local x, y = city:GetX(), city:GetY()
    local center = Map.GetPlot(x, y)
    if not center then return 0 end
    -- Bounded hex traversal: at radius three there are at most 37 distinct plots.
    -- Deduplication also prevents double counting near wrapping map boundaries.
    local queue, seen, head, count = {{plot=center, depth=0}}, {[x .. ':' .. y]=true}, 1, 0
    while head <= #queue do
        local item = queue[head]
        head = head + 1
        local plot = item.plot
        if plot:IsMountain() and plot:GetOwner() == city:GetOwner()
           and Map.PlotDistance(x, y, plot:GetX(), plot:GetY()) <= radius then
            count = count + 1
        end
        if item.depth < radius then
            for direction = 0, 5 do
                local adjacent = Map.PlotDirection(plot:GetX(), plot:GetY(), direction)
                if adjacent then
                    local key = adjacent:GetX() .. ':' .. adjacent:GetY()
                    if not seen[key] then
                        seen[key] = true
                        queue[#queue+1] = {plot=adjacent, depth=item.depth+1}
                    end
                end
            end
        end
    end
    return count
end

local function RemoveHollowChoirDummyBuildings(city)
    for _, building in ipairs(dummies) do CWC3.SetBuilding(city, building, false) end
end

local function ReconcileHollowChoirCity(city)
    if not city then return end
    local eligible = IsHollowChoirPlayer(Players[city:GetOwner()])
    local x, y = city:GetX(), city:GetY()
    watchedCities[x .. ':' .. y] = eligible and {x=x, y=y} or nil
    if not eligible then
        RemoveHollowChoirDummyBuildings(city)
        return
    end
    local center = Map.GetPlot(x, y)
    CWC3.SetBuilding(city, HILL, center and center:IsHills())
    -- Adjacency Faith is independent of hills and mountain ownership.
    local faith = math.min(2, CountAdjacentMountains(city))
    CWC3.SetBuilding(city, F1, faith >= 1)
    CWC3.SetBuilding(city, F2, faith >= 2)
    local science = 0
    if city:GetNumBuilding(HALL) > 0 then
        -- Civilization ownership, never working-city assignment: overlapping
        -- radii independently count the same owned mountains.
        science = math.min(2, math.floor(CountOwnedMountainsWithinRadius(city, 3) / 2))
    end
    CWC3.SetBuilding(city, S1, science >= 1)
    CWC3.SetBuilding(city, S2, science >= 2)
end

local function ReconcileHollowChoirPlayer(iPlayer)
    local player = Players[iPlayer]
    if player then
        for city in player:Cities() do ReconcileHollowChoirCity(city) end
    end
end

local function Reconcile(work)
    if reconciling then return end
    reconciling = true
    local ok, err = pcall(work)
    reconciling = false
    if not ok then error(err) end
end

local function ReconcileChoirPlayers()
    for i = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
        if IsHollowChoirPlayer(Players[i]) then ReconcileHollowChoirPlayer(i) end
    end
end

local function ReconcileTracked()
    Reconcile(function()
        for key, coord in pairs(watchedCities) do
            local plot = Map.GetPlot(coord.x, coord.y)
            local city = plot and plot:GetPlotCity()
            if city then ReconcileHollowChoirCity(city) else watchedCities[key] = nil end
        end
    end)
end

GameEvents.PlayerCityFounded.Add(function(iPlayer, x, y)
    Reconcile(function()
        local plot = Map.GetPlot(x, y)
        ReconcileHollowChoirCity(plot and plot:GetPlotCity())
    end)
end)
GameEvents.CityCaptureComplete.Add(function(_, _, x, y)
    -- CP151 completion follows building/territory transfer for conquest, gifts,
    -- cessions and liberation. Query the new city object; strip all foreign dummies.
    Reconcile(function()
        local plot = Map.GetPlot(x, y)
        ReconcileHollowChoirCity(plot and plot:GetPlotCity())
        ReconcileChoirPlayers()
    end)
end)
GameEvents.PlayerLiberated.Add(function(_, iPlayer)
    Reconcile(function() ReconcileHollowChoirPlayer(iPlayer); ReconcileChoirPlayers() end)
end)
GameEvents.TileOwnershipChanged.Add(function(_, _, newOwner, oldOwner)
    -- Callback follows the native ownership assignment; borders are never cached.
    Reconcile(function()
        if IsHollowChoirPlayer(Players[newOwner]) then ReconcileHollowChoirPlayer(newOwner) end
        if oldOwner ~= newOwner and IsHollowChoirPlayer(Players[oldOwner]) then
            ReconcileHollowChoirPlayer(oldOwner)
        end
    end)
end)
local function OnBuilding(iPlayer, iCity, iBuilding)
    if iBuilding ~= HALL then return end
    Reconcile(function()
        local player = Players[iPlayer]
        if player then ReconcileHollowChoirCity(player:GetCityByID(iCity)) end
    end)
end
GameEvents.CityConstructed.Add(OnBuilding)
GameEvents.CitySoldBuilding.Add(OnBuilding)
Events.SerialEventCityInfoDirty.Add(ReconcileTracked)
-- Pre-first-player publication repairs all Choir cities. These are passive map
-- yields, not a per-turn snapshot; there is no first-player-slot restriction.
-- Native UI dispatch synchrony still requires in-game acceptance.
Events.NewGameTurn.Add(function() Reconcile(function() ReconcileChoirPlayers() end) end)
Events.ActivePlayerTurnStart.Add(ReconcileTracked)
GameEvents.PlayerDoTurn.Add(function(iPlayer)
    -- Verified CP151 PlayerDoTurn is post-economy: recovery only. Direct map/building
    -- callbacks and bootstrap establish yields before ordinary economic collection.
    Reconcile(function() ReconcileHollowChoirPlayer(iPlayer) end)
    ReconcileTracked()
end)
GameEvents.CityCanConstruct.Add(function(_, _, building)
    for _, dummy in ipairs(dummies) do if building == dummy then return false end end
    return true
end)

-- Fresh game/load: no saved Lua state, random calls or accumulated rewards.
-- One bounded city scan also strips any foreign real/free controller copies.
Reconcile(function()
    for i = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
        if Players[i] and Players[i]:IsAlive() then ReconcileHollowChoirPlayer(i) end
    end
end)
