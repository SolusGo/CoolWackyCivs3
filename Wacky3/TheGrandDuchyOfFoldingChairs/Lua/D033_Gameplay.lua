include('CWC3_Daily')
local daily=CWC3Daily
local hall=assert(GameInfoTypes.BUILDING_CWC3_D033)
local previous, dying = {}, {}

local function garrison(city)
    -- CP may designate a naval unit or a scripted override. Independently
    -- apply the design's exact center, ownership, land and combat filter.
    local center=city:Plot()
    for i=0,center:GetNumUnits()-1 do
        local unit=center:GetUnit(i)
        if daily.Military(unit) and unit:GetOwner()==city:GetOwner() and not dying[unit:GetID()]
            and unit:GetDomainType()==DomainTypes.DOMAIN_LAND and not unit:IsEmbarked() then
            previous[unit:GetID()]=center
            return true
        end
    end
    return false
end

local lifecycle=daily.Install('D033',{'GARRISON','HALL'},function(city)
    local qualifies=garrison(city)
    return {GARRISON=qualifies,HALL=qualifies and city:GetNumBuilding(hall)>0}
end)

local function at(plot)
    if plot then lifecycle.city(plot:GetPlotCity()) end
end

local function moved(owner,id,x,y)
    if not lifecycle.eligible(Players[owner]) then return end
    local from,to=previous[id],Map.GetPlot(x,y)
    previous[id]=nil
    if from~=to then at(from) end
    at(to)
end

GameEvents.UnitSetXY.Add(moved)
GameEvents.UnitCreated.Add(function(owner,id)
    if lifecycle.eligible(Players[owner]) then
        local unit=Players[owner]:GetUnitByID(id)
        if unit then moved(owner,id,unit:GetX(),unit:GetY()) end
    end
end)
GameEvents.UnitConverted.Add(function(_,owner,_,id)
    if lifecycle.eligible(Players[owner]) then
        local unit=Players[owner]:GetUnitByID(id)
        if unit then moved(owner,id,unit:GetX(),unit:GetY()) end
    end
end)
GameEvents.UnitPrekill.Add(function(owner,id,_,x,y)
    if lifecycle.eligible(Players[owner]) then
        -- Native hook is pre-removal. Ignore this unit during the synchronous
        -- refresh. Dirty/turn reconciliation will see its final removal.
        dying[id]=true
        previous[id]=nil
        at(Map.GetPlot(x,y))
        dying[id]=nil
    end
end)
