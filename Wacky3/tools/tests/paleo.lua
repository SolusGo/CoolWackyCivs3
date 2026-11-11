-- Production Lua under a Lua51 mock of source-verified native event contracts.
local assertions = 0
local function eq(a,b,label)
    assertions = assertions + 1
    assert(a == b, (label or '') .. ': expected ' .. tostring(b) .. ', got ' .. tostring(a))
end
local function Event()
    local event = {handlers={}}
    function event.Add(fn) event.handlers[#event.handlers+1] = fn end
    function event.Fire(...) for _, fn in ipairs(event.handlers) do fn(...) end end
    return event
end
local function Bus()
    return setmetatable({}, {__index=function(t,k) local event=Event(); rawset(t,k,event); return event end})
end
local function NewContext()
    Events, GameEvents, MapModData = Bus(), Bus(), {}
end
NewContext()
GameDefines = {MAX_CIV_PLAYERS=6}
GameInfoTypes = {CIVILIZATION_PALEO_DIRECTORATE=1,UNIT_PALEO_FOSSIL_EXPEDITION=20,
    BUILDING_PALEO_LIBRARY_SCIENCE=100,BUILDING_PALEO_UNIVERSITY_CULTURE=101,
    BUILD_ARCHAEOLOGY_DIG=30,IMPROVEMENT_ARCHAEOLOGICAL_DIG=40}
local buildingRows = {{ID=10,BuildingClass='BUILDINGCLASS_LIBRARY'},
    {ID=11,BuildingClass='BUILDINGCLASS_LIBRARY'}, {ID=12,BuildingClass='BUILDINGCLASS_UNIVERSITY'},
    {ID=13,BuildingClass='BUILDINGCLASS_UNIVERSITY'}, {ID=14,BuildingClass='BUILDINGCLASS_MUSEUM'}}
GameInfo = {GameSpeeds={[2]={Type=SpeedName}}, Buildings=function()
    local i=0
    return function() i=i+1; return buildingRows[i] end
end}
Game = {GetGameSpeedType=function() return 2 end}
local plots = {}
Map = {GetPlot=function(x,y) return plots[x..':'..y] end}
local function Plot(x,y)
    local p = {x=x,y=y,improvement=-1,artifact=-1}
    function p:GetPlotCity() return self.city end
    function p:GetImprovementType() return self.improvement end
    function p:GetArchaeologyArtifactType() return self.artifact end
    plots[x..':'..y]=p; return p
end
Players = {}
for id=0,5 do
    local p = {id=id,civ=id==PaleoSlot and 1 or 2,alive=true,cities={},units={},data='other-mod:[DATA:1]',research=7,overflow=350}
    function p:IsAlive() return self.alive end
    function p:IsHuman() return self.id==PaleoSlot end
    function p:GetCivilizationType() return self.civ end
    function p:GetTeam() return self.id end
    function p:GetCityByID(cityID) return self.cities[cityID] end
    function p:GetUnitByID(unitID) return self.units[unitID] end
    function p:GetScriptData() return self.data end
    function p:SetScriptData(data) self.data=data end
    function p:GetCurrentResearch() return self.research end
    function p:GetOverflowResearchTimes100() return self.overflow end
    function p:ChangeOverflowResearch(amount) if not self.refuse then self.overflow=self.overflow+amount*100 end end
    function p:Cities()
        local keys={}; for key in pairs(self.cities) do keys[#keys+1]=key end
        table.sort(keys); local i=0
        return function() i=i+1; return self.cities[keys[i]] end
    end
    Players[id]=p
end
local owner=Players[PaleoSlot]
local rival=Players[PaleoSlot==0 and 1 or 0]
local function City(player,id,x)
    local c={owner=player.id,id=id,x=x,y=0,real={},free={},writes=0}
    function c:GetOwner() return self.owner end
    function c:GetX() return self.x end
    function c:GetY() return self.y end
    function c:GetNumRealBuilding(b) return self.real[b] or 0 end
    function c:GetNumBuilding(b) return (self.real[b] or 0)+(self.free[b] or 0) end
    function c:GetNumFreeBuilding(b) return self.free[b] or 0 end
    function c:SetNumRealBuilding(b,n,noBonus)
        eq(noBonus,true,'suppress construction rewards'); self.real[b]=n; self.writes=self.writes+1
        Events.SerialEventCityInfoDirty.Fire() -- Deliberately reentrant.
    end
    function c:SetNumFreeBuilding(b,n,refund,bonus)
        eq(refund,false,'no refund'); eq(bonus,false,'no free-construction rewards'); self.free[b]=n
    end
    player.cities[id]=c; Plot(x,0).city=c; return c
end
local cities={}
for i=1,5 do cities[i]=City(owner,i,i) end
local c=cities[1]; c.real[11]=1; c.real[13]=1; c.real[100]=7; c.free[100]=3
local foreign=City(rival,1,9); foreign.real[100]=1; foreign.free[101]=1
Teams = {}
for id=0,5 do
    local team={progress=500,cost=100000,awards=0,total=0}
    function team:GetTeamTechs() return self end
    function team:ChangeResearchProgress(tech,amount,playerID)
        if self.fail then error('injected native API failure') end
        eq(playerID,id,'research owner'); eq(tech,Players[id].research,'current tech')
        self.awards=self.awards+1; self.total=self.total+amount
        self.progress=self.progress+amount*100
        if self.progress>=self.cost then
            Players[id].overflow=Players[id].overflow+self.progress-self.cost
            self.progress=self.cost; Players[id].research=-1
        end
    end
    Teams[id]=team
end
local team=Teams[PaleoSlot]
LoadPaleo()
eq(c.real[100],1,'real unique Library class'); eq(c.real[101],1,'real unique University class')
eq(c.free[100],0,'clear free dummy'); eq(foreign.real[100],0,'foreign cleanup'); eq(foreign.free[101],0,'foreign free cleanup')
local writes=c.writes
GameEvents.PlayerDoTurn.Fire(PaleoSlot); LoadPaleo()
eq(c.writes,writes,'idempotent repair and registration guard')
eq(#GameEvents.PlayerBuilt.handlers,1,'one completion listener')
c.real[10]=2; c.real[11]=3; c.real[12]=2; c.real[13]=4
GameEvents.CityConstructed.Fire(PaleoSlot,1,11)
eq(c.real[100],1,'duplicate Library capped'); eq(c.real[101],1,'duplicate University capped')
c.real[10]=0; c.real[11]=0
GameEvents.CitySoldBuilding.Fire(PaleoSlot,1,11)
eq(c.real[100],0,'sold last Library'); eq(c.real[101],1,'independent University')
c.real[12]=0; c.real[13]=0; c.free[11]=1; c.free[13]=1
Events.SerialEventCityInfoDirty.Fire()
eq(c.real[100],1,'free Library qualifies once'); eq(c.real[101],1,'free University qualifies once')
c.real[11]=1; c.real[13]=1
Events.NewGameTurn.Fire()
eq(c.real[100],1,'recover script building'); eq(c.real[101],1,'recover script university')
for _,city in ipairs(cities) do city.real[11]=1; city.real[13]=1 end
Events.ActivePlayerTurnStart.Fire()
local science,culture=0,0
for _,city in ipairs(cities) do
    science=science+city.real[100]+MuseumScience; culture=culture+city.real[101]+MuseumCulture
end
eq(science,15,'five cities expected Science'); eq(culture,10,'five cities expected Culture')
eq(MuseumScience+1,3,'one city unique Science'); eq(MuseumCulture+1,2,'one city unique Culture')
local function Transfer(city,from,to)
    from.cities[city.id]=nil; city.owner=to.id; to.cities[city.id]=city
end
-- Native CityCaptureComplete follows all building/ownership copying.
Transfer(c,owner,rival); c.free[100]=1
GameEvents.CityCaptureComplete.Fire(owner.id,true,c.x,0,rival.id,5,true)
eq(c.real[100],0,'capture strip Science'); eq(c.real[101],0,'capture strip Culture'); eq(c.free[100],0,'capture strip free dummy')
Transfer(c,rival,owner)
GameEvents.CityCaptureComplete.Fire(rival.id,true,c.x,0,owner.id,5,true)
eq(c.real[100],1,'recapture'); eq(c.real[101],1,'recapture independent')
Transfer(c,owner,rival); GameEvents.PlayerDoTurn.Fire(rival.id)
eq(c.real[100],0,'silent ownership recovery')
Transfer(c,rival,owner); GameEvents.PlayerLiberated.Fire(rival.id,owner.id,1)
eq(c.real[100],1,'liberation')
local founded=City(owner,7,7); founded.real[11]=1
GameEvents.PlayerCityFounded.Fire(owner.id,7,0)
eq(founded:GetNumRealBuilding(100),1,'founding with real Library'); eq(founded:GetNumRealBuilding(101),0,'founding no University')
eq(GameEvents.CityCanConstruct.handlers[1](owner.id,1,100),false,'dummy cannot construct')
eq(GameEvents.CityCanConstruct.handlers[1](owner.id,1,101),false,'culture dummy cannot construct')
eq(GameEvents.CityCanConstruct.handlers[1](owner.id,1,11),true,'normal building')
local function Unit(player,id,typ,x)
    local unit={owner=player.id,id=id,typ=typ,x=x,y=2}
    function unit:GetOwner() return self.owner end
    function unit:GetUnitType() return self.typ end
    function unit:GetX() return self.x end
    function unit:GetY() return self.y end
    player.units[id]=unit; return unit
end
local unit=Unit(owner,1,20,20); local site=Plot(20,2)
-- No completion signal for moving, starting, cancelling, disappearing or dying.
GameEvents.UnitSetXY.Fire(owner.id,1,20,2)
GameEvents.PlayerBuilding.Fire(owner.id,1,20,2,30,true)
GameEvents.BuildFinished.Fire(owner.id,20,2,40)
GameEvents.UnitPrekill.Fire(owner.id,1,20,2,false,-1)
eq(team.total,0,'no pseudo-completion detector')
GameEvents.PlayerBuilt.Fire(owner.id,1,20,2,31)
eq(team.total,0,'unrelated successful build')
site.improvement=40; site.artifact=0
unit.typ=21; GameEvents.PlayerBuilt.Fire(owner.id,1,20,2,30)
eq(team.total,0,'ordinary Archaeologist excluded'); unit.typ=20
Unit(rival,1,20,20); GameEvents.PlayerBuilt.Fire(rival.id,1,20,2,30)
eq(team.total,0,'foreign Fossil Expedition excluded')
owner.units[1]=nil; GameEvents.PlayerBuilt.Fire(owner.id,1,20,2,30)
eq(team.total,0,'missing completing unit excluded'); owner.units[1]=unit
unit.x=19; GameEvents.PlayerBuilt.Fire(owner.id,1,20,2,30)
eq(team.total,0,'coordinate mismatch excluded'); unit.x=20
site.artifact=-1; GameEvents.PlayerBuilt.Fire(owner.id,1,20,2,30)
eq(team.total,0,'no valid archaeological record'); site.artifact=0
GameEvents.PlayerBuilt.Fire(owner.id,1,20,2,30)
eq(team.total,ExpectedReward,'completed Artifact dig')
eq(owner.data:sub(1,18),'other-mod:[DATA:1]','preserve unrelated save data')
GameEvents.PlayerBuilt.Fire(owner.id,1,20,2,30)
eq(team.total,ExpectedReward,'repeat dispatch once')
-- Choice does not publish completion again; removing unit/site never pays.
site.improvement=-1; site.artifact=-1
GameEvents.UnitPrekill.Fire(owner.id,1,20,2,true,-1)
eq(team.total,ExpectedReward,'Artifact resolution no second reward')
local function Complete(x,id,typ)
    local u=Unit(owner,id,typ or 20,x); local p=Plot(x,2); p.improvement=40; p.artifact=0
    GameEvents.PlayerBuilt.Fire(owner.id,id,x,2,30)
    return u,p
end
local landmark,landmarkSite=Complete(21,2)
eq(team.total,ExpectedReward*2,'completed Landmark dig')
landmarkSite.improvement=41; landmarkSite.artifact=-1
GameEvents.UnitPrekill.Fire(owner.id,2,20,2,true,-1)
eq(team.total,ExpectedReward*2,'Landmark resolution no second reward')
-- Started by ordinary unit; completion uses the event's actual finishing unit.
GameEvents.PlayerBuilding.Fire(owner.id,1,22,2,30,true)
Complete(22,3)
eq(team.total,ExpectedReward*3,'qualifying finisher after handoff')
GameEvents.PlayerBuilding.Fire(owner.id,3,23,2,30,true)
Complete(23,4,21)
eq(team.total,ExpectedReward*3,'ordinary finisher after handoff')
-- No selected research and exhausted-tree state bank native Science overflow.
owner.research=-1; local before=owner.overflow
Complete(24,5)
eq(owner.overflow,before+ExpectedReward*100,'no selected research banks exact Science')
before=owner.overflow; Complete(25,6)
eq(owner.overflow,before+ExpectedReward*100,'end of tree preserves bank')
-- A refused commit never writes the site ledger.
owner.refuse=true; local data=owner.data; Complete(26,7)
eq(owner.data,data,'failed award never marked paid'); owner.refuse=false
before=owner.overflow; GameEvents.PlayerBuilt.Fire(owner.id,7,26,2,30)
eq(owner.overflow,before+ExpectedReward*100,'retry committed once')
owner.research=7; team.fail=true; data=owner.data
local ok=pcall(function() Complete(29,10) end)
eq(ok,false,'API failure reported'); eq(owner.data,data,'API failure never marked paid')
team.fail=false; GameEvents.PlayerBuilt.Fire(owner.id,10,29,2,30)
eq(team.total,ExpectedReward*4,'error releases award guard')
-- Native API completes a tech and preserves all excess, including old overflow.
owner.research=7; team.cost=10000; team.progress=9900; before=owner.overflow
Complete(27,8)
eq(owner.research,-1,'technology completes'); eq(owner.overflow,before+(ExpectedReward-1)*100,'no lost excess or old overflow')
-- Reload reconstructs class controllers while ScriptData and native stores persist.
local earned=team.total; local stored=owner.data; before=owner.overflow
for i=1,3 do
    NewContext(); LoadPaleo()
    GameEvents.PlayerBuilt.Fire(owner.id,8,27,2,30)
    eq(team.total,earned,'reload never pays twice'); eq(owner.data,stored,'ledger stable'); eq(owner.overflow,before,'overflow stable')
    eq(c.real[100],1,'reload Library'); eq(c.real[101],1,'reload University')
end
eq(#GameEvents.UnitPrekill.handlers,0,'no death hook')
eq(#GameEvents.UnitSetXY.handlers,0,'no movement hook')
eq(#GameEvents.BuildFinished.handlers,0,'no identity-free completion hook')
eq(#Events.SerialEventGameDataDirty.handlers,0,'no frame polling')
-- Custom speeds are explicitly disabled, not guessed from percentages.
SpeedName='GAMESPEED_CUSTOM'; GameInfo.GameSpeeds[2].Type=SpeedName
NewContext(); LoadPaleo(); data=owner.data; Complete(28,9)
eq(owner.data,data,'unsupported speed no payout or paid marker')
print('PASS PALEO '..ExpectedReward..' Science, human slot '..PaleoSlot..': '..assertions..' lifecycle/reward assertions (Lua51 mock; native acceptance NOT RUN)')
