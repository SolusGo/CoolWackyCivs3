include('CWC3_Daily')
local daily = CWC3Daily
local key = 'CWC3_D022_V1'
local counterKey = 'CWC3_D022_COUNTER_V1'
local lineage = assert(GameInfoTypes.PROMOTION_CWC3_D022_LINEAGE)
local counter = assert(GameInfoTypes.PROMOTION_CWC3_D022_COUNTER)
local doctrine = assert(GameInfoTypes.PROMOTION_CWC3_D022_DOCTRINE)
local chamber = assert(GameInfoTypes.BUILDING_CWC3_D022)
-- BattleTypeTypes in CP151 CustomMods.h.
local MELEE, RANGED, AIR, SWEEP = 0, 1, 2, 3
local armed, doctrineApplied = {}, {}

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
    local owner, id = unit:GetOwner(), unit:GetID()
    armed[owner] = armed[owner] or {}
    armed[owner][id] = serial
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
    doctrineApplied[player:GetID()] = state.turn < state.combat + 3
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
Events.GameplaySetActivePlayer.Add(paint)
Events.LoadScreenClose.Add(paint)

GameEvents.PlayerDoTurn.Add(function(owner)
    local player = Players[owner]
    if not lifecycle.eligible(player) then return end
    local state = load(player)
    if state.last == Game.GetGameTurn() then return end
    state.turn, state.last = state.turn + 1, Game.GetGameTurn()
    save(player, state)
    -- This hook follows native research. Method applies to the five ensuing
    -- research settlements and expires after the fifth settlement.
    lifecycle.all()
    if doctrineApplied[owner] ~= (state.turn < state.combat + 3) then units(player, state) end
    paint()
end)

GameEvents.PlayerDoneTurn.Add(function(owner)
    local player = Players[owner]
    if not lifecycle.eligible(player) then return end
    local state = load(player)
    for id, expiry in pairs(armed[owner] or {}) do
        local unit = player:GetUnitByID(id)
        if not daily.Military(unit) then
            armed[owner][id] = nil
        elseif expiry <= state.turn then
            setCounter(unit, nil)
        end
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
    local oldPlayer = Players[oldOwner]
    local old = oldPlayer and oldPlayer:GetUnitByID(oldID)
    local state = lifecycle.eligible(player) and load(player) or nil
    local expiry = oldOwner == owner and old and tonumber(daily.Load(old, counterKey)) or nil
    if old and old ~= unit then setCounter(old, nil) end
    setCounter(unit, expiry)
    refreshUnit(unit, state)
end)

local battle, ranged
local present = false
local pending = {}
local function combatKey(a,au,d,du,x,y)
    -- City ownership can change during resolution. A city target has no unit ID.
    if du < 0 then d=-1 end
    return table.concat({a,au,d,du,x,y}, ':')
end
GameEvents.BattleStarted.Add(function(kind, x, y)
    if present then battle = {kind=kind, x=x, y=y} end
end)

local function hostile(a,d)
    return a and d and a:GetTeam() ~= d:GetTeam() and Teams[a:GetTeam()]:IsAtWar(d:GetTeam())
end

local function participant(player, id)
    if not player or id < 0 then return end
    local unit = player:GetUnitByID(id)
    if daily.Military(unit) then return unit end
end

-- Positive air interception aborts the bombing run before its normal damage
-- and zeros attackerFinalDamage. A sweep against ground AA likewise may leave
-- attackerFinalDamage unset. In both cases the actual damage field and the
-- victim's pre-resolution HP provide the lethal test.
local function qualifyingKiller(victim, killer, unit)
    return unit and daily.Major(killer) and hostile(victim, killer)
end

local function lossCandidate(unit, lethal)
    return unit and lethal and unit:GetGameTurnCreated() or nil
end

