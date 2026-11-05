-- CP151 PlayerDoTurn is post-economy. A phase governs combat now and the NEXT
-- city payout. Never infer a pre-economy boundary from asynchronous UI events.
if MapModData.CWC3_SummerRegistered then return end
include('CWC3_Runtime')
local CIV = GameInfoTypes.CIVILIZATION_CWC3_SEVENTEENTH_SUMMER
local SHELL = GameInfoTypes.UNIT_CWC3_SHELLGUARD
local NURSERY = GameInfoTypes.BUILDING_CWC3_BROOD_NURSERY
local LINEAGE = GameInfoTypes.PROMOTION_SUMMER_BROOD_LINEAGE
local AWAKENED = GameInfoTypes.PROMOTION_SUMMER_AWAKENED
local FOOD = GameInfoTypes.BUILDING_SUMMER_DORMANT_FOOD
local PRODUCTION = GameInfoTypes.BUILDING_SUMMER_EMERGENCE_PRODUCTION
local CULTURE = GameInfoTypes.BUILDING_SUMMER_EMERGENCE_CULTURE
local EXTRA = GameInfoTypes.BUILDING_SUMMER_NURSERY_PRODUCTION
assert(CIV and SHELL and NURSERY and LINEAGE and AWAKENED and FOOD and PRODUCTION and CULTURE and EXTRA,
       'CWC3 Summer: missing database definitions; check Database.log')
local speed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
local cycle
-- Custom configuration has GameSpeedType rather than the engine's Type/ID keys.
for row in GameInfo.CWC3_SummerCycles() do
    if speed and row.GameSpeedType == speed.Type then cycle = row end
end
assert(cycle and cycle.Dormancy > 0 and cycle.Emergence > 0,
       'CWC3 Summer: configure positive durations in CWC3_SummerCycles for this game speed')
MapModData.CWC3_SummerRegistered = true
local dormant, emerged = cycle.Dormancy, cycle.Emergence
local dummies = {FOOD, PRODUCTION, CULTURE, EXTRA}
local states, watched, busy = {}, {}, false

local function Eligible(player)
    return player and player:IsAlive() and player:IsHuman() and player:GetCivilizationType() == CIV
end

local function Phase(count)
    return count > 0 and ((count - 1) % (dormant + emerged)) >= dormant and 1 or 0
end

local function State(iPlayer)
    if states[iPlayer] then return states[iPlayer] end
    local player = Players[iPlayer]
    local count, phase, last = (player:GetScriptData() or ''):match('%[CWC3_SUMMER:(%d+):([01]):(%-?%d+)%]')
    count, phase, last = tonumber(count), tonumber(phase), tonumber(last)
    -- No phase progression on load. Invalid/absent state starts in Dormancy.
    if not count or not last or last < -1 or phase ~= Phase(count) then
        count, phase, last = 0, 0, -1
    end
    states[iPlayer] = {count=count, phase=phase, last=last}
    return states[iPlayer]
end

local function Save(player, state)
    local old = player:GetScriptData() or ''
    local data = old:gsub('%[CWC3_SUMMER:%d+:[01]:%-?%d+%]', '')
    data = data .. '[CWC3_SUMMER:' .. state.count .. ':' .. state.phase .. ':' .. state.last .. ']'
    if old ~= data then player:SetScriptData(data) end
end

local function Awake(iPlayer)
    return Eligible(Players[iPlayer]) and State(iPlayer).phase == 1
end

local function City(city)
    if not city then return end
    local owner, x, y = city:GetOwner(), city:GetX(), city:GetY()
    local eligible = Eligible(Players[owner])
    watched[x .. ':' .. y] = eligible and {x=x, y=y} or nil
    local awake = eligible and Awake(owner)
    CWC3.SetBuilding(city, FOOD, eligible and not awake)
    CWC3.SetBuilding(city, PRODUCTION, awake)
    CWC3.SetBuilding(city, CULTURE, awake)
    CWC3.SetBuilding(city, EXTRA, awake and city:GetNumBuilding(NURSERY) > 0)
end

