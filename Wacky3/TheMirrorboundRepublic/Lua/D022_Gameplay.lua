include('CWC3_Daily')
local daily = CWC3Daily
local key = 'CWC3_D022_V1'
local counterKey = 'CWC3_D022_COUNTER_V1'
local lineage = assert(GameInfoTypes.PROMOTION_CWC3_D022_LINEAGE)
local counter = assert(GameInfoTypes.PROMOTION_CWC3_D022_COUNTER)
local doctrine = assert(GameInfoTypes.PROMOTION_CWC3_D022_DOCTRINE)
local chamber = assert(GameInfoTypes.BUILDING_CWC3_D022)
local MELEE = 0 -- BattleTypeTypes in CP151 CustomMods.h

local function load(player)
    local turn, last, lessons, combat, science = (daily.Load(player, key) or ''):match(
        '^(%d+):(-?%d+):(%d+):(-?%d+):(-?%d+)$')
    return {turn=tonumber(turn) or 0, last=tonumber(last) or -1, lessons=tonumber(lessons) or 0,
        combat=tonumber(combat) or -100, science=tonumber(science) or -100}
end

local function save(player, state)
    daily.Save(player, key, table.concat({state.turn,state.last,state.lessons,state.combat,state.science}, ':'))
end

local lifecycle = daily.Install('D022', {'CHAMBER','METHOD'}, function(city, _, state)
    return {CHAMBER=state.lessons >= 3 and city:GetNumBuilding(chamber) > 0,
        METHOD=state.turn < state.science + 5 and city:IsCapital()}
end, load)

local function setCounter(unit, serial)
    daily.Save(unit, counterKey, serial)
    daily.Promotion(unit, counter, serial ~= nil)
end

local function refreshUnit(unit, state)
    if not unit then return end
    if not state or not daily.Military(unit) then
        daily.Promotion(unit, doctrine, false)
        setCounter(unit, nil)
        return
    end
    daily.Promotion(unit, doctrine, state.turn < state.combat + 3)
    local expiry = tonumber(daily.Load(unit, counterKey))
    setCounter(unit, unit:IsHasPromotion(lineage) and expiry and expiry >= state.turn and expiry or nil)
end

local function units(player, state)
    for unit in player:Units() do refreshUnit(unit, state) end
end

local function active()
    local player = Players[Game.GetActivePlayer()]
    if lifecycle.eligible(player) and player:IsHuman() then return player end
end

local function paint()
    local player = active()
    ContextPtr:SetHide(not player)
    if not player then return end
    local state = load(player)
    local combat = math.max(0, state.combat + 10 - state.turn)
    local science = math.max(0, state.science + 10 - state.turn)
    Controls.Lessons:SetText('Lessons: ' .. state.lessons .. ' / 5')
    Controls.Doctrine:SetText(combat > 0 and 'Revised Doctrine (' .. combat .. ' turns)' or 'Revised Doctrine (2 Lessons)')
    Controls.Method:SetText(science > 0 and 'Corrected Method (' .. science .. ' turns)' or 'Corrected Method (3 Lessons)')
    Controls.Doctrine:SetDisabled(state.lessons < 2 or combat > 0 or not player:IsTurnActive())
    Controls.Method:SetDisabled(state.lessons < 3 or science > 0 or not player:IsTurnActive())
end

local function spend(action, cost)
    local player = active()
    if not player or not player:IsTurnActive() then return end
    local state = load(player)
    if state.lessons < cost or state.turn < state[action] + 10 then return end
    state.lessons = state.lessons - cost
    state[action] = state.turn
    save(player, state)
    lifecycle.all()
    if action == 'combat' then units(player, state) end
    paint()
end

Controls.Doctrine:RegisterCallback(Mouse.eLClick, function() spend('combat', 2) end)
Controls.Method:RegisterCallback(Mouse.eLClick, function() spend('science', 3) end)
Events.ActivePlayerTurnStart.Add(paint)

