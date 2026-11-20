include('CWC3_Daily')
local open = {[GameInfoTypes.TERRAIN_PLAINS]=true, [GameInfoTypes.TERRAIN_GRASS]=true}
local pavilion = assert(GameInfoTypes.BUILDING_CWC3_D023)
CWC3Daily.Install('D023', {'OPEN', 'RING', 'PAVILION'}, function(city)
    local plains = open[city:Plot():GetTerrainType()]
    local count = 0
    for direction = 0, 5 do
        local plot = Map.PlotDirection(city:GetX(), city:GetY(), direction)
        if plot and open[plot:GetTerrainType()] then count = count + 1 end
    end
    return {OPEN=plains, RING=count >= 3, PAVILION=plains and city:GetNumBuilding(pavilion) > 0}
end)