local function Unit(iPlayer, iUnit)
    local player = Players[iPlayer]
    local unit = player and player:GetUnitByID(iUnit)
    if not unit then return end
    -- Only the actual unique unit can seed ancestry. Descendants use the native
    -- persistent marker, never unit class, combat class or upgrade destination.
    if unit:GetUnitType() == SHELL and not unit:IsHasPromotion(LINEAGE) then
        unit:SetHasPromotion(LINEAGE, true)
    end
    local awake = Awake(iPlayer) and unit:IsHasPromotion(LINEAGE)
    if unit:IsHasPromotion(AWAKENED) ~= awake then unit:SetHasPromotion(AWAKENED, awake) end
end

local function Player(iPlayer)
    local player = Players[iPlayer]
    if not player then return end
    for city in player:Cities() do City(city) end
    for unit in player:Units() do Unit(iPlayer, unit:GetID()) end
end

local function Reconcile(work)
    if busy then return end
    busy = true
    local ok, err = pcall(work)
    busy = false
    if not ok then error(err) end
end

local function Tracked()
    Reconcile(function()
        for key, coord in pairs(watched) do
            local plot = Map.GetPlot(coord.x, coord.y)
            local city = plot and plot:GetPlotCity()
            if city then City(city) else watched[key] = nil end
        end
    end)
end

GameEvents.PlayerDoTurn.Add(function(iPlayer)
    Reconcile(function()
        local player = Players[iPlayer]
        if Eligible(player) then
            local state, turn = State(iPlayer), Game.GetGameTurn()
            if turn > state.last then
                local previous = state.phase
                state.count, state.last = state.count + 1, turn
                state.phase = Phase(state.count)
                -- Persist before callbacks from building/promotion writes.
                Save(player, state)
                Player(iPlayer)
                if previous ~= state.phase then
                    local key = state.phase == 1 and 'EMERGENCE' or 'DORMANCY'
                    player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,
                        Locale.ConvertTextKey('TXT_KEY_CWC3_SUMMER_' .. key .. '_NOTICE'),
                        Locale.ConvertTextKey('TXT_KEY_CWC3_SUMMER_' .. key .. '_TITLE'), -1, -1, -1)
                end
                return
            end
        end
        -- Duplicate callbacks repair counts but do not advance or notify.
        Player(iPlayer)
    end)
    Tracked()
end)

local function At(x, y)
    local plot = Map.GetPlot(x, y)
    City(plot and plot:GetPlotCity())
end
GameEvents.PlayerCityFounded.Add(function(_, x, y) Reconcile(function() At(x,y) end) end)
GameEvents.CityCaptureComplete.Add(function(_, _, x, y) Reconcile(function() At(x,y) end) end)
GameEvents.PlayerLiberated.Add(function(_, owner) Reconcile(function() Player(owner) end) end)
local function Building(owner, id, building)
    if building ~= NURSERY then return end
    Reconcile(function()
        local player = Players[owner]
        if player then City(player:GetCityByID(id)) end
    end)
end
GameEvents.CityConstructed.Add(Building)
GameEvents.CitySoldBuilding.Add(Building)
Events.SerialEventCityInfoDirty.Add(Tracked)
GameEvents.UnitCreated.Add(function(owner, id) Reconcile(function() Unit(owner,id) end) end)
GameEvents.UnitConverted.Add(function(oldOwner, newOwner, oldID, newID, upgrade)
    -- CP151 invokes this after promotion transfer and before killing the old unit.
    -- New-unit creation and UnitUpgraded are too early to repair lost Awakened.
    Reconcile(function()
        local oldPlayer, newPlayer = Players[oldOwner], Players[newOwner]
        local old = oldPlayer and oldPlayer:GetUnitByID(oldID)
        local new = newPlayer and newPlayer:GetUnitByID(newID)
        if upgrade and old and new and old:IsHasPromotion(LINEAGE) and not new:IsHasPromotion(LINEAGE) then
            new:SetHasPromotion(LINEAGE, true)
        end
        Unit(newOwner,newID)
    end)
end)
GameEvents.UnitSetXY.Add(function(owner,id) Reconcile(function() Unit(owner,id) end) end)
GameEvents.CityCanConstruct.Add(function(_, _, building)
    for _, dummy in ipairs(dummies) do if building == dummy then return false end end
    return true
end)

-- Bootstrap/load: repair every living player's cities/units, including foreign
-- free copies and leaked temporary promotions. Never advance or notify here.
Reconcile(function()
    for i = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
        if Players[i] and Players[i]:IsAlive() then Player(i) end
    end
end)
