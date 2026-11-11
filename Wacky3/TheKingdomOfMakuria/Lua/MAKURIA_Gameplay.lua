if MapModData.CWC3_MAKURIA_Registered then return end
include('CWC3_ArchiveLifecycle')
local CIV=assert(GameInfoTypes.CIVILIZATION_CWC3_MAKURIA)
local WALLS=CWC3Archive.ClassBuildings('BUILDINGCLASS_WALLS')
MapModData.CWC3_MAKURIA_Registered=true
CWC3Archive.Install{civ=CIV,controllers={WALLS=assert(GameInfoTypes.BUILDING_CWC3_MAKURIA_WALLS)},
    calculate=function(city) return {WALLS=CWC3Archive.HasClass(city,WALLS)} end}
