include('CWC3_Daily')
local daily = CWC3Daily
local tundra = assert(GameInfoTypes.TERRAIN_TUNDRA)
local snow = assert(GameInfoTypes.TERRAIN_SNOW)
local garden = assert(GameInfoTypes.BUILDING_CWC3_D029)
local function cold(plot)
    local terrain=plot:GetTerrainType()
    return terrain==tundra or terrain==snow
end

daily.Install('D029', {'FOOD_1','FOOD_2','FOOD_3','FOOD_4','SCIENCE_1','SCIENCE_2','SCIENCE_3','COLD',
    'GARDEN_SCIENCE','GARDEN_CULTURE'}, function(city)
    local food, science, owned = 0,0,0
    daily.Worked(city,function(plot)
        local terrain=plot:GetTerrainType()
        if terrain==tundra then food=food+1 end
        if terrain==snow then science=science+1 end
    end)
    local building=city:GetNumBuilding(garden)>0
    if building then daily.Owned(city,function(plot) if cold(plot) then owned=owned+1 end end) end
    return {FOOD_1=food>=1,FOOD_2=food>=2,FOOD_3=food>=3,FOOD_4=food>=4,
        SCIENCE_1=science>=1,SCIENCE_2=science>=2,SCIENCE_3=science>=3,COLD=cold(city:Plot()),
        GARDEN_SCIENCE=owned>=3,GARDEN_CULTURE=owned>=6}
end, nil, true)
