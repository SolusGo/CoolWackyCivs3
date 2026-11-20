include('CWC3_Daily')
local walls = CWC3Archive.ClassBuildings('BUILDINGCLASS_WALLS')
local bastion = assert(GameInfoTypes.BUILDING_CWC3_D025)
local lifecycle = CWC3Daily.Install('D025', {'COAST', 'WALL', 'BASTION'}, function(city)
    local coast = city:IsCoastal(GameDefines.MIN_WATER_SIZE_FOR_OCEAN)
    return {COAST=coast, WALL=coast and CWC3Archive.HasClass(city, walls),
        BASTION=coast and city:GetNumBuilding(bastion) > 0}
end)
CWC3Daily.Defend(lifecycle, 'D025', function(plot, unit)
    if plot:IsWater() or plot:IsImpassable(unit:GetTeam()) then return false end
    for direction = 0, 5 do
        local nextPlot = Map.PlotDirection(plot:GetX(), plot:GetY(), direction)
        if nextPlot and nextPlot:IsWater() then return true end
    end
    return false
end)
