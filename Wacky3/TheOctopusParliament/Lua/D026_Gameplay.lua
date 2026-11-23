include('CWC3_Daily')
local daily = CWC3Daily
local applied = {}
local key = 'CWC3_D026_V1'
local chamber = assert(GameInfoTypes.BUILDING_CWC3_D026)
local defense = assert(GameInfoTypes.PROMOTION_CWC3_D026_RESOLUTION)

local function state(player)
    local era = player:GetCurrentEra()
    local savedEra, vote = (daily.Load(player, key) or ''):match('^(%d+):([0-3])$')
    return era, tonumber(savedEra) == era and tonumber(vote) or 0
end

local lifecycle = daily.Install('D026', {'PROSPERITY','ENLIGHTENMENT','CHAMBER_GOLD','CHAMBER_SCIENCE'},
    function(city, _, vote)
        local present = city:GetNumBuilding(chamber) > 0
        return {PROSPERITY=vote==1,ENLIGHTENMENT=vote==2,CHAMBER_GOLD=present and vote==1,
            CHAMBER_SCIENCE=present and vote==2}
    end,
    function(player) local _,vote=state(player); return vote end)

local function active()
    local player = Players[Game.GetActivePlayer()]
    if lifecycle.eligible(player) and player:IsHuman() then return player end
end

local function paint()
    local player = active()
    local show = false
    if player then
        local _, vote = state(player)
        show = vote == 0
        for _, key in ipairs({'Prosperity','Enlightenment','Defence'}) do
            Controls[key]:SetDisabled(not player:IsTurnActive())
        end
    end
    ContextPtr:SetHide(not show)
end

local function updateUnit(unit, vote)
    if unit then daily.Promotion(unit, defense, vote == 3 and daily.Military(unit) and true or false) end
end

local function apply(player, era, vote)
    local id = player:GetID()
    local previous = applied[id]
    if not previous or previous.era ~= era or previous.vote ~= vote then
        applied[id] = {era=era, vote=vote}
        lifecycle.all()
        if not previous or (previous.vote == 3) ~= (vote == 3) then
            for unit in player:Units() do updateUnit(unit, vote) end
        end
    end
    paint()
end

local function current(player)
    local era, vote = state(player)
    if vote == 0 then daily.Save(player, key, era .. ':0') end
    apply(player, era, vote)
end

local function choose(vote)
    local player = active()
    if not player or not player:IsTurnActive() then return end
    local era, old = state(player)
    if old ~= 0 then return end
    daily.Save(player, key, era .. ':' .. vote)
    apply(player, era, vote)
end

Controls.Prosperity:RegisterCallback(Mouse.eLClick, function() choose(1) end)
Controls.Enlightenment:RegisterCallback(Mouse.eLClick, function() choose(2) end)
Controls.Defence:RegisterCallback(Mouse.eLClick, function() choose(3) end)
GameEvents.TeamSetEra.Add(function(team)
    for id=0,GameDefines.MAX_CIV_PLAYERS-1 do
        local player=Players[id]
        if lifecycle.eligible(player) and player:GetTeam()==team then current(player) end
    end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
    if lifecycle.eligible(Players[owner]) then current(Players[owner]) end
end)
Events.ActivePlayerTurnStart.Add(paint)
Events.GameplaySetActivePlayer.Add(paint)
Events.LoadScreenClose.Add(paint)
GameEvents.UnitCreated.Add(function(owner,id)
    local player = Players[owner]
    if lifecycle.eligible(player) then
        local _,vote=state(player)
        updateUnit(player:GetUnitByID(id), vote)
    end
end)
GameEvents.UnitConverted.Add(function(_,owner,_,id)
    local player = Players[owner]
    local vote = 0
    if lifecycle.eligible(player) then local _,selected=state(player); vote=selected end
    if player then updateUnit(player:GetUnitByID(id), vote) end
end)
for id=0,GameDefines.MAX_CIV_PLAYERS-1 do
    local player=Players[id]
    if lifecycle.eligible(player) then current(player) end
end
paint()