GameEvents.CombatResult.Add(function(a, au, ad, af, am, d, du, dd, df, dm, ip, iu, damage, x, y)
    local kind = battle and battle.x == x and battle.y == y and battle.kind
    battle = nil
    local attacker, defender, interceptor = Players[a], Players[d], Players[ip]
    local oursA, oursD = lifecycle.eligible(attacker), lifecycle.eligible(defender)
    if kind ~= MELEE and kind ~= RANGED and kind ~= AIR and kind ~= SWEEP then return end
    local signature = combatKey(a,au,d,du,x,y)
    local aUnit, dUnit = participant(attacker, au), participant(defender, du)
    local splash
    if kind == RANGED and aUnit and daily.Major(attacker) then
        -- ResolveRangedUnitVsCombat calls the attacker's adjacent and target-
        -- plot damage helpers. Keep a narrow source window through CombatEnded.
        splash = {key=signature, attacker=attacker, primaryOwner=d, primaryID=du, x=x, y=y, victims={}}
        ranged = splash
    end
    if not oursA and not oursD and not splash then return end
    local lossA, lossD
    if oursA and aUnit then
        if kind == AIR and damage > 0 then
            lossA = lossCandidate(aUnit, damage >= aUnit:GetCurrHitPoints()
                and qualifyingKiller(attacker, interceptor, participant(interceptor, iu)))
        elseif ad > 0 then
            lossA = lossCandidate(aUnit, (af >= am or (kind == SWEEP and ad >= aUnit:GetCurrHitPoints()))
                and qualifyingKiller(attacker, defender, dUnit))
        end
    end
    if oursD and dUnit and dd > 0 then
        lossD = lossCandidate(dUnit, df >= dm and qualifyingKiller(defender, attacker, aUnit))
    end
    local survived = kind == MELEE and oursD and dUnit and aUnit and df < dm
        and dUnit:IsHasPromotion(lineage) and hostile(attacker, defender)
    pending[signature] = {
        lossA=lossA, lossD=lossD, counterD=survived and dUnit:GetGameTurnCreated() or nil,
        splash=splash,
    }
    -- ResolveCombat already sampled and fixed all damage and passed the abort
    -- gate when CombatResult fires. Consume even on a nonlethal hit or city
    -- attack, before the resolver can trigger a nested callback.
    if aUnit and oursA and aUnit:IsHasPromotion(counter) then setCounter(aUnit, nil) end
end)

GameEvents.UnitPrekill.Add(function(owner, id, _, x, y, delayed, killer)
    local scope = ranged
    local victim = Players[owner]
    if not scope or not delayed or killer ~= scope.attacker:GetID() or not lifecycle.eligible(victim)
        or (owner == scope.primaryOwner and id == scope.primaryID)
        or not hostile(victim, scope.attacker) or Map.PlotDistance(x,y,scope.x,scope.y) > 1 then return end
    local unit = victim:GetUnitByID(id)
    -- A normal kill(), disband or conversion does not set lethal damage.
    -- setDamage does so before it invokes kill(true, ePlayer).
    if unit and unit:IsCombatUnit() and unit:IsDead() then
        local created=unit:GetGameTurnCreated()
        scope.victims[owner..':'..id..':'..created]={owner=owner,id=id,created=created}
    end
end)

local function loss(player, id, created)
    if not created then return false end
    local unit = player:GetUnitByID(id)
    if unit and (unit:GetGameTurnCreated() ~= created or not unit:IsDead()) then return false end
    if armed[player:GetID()] then armed[player:GetID()][id] = nil end
    local state = load(player)
    state.lessons = math.min(5, state.lessons + 1)
    save(player, state)
    return true
end

GameEvents.CombatEnded.Add(function(a, au, _, _, _, d, du, _, _, _, _, _, _, x, y)
    local signature = combatKey(a,au,d,du,x,y)
    local result = pending[signature]
    if not result then return end
    pending[signature] = nil
    if ranged and ranged.key == signature then ranged = nil end
    local paidA = loss(Players[a], au, result.lossA)
    local paidD = loss(Players[d], du, result.lossD)
    if result.counterD then
        local unit = participant(Players[d], du)
        if unit and unit:GetGameTurnCreated() == result.counterD then
            setCounter(unit, load(Players[d]).turn + 1)
        end
    end
    local paidSplash = false
    if result.splash then
        for _,victim in pairs(result.splash.victims) do
            if loss(Players[victim.owner],victim.id,victim.created) then paidSplash = true end
        end
    end
    if paidA or paidD or paidSplash then lifecycle.all(); paint() end
end)

-- An aborted mission does not publish CombatEnded. Never match a snapshot
-- left by an incomplete update to a later combat at the same coordinates.
GameEvents.GameCoreUpdateEnd.Add(function()
    battle, ranged = nil, nil
    if next(pending) then pending = {} end
end)

for id = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
    local player = Players[id]
    if lifecycle.eligible(player) then
        present = true
        units(player, load(player))
    end
end
paint()
