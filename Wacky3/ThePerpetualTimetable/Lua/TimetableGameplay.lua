-- CP151 PlayerDoTurn is post-economy: these recurring city yields govern the
-- NEXT payout after reconciliation. No instant yields, UI polling or ledger.
if MapModData.CWC3_TimetableRegistered then return end
include('CWC3_Runtime')
local CIV = GameInfoTypes.CIVILIZATION_CWC3_PERPETUAL_TIMETABLE
local OFFICE = GameInfoTypes.BUILDING_CWC3_DISPATCH_OFFICE
local TECH = GameInfoTypes.TECH_RAILROAD
local RAIL = GameInfoTypes.ROUTE_RAILROAD
local PRODUCTION = GameInfoTypes.BUILDING_CWC3_TIMETABLE_CONNECTION_PRODUCTION
local SCIENCE = GameInfoTypes.BUILDING_CWC3_TIMETABLE_CONNECTION_SCIENCE
local CULTURE = GameInfoTypes.BUILDING_CWC3_TIMETABLE_RAIL_CULTURE
local OFFICE_CULTURE = GameInfoTypes.BUILDING_CWC3_TIMETABLE_DISPATCH_CULTURE
local OFFICE_PRODUCTION = GameInfoTypes.BUILDING_CWC3_TIMETABLE_DISPATCH_RAIL_PRODUCTION
assert(CIV and OFFICE and TECH and RAIL and PRODUCTION and SCIENCE and CULTURE
       and OFFICE_CULTURE and OFFICE_PRODUCTION,
       'CWC3 Timetable: missing database definitions; check Database.log')
MapModData.CWC3_TimetableRegistered = true
local dummies = {PRODUCTION, SCIENCE, CULTURE, OFFICE_CULTURE, OFFICE_PRODUCTION}
local watched, busy = {}, false

local function Eligible(player)
    return player and player:IsAlive() and player:IsHuman() and player:GetCivilizationType() == CIV
end

local function Clear(city)
    for _, building in ipairs(dummies) do CWC3.SetBuilding(city, building, 0) end
end

-- One queue walk shared by ALL cities and BOTH UA/UB. Only the reachable owned
-- rail network and its boundary are visited; no whole-map or per-city searches.
local function RailNetwork(owner, team, capital)
    local reached, examined, queue = {}, {}, {}
    local function Accept(plot)
        if not plot then return end
        local index = plot:GetPlotIndex()
        if examined[index] then return end
        examined[index] = true
        if plot:GetOwner() ~= owner or plot:IsWater() or plot:IsMountain()
           or plot:IsImpassable(team) then return end
        local city = plot:GetPlotCity()
        if not (city and city:GetOwner() == owner)
           and (plot:GetRouteType() ~= RAIL or plot:IsRoutePillaged()) then return end
        reached[index] = true
        queue[#queue + 1] = plot
    end
    Accept(Map.GetPlot(capital:GetX(), capital:GetY()))
    local head = 1
    while head <= #queue do
        local plot = queue[head]
        for direction = 0, 5 do
            Accept(Map.PlotDirection(plot:GetX(), plot:GetY(), direction))
        end
        head = head + 1
    end
    return reached
end

local function Player(owner)
    local player = Players[owner]
    if not player then return end
    local eligible = Eligible(player)
    local capital = eligible and player:GetCapitalCity()
    local reached = {}
    if capital then
        local team = player:GetTeam()
        if Teams[team]:IsHasTech(TECH) then reached = RailNetwork(owner, team, capital) end
    end
    for city in player:Cities() do
        local x, y = city:GetX(), city:GetY()
        watched[x .. ':' .. y] = eligible and {x=x, y=y} or nil
        if not eligible then
            Clear(city)
        else
            local nonCapital = capital and city:GetID() ~= capital:GetID()
            -- This binding reads the native city's ordinary connection flag;
            -- roads, Harbors and legitimate CP connections retain engine rules.
            local connected = nonCapital and player:IsCapitalConnectedToCity(city)
            local plot = Map.GetPlot(x, y)
            local railroad = nonCapital and plot and reached[plot:GetPlotIndex()] == true
            local office = city:GetNumBuilding(OFFICE) > 0
            CWC3.SetBuilding(city, PRODUCTION, connected)
            CWC3.SetBuilding(city, SCIENCE, connected)
            CWC3.SetBuilding(city, CULTURE, railroad)
            CWC3.SetBuilding(city, OFFICE_CULTURE, office and connected)
            CWC3.SetBuilding(city, OFFICE_PRODUCTION, office and railroad)
        end
    end
end

local function Reconcile(work)
    if busy then return end
    busy = true
    local ok, err = pcall(work)
    busy = false
    if not ok then error(err) end
end

local function CleanupTransfers()
    for key, coord in pairs(watched) do
        local plot = Map.GetPlot(coord.x, coord.y)
        local city = plot and plot:GetPlotCity()
        if not city then watched[key] = nil
        elseif not Eligible(Players[city:GetOwner()]) then
            Clear(city)
            watched[key] = nil
        end
    end
end

GameEvents.PlayerDoTurn.Add(function(owner)
    Reconcile(function()
        Player(owner)
        if Eligible(Players[owner]) then CleanupTransfers() end
    end)
end)
GameEvents.PlayerCityFounded.Add(function(owner)
    Reconcile(function() Player(owner) end)
end)
GameEvents.CityCaptureComplete.Add(function(oldOwner, _, x, y, newOwner)
    Reconcile(function()
        -- acquireCity can replace both city ID and object; resolve coordinates.
        local plot = Map.GetPlot(x, y)
        local city = plot and plot:GetPlotCity()
        if city and not Eligible(Players[city:GetOwner()]) then Clear(city) end
        -- Capital replacement and an acquired city junction can change the whole
        -- network, so evaluate each affected eligible owner once, not each city.
        if Eligible(Players[oldOwner]) then Player(oldOwner) end
        if newOwner ~= oldOwner and Eligible(Players[newOwner]) then Player(newOwner) end
        CleanupTransfers()
    end)
end)
GameEvents.PlayerLiberated.Add(function(_, owner)
    Reconcile(function() Player(owner); CleanupTransfers() end)
end)
local function Building(owner, _, building)
    if building ~= OFFICE then return end
    Reconcile(function() Player(owner) end)
end
GameEvents.CityConstructed.Add(Building)
GameEvents.CitySoldBuilding.Add(Building)
GameEvents.CityCanConstruct.Add(function(_, _, building)
    for _, dummy in ipairs(dummies) do if building == dummy then return false end end
    return true
end)

-- Bootstrap/reload recomputes from current state, clears foreign/free leaks and
-- repairs exact 0/1 counts. Does not award income or modify any ScriptData.
Reconcile(function()
    for owner = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
        if Players[owner] then Player(owner) end
    end
end)
