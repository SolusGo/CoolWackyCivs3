include('CWC3_Daily')
local office = assert(GameInfoTypes.BUILDING_CWC3_D024)
local courier = assert(GameInfoTypes.UNIT_CWC3_D024)
local depot = assert(GameInfoTypes.PROMOTION_CWC3_D024_DEPOT)
local lifecycle = CWC3Daily.Install('D024', {'MAIL','CULTURE_1','CULTURE_2'}, function(city, _, count)
    local hasOffice = city:GetNumBuilding(office) > 0
    return {MAIL=hasOffice, CULTURE_1=hasOffice and count >= 3, CULTURE_2=hasOffice and count >= 6}
end, function(player)
    local count = 0
    for city in player:Cities() do
        if city:GetNumBuilding(office) > 0 then count = count + 1 end
    end
    return count
end)

local function friendly(unit)
    local plot = unit:Plot()
    return not unit:IsEmbarked() and plot and plot:IsFriendlyTerritory(unit:GetOwner()) or false
end

local daily = CWC3Daily
local grantKey = 'CWC3_D024_TURN_V1'
local points = GameDefines.MOVE_DENOMINATOR
local dispatched = {}

local function tracked(unit, enabled)
    local owner, id = unit:GetOwner(), unit:GetID()
    dispatched[owner] = dispatched[owner] or {}
    dispatched[owner][id] = enabled and unit:GetGameTurnCreated() or nil
end

local function apply(unit, want)
    tracked(unit, want)
    if unit:IsHasPromotion(depot) == want then return end
    unit:SetHasPromotion(depot, want)
    -- CP switches to the embarked movement formula before UnitSetXY. That
    -- formula ignores MovesChange, but the actual movement store still holds
    -- our grant. Undo exactly the granted points regardless of current max.
    unit:SetMoves(math.max(0, unit:GetMoves() + (want and points or -points)))
end

local function ownerTurn(owner)
    local player = Players[owner]
    if not lifecycle.eligible(player) then return end
    local turn = tostring(Game.GetGameTurn())
    if daily.Load(player, grantKey) == turn then return end
    daily.Save(player, grantKey, turn)
    for unit in player:Units() do
        if unit:GetUnitType() == courier and daily.Military(unit) then apply(unit, friendly(unit)) end
    end
end

local function review(unit)
    if unit and unit:IsHasPromotion(depot) then
        local eligible = lifecycle.eligible(Players[unit:GetOwner()]) and daily.Military(unit)
            and unit:GetUnitType() == courier and friendly(unit)
        apply(unit, eligible and true or false)
    end
end

local function reviewDispatched(owner, endTurn)
    local player = Players[owner]
    for id, created in pairs(dispatched[owner] or {}) do
        local unit = player and player:GetUnitByID(id)
        if not unit or unit:GetGameTurnCreated() ~= created then
            dispatched[owner][id] = nil
        elseif endTurn then
            -- PlayerDoneTurn precedes native DoUnitReset. Reset the next
            -- turn from the unit's baseline, then grant only at PlayerDoTurn.
            apply(unit, false)
        else
            review(unit)
        end
    end
end

GameEvents.PlayerDoTurn.Add(ownerTurn)
GameEvents.PlayerDoneTurn.Add(function(owner) reviewDispatched(owner, true) end)
GameEvents.UnitSetXY.Add(function(owner, id)
    local player = Players[owner]
    if lifecycle.eligible(player) then review(player:GetUnitByID(id)) end
end)
GameEvents.TileOwnershipChanged.Add(function(x,y)
    local plot = Map.GetPlot(x,y)
    if plot then
        for i = 0, plot:GetNumUnits() - 1 do review(plot:GetUnit(i)) end
    end
end)
-- SetAllowsOpenBordersToTeam changes the flag, verifies displaced units, and
-- marks Score dirty for the active team. This covers a stationary courier.
local function reviewAllDispatched()
    for owner in pairs(dispatched) do reviewDispatched(owner, false) end
end
Events.SerialEventScoreDirty.Add(reviewAllDispatched)
Events.WarStateChanged.Add(reviewAllDispatched)
GameEvents.UnitConverted.Add(function(oldOwner, owner, oldID, id)
    if dispatched[oldOwner] then dispatched[oldOwner][oldID] = nil end
    local oldPlayer, player = Players[oldOwner], Players[owner]
    local old = oldPlayer and oldPlayer:GetUnitByID(oldID)
    local unit = player and player:GetUnitByID(id)
    if not unit then return end
    local carried = old and old:IsHasPromotion(depot)
    if unit:IsHasPromotion(depot) then
        apply(unit, false)
    elseif carried then
        -- convert copies the raw store before this hook, even when the
        -- upgrade filters the temporary promotion out of the new unit.
        unit:SetMoves(math.max(0, unit:GetMoves() - points))
    end
    if carried and old ~= unit then old:SetHasPromotion(depot, false) end
end)
for owner=0,GameDefines.MAX_CIV_PLAYERS-1 do
    local player=Players[owner]
    if lifecycle.eligible(player) then
        for unit in player:Units() do review(unit) end
    end
end
