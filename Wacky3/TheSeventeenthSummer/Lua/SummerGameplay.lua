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
local unitSweepTurns = {}

local function Eligible(player)
    return player and player:IsAlive() and player:IsHuman() and player:GetCivilizationType() == CIV
end

local function Phase(count)
    return count > 0 and ((count - 1) % (dormant + emerged)) >= dormant and 1 or 0
end

local function Save(player, state)
    local old = player:GetScriptData() or ''
    -- Remove malformed closed records too, without swallowing another namespace.
    local data = old:gsub('%[CWC3_SUMMER:[^%[%]]*%]', '')
    data = data .. '[CWC3_SUMMER:' .. state.count .. ':' .. state.phase .. ':' .. state.last .. ']'
    if old ~= data then player:SetScriptData(data) end
end

local function State(iPlayer)
    if states[iPlayer] then return states[iPlayer] end
    local player, now = Players[iPlayer], Game.GetGameTurn()
    local data = player:GetScriptData() or ''
    local state, repair
    for record in data:gmatch('%[CWC3_SUMMER:([^%[%]]*)%]') do
        local count, phase, last = record:match('^(%d+):([01]):(%-?%d+)$')
        count, phase, last = tonumber(count), tonumber(phase), tonumber(last)
        -- At most one owner-turn per nonnegative game-turn identifier. Bounds
        -- also reject infinities/overflow before applying the existing Phase rule.
        if count and last and count <= now + 1 and last >= -1 and last < math.huge
           and count <= last + 1 and phase == Phase(count) then
            state = {count=count, phase=phase, last=math.min(last, now)}
            repair = last > now
            break
        end
    end
    if not state then
        -- Missing state is a fresh game. Corrupt state cannot establish whether
        -- this turn already paid: recover Dormancy and wait until the next turn.
        local corrupt = data:find('[CWC3_SUMMER:', 1, true) ~= nil
        state = {count=0, phase=0, last=corrupt and now or -1}
        repair = corrupt
    end
    states[iPlayer] = state
    local _, records = data:gsub('%[CWC3_SUMMER:[^%[%]]*%]', '')
    if repair or records > 1 then Save(player, state) end
    return state
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

local function Unit(iPlayer, unit)
    if not unit then return end
    local lineage = unit:IsHasPromotion(LINEAGE)
    local current = unit:IsHasPromotion(AWAKENED)
    -- Only the actual unique unit can seed ancestry. Descendants use the native
    -- persistent marker, never unit class, combat class or upgrade destination.
    if not lineage and unit:GetUnitType() == SHELL then
        unit:SetHasPromotion(LINEAGE, true)
        lineage = true
    end
    -- Ordinary units never need owner/phase/ScriptData queries. Illegal Awakened
    -- copies are still removed, including from unrelated foreign units.
    local awake = lineage and Awake(iPlayer)
    if current ~= awake then unit:SetHasPromotion(AWAKENED, awake) end
end

local function Cities(iPlayer)
    local player = Players[iPlayer]
    if not player then return end
    for city in player:Cities() do City(city) end
end

local function SweepUnits(iPlayer)
    local player = Players[iPlayer]
    if not player then return end
    -- Keep one owner-local recovery scan per game turn, even for foreign players:
    -- this discovers illegal promotions inserted without a lifecycle callback.
    local turn = Game.GetGameTurn()
    if unitSweepTurns[iPlayer] and turn <= unitSweepTurns[iPlayer] then return end
    unitSweepTurns[iPlayer] = turn
    for unit in player:Units() do Unit(iPlayer, unit) end
end

local function Reconcile(work)
    if busy then return end
    busy = true
    local ok, err = pcall(work)
    busy = false
    if not ok then error(err) end
end

local function Tracked(transfersOnly)
    Reconcile(function()
        for key, coord in pairs(watched) do
            local plot = Map.GetPlot(coord.x, coord.y)
            local city = plot and plot:GetPlotCity()
            if not city then watched[key] = nil
            elseif not transfersOnly or not Eligible(Players[city:GetOwner()]) then City(city) end
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
                Cities(iPlayer)
                SweepUnits(iPlayer)
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
        Cities(iPlayer)
        SweepUnits(iPlayer)
    end)
    -- Native acquisition callbacks and city dirtiness handle transfers promptly.
    -- Recover missed transfers on the Summer owner's turn without re-reading
    -- every Summer city's eight controller counts after every unrelated turn.
    if Eligible(Players[iPlayer]) then Tracked(true) end
end)

local function At(x, y)
    local plot = Map.GetPlot(x, y)
    City(plot and plot:GetPlotCity())
end
GameEvents.PlayerCityFounded.Add(function(_, x, y) Reconcile(function() At(x,y) end) end)
GameEvents.CityCaptureComplete.Add(function(_, _, x, y) Reconcile(function() At(x,y) end) end)
GameEvents.PlayerLiberated.Add(function(_, owner) Reconcile(function() Cities(owner) end) end)
local function Building(owner, id, building)
    if building ~= NURSERY then return end
    Reconcile(function()
        local player = Players[owner]
        if player then City(player:GetCityByID(id)) end
    end)
end
GameEvents.CityConstructed.Add(Building)
GameEvents.CitySoldBuilding.Add(Building)
Events.SerialEventCityInfoDirty.Add(function() Tracked(false) end)
local function OnUnit(owner, id)
    if busy then return end
    local player = Players[owner]
    local unit = player and player:GetUnitByID(id)
    if not unit then return end
    if unit:GetUnitType() ~= SHELL and not unit:IsHasPromotion(LINEAGE)
       and not unit:IsHasPromotion(AWAKENED) then return end
    Reconcile(function() Unit(owner,unit) end)
end
GameEvents.UnitCreated.Add(OnUnit)
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
        Unit(newOwner,new)
    end)
end)
GameEvents.UnitSetXY.Add(OnUnit)
GameEvents.CityCanConstruct.Add(function(_, _, building)
    for _, dummy in ipairs(dummies) do if building == dummy then return false end end
    return true
end)

-- Bootstrap/load: repair every living player's cities/units, including foreign
-- free copies and leaked temporary promotions. Never advance or notify here.
Reconcile(function()
    for i = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
        if Players[i] and Players[i]:IsAlive() then
            Cities(i)
            -- Do not consume this turn's recovery scan during bootstrap: the
            -- forthcoming callback may establish a different saved phase.
            for unit in Players[i]:Units() do Unit(i,unit) end
        end
    end
end)
