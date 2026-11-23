local qu = CWC3Qu
local daily = CWC3Daily
local lineage = assert(GameInfoTypes.PROMOTION_CWC3_QU_BIOLOGICAL_HARVESTING)
local defense = assert(GameInfoTypes.PROMOTION_CWC3_QU_BIOLOGICAL_DEFENSE)
local AIR, NUKE = 2, 5
local ATTACKER, DEFENDER, INTERCEPTOR = 0, 1, 2
local battle, applied, lethal, overrun

local function getUnit(owner, id)
    local player = Players[owner]
    return player and player:GetUnitByID(id)
end

local function clearDefense()
    if not applied then return end
    local unit = getUnit(applied.owner, applied.id)
    if unit and unit:GetGameTurnCreated() == applied.created then daily.Promotion(unit, defense, false) end
    applied = nil
end

local function clearCombat()
    clearDefense()
    battle, lethal, overrun = nil, nil, nil
end

local function enemy(killer, opponent)
    local rival = Players[opponent]
    return rival and (rival:IsMajorCiv() or rival:IsMinorCiv()) and not rival:IsBarbarian()
        and Teams[killer:GetTeam()]:IsAtWar(rival:GetTeam())
end

GameEvents.BattleStarted.Add(function(kind, x, y)
    clearCombat()
    if qu.player() then battle = {kind=kind, x=x, y=y, roles={}} end
end)

GameEvents.BattleJoined.Add(function(owner, id, role, isCity)
    if not battle or role > INTERCEPTOR then return end
    battle.roles[role] = {owner=owner, id=id, city=isCity}
    if role ~= DEFENDER or isCity or battle.kind > AIR then return end
    local player, attacker = qu.player(owner), battle.roles[ATTACKER]
    if not player or not attacker or attacker.city then return end
    local rival = Players[attacker.owner]
    if not rival or not Teams[player:GetTeam()]:IsAtWar(rival:GetTeam()) then return end
    local unit, other = getUnit(owner, id), getUnit(attacker.owner, attacker.id)
    if not daily.Military(unit) or unit:IsEmbarked() or not unit:IsHasPromotion(lineage)
        or not other or other:GetDamage() <= 0 then return end
    daily.Promotion(unit, defense, true)
    applied = {owner=owner, id=id, created=unit:GetGameTurnCreated()}
end)

GameEvents.CombatResult.Add(function(a, _, _, _, _, d, _, _, _, _, i, _, _, x, y)
    -- The real damage has been calculated and the veto gate has passed.
    clearDefense()
    if not battle or x ~= battle.x or y ~= battle.y then return end
    local attacker, defender = battle.roles[ATTACKER], battle.roles[DEFENDER]
    battle.sources = {}
    for _, owner in ipairs({a,d,i,attacker and attacker.owner or -1,defender and defender.owner or -1}) do
        if qu.player(owner) then battle.sources[owner] = true end
    end
end)

GameEvents.UnitCaptured.Add(function(killer, _, victim, id, killed, reason)
    -- In setXY, reason 0 precedes the actual immediate destruction on overrun.
    local player = qu.player(killer)
    if killed and reason == 0 and player and enemy(player, victim) then
        overrun = {killer=killer, victim=victim, id=id}
    end
end)

GameEvents.UnitPrekill.Add(function(victim, id, kind, _, _, delayed, killer)
    lethal = nil
    local player = qu.player(killer)
    if not player or not enemy(player, victim) then return end
    local unit = getUnit(victim, id)
    if not unit or unit:IsDelayedDeath() then return end
    -- CP151's IsCombatUnit checks base melee strength, which is zero on aircraft.
    if not (unit:IsCombatUnit() or unit:IsCanAttackRanged() or unit:CanNuke()) then return end

    if not delayed and overrun and overrun.killer == killer and overrun.victim == victim and overrun.id == id then
        overrun = nil
        qu.addKill(player)
        return
    end
    if not delayed or not battle then return end
    if battle.sources and battle.sources[killer] and unit:IsDead() then
        -- setDamage raises this hook just before UnitKilledInCombat, which lacks the victim ID.
        lethal = {killer=killer, victim=victim, kind=kind}
    elseif battle.kind == NUKE and not battle.sources then
        -- Atomic bomb shot down while generating the attack, before CombatResult.
        local attacker, interceptor = battle.roles[ATTACKER], battle.roles[DEFENDER]
        if attacker and attacker.owner == victim and attacker.id == id and interceptor
            and interceptor.city and interceptor.owner == killer then qu.addKill(player) end
    end
end)

GameEvents.UnitKilledInCombat.Add(function(killer, victim, kind)
    if lethal and lethal.killer == killer and lethal.victim == victim and lethal.kind == kind then
        lethal = nil
        local player = qu.player(killer)
        if player then qu.addKill(player) end
    end
end)

GameEvents.BattleFinished.Add(clearDefense)
GameEvents.CombatEnded.Add(clearCombat)
GameEvents.GameCoreUpdateEnd.Add(clearCombat)
Events.ActivePlayerTurnStart.Add(clearCombat)
GameEvents.UnitConverted.Add(function(_, owner, _, id)
    if not qu.player(owner) then return end
    local unit = getUnit(owner, id)
    if unit then daily.Promotion(unit, defense, false) end
end)

local function initialize()
    clearCombat()
    local player = qu.player()
    if player then
        for unit in player:Units() do daily.Promotion(unit, defense, false) end
    end
end
Events.SequenceGameInitComplete.Add(initialize)
initialize()
