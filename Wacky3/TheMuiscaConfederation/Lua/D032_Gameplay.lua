include('CWC3_Daily')
local daily=CWC3Daily
local gold,silver=assert(GameInfoTypes.RESOURCE_GOLD),assert(GameInfoTypes.RESOURCE_SILVER)
local mine,exchange=assert(GameInfoTypes.IMPROVEMENT_MINE),assert(GameInfoTypes.BUILDING_CWC3_D032)

daily.Install('D032', {'METALS','LAKE','MINE_1','MINE_2'},function(city,player)
    local metals,lake,mines=false,false,0
    daily.Worked(city,function(plot)
        local improvement=plot:GetImprovementType()
        if plot:GetOwner()==city:GetOwner() and improvement>=0 and not plot:IsImprovementPillaged() then
            local resource=plot:GetResourceType(player:GetTeam())
            if (resource==gold or resource==silver) and plot:IsResourceConnectedByImprovement(improvement) then
                metals=true
            end
            if improvement==mine then mines=mines+1 end
        end
    end)
    daily.Owned(city,function(plot) if plot:IsLake() then lake=true end end)
    local building=city:GetNumBuilding(exchange)>0
    return {METALS=metals,LAKE=lake,MINE_1=building and mines>=1,MINE_2=building and mines>=2}
end,nil,true)
