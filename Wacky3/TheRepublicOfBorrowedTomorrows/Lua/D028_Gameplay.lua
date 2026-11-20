include('CWC3_Daily')
local exchange = assert(GameInfoTypes.BUILDING_CWC3_D028)
-- The advance is disabled because exact debt-neutral withholding is unavailable.
-- With no advances issued, the Exchange is always in its debt-free state.
CWC3Daily.Install('D028', {'NO_DEBT'}, function(city)
    return {NO_DEBT=city:GetNumBuilding(exchange)>0}
end)
