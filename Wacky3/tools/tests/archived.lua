-- Actual production contexts, source-ordered mock events. No native pass claimed.
local assertions=0
local function eq(a,b,label)
    assertions=assertions+1
    assert(a==b,(label or '')..': expected '..tostring(b)..', got '..tostring(a))
end
local function Event()
    local e={handlers={}}
    function e.Add(f) e.handlers[#e.handlers+1]=f end
    function e.Fire(...) for _,f in ipairs(e.handlers) do f(...) end end
    return e
end
local function Bus() return setmetatable({},{__index=function(t,k) local e=Event(); rawset(t,k,e); return e end}) end
local function Context() Events,GameEvents,MapModData=Bus(),Bus(),{} end
Context()
GameDefines={MAX_CIV_PLAYERS=SlotCount}
DomainTypes={DOMAIN_LAND=2,DOMAIN_SEA=1}
Game={GetGameTurn=function() return 10 end,GetGameSpeedType=function() return SpeedName end}
GameInfo={Buildings=function() local n=0; return function() n=n+1; return BuildingRows[n] end end}
local plots,plotIndex,neighbors={},{},0
local farm=GameInfoTypes.IMPROVEMENT_FARM
Map={}
function Map.GetPlot(x,y)
    local key=x..':'..y
    if not plots[key] then
        local p={x=x,y=y,index=#plotIndex+1,owner=-1,improvement=-1,pillaged=false}
        function p:GetX() return self.x end; function p:GetY() return self.y end
        function p:GetOwner() return self.owner end; function p:GetPlotIndex() return self.index end
        function p:GetPlotCity() return self.city end
        function p:GetImprovementType() return self.improvement end
        function p:IsImprovementPillaged() return self.pillaged end
        -- No worked-plot API is supplied; touching one would fail the test.
        plots[key]=p; plotIndex[#plotIndex+1]=p
    end
    return plots[key]
end
local directions={{1,0},{0,1},{-1,1},{-1,0},{0,-1},{1,-1}}
function Map.PlotDirection(x,y,d)
    neighbors=neighbors+1
    local delta=directions[d+1]; return Map.GetPlot(x+delta[1],y+delta[2])
end
function Map.PlotDistance(x,y,a,b) local q,r=x-a,y-b; return math.max(math.abs(q),math.abs(r),math.abs(q+r)) end
local function iterator(t)
    local keys={}; for k in pairs(t) do keys[#keys+1]=k end
    table.sort(keys,function(a,b) return a>b end) -- tie attribution must not depend on order
    local n=0; return function() n=n+1; return keys[n] and t[keys[n]] end
end
Players,Teams={},{}
local codes={'LOST','SCARECROW','MAKURIA','SALT'}
for id=0,SlotCount-1 do
    local p={id=id,civ=id<4 and GameInfoTypes['CIVILIZATION_CWC3_'..codes[id+1]] or -50,cities={},units={},data='other-mod|[CWC3_ALMOST:9:2]',routes={},routeReads=0,unitScans=0}
    function p:GetID() return self.id end; function p:GetTeam() return self.id end
    function p:IsAlive() return true end; function p:IsHuman() return true end
    function p:GetCivilizationType() return self.civ end
    function p:Cities() return iterator(self.cities) end
    function p:Units() self.unitScans=self.unitScans+1; error('No global unit scan permitted') end
    function p:GetCityByID(i) return self.cities[i] end
    function p:GetUnitByID(i) return self.units[i] end
    function p:GetScriptData() return self.data end
    function p:SetScriptData(data) self.data=data end
    function p:GetTradeRoutes() self.routeReads=self.routeReads+1; return self.routes end
    Players[id]=p
    Teams[id]={IsAtWar=function(_,other) return id~=other end}
end
local lost,scare,mak,salt=Players[0],Players[1],Players[2],Players[3]
local function City(p,id,x,y)
    local c={owner=p.id,id=id,x=x,y=y or 0,real={},free={},original=p.id,founded=0,writes=0}
    function c:GetID() return self.id end; function c:GetOwner() return self.owner end
    function c:GetX() return self.x end; function c:GetY() return self.y end
    function c:GetOriginalOwner() return self.original end; function c:GetGameTurnFounded() return self.founded end
    function c:GetNumRealBuilding(b) return self.real[b] or 0 end
    function c:GetNumFreeBuilding(b) return self.free[b] or 0 end
    function c:GetNumBuilding(b) return self:GetNumRealBuilding(b)+self:GetNumFreeBuilding(b) end
    function c:SetNumRealBuilding(b,n,noBonus)
        eq(noBonus,true,'suppress instant construction yields'); eq(n==0 or n==1,true,'binary controller')
        self.real[b]=n; self.writes=self.writes+1
    end
    function c:SetNumFreeBuilding(b,n,refund,bonus)
        eq(n,0,'strip free controllers'); eq(refund,false,'no refunds'); eq(bonus,false,'no free bonuses'); self.free[b]=n
    end
    p.cities[id]=c; local plot=Map.GetPlot(x,c.y); plot.city=c; plot.owner=p.id
    return c
end
local lc,sc,mc,tc=City(lost,1,0),City(scare,1,20),City(mak,1,40),City(salt,1,60)
local function id(code,key) return assert(GameInfoTypes['BUILDING_CWC3_'..code..(key and '_'..key or '')]) end
local function dummy(c,code,key) return c:GetNumRealBuilding(id(code,key)) end
local function sum(c,code,prefix,max)
    local n=0; for i=1,max do n=n+dummy(c,code,prefix..'_'..i) end; return n
end
local function Curios(c) return sum(c,'LOST','CURIO_CULTURE',4) end
-- Bootstrap removes foreign and corrupt real/free controller copies.
sc.real[id('LOST','CURIO_CULTURE_1')]=7; sc.free[id('LOST','CURIO_CULTURE_1')]=4
lc.real[id('SCARECROW','FIELDS')]=1; lc.free[id('MAKURIA','WALLS')]=2
for _,code in ipairs(codes) do LoadArchive(code) end
eq(Curios(sc),0,'foreign Curio removed'); eq(sc:GetNumFreeBuilding(id('LOST','CURIO_CULTURE_1')),0,'free Curio removed')
eq(dummy(lc,'SCARECROW','FIELDS'),0,'foreign fields removed'); eq(lc:GetNumFreeBuilding(id('MAKURIA','WALLS')),0,'foreign free Walls controller removed')
local function handlers() local n=0; for _,bus in ipairs({GameEvents,Events}) do for _,e in pairs(bus) do n=n+#e.handlers end end; return n end
local nhandlers=handlers(); for _,code in ipairs(codes) do LoadArchive(code) end
eq(handlers(),nhandlers,'no duplicate context registration')
local function Unit(p,i,combat,x,y)
    local u={owner=p.id,id=i,combat=combat~=false,x=x or 1,y=y or 0,born=5,type=7,dead=false}
    function u:GetOwner() return self.owner end; function u:GetID() return self.id end
    function u:GetX() return self.x end; function u:GetY() return self.y end
    function u:GetGameTurnCreated() return self.born end; function u:GetUnitType() return self.type end
    function u:IsCombatUnit() return self.combat end; function u:IsDead() return self.dead end
    p.units[i]=u; return u
end
local officer=Unit(lost,1,true,1,0)
local nextVictim=0
local function battle(opts)
    opts=opts or {}; nextVictim=nextVictim+1
    local victim=Unit(scare,nextVictim,opts.combat,opts.x or 1,opts.y or 0)
    local args={0,1,0,opts.attackerDamage or 0,100,1,victim.id,100,opts.damage or 100,100,-1,-1,0,victim.x,victim.y}
    if opts.defending then args={1,victim.id,100,100,100,0,1,0,0,100,-1,-1,0,officer.x,officer.y} end
    GameEvents.CombatResult.Fire(unpack(args))
    if opts.cancel then return args,victim end
    victim.dead=opts.alive~=true
    GameEvents.CombatEnded.Fire(unpack(args))
    return args,victim
end
eq(Curios(lc),0,'zero Curios')
battle{combat=false}; eq(Curios(lc),0,'civilian capture excluded')
battle{x=10}; eq(Curios(lc),0,'outside radius excluded')
battle{damage=90,alive=true}; eq(Curios(lc),0,'nonlethal excluded')
battle{alive=true}; eq(Curios(lc),0,'surviving victim excluded')
battle{cancel=true}; eq(Curios(lc),0,'no completed combat excluded')
GameEvents.UnitPrekill.Fire(1,1,0,1,0,false,0); eq(Curios(lc),0,'disband/prekill excluded')
local args,victim=battle(); eq(Curios(lc),1,'first genuine combat kill')
GameEvents.CombatEnded.Fire(unpack(args)); eq(Curios(lc),1,'duplicate completion ignored')
-- Replayed full callback pair still cannot pay for a consumed victim.
GameEvents.CombatResult.Fire(unpack(args)); GameEvents.CombatEnded.Fire(unpack(args)); eq(Curios(lc),1,'persisted kill deduplication')
local second=City(lost,2,4)
battle{x=3}; eq(Curios(second),1,'nearest city attribution'); eq(Curios(lc),1,'only one city rewarded')
battle{x=2}; eq(Curios(lc),2,'tie chooses lowest city ID despite reversed iteration')
battle{defending=true}; eq(Curios(lc),3,'Department defending combat kill')
battle(); eq(Curios(lc),4,'four Curios')
battle(); eq(Curios(lc),4,'no fifth Curio')
battle{x=1}; eq(Curios(second),1,'full nearest city does not spill reward')
lc.real[id('LOST')]=1; GameEvents.CityConstructed.Fire(0,1,id('LOST'))
eq(sum(lc,'LOST','OFFICE_CULTURE',4),4,'Office adds four Culture')
eq(sum(lc,'LOST','OFFICE_GOLD',4),4,'Office adds four Gold')
eq(sum(lc,'LOST','CURIO_SCIENCE',4),4,'UA four recurring Science')
lc.real[id('LOST')]=0; GameEvents.CitySoldBuilding.Fire(0,1,id('LOST')); eq(sum(lc,'LOST','OFFICE_GOLD',4),0,'Office removal')
lc.real[id('LOST')]=1; GameEvents.CityConstructed.Fire(0,1,id('LOST')); eq(Curios(lc),4,'reconstruction cannot multiply Curios')
eq(lost.data:sub(1,9),'other-mod','unrelated ScriptData prefix preserved')
local function Transfer(c,from,to)
    from.cities[c.id]=nil; c.owner=to.id; to.cities[c.id+100]=c; Map.GetPlot(c.x,c.y).owner=to.id
end
Transfer(lc,lost,scare); GameEvents.CityCaptureComplete.Fire(0,false,lc.x,lc.y,1)
eq(Curios(lc),0,'captured city strips Department yields'); eq(sum(lc,'LOST','OFFICE_GOLD',4),0,'foreign Office conditional removed')
scare.cities[101]=nil; lc.owner=0; lost.cities[lc.id]=lc; Map.GetPlot(lc.x,lc.y).owner=0
GameEvents.PlayerLiberated.Fire(1,0,1); eq(Curios(lc),4,'liberation restores same lifetime ledger')
local saved=lost.data
Context(); for _,code in ipairs(codes) do LoadArchive(code) end
eq(Curios(lc),4,'reload restores ledger'); eq(lost.data,saved,'reload preserves serialized data')
GameEvents.CombatEnded.Fire(unpack(args)); eq(Curios(lc),4,'reload duplicate callback has no pending combat')
-- Destruction cleanup and refounding, even same coordinates/founding turn.
lost.cities[2]=nil; Map.GetPlot(4,0).city=nil; Events.SerialEventCityInfoDirty.Fire()
eq(lost.data:find('[CWC3_LOST_CITY_V1:4:0:',1,true),nil,'razed city ledger removed')
local refounded=City(lost,2,4); GameEvents.PlayerCityFounded.Fire(0,4,0); eq(Curios(refounded),0,'refounded city has zero Curios')
-- Farm thresholds are cumulative, unworked, unpillaged and owned only.
local farms={}
for _,p in pairs(plots) do if Map.PlotDistance(sc.x,sc.y,p.x,p.y)<=3 and p~=Map.GetPlot(sc.x,sc.y) then farms[#farms+1]=p end end
table.sort(farms,function(a,b) return a.index<b.index end)
eq(#farms,36,'bounded radius-three hex traversal')
sc.real[id('SCARECROW')]=1
local function Fields(n)
    for i,p in ipairs(farms) do p.improvement=i<=n and farm or -1; p.owner=scare.id; p.pillaged=false end
    GameEvents.TileImprovementChanged.Fire(sc.x,sc.y,1,-1,farm,false)
end
for _,n in ipairs({0,2,3,5,6,8,9,12}) do
    Fields(n)
    eq(dummy(sc,'SCARECROW','FIELDS'),n>=3 and 1 or 0,'Farm Culture/Production threshold '..n)
    eq(dummy(sc,'SCARECROW','GROWTH'),n>=6 and 1 or 0,'Farm additional Food '..n)
    eq(sum(sc,'SCARECROW','BELL_GOLD',3),math.min(3,math.floor(n/3)),'Harvest Bell capped Gold '..n)
end
Fields(3); farms[1].pillaged=true; GameEvents.TileImprovementChanged.Fire(farms[1].x,farms[1].y,1,farm,farm,true)
eq(dummy(sc,'SCARECROW','FIELDS'),0,'pillaged farm excluded')
farms[1].pillaged=false; GameEvents.TileImprovementChanged.Fire(); eq(dummy(sc,'SCARECROW','FIELDS'),1,'repair refresh')
farms[1].owner=0; GameEvents.TileOwnershipChanged.Fire(farms[1].x,farms[1].y,0,1); eq(dummy(sc,'SCARECROW','FIELDS'),0,'foreign-owned Farm excluded')
farms[1].owner=1; GameEvents.TileOwnershipChanged.Fire(); eq(dummy(sc,'SCARECROW','FIELDS'),1,'ownership transfer refresh')
Fields(0)
local overlap=City(scare,2,21,0)
for _,xy in ipairs({{20,1},{21,1},{22,0}}) do local p=Map.GetPlot(xy[1],xy[2]); p.owner=1; p.improvement=farm end
GameEvents.PlayerCityFounded.Fire(1,21,0)
eq(dummy(sc,'SCARECROW','FIELDS'),1,'shared Farm qualifies first city'); eq(dummy(overlap,'SCARECROW','FIELDS'),1,'shared Farm qualifies overlapping city')
Fields(9); sc.real[id('SCARECROW')]=0; GameEvents.CitySoldBuilding.Fire(1,1,id('SCARECROW'))
eq(sum(sc,'SCARECROW','BELL_GOLD',3),0,'no Bell no conditional Gold'); eq(dummy(sc,'SCARECROW','FIELDS'),1,'UA independent of Bell')
Transfer(overlap,scare,lost); GameEvents.CityCaptureComplete.Fire(1,false,21,0,0)
eq(dummy(overlap,'SCARECROW','FIELDS'),0,'foreign farm controllers cleared')
-- Walls normal, unique, free and duplicate representations; per-city condition.
local walls=assert(GameInfoTypes.BUILDING_WALLS)
eq(dummy(mc,'MAKURIA','WALLS'),0,'no Walls no UA')
mc.real[walls]=1; GameEvents.CityConstructed.Fire(2,1,walls); eq(dummy(mc,'MAKURIA','WALLS'),1,'native Walls class')
mc.real[walls]=0; mc.free[30000]=2; GameEvents.CityConstructed.Fire(2,1,30000); eq(dummy(mc,'MAKURIA','WALLS'),1,'free unique Walls replacement')
mc.real[walls]=3; mc.real[30000]=4; Events.SerialEventCityInfoDirty.Fire(); eq(dummy(mc,'MAKURIA','WALLS'),1,'duplicate free/real Walls capped')
mc.real[walls]=0; mc.real[30000]=0; mc.free[30000]=0; GameEvents.CitySoldBuilding.Fire(2,1,walls); eq(dummy(mc,'MAKURIA','WALLS'),0,'last Walls removed')
-- Trade-route native structure: real origin City object, domain and circuits.
local dest=City(lost,7,80)
local function Route(from,to,domain)
    return {FromID=from.owner,ToID=to.owner,FromCity=from,ToCity=to,Domain=domain or 2,CircuitsCompleted=0,CircuitsToComplete=5,IsRecalled=false,TurnsLeft=10}
end
tc.real[id('SALT')]=1
eq(dummy(tc,'SALT','PASSAGE'),0,'no route no bonus')
salt.routes={Route(tc,dest)}; GameEvents.UnitPrekill.Fire(3,7,7,60,0,true,-1)
eq(dummy(tc,'SALT','PASSAGE'),1,'post-establishment Caravan kill observes active land route')
eq(dummy(tc,'SALT','EXCHANGE'),1,'Exchange conditional Science')
for i=2,5 do salt.routes[i]=Route(tc,dest) end
Events.SerialEventGameDataDirty.Fire(); eq(dummy(tc,'SALT','PASSAGE'),1,'five routes remain binary')
salt.routes={Route(dest,tc)}; Events.SerialEventGameDataDirty.Fire(); eq(dummy(tc,'SALT','PASSAGE'),0,'incoming route excluded')
salt.routes={Route(tc,dest,1)}; Events.SerialEventGameDataDirty.Fire(); eq(dummy(tc,'SALT','PASSAGE'),0,'sea route excluded')
salt.routes={Route(tc,dest)}; salt.routes[1].IsRecalled=true; Events.SerialEventGameDataDirty.Fire(); eq(dummy(tc,'SALT','PASSAGE'),0,'canceled/recalled route excluded')
salt.routes[1].IsRecalled=false; salt.routes[1].TurnsLeft=-1; Events.SerialEventGameDataDirty.Fire(); eq(dummy(tc,'SALT','PASSAGE'),1,'native circuits govern expiry, not estimated turns')
salt.routes[1].CircuitsCompleted=5; GameEvents.PlayerTradeRouteCompleted.Fire(3,1,0,7,2,0)
eq(dummy(tc,'SALT','PASSAGE'),0,'pre-clear completion already excluded'); eq(dummy(tc,'SALT','EXCHANGE'),0,'expired conditional Science removed')
eq(tc.real[id('SALT')],1,'expiry preserves permanent Exchange')
salt.routes={Route(tc,dest)}; Events.SerialEventGameDataDirty.Fire(); salt.routes={}; GameEvents.PlayerPlunderedTradeRoute.Fire()
eq(dummy(tc,'SALT','PASSAGE'),0,'plunder after clear')
salt.routes={Route(tc,dest)}; Events.SerialEventGameDataDirty.Fire(); Transfer(tc,salt,lost); GameEvents.CityCaptureComplete.Fire(3,false,60,0,0)
eq(dummy(tc,'SALT','PASSAGE'),0,'captured origin cleaned')
-- Realistic load: 25+ cities, 34 occupied slots, many routes/Farms/units.
for i=10,34 do
    City(lost,i,100+i*12); local s=City(scare,i,600+i*12)
    for d=0,5 do local p=Map.PlotDirection(s.x,s.y,d); p.owner=1; p.improvement=farm end
    local m=City(mak,i,1200+i*12); m.free[walls]=1
    local t=City(salt,i,1800+i*12); t.real[id('SALT')]=1
    for j=1,4 do salt.routes[#salt.routes+1]=Route(t,dest) end
    for j=1,40 do Unit(lost,i*100+j) end
end
local beforeNeighbors,beforeRoutes=neighbors,salt.routeReads
Events.NewGameTurn.Fire()
eq(neighbors-beforeNeighbors<=30*19*6*4,true,'bounded Farm adjacency work, no map scan')
eq(salt.routeReads-beforeRoutes<=4,true,'route enumeration shared across cities')
for i=10,34 do
    eq(dummy(scare.cities[i],'SCARECROW','GROWTH'),1,'large-game six Farms')
    eq(dummy(mak.cities[i],'MAKURIA','WALLS'),1,'large-game free Walls')
    eq(dummy(salt.cities[i],'SALT','PASSAGE'),1,'large-game active origins')
end
for i=0,SlotCount-1 do GameEvents.PlayerDoTurn.Fire(i); eq(Players[i].unitScans,0,'no owner-turn unit scan') end
local before=lc.writes+sc.writes+mc.writes
Events.SerialEventCityInfoDirty.Fire(); Events.SerialEventCityInfoDirty.Fire()
eq(lc.writes+sc.writes+mc.writes,before,'idempotent reconciliation')
local persistent=lost.data
Context(); for _,code in ipairs(codes) do LoadArchive(code) end
eq(lost.data,persistent,'large reload preserves ledger and unrelated records')
eq(Curios(lc),4,'large reload Curios')
eq(#GameEvents.CombatEnded.handlers,1,'one combat completion registration')
eq(#GameEvents.UnitKilledInCombat.handlers,0,'ambiguous killer-only hook unused')
print('PASS archived civilizations: '..assertions..' Lua51 assertions; '..SlotCount..' occupied major slots, '..SpeedName..', 25+ cities per civ, 100 routes, 1000+ units, reload/ownership/thresholds/combat completion; native gameplay NOT RUN')
