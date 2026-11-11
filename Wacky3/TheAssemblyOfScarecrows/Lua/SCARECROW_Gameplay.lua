if MapModData.CWC3_SCARECROW_Registered then return end
include('CWC3_ArchiveLifecycle')
local CIV=assert(GameInfoTypes.CIVILIZATION_CWC3_SCARECROW)
local FARM=assert(GameInfoTypes.IMPROVEMENT_FARM)
local BELL=assert(GameInfoTypes.BUILDING_CWC3_SCARECROW)
MapModData.CWC3_SCARECROW_Registered=true
local controllers={}
for _,key in ipairs({'FIELDS','GROWTH','BELL_GOLD_1','BELL_GOLD_2','BELL_GOLD_3'}) do
    controllers[key]=assert(GameInfoTypes['BUILDING_CWC3_SCARECROW_'..key])
end
CWC3Archive.Install{civ=CIV,controllers=controllers,farms=true,calculate=function(city)
    local count=0
    local center=Map.GetPlot(city:GetX(),city:GetY())
    local queue,seen,head={{plot=center,depth=0}},{[center:GetPlotIndex()]=true},1
    -- At most 37 distinct plots. Independent of working radius and worked status.
    while head<=#queue do
        local item=queue[head]; head=head+1
        local plot=item.plot
        if plot:GetOwner()==city:GetOwner() and plot:GetImprovementType()==FARM
           and not plot:IsImprovementPillaged() then count=count+1 end
        if item.depth<3 then
            for direction=0,5 do
                local neighbor=Map.PlotDirection(plot:GetX(),plot:GetY(),direction)
                if neighbor and not seen[neighbor:GetPlotIndex()] then
                    seen[neighbor:GetPlotIndex()]=true
                    queue[#queue+1]={plot=neighbor,depth=item.depth+1}
                end
            end
        end
    end
    local gold=city:GetNumBuilding(BELL)>0 and math.min(3,math.floor(count/3)) or 0
    return {FIELDS=count>=3,GROWTH=count>=6,BELL_GOLD_1=gold>=1,BELL_GOLD_2=gold>=2,BELL_GOLD_3=gold>=3}
end}
