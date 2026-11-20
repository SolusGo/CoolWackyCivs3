include('CWC3_Daily')
local harbors = CWC3Archive.ClassBuildings('BUILDINGCLASS_HARBOR')
local lifecycle = CWC3Daily.Install('D021', {'COAST', 'HARBOR'}, function(city)
    local coast = city:IsCoastal(GameDefines.MIN_WATER_SIZE_FOR_OCEAN)
    return {COAST=coast, HARBOR=coast and CWC3Archive.HasClass(city, harbors)}
end)
CWC3Daily.Defend(lifecycle, 'D021', CWC3Daily.Friendly)
