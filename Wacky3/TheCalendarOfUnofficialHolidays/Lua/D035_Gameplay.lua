include('CWC3_Daily')
local office=assert(GameInfoTypes.BUILDING_CWC3_D035)
local lifecycle=CWC3Daily.Install('D035',{'CELEBRATION','OFFICE'},function(city)
    local celebrating=city:GetWeLoveTheKingDayCounter()>0
    return {CELEBRATION=celebrating,OFFICE=celebrating and city:GetNumBuilding(office)>0}
end)

local function transition(owner,x,y)
    if not lifecycle.eligible(Players[owner]) then return end
    local plot=Map.GetPlot(x,y)
    if plot then lifecycle.city(plot:GetPlotCity()) end
end
-- These change hooks are synchronous. Native doProduction has already
-- sampled the old counter on a natural transition; treasury and research
-- must see the new counter. Leave settlement to those native readers.
GameEvents.CityBeginsWLTKD.Add(transition)
GameEvents.CityEndsWLTKD.Add(transition)
GameEvents.CityExtendsWLTKD.Add(transition)
CWC3Daily.Defend(lifecycle,'D035',CWC3Daily.Friendly)
