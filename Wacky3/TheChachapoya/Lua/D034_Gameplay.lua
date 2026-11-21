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
    if #engaged == 0 then return end
    for _,entry in ipairs(engaged) do
        local player=Players[entry.owner]
        local unit=player and player:GetUnitByID(entry.id)
        if unit and unit:GetGameTurnCreated()==entry.created then daily.Promotion(unit,defense,false) end
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
            engaged[#engaged+1]={owner=unit:GetOwner(),id=unit:GetID(),created=unit:GetGameTurnCreated()}
        end
    end
end)
-- Damage has already been calculated on entry to ResolveCombat.
-- A vetoed mission skips both CombatResult and BattleFinished, so the
-- end-of-update hook is the cancellation fallback for that same update.
GameEvents.CombatResult.Add(clear)
GameEvents.BattleFinished.Add(clear)
GameEvents.GameCoreUpdateEnd.Add(clear)
Events.ActivePlayerTurnStart.Add(clear)
GameEvents.UnitConverted.Add(function(_,owner,_,id)
    local player=Players[owner]
    local unit=player and player:GetUnitByID(id)
    if unit then daily.Promotion(unit,defense,false) end
end)
for id=0,GameDefines.MAX_CIV_PLAYERS-1 do
    local player=Players[id]
    if player and player:IsAlive() and player:GetCivilizationType()==civ then
        for unit in player:Units() do daily.Promotion(unit,defense,false) end
    end
end
