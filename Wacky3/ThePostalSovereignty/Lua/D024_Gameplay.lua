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

local function apply(unit, want)
    if unit:IsHasPromotion(depot) == want then return end
    local before = unit:MaxMoves()
    unit:SetHasPromotion(depot, want)
    -- Movement is restored by native DoUnitReset at the end of the preceding
    -- owner turn. Change the real store by the max-movement delta, exactly once.
    local after = unit:MaxMoves()
    unit:SetMoves(math.max(0, math.min(after, unit:GetMoves() + after - before)))
end

local function ownerTurn(owner)
    local player = Players[owner]
    if not lifecycle.eligible(player) then return end
    local turn = tostring(Game.GetGameTurn())
    if CWC3Daily.Load(player, 'CWC3_D024_TURN_V1') == turn then return end
    CWC3Daily.Save(player, 'CWC3_D024_TURN_V1', turn)
    for unit in player:Units() do
        if unit:GetUnitType() == courier then apply(unit, friendly(unit)) end
    end
end

local function review(unit)
    if unit and unit:IsHasPromotion(depot) and not friendly(unit) then apply(unit, false) end
end
GameEvents.PlayerDoTurn.Add(ownerTurn)
GameEvents.UnitSetXY.Add(function(owner, id)
    if lifecycle.eligible(Players[owner]) then review(Players[owner]:GetUnitByID(id)) end
end)
GameEvents.TileOwnershipChanged.Add(function(x,y)
    local plot = Map.GetPlot(x,y)
    if plot then
        for i = 0, plot:GetNumUnits() - 1 do review(plot:GetUnit(i)) end
    end
end)
GameEvents.UnitConverted.Add(function(_, owner, _, id)
    local unit = Players[owner]:GetUnitByID(id)
    if unit then apply(unit, false) end
end)
