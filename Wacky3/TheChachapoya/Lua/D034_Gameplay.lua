include('CWC3_Daily')
local walls=CWC3Archive.ClassBuildings('BUILDINGCLASS_WALLS')
local terrace=assert(GameInfoTypes.BUILDING_CWC3_D034)
CWC3Daily.Install('D034', {'HILL','WALL','TERRACE'},function(city)
    local hill=city:Plot():IsHills()
    return {HILL=hill,WALL=CWC3Archive.HasClass(city,walls),TERRACE=hill and city:GetNumBuilding(terrace)>0}
end)

-- The Cloud Sentinel's design limits this to incoming melee. The native
-- HillsDefense field also affects the non-attacking ranged-strength branch,
-- so scope it to melee resolution for these ranged units.
local daily=CWC3Daily
local civ=assert(GameInfoTypes.CIVILIZATION_CWC3_D034)
local lineage=assert(GameInfoTypes.PROMOTION_CWC3_D034_LINEAGE)
local defense=assert(GameInfoTypes.PROMOTION_CWC3_D034_DEFEND)
local engaged={}
local function clear()
    for _,entry in ipairs(engaged) do
        local unit=Players[entry.owner]:GetUnitByID(entry.id)
        if unit then daily.Promotion(unit,defense,false) end
    end
    engaged={}
end
GameEvents.BattleStarted.Add(function(kind,x,y)
    clear()
    if kind~=0 then return end
    local plot=Map.GetPlot(x,y)
    if not plot or not plot:IsHills() then return end
    for i=0,plot:GetNumUnits()-1 do
        local unit=plot:GetUnit(i)
        if daily.Military(unit) and not unit:IsEmbarked() and unit:IsHasPromotion(lineage)
            and Players[unit:GetOwner()]:GetCivilizationType()==civ then
            daily.Promotion(unit,defense,true)
            engaged[#engaged+1]={owner=unit:GetOwner(),id=unit:GetID()}
        end
    end
end)
GameEvents.BattleFinished.Add(clear)
Events.ActivePlayerTurnStart.Add(clear)
GameEvents.UnitConverted.Add(function(_,owner,_,id)
    local unit=Players[owner]:GetUnitByID(id)
    if unit then daily.Promotion(unit,defense,false) end
end)
local active=Players[Game.GetActivePlayer()]
if active and active:GetCivilizationType()==civ then
    for unit in active:Units() do daily.Promotion(unit,defense,false) end
end
