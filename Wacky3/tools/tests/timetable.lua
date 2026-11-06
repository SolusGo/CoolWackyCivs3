-- Production Lua controller, real executed SQL yield mapping, axial hex graph.
-- Engine connection flags are independent of our railroad graph on purpose.
GameInfoTypes={CIVILIZATION_CWC3_PERPETUAL_TIMETABLE=200,BUILDING_CWC3_DISPATCH_OFFICE=201,
 BUILDING_CWC3_TIMETABLE_CONNECTION_PRODUCTION=202,BUILDING_CWC3_TIMETABLE_CONNECTION_SCIENCE=203,
 BUILDING_CWC3_TIMETABLE_RAIL_CULTURE=204,BUILDING_CWC3_TIMETABLE_DISPATCH_CULTURE=205,
 BUILDING_CWC3_TIMETABLE_DISPATCH_RAIL_PRODUCTION=206,TECH_RAILROAD=300,ROUTE_RAILROAD=2}
GameDefines={MAX_CIV_PLAYERS=MajorCount}
local checks,writes,reads,steps,ordinary = 0,0,0,0,0
local roots,plots = {},{}
local function Check(v,message) checks=checks+1; assert(v,message) end
local function Key(x,y) return x..':'..y end
local directions={{1,0},{1,-1},{0,-1},{-1,0},{-1,1},{0,1}}
local function Registry()
 return setmetatable({}, {__index=function(self,key)
  local event={handlers={}}
  function event.Add(f) event.handlers[#event.handlers+1]=f end
  function event.Fire(...)
   local result=true
   for _,f in ipairs(event.handlers) do if f(...)==false then result=false end end
   return result
  end
  rawset(self,key,event); return event
 end})
end
local function ResetEvents()
 MapModData={}; GameEvents=Registry(); Events=Registry()
end
local function Plot(x,y,owner,route)
 local p={x=x,y=y,owner=owner or -1,route=route or -1,pillaged=false,water=false,mountain=false,impassable=false}
 function p:GetX() return self.x end
 function p:GetY() return self.y end
 function p:GetPlotIndex() return self.index end
 function p:GetOwner() return self.owner end
 function p:IsWater() return self.water end
 function p:IsMountain() return self.mountain end
 function p:IsImpassable(team) assert(team~=nil); return self.impassable end
 function p:GetPlotCity() return self.city end
 function p:GetRouteType() return self.route end
 function p:IsRoutePillaged() return self.pillaged end
 p.index=x*10000+y+5000
 plots[Key(x,y)]=p; return p
end
Map={}
function Map.GetPlot(x,y) reads=reads+1; return plots[Key(x,y)] end
function Map.PlotDirection(x,y,d)
 steps=steps+1
 if d==0 then roots[Key(x,y)]=(roots[Key(x,y)] or 0)+1 end
 local delta=directions[d+1]
 return Map.GetPlot(x+delta[1],y+delta[2])
end
local function World()
 ResetEvents(); plots={}; roots={}; writes=0; reads=0; steps=0; ordinary=0
 Players={}; Teams={}
 for i=0,MajorCount-1 do
  local player={civ=(i==0 or i==2 or i==3) and 200 or 0,alive=true,human=i==0 or i==2,cities={},capital=nil}
  function player:IsAlive() return self.alive end
  function player:IsHuman() return self.human end
  function player:GetCivilizationType() return self.civ end
  function player:GetTeam() return i end
  function player:GetCapitalCity() return self.capital end
  function player:Cities() local n=0; return function() n=n+1; return self.cities[n] end end
  function player:GetCityByID(id) for _,c in ipairs(self.cities) do if c.id==id then return c end end end
  function player:IsCapitalConnectedToCity(city)
   Check(city.owner==i,'ordinary API called for wrong owner')
   ordinary=ordinary+1; return city.connection~=nil
  end
  -- Deliberately no ScriptData/instant-yield APIs in this mock.
  Players[i]=player
  local team={rail=false}
  function team:IsHasTech(tech) assert(tech==300); return self.rail end
  Teams[i]=team
 end
end
local function City(owner,id,x,y,office)
 local city={owner=owner,id=id,x=x,y=y,buildings={[201]=office and 1 or 0},free={},connection=nil}
 function city:GetOwner() return self.owner end
 function city:GetID() return self.id end
 function city:GetX() return self.x end
 function city:GetY() return self.y end
 function city:GetNumBuilding(b) return (self.buildings[b] or 0)+(self.free[b] or 0) end
 function city:GetNumRealBuilding(b) return self.buildings[b] or 0 end
 function city:GetNumFreeBuilding(b) return self.free[b] or 0 end
 function city:SetNumRealBuilding(b,n,noBonus)
  Check(n==0 or n==1,'dummy must be bounded'); Check(noBonus==true,'suppress rewards')
  self.buildings[b]=n; writes=writes+1
  -- An event raised inside a write cannot reenter/repeat reconciliation.
  if GameEvents.CityConstructed then GameEvents.CityConstructed.Fire(self.owner,self.id,b,false,false) end
 end
 function city:SetNumFreeBuilding(b,n,refund,validate)
  Check(n==0 and refund==false and validate==false,'free controller cleanup flags')
  self.free[b]=n; writes=writes+1
 end
 local plot=plots[Key(x,y)] or Plot(x,y,owner)
 plot.city=city; plot.owner=owner
 Players[owner].cities[#Players[owner].cities+1]=city
 return city
end
local function Evaluate(owner)
 roots={}; steps=0; ordinary=0
 GameEvents.PlayerDoTurn.Fire(owner or 0)
end
local function Expected(city,p,s,c,g)
 local yields={YIELD_PRODUCTION=0,YIELD_SCIENCE=0,YIELD_CULTURE=0,YIELD_GOLD=0}
 for b=202,206 do
  Check(city:GetNumRealBuilding(b)==0 or city:GetNumRealBuilding(b)==1,'0/1 state')
  Check(city:GetNumFreeBuilding(b)==0,'no free dummy leak')
  local row=DatabaseYields[b]
  yields[row.kind]=yields[row.kind]+row.amount*city:GetNumRealBuilding(b)
 end
 if city:GetNumBuilding(201)>0 then yields.YIELD_GOLD=DatabaseGold end
 Check(yields.YIELD_PRODUCTION==p,'unique Production expected '..p..', got '..yields.YIELD_PRODUCTION)
 Check(yields.YIELD_SCIENCE==s,'unique Science expected '..s)
 Check(yields.YIELD_CULTURE==c,'unique Culture expected '..c)
 Check(yields.YIELD_GOLD==g,'unique Gold expected '..g)
 return yields
end
local function Basic(office)
 World()
 local a=City(0,1,0,0,office); Players[0].capital=a
 local b=City(0,2,4,0,office)
 LoadTimetable()
 return a,b
end
local function RailPath()
 for x=1,3 do Plot(x,0,0,2) end
end
local function Transfer(city,owner,replacement)
 local old=Players[city.owner].cities
 for i,c in ipairs(old) do if c==city then table.remove(old,i); break end end
 if Players[city.owner].capital==city then Players[city.owner].capital=old[1] end
 if replacement then
  -- Native acquisition can replace both object and ID at stable coordinates.
  local new=City(owner,city.id+1000,city.x,city.y,city:GetNumBuilding(201)>0)
  for b=202,206 do new.buildings[b]=city.buildings[b]; new.free[b]=city.free[b] end
  new.connection=city.connection; return new
 end
 city.owner=owner; plots[Key(city.x,city.y)].owner=owner
 Players[owner].cities[#Players[owner].cities+1]=city
 return city
end

-- A/B/C/I: real building yields, roads/Harbors, flat non-capital effects.
local a,b=Basic(true)
Expected(a,0,0,0,1); Expected(b,0,0,0,1)
for _,mode in ipairs({'road','harbor'}) do
 b.connection=mode; Evaluate()
 Expected(b,1,1,1,1); Expected(a,0,0,0,1)
 b.buildings[201]=0; Evaluate(); Expected(b,1,1,0,0)
 b.buildings[201]=1
end
b.connection=nil; Evaluate(); Expected(b,0,0,0,1)

-- D/H: railroad technology gates one shared BFS, independent of normal flag.
RailPath(); b.connection='rail'; Evaluate(); Expected(b,1,1,1,1)
Check(steps==0,'skip BFS before technology')
Teams[0].rail=true; Evaluate(); Expected(b,2,1,2,1)
Check(roots['0:0']==1 and steps==30,'one BFS across five plots')
b.buildings[201]=0; Evaluate(); Expected(b,1,1,1,0)
b.buildings[201]=1
b.connection=nil; Evaluate(); Expected(b,1,0,1,1)
Check(b:GetNumRealBuilding(204)==1 and b:GetNumRealBuilding(205)==0,'rail is independent of ordinary flag')
b.connection='rail'

-- E/F/G: missing/foreign/unowned/pillaged/impassable/water/mountain segment.
local segment=plots['2:0']
for _,case in ipairs({'road','missing','foreign','unowned','pillaged','water','mountain','impassable'}) do
 segment.route=2; segment.owner=0; segment.pillaged=false; segment.water=false; segment.mountain=false; segment.impassable=false
 if case=='road' then segment.route=1 elseif case=='missing' then segment.route=-1
 elseif case=='foreign' then segment.owner=2 -- even same civilization or allied territory fails
 elseif case=='unowned' then segment.owner=-1 elseif case=='pillaged' then segment.pillaged=true
 elseif case=='water' then segment.water=true elseif case=='mountain' then segment.mountain=true
 elseif case=='impassable' then segment.impassable=true end
 Evaluate(); Expected(b,1,1,1,1)
end
segment.impassable=false; segment.owner=0; segment.route=2; Evaluate(); Expected(b,2,1,2,1)
segment.pillaged=true
-- Alternative continuous hex path around the broken segment, with a cycle.
for x=0,4 do Plot(x,1,0,2) end
Evaluate(); Expected(b,2,1,2,1)
Check(roots['0:0']==1,'cycles cannot revisit the root')
plots['2:1'].owner=-1; Evaluate(); Expected(b,1,1,1,1)
segment.pillaged=false; Evaluate(); Expected(b,2,1,2,1)
for x=0,4 do plots[Key(x,1)].route=-1 end

-- Owned centers are route-free junctions; foreign city centers cannot bridge.
local junction=City(0,3,2,0,false); junction.connection='road'
plots['2:0'].route=-1; Evaluate(); Expected(b,2,1,2,1); Expected(junction,1,1,1,0)
Transfer(junction,1); GameEvents.CityCaptureComplete.Fire(0,false,2,0,1,5,false)
Expected(b,1,1,1,1); Expected(junction,0,0,0,0)
junction=Transfer(junction,0,true); GameEvents.CityCaptureComplete.Fire(1,false,2,0,0,5,true)
Expected(b,2,1,2,1)

-- L: construction, sale and scripted removal through bounded owner fallback.
b.buildings[201]=0; GameEvents.CitySoldBuilding.Fire(0,b.id,201); Expected(b,1,1,1,0)
b.buildings[201]=1; GameEvents.CityConstructed.Fire(0,b.id,201,true,false); Expected(b,2,1,2,1)
b.buildings[201]=0; Evaluate(); Expected(b,1,1,1,0)
b.free[201]=1; GameEvents.CityConstructed.Fire(0,b.id,201,false,true); Expected(b,2,1,2,1)
b.free[201]=0; b.buildings[201]=1
-- Founding at an adjacent center extends the same network without a route tile.
local founded=City(0,4,5,0,true); founded.connection='road'
GameEvents.PlayerCityFounded.Fire(0,5,0); Expected(founded,2,1,2,1)
-- Capital relocation removes EVERY conditional bonus from the new Capital.
Players[0].capital=b; a.connection='road'; Evaluate()
Expected(b,0,0,0,1); Expected(a,2,1,2,1)
Players[0].capital=a; Evaluate(); Expected(a,0,0,0,1)

-- Conquest, cession/gift, liberation; replacement city objects and IDs.
local captured=Transfer(b,1,true)
GameEvents.CityCaptureComplete.Fire(0,false,4,0,1,5,true)
Expected(captured,0,0,0,1); Expected(founded,1,1,1,1)
captured=Transfer(captured,0,true)
GameEvents.CityCaptureComplete.Fire(1,false,4,0,0,5,false); Expected(captured,2,1,2,1)
captured=Transfer(captured,1,true); GameEvents.CityCaptureComplete.Fire(0,false,4,0,1,5,false)
captured=Transfer(captured,0,true); GameEvents.PlayerLiberated.Fire(1,0,captured.id)
Expected(captured,2,1,2,1)
-- Missed transfer completion recovered by coordinates on Timetable owner turn.
captured=Transfer(captured,1,true); Evaluate(); Expected(captured,0,0,0,1)
captured=Transfer(captured,0,true); Evaluate(); Expected(captured,2,1,2,1)
-- Capital capture selects a new native Capital; old Capital's yields clear.
a=Transfer(a,1,true); GameEvents.CityCaptureComplete.Fire(0,true,0,0,1,5,true)
Expected(a,0,0,0,1); Expected(Players[0].capital,0,0,0,0)
-- No capital and eliminated players are safe and do not keep conditionals.
Players[0].capital=nil; Evaluate(); Expected(captured,0,0,0,1)
Players[0].alive=false; Evaluate(); Expected(founded,0,0,0,1)
Players[0].alive=true; Players[0].capital=captured; Evaluate(); Expected(captured,0,0,0,1)

-- Human-only; multiple Timetable owners have independent networks and teams.
local other=City(2,1,20,0,true); Players[2].capital=other
local otherCity=City(2,2,22,0,true); otherCity.connection='harbor'
Plot(21,0,2,2); Evaluate(2); Expected(otherCity,1,1,1,1)
Teams[2].rail=true; Evaluate(2); Expected(otherCity,2,1,2,1)
local ai=City(3,1,25,0,false); ai.connection='road'
for id=202,206 do ai.buildings[id]=5; ai.free[id]=2 end
Evaluate(3); Expected(ai,0,0,0,0)

-- Reload corrupt real/free counts, free copies on foreign cities, and leave an
-- unrelated civilization's assets untouched. No persistent ledger is required.
captured.buildings[999]=7; a.buildings[998]=4
for id=202,206 do captured.buildings[id]=9; captured.free[id]=3; a.buildings[id]=4; a.free[id]=2 end
ResetEvents(); LoadTimetable()
Expected(captured,0,0,0,1); Expected(a,0,0,0,1)
Check(captured.buildings[999]==7 and a.buildings[998]==4,'unrelated state preserved')
local registrations={}
for name,event in pairs(GameEvents) do registrations[name]=#event.handlers end
local oldWrites=writes; LoadTimetable()
for name,event in pairs(GameEvents) do Check(#event.handlers==registrations[name],'duplicate registration '..name) end
Check(writes==oldWrites,'reinclude has no writes')
Evaluate(2); oldWrites=writes; Evaluate(2); Check(writes==oldWrites,'idempotent reconciliation')
for id=202,206 do Check(GameEvents.CityCanConstruct.Fire(0,captured.id,id)==false,'unbuildable dummy') end
Check(GameEvents.CityCanConstruct.Fire(0,captured.id,201),'Office remains constructible')

-- Economic model: settle existing city yields, THEN fire post-economy callback.
-- These checks demonstrate our contract, not actual engine settlement timing.
a,b=Basic(true); b.connection='road'
local function Payout(city)
 local total={p=0,s=0,c=0,g=city:GetNumBuilding(201)>0 and DatabaseGold or 0}
 local keys={YIELD_PRODUCTION='p',YIELD_SCIENCE='s',YIELD_CULTURE='c'}
 for id=202,206 do local row=DatabaseYields[id]; local k=keys[row.kind]; total[k]=total[k]+city:GetNumRealBuilding(id)*row.amount end
 return total
end
local payout=Payout(b); Evaluate(); Check(payout.p==0 and payout.s==0,'current payout already settled')
payout=Payout(b); Check(payout.p==1 and payout.s==1,'following payout uses reconciled connection')
b.connection=nil; payout=Payout(b); Evaluate(); Check(payout.p==1,'no retroactive payout changes')
payout=Payout(b); Check(payout.p==0 and payout.s==0,'following payout removes lost connection')

-- M: six-city acceptance example, SQL-derived totals 10/5/10/6 exactly.
World(); local capital=City(0,1,0,0,true); Players[0].capital=capital; Teams[0].rail=true
for x=1,10 do
 if x%2==0 then local c=City(0,x, x,0,true); c.connection='rail'
 else Plot(x,0,0,2) end
end
LoadTimetable(); local sum={YIELD_PRODUCTION=0,YIELD_SCIENCE=0,YIELD_CULTURE=0,YIELD_GOLD=0}
for c in Players[0]:Cities() do
 local y=Expected(c,c==capital and 0 or 2,c==capital and 0 or 1,c==capital and 0 or 2,1)
 for k,v in pairs(y) do sum[k]=sum[k]+v end
end
Check(sum.YIELD_PRODUCTION==10 and sum.YIELD_SCIENCE==5 and sum.YIELD_CULTURE==10 and sum.YIELD_GOLD==6,'six-city economy')

-- N: 34 players, hundreds of foreign/disconnected cities, 100 rail cities.
-- PlotDirection is instrumented: exactly six neighbor checks per reached plot.
for x=11,200 do
 if x%2==0 then local c=City(0,x,x,0,true); c.connection='rail'
 else Plot(x,0,0,2) end
end
for owner=1,MajorCount-1 do
 for n=1,15 do City(owner,n,500+owner*20,n,false) end
end
for n=1,50 do City(0,1000+n,-500,n,true) end
Evaluate(); Check(roots['0:0']==1,'exactly one BFS for owner, not one per city')
Check(steps==201*6,'BFS is bounded by reachable rail plots, not empire/map size')
Check(ordinary==150,'one ordinary connection query per non-capital city')
local ownerSteps=steps; Evaluate(1); Check(steps==0,'unrelated player turn does not search Timetable rail network')
for c in Players[0]:Cities() do
 if c.x>0 then Expected(c,2,1,2,1) elseif c.x<0 then Expected(c,0,0,0,1) end
end
-- Technology skip at scale, followed by current-state reload restoration.
Teams[0].rail=false; Evaluate(); Check(steps==0,'large pre-tech game skips BFS')
Teams[0].rail=true; ResetEvents(); LoadTimetable()
Check(roots['0:0']==1,'reload searches each eligible owner once')
print('PASS Timetable: '..checks..' assertions; A-I/L-M connection, rail, lifecycle, yield/reload cases; '..MajorCount..'-player N fixture; '..ownerSteps..' neighbor calls for 100 rail cities; native in-game timing NOT tested')
