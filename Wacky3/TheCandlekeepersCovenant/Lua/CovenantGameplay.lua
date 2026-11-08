-- CP151, sequential single-player. No population, visibility or capture rewards.
if MapModData.CWC3_CovenantRegistered then return end
include('CWC3_Runtime')
local CIV = GameInfoTypes.CIVILIZATION_CWC3_COVENANT
local HALL = GameInfoTypes.BUILDING_CWC3_COVENANT_HALL
local IDENTITY = GameInfoTypes.PROMOTION_CWC3_COVENANT_ETERNAL_VIGIL
local DEFENSE = GameInfoTypes.PROMOTION_CWC3_COVENANT_DEFENSE
assert(CIV and HALL and IDENTITY and DEFENSE, 'CWC3 Covenant: database registration failed')
local keepers, storage = {}, nil
for i = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
    local p = Players[i]
    if p and p:IsHuman() and p:GetCivilizationType() == CIV then
        keepers[#keepers+1] = i
        storage = storage or p
    end
end
-- No Covenant present: no scans or event registrations.
if not storage then return end
MapModData.CWC3_CovenantRegistered = true
local culture, science, hallScience, dummies = {}, {}, {}, {}
local function Controllers(list, suffix, count)
    for i = 1, count do
        local b = GameInfoTypes['BUILDING_CWC3_COVENANT_' .. suffix .. i]
        assert(b, 'CWC3 Covenant: missing yield controller')
        list[i], dummies[#dummies+1] = b, b
    end
end
Controllers(culture, 'CAPITAL_CULTURE_', 12)
Controllers(science, 'CAPITAL_SCIENCE_', 4)
Controllers(hallScience, 'HALL_SCIENCE_', 2)
local flames, sequence, snapshots, ledger, awarded = 0, 0, {}, {}, {}
local dirty, pending = true, {}
local watched, veterans, busy = {}, {}, false
local function Key(x,y) return x .. ',' .. y end
local function Eligible(p)
    return p and p:IsAlive() and p:IsHuman() and p:GetCivilizationType() == CIV
end
local function Major(owner)
    local p = Players[owner]
    -- Do not require IsAlive: eliminated civilizations' last cities still count.
    return p and not p:IsMinorCiv() and not p:IsBarbarian() and p:GetCivilizationType() ~= CIV
end
local function CovenantFounder(owner)
    local p = Players[owner]
    return p and p:GetCivilizationType() == CIV
end
local function Identity(r)
    return table.concat({r.x,r.y,r.founded,r.original,r.serial}, ',')
end
local function At(x,y)
    local plot = Map.GetPlot(x,y)
    return plot and plot:GetPlotCity()
end

-- One shared world ledger is stored on the lowest-slot human Covenant player,
-- including while eliminated. Duplicate human Covenants share these global rules.
-- Other mods' ScriptData is preserved. Serial distinguishes observed same-turn
-- refounding even when the engine reuses a local city ID/founding-turn pair.
local function Save()
    if not dirty then return end
    local records = {flames .. ',' .. sequence}
    for _, id in ipairs(ledger) do records[#records+1] = 'L,' .. id end
    local keys = {}
    for key in pairs(snapshots) do keys[#keys+1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local r = snapshots[key]
        records[#records+1] = 'S,' .. table.concat({r.x,r.y,r.founded,r.original,r.owner,r.cityID,r.serial,r.blocked and 1 or 0,r.pending and 1 or 0}, ',')
    end
    local old = storage:GetScriptData() or ''
    local value = old:gsub('%[CWC3_COVENANT_V1:[^%]]*%]', '')
        .. '[CWC3_COVENANT_V1:' .. table.concat(records, ';') .. ']'
    if value ~= old then storage:SetScriptData(value) end
    dirty = false
end
local function Load()
    local data = (storage:GetScriptData() or ''):match('%[CWC3_COVENANT_V1:([^%]]*)%]')
    if not data then return end
    local n, seq = data:match('^(%d+),(%d+)')
    flames, sequence = math.min(12,tonumber(n) or 0), tonumber(seq) or 0
    for part in data:gmatch('[^;]+') do
        local id = part:match('^L,([%d,%-]+)$')
        if id and not awarded[id] and #ledger < 12 then
            ledger[#ledger+1], awarded[id] = id, true
        end
        local x,y,f,o,owner,cid,serial,blocked,pendingFlag = part:match('^S,(%d+),(%d+),(%-?%d+),(%-?%d+),(%d+),(%d+),(%d+),([01]),([01])$')
        if x then
            local r = {x=tonumber(x),y=tonumber(y),founded=tonumber(f),original=tonumber(o),owner=tonumber(owner),cityID=tonumber(cid),serial=tonumber(serial),blocked=blocked=='1',pending=pendingFlag=='1'}
            snapshots[Key(r.x,r.y)] = r
            if r.pending then pending[Key(r.x,r.y)] = true end
            sequence = math.max(sequence,r.serial)
        end
    end
end
local function Destroyed(r)
    local id = Identity(r)
    if flames < 12 and not awarded[id] and not r.blocked and Major(r.owner) then
        flames = flames + 1
        ledger[#ledger+1], awarded[id] = id, true
        dirty = true
    end
end
local function Observe(city, fresh)
    local x,y = city:GetX(),city:GetY()
    local key, founded = Key(x,y), city:GetGameTurnFounded()
    local r = snapshots[key]
    -- Only a verified founding callback can force a same-turn new lifetime.
    -- OriginalOwner may change in special acquisitions; that alone is no death.
    if r and (fresh or r.founded ~= founded) then
        Destroyed(r)
        snapshots[key], r = nil, nil
        pending[key], dirty = nil, true
    end
    if not r then
        sequence = sequence + 1
        r = {x=x,y=y,founded=founded,original=city:GetOriginalOwner(),serial=sequence}
        r.blocked = CovenantFounder(r.original) or false
        snapshots[key] = r
        dirty = true
    end
    if r.owner ~= city:GetOwner() or r.cityID ~= city:GetID() then dirty = true end
    r.owner, r.cityID = city:GetOwner(), city:GetID()
    -- Once excluded as Covenant-founded, preserve that fact through acquisitions.
    local blocked = r.blocked or CovenantFounder(city:GetOriginalOwner()) or false
    if r.blocked ~= blocked then dirty = true end
    r.blocked = blocked
    return r
end
local function FullWorld()
    local seen = {}
    -- City iterators, never map scans; include minor cities to track later transfers.
    for i = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
        local p = Players[i]
        if p then
            for city in p:Cities() do
                Observe(city)
                seen[Key(city:GetX(),city:GetY())] = true
            end
        end
    end
    for key,r in pairs(snapshots) do
        if not seen[key] then
            -- A surviving city on the plot always defeats a missing-owner entry.
            local city = At(r.x,r.y)
            if city then Observe(city)
            else
                Destroyed(r); snapshots[key], pending[key], dirty = nil, nil, true
            end
        end
    end
end
local function ResolvePending()
    for key in pairs(pending) do
        local r = snapshots[key]
        if r then
            local city = At(r.x,r.y)
            if city then
                Observe(city)
                r.pending = false
            else Destroyed(r); snapshots[key] = nil end
            dirty = true
        end
        pending[key] = nil
    end
end
local function CityYields(city)
    local p = Players[city:GetOwner()]
    local valid = Eligible(p)
    local capital = valid and p:GetCapitalCity()
    local isCapital = capital and capital:GetID() == city:GetID()
    local hasHall = valid and city:GetNumBuilding(HALL) > 0
    for i,b in ipairs(culture) do CWC3.SetBuilding(city,b,isCapital and flames >= i) end
    for i,b in ipairs(science) do CWC3.SetBuilding(city,b,isCapital and math.floor(flames/3) >= i) end
    CWC3.SetBuilding(city,hallScience[1],hasHall and flames >= 3)
    CWC3.SetBuilding(city,hallScience[2],hasHall and flames >= 9)
    watched[Key(city:GetX(),city:GetY())] = valid and {x=city:GetX(),y=city:GetY()} or nil
end
local function Yields()
    for key,coord in pairs(watched) do
        local city = At(coord.x,coord.y)
        if not city then watched[key] = nil
        elseif not Eligible(Players[city:GetOwner()]) then CityYields(city) end
    end
    for _,i in ipairs(keepers) do
        for city in Players[i]:Cities() do CityYields(city) end
    end
end
local function Transaction(work)
    if busy then return end
    busy = true
    local ok,err = pcall(work)
    busy = false
    if not ok then error(err) end
end
local function Unit(unit)
    if not unit then return end
    local identity = unit:IsHasPromotion(IDENTITY)
    local owner,id = unit:GetOwner(),unit:GetID()
    if not identity and not unit:IsHasPromotion(DEFENSE) and not (veterans[owner] and veterans[owner][id]) then return end
    veterans[owner] = veterans[owner] or {}
    veterans[owner][id] = identity and true or nil
    local plot = unit:GetPlot()
    local active = identity and plot and plot:IsFriendlyTerritory(owner) or false
    if unit:IsHasPromotion(DEFENSE) ~= active then unit:SetHasPromotion(DEFENSE,active) end
end
local function OnUnit(owner,id)
    local p = Players[owner]
    if p then Unit(p:GetUnitByID(id)) end
end
local function PlotUnits(x,y)
    local plot = Map.GetPlot(x,y)
    if plot then for i = 0,plot:GetNumUnits()-1 do Unit(plot:GetUnit(i)) end end
end
local function Veterans()
    for owner,units in pairs(veterans) do
        for id in pairs(units) do
            local unit = Players[owner]:GetUnitByID(id)
            if unit then Unit(unit) else units[id] = nil end
        end
    end
end
GameEvents.UnitSetXY.Add(OnUnit)
GameEvents.UnitCreated.Add(OnUnit)
GameEvents.UnitConverted.Add(function(oldOwner,newOwner,oldUnit,newUnit)
    if veterans[oldOwner] then veterans[oldOwner][oldUnit] = nil end
    OnUnit(newOwner,newUnit)
end)
GameEvents.TileOwnershipChanged.Add(PlotUnits)
-- Verified BATTLE_STARTED precedes melee/ranged/air strength calculation.
-- Repair target veterans even after diplomacy changes without any movement.
GameEvents.BattleStarted.Add(function(_,x,y) PlotUnits(x,y) end)
GameEvents.CityRazed.Add(function(owner,x,y)
    Transaction(function()
        local city = At(x,y)
        if city then
            local r = Observe(city)
            r.owner, r.pending = owner, true
            pending[Key(x,y)], dirty = true, true
            Save()
        end
        -- PRE-removal callback: never award here or poll while native kill runs.
    end)
end)
GameEvents.PlayerCityFounded.Add(function(_,x,y)
    Transaction(function()
        local city = At(x,y)
        if city then Observe(city,true) end
        ResolvePending(); Yields(); Save()
    end)
end)
GameEvents.CityCaptureComplete.Add(function(_,_,x,y)
    Transaction(function()
        local city = At(x,y)
        if city then Observe(city); CityYields(city) end
        -- Never interpret the temporary delete/recreate inside acquireCity as death.
        Yields(); Save()
    end)
end)
GameEvents.PlayerLiberated.Add(function(_,owner,id)
    Transaction(function()
        local city = Players[owner] and Players[owner]:GetCityByID(id)
        if city then Observe(city); CityYields(city) end
        Yields(); Save()
    end)
end)
local function Building(owner,id,building)
    if building ~= HALL then return end
    Transaction(function()
        local city = Players[owner] and Players[owner]:GetCityByID(id)
        if city then CityYields(city) end
    end)
end
GameEvents.CityConstructed.Add(Building) -- Gold/Faith purchase included in CP151.
GameEvents.CitySoldBuilding.Add(Building)
GameEvents.CityCanConstruct.Add(function(_,_,building)
    for _,b in ipairs(dummies) do if building == b then return false end end
    return true
end)
GameEvents.PlayerDoTurn.Add(function(owner)
    Transaction(function()
        -- Owner-local snapshots, plus bounded pre-removal candidates from ANY turn.
        local p = Players[owner]
        if p then for city in p:Cities() do Observe(city) end end
        ResolvePending(); Yields(); Veterans(); Save()
    end)
end)
Events.NewGameTurn.Add(function()
    Transaction(function() FullWorld(); Yields(); Veterans(); Save() end)
end)
-- Load saved state BEFORE observing current world; missing saved cities can award
-- once. A fresh game seeds only existing cities; it fabricates no ancient losses.
Transaction(function()
    Load(); FullWorld()
    for i = 0,GameDefines.MAX_CIV_PLAYERS-1 do
        local p = Players[i]
        if p then
            for city in p:Cities() do CityYields(city) end
            for unit in p:Units() do Unit(unit) end
        end
    end
    Save()
end)