GameEvents.PlayerDoTurn.Add(function(owner)
    local player = Players[owner]
    if not lifecycle.eligible(player) then return end
    local state = load(player)
    if state.last ~= Game.GetGameTurn() then
        state.turn, state.last = state.turn + 1, Game.GetGameTurn()
        save(player, state)
    end
    -- This hook follows native research. Method applies to the five ensuing
    -- research settlements and expires after the fifth settlement.
    lifecycle.all()
    units(player, state)
    paint()
end)

GameEvents.PlayerDoneTurn.Add(function(owner)
    local player = Players[owner]
    if not lifecycle.eligible(player) then return end
    local state = load(player)
    for unit in player:Units() do
        local expiry = tonumber(daily.Load(unit, counterKey))
        if expiry and expiry <= state.turn then setCounter(unit, nil) end
    end
end)

GameEvents.UnitCreated.Add(function(owner, id)
    local player = Players[owner]
    if lifecycle.eligible(player) then refreshUnit(player:GetUnitByID(id), load(player)) end
end)

GameEvents.UnitConverted.Add(function(oldOwner, owner, oldID, id)
    local player = Players[owner]
    local unit = player and player:GetUnitByID(id)
    if not unit then return end
    local old = Players[oldOwner]:GetUnitByID(oldID)
    local state = lifecycle.eligible(player) and load(player) or nil
    local expiry = oldOwner == owner and old and tonumber(daily.Load(old, counterKey)) or nil
    setCounter(unit, expiry)
    refreshUnit(unit, state)
end)

local battle
local pending = {}
GameEvents.BattleStarted.Add(function(kind, x, y)
    battle = {kind=kind, x=x, y=y}
end)

local function hostile(a,d)
    return a and d and a:GetTeam() ~= d:GetTeam() and Teams[a:GetTeam()]:IsAtWar(d:GetTeam())
end

local function participant(player, id)
    if not player or id < 0 then return end
    local unit = player:GetUnitByID(id)
    if daily.Military(unit) then return unit end
end

GameEvents.CombatResult.Add(function(a, au, ad, af, am, d, du, dd, df, dm, ip, iu, damage, x, y)
    local attacker, defender = Players[a], Players[d]
    local relevant = lifecycle.eligible(attacker) or lifecycle.eligible(defender)
    if not relevant then return end
    local aUnit, dUnit = participant(attacker, au), participant(defender, du)
    local enemy = hostile(attacker, defender) and aUnit and dUnit
    local signature = table.concat({a,au,ad,af,am,d,du,dd,df,dm,ip,iu,damage,x,y}, ':')
    pending[signature] = {
        lossA=enemy and lifecycle.eligible(attacker) and daily.Major(defender) and af >= am and ad > 0 and damage == 0,
        lossD=enemy and lifecycle.eligible(defender) and daily.Major(attacker) and df >= dm and dd > 0,
        counterD=enemy and lifecycle.eligible(defender) and df < dm and dUnit:IsHasPromotion(lineage)
            and battle and battle.kind == MELEE and battle.x == x and battle.y == y,
        spendA=aUnit and aUnit:IsHasPromotion(counter)
    }
    battle = nil
end)

local function loss(player, id, qualifies)
    if not qualifies or daily.Military(player:GetUnitByID(id)) then return end
    local state = load(player)
    state.lessons = math.min(5, state.lessons + 1)
    save(player, state)
end

GameEvents.CombatEnded.Add(function(a, au, ad, af, am, d, du, dd, df, dm, ip, iu, damage, x, y)
    local signature = table.concat({a,au,ad,af,am,d,du,dd,df,dm,ip,iu,damage,x,y}, ':')
    local result = pending[signature]
    if not result then return end
    pending[signature] = nil
    loss(Players[a], au, result.lossA)
    loss(Players[d], du, result.lossD)
    if result.spendA then
        local unit = participant(Players[a], au)
        if unit then setCounter(unit, nil) end
    end
    if result.counterD then
        local unit = participant(Players[d], du)
        if unit then setCounter(unit, load(Players[d]).turn + 1) end
    end
    if result.lossA or result.lossD then lifecycle.all(); paint() end
end)

for id = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
    local player = Players[id]
    if lifecycle.eligible(player) then units(player, load(player)) end
end
paint()
