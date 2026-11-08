-- Production controller with save strings retained across isolated context reloads.
local checks,reads,writes,iterations = 0,0,0,0
local function Check(value,label) checks=checks+1; assert(value,label) end
local names={'PlayerDoTurn','PlayerCityFounded','CityCaptureComplete','PlayerLiberated','CityRazed',
 'CityConstructed','CitySoldBuilding','CityCanConstruct','UnitSetXY','UnitCreated','UnitConverted','TileOwnershipChanged','BattleStarted'}
local function EventsFor(keys)
 local t={}
 for _,k in ipairs(keys) do
  local event={handlers={}}
  function event.Add(f) event.handlers[#event.handlers+1]=f end
  function event.Fire(...)
   local result=true
   for _,f in ipairs(event.handlers) do if f(...)==false then result=false end end
   return result
  end
  t[k]=event
 end
 return setmetatable(t,{__index=function(_,k) error('Unverified event: '..k) end})
end
GameInfoTypes={CIVILIZATION_CWC3_COVENANT=100,BUILDING_CWC3_COVENANT_HALL=101,
 PROMOTION_CWC3_COVENANT_ETERNAL_VIGIL=102,PROMOTION_CWC3_COVENANT_DEFENSE=103}
local suffixes={}
for i=1,12 do suffixes[#suffixes+1]='CAPITAL_CULTURE_'..i end
for i=1,4 do suffixes[#suffixes+1]='CAPITAL_SCIENCE_'..i end
for i=1,2 do suffixes[#suffixes+1]='HALL_SCIENCE_'..i end
for i,s in ipairs(suffixes) do GameInfoTypes['BUILDING_CWC3_COVENANT_'..s]=200+i end
GameDefines={MAX_CIV_PLAYERS=MajorCount+1}
Game={GetGameTurn=function() return 50 end,GetGameSpeedType=function() return 3 end}
local plots,serial,storageWrites
local function Key(x,y) return x..','..y end
local function Plot(x,y,owner)
 local plot={x=x,y=y,owner=owner,units={},open=false}
 function plot:GetPlotCity() return self.city end
 function plot:GetOwner() return self.owner end
 function plot:IsFriendlyTerritory(ownerID)
  if self.owner<0 then return false end
  return self.open or Players[self.owner].team==Players[ownerID].team
 end
 function plot:GetNumUnits() return #self.units end
 function plot:GetUnit(i) return self.units[i+1] end
 plots[Key(x,y)]=plot; return plot
end
Map={GetPlot=function(x,y) reads=reads+1; return plots[Key(x,y)] end}
local function ResetEvents()
 MapModData={}; GameEvents=EventsFor(names); Events=EventsFor({'NewGameTurn'})
end
local function World(present)
 ResetEvents(); plots={}; serial=0; storageWrites=0
 reads,writes,iterations=0,0,0
 Players={}
 for i=0,MajorCount do
  local p={civ=i==KeeperSlot and present~=false and 100 or 0,alive=true,human=i==KeeperSlot,team=i,cities={},units={},data='[OTHER_MOD:preserved]'}
  function p:IsHuman() return self.human end
  function p:IsAlive() return self.alive end
  function p:IsMinorCiv() return i==MajorCount end
  function p:IsBarbarian() return false end
  function p:GetCivilizationType() return self.civ end
  function p:GetCapitalCity() return self.capital end
  function p:GetScriptData() return self.data end
  function p:SetScriptData(data) self.data=data; storageWrites=storageWrites+1 end
  function p:Cities()
   iterations=iterations+1
   local n=0; return function() n=n+1; return self.cities[n] end
  end
  function p:Units() local n=0; return function() n=n+1; return self.units[n] end end
  function p:GetCityByID(id) for _,c in ipairs(self.cities) do if c.id==id then return c end end end
  function p:GetUnitByID(id) for _,u in ipairs(self.units) do if u.id==id then return u end end end
  Players[i]=p
 end
end
local function City(owner,x,y,hall,founded,original)
 serial=serial+1
 local c={owner=owner,id=serial,x=x,y=y,founded=founded or serial,original=original or owner,real={[101]=hall and 1 or 0},free={}}
 function c:GetOwner() return self.owner end
 function c:GetID() return self.id end
 function c:GetX() return self.x end
 function c:GetY() return self.y end
 function c:GetGameTurnFounded() return self.founded end
 function c:GetOriginalOwner() return self.original end
 function c:GetNumBuilding(b) return (self.real[b] or 0)+(self.free[b] or 0) end
 function c:GetNumRealBuilding(b) return self.real[b] or 0 end
 function c:GetNumFreeBuilding(b) return self.free[b] or 0 end
 function c:SetNumRealBuilding(b,n,noBonus)
  Check(n==0 or n==1,'0/1 controller'); Check(noBonus==true,'construction rewards suppressed')
  self.real[b]=n; writes=writes+1
  GameEvents.CityConstructed.Fire(self.owner,self.id,b,false,false)
 end
 function c:SetNumFreeBuilding(b,n,refund,validate)
  Check(n==0 and refund==false and validate==false,'free cleanup without refunds')
  self.free[b]=n; writes=writes+1
 end
 local plot=plots[Key(x,y)] or Plot(x,y,owner)
 plot.owner=owner; plot.city=c
 local p=Players[owner]; p.cities[#p.cities+1]=c
 p.capital=p.capital or c
 return c
end
local function Remove(city)
 local p=Players[city.owner]
 for i,c in ipairs(p.cities) do if c==city then table.remove(p.cities,i); break end end
 if p.capital==city then p.capital=p.cities[1] end
 plots[Key(city.x,city.y)].city=nil
end
local function Transfer(city,newOwner)
 Remove(city)
 -- Native acquireCity replaces city object and local ID, but preserves lifetime.
 local new=City(newOwner,city.x,city.y,city:GetNumBuilding(101)>0,city.founded,city.original)
 new.real=city.real; new.free=city.free
 GameEvents.CityCaptureComplete.Fire(city.owner,false,city.x,city.y,newOwner,5,true)
 return new
end
local function FlameCount()
 return tonumber(Players[KeeperSlot].data:match('%[CWC3_COVENANT_V1:(%d+),')) or 0
end
local function Expected(city,culture,science)
 local c,s=0,0
 for i=201,218 do
  local n=city:GetNumBuilding(i)
  Check(n==0 or n==1,'bounded total controller count')
  Check(city:GetNumFreeBuilding(i)==0,'no free leak')
  local row=DatabaseYields[i]
  if row.kind=='YIELD_CULTURE' then c=c+n*row.amount else s=s+n*row.amount end
 end
 if city:GetNumBuilding(101)>0 then c=c+DatabaseHallCulture end
 Check(c==culture,'culture '..culture..' actual '..c)
 Check(s==science,'science '..science..' actual '..s)
 return c,s
end
local function Reload() ResetEvents(); LoadCovenant() end
local function Turn(owner) GameEvents.PlayerDoTurn.Fire(owner or KeeperSlot) end
local function Reconcile() Events.NewGameTurn.Fire() end
local function Basic()
 World(); local capital=City(KeeperSlot,0,0,true); local hall=City(KeeperSlot,1,0,true)
 local foreign=City(RivalSlot,10,0,false)
 LoadCovenant()
 return capital,hall,foreign
end
local function Raze(city)
 local before=FlameCount()
 GameEvents.CityRazed.Fire(city.owner,city.x,city.y)
 Check(FlameCount()==before,'pre-removal cannot award')
 Remove(city); Turn(RivalSlot)
end

local a,b,foreign=Basic()
Expected(a,1,0); Expected(b,1,0); Check(FlameCount()==0,'new-game no losses')
GameEvents.CityRazed.Fire(RivalSlot,foreign.x,foreign.y)
Turn(); Reload(); Check(FlameCount()==0,'surviving pre-removal candidate never qualifies')
foreign=Transfer(foreign,KeeperSlot); Check(FlameCount()==0,'capture alone')
foreign=Transfer(foreign,RivalSlot); Check(FlameCount()==0,'repeated transfer')
Raze(foreign); Check(FlameCount()==1,'foreign capture then raze')
Expected(a,2,0); Expected(b,1,0)
for n=2,13 do
 local c=City(RivalSlot,10+n,0,false)
 GameEvents.PlayerCityFounded.Fire(RivalSlot,c.x,c.y)
 Raze(c)
 local count=math.min(n,12)
 Check(FlameCount()==count,'flame cap and each distinct destruction '..n)
 local hs=count>=9 and 2 or count>=3 and 1 or 0
 Expected(a,count+1,math.floor(count/3)+hs); Expected(b,1,hs)
 if n==2 or n==3 or n==6 or n==9 or n==12 then
  local data=Players[KeeperSlot].data
  Reload(); Check(Players[KeeperSlot].data==data,'byte-stable reload '..n..'\nbefore: '..data..'\nafter: '..Players[KeeperSlot].data)
  local oldWrites=writes; Reconcile(); Turn(); Check(writes==oldWrites,'idempotent yields')
 end
end
Check(select(2,Players[KeeperSlot].data:gsub(';L,',''))==12,'bounded 12 destruction ledger')
Check(Players[KeeperSlot].data:find('[OTHER_MOD:preserved]',1,true),'other namespaces preserved')
-- Capital moves and captured Hall cleanup, including corrupted free controllers.
Players[KeeperSlot].capital=b; Turn(); Expected(a,1,2); Expected(b,13,6)
a.free[201]=5; a.real[218]=8
local captured=Transfer(a,RivalSlot); Expected(captured,1,0)
Check(FlameCount()==12,'capital capture preserves ledger')
Players[KeeperSlot].capital=nil; Turn(); Expected(b,1,2)
Players[KeeperSlot].capital=b; Turn(); Expected(b,13,6)
b.real[101]=0; GameEvents.CitySoldBuilding.Fire(KeeperSlot,b.id,101); Expected(b,12,4)
b.real[101]=1; GameEvents.CityConstructed.Fire(KeeperSlot,b.id,101,true,false); Expected(b,13,6)
b.real[101]=0; Turn(); Expected(b,12,4) -- scripted removal recovery
b.free[101]=1; GameEvents.CityConstructed.Fire(KeeperSlot,b.id,101,false,true); Expected(b,13,6)

-- Eligibility, minor-to-major classification, own-founder anti-farming.
a,b,foreign=Basic()
Raze(a); Check(FlameCount()==0,'Covenant-owned destruction')
local minor=City(MajorCount,30,0,false); GameEvents.PlayerCityFounded.Fire(MajorCount,30,0)
Raze(minor); Check(FlameCount()==0,'city-state destruction')
local own=City(KeeperSlot,31,0,false); GameEvents.PlayerCityFounded.Fire(KeeperSlot,31,0)
own=Transfer(own,RivalSlot); own.original=RivalSlot -- special acquisition must not clear exclusion
Reconcile(); Raze(own); Check(FlameCount()==0,'Covenant founder never farmed')
minor=City(MajorCount,32,0,false); GameEvents.PlayerCityFounded.Fire(MajorCount,32,0)
minor=Transfer(minor,RivalSlot); Raze(minor); Check(FlameCount()==1,'minor founder, last major owner qualifies')
foreign=Transfer(foreign,MajorCount); Raze(foreign); Check(FlameCount()==1,'major founder, last minor owner excluded')
-- Known snapshot disappears by scripted kill; eliminated owner is still major.
local c=City(RivalSlot,33,0,false); GameEvents.PlayerCityFounded.Fire(RivalSlot,33,0)
Remove(c); Players[RivalSlot].alive=false; Reconcile(); Check(FlameCount()==2,'script kill with eliminated owner')
Reload(); Check(FlameCount()==2,'no repeat on reload of destruction')
-- Same coordinates, same founded turn, recycled local ID; founding hook proves new lifetime.
Players[RivalSlot].alive=true
c=City(RivalSlot,33,0,false,7); GameEvents.PlayerCityFounded.Fire(RivalSlot,33,0)
local reusedID=c.id
GameEvents.CityRazed.Fire(RivalSlot,33,0); Remove(c)
local replacement=City(RivalSlot,33,0,false,7); replacement.id=reusedID
GameEvents.PlayerCityFounded.Fire(RivalSlot,33,0)
Check(FlameCount()==3,'old lifetime counted before refounding')
Raze(replacement); Check(FlameCount()==4,'new lifetime counts independently')
-- Multiple cities before any turn, reload with pending removals and count cap.
for i=1,4 do
 local d=City(RivalSlot,40+i,0,false); GameEvents.PlayerCityFounded.Fire(RivalSlot,40+i,0)
 GameEvents.CityRazed.Fire(RivalSlot,d.x,d.y); Remove(d)
end
Reload(); Check(FlameCount()==8,'multiple pending destruction reload')
Reconcile(); Check(FlameCount()==8,'duplicates suppressed')
-- Missed acquisition callback: stable plot city beats missing old owner entry.
local d=City(RivalSlot,50,0,false); GameEvents.PlayerCityFounded.Fire(RivalSlot,50,0)
Remove(d); local moved=City(KeeperSlot,50,0,false,d.founded,d.original)
Reconcile(); Check(FlameCount()==8,'unreported transfer surviving city')
Raze(moved); Check(FlameCount()==8,'new Covenant last owner excluded')

-- Exact nine-flame six-Hall example from executed SQL deltas.
a,b,foreign=Basic()
for i=1,4 do City(KeeperSlot,i+1,0,true) end
for i=1,9 do
 local d=City(RivalSlot,60+i,0,false); GameEvents.PlayerCityFounded.Fire(RivalSlot,60+i,0); Raze(d)
end
local totalC,totalS=0,0
for city in Players[KeeperSlot]:Cities() do
 local cY,sY=Expected(city,city==a and 10 or 1,city==a and 5 or 2)
 totalC,totalS=totalC+cY,totalS+sY
end
Check(totalC==15 and totalS==15,'six halls exact 15/15')
for i=201,218 do Check(GameEvents.CityCanConstruct.Fire(KeeperSlot,a.id,i)==false,'cannot construct controller') end
Check(GameEvents.CityCanConstruct.Fire(KeeperSlot,a.id,101),'Hall constructible')
-- Economic timing is intentionally next-payout: no instant yield APIs exist here.

-- Promotion is native Sight plus defense-only conditional. Combat values supplied
-- from executed SQL. Real DLL branch inclusion is separately source-audited.
local function Unit(owner,id,plot,identity)
 local u={owner=owner,id=id,plot=plot,promos={[102]=identity}}
 function u:GetOwner() return self.owner end
 function u:GetID() return self.id end
 function u:GetPlot() return self.plot end
 function u:IsHasPromotion(p) return self.promos[p]==true end
 function u:SetHasPromotion(p,b) self.promos[p]=b end
 Players[owner].units[#Players[owner].units+1]=u; plot.units[#plot.units+1]=u
 return u
end
local p=plots['0,0']; local u=Unit(KeeperSlot,700,p,true)
GameEvents.UnitCreated.Fire(KeeperSlot,700)
Check(u:IsHasPromotion(103),'friendly veteran defense active')
Check(DefenseValue==15 and AttackValue==0,'SQL defense-only 15/0')
local neutral=Plot(90,0,-1); p.units={}; neutral.units={u}; u.plot=neutral
GameEvents.UnitSetXY.Fire(KeeperSlot,700,90,0); Check(not u:IsHasPromotion(103),'neutral no defense')
neutral.owner=RivalSlot; GameEvents.TileOwnershipChanged.Fire(90,0,RivalSlot,-1)
Check(not u:IsHasPromotion(103),'enemy no defense')
neutral.open=true; GameEvents.BattleStarted.Fire(0,90,0)
Check(u:IsHasPromotion(103),'native Open Borders qualifies before strength')
neutral.open=false; GameEvents.BattleStarted.Fire(1,90,0)
Check(not u:IsHasPromotion(103),'diplomacy expiry repaired before ranged/melee defense')
neutral.owner=KeeperSlot
local upgraded=Unit(KeeperSlot,701,neutral,false)
GameEvents.UnitCreated.Fire(KeeperSlot,701)
Check(not upgraded:IsHasPromotion(103),'pre-conversion has no identity')
upgraded.promos[102]=true -- native non-lost promotion transfer
GameEvents.UnitConverted.Fire(KeeperSlot,KeeperSlot,700,701,true)
Check(upgraded:IsHasPromotion(103) and SightValue==1 and LostWithUpgrade==0,'upgrade sight and defense persist once')
Reload(); Check(upgraded:IsHasPromotion(103),'reload veteran reconstruction')
upgraded.promos[102]=false; Turn(); Check(not upgraded:IsHasPromotion(103),'no defense without lineage')

-- Bounded large-world operations: one world iterator pass per NewGameTurn, one
-- owner iterator at PlayerDoTurn; no per-frame handlers or full-map API exists.
for i=0,MajorCount do if i~=KeeperSlot then for n=1,8 do City(i,200+i*10+n,0,false) end end end
Reconcile(); local it=iterations; Turn(RivalSlot)
Check(iterations-it<=3,'owner local recovery rather than full-world enumeration')
local oldWrites=storageWrites; local oldBuild=writes
Reconcile(); Reconcile(); Check(storageWrites==oldWrites and writes==oldBuild,'unchanged state performs no writes')
-- Same global rules support two human Covenant slots without duplicate scans.
Players[MajorCount-1].civ=100; Players[MajorCount-1].human=true; Reload(); Turn()
Check(FlameCount()==9,'second Covenant shares saved global ledger')
-- Lost Flame record remains present while the designated storage player has no cities.
for i=#Players[KeeperSlot].cities,1,-1 do Remove(Players[KeeperSlot].cities[i]) end
Players[KeeperSlot].alive=false
Reload(); Check(FlameCount()==9,'eliminated storage player retains accumulated Flames')
Players[KeeperSlot].alive=true
local reborn=City(KeeperSlot,120,0,true)
GameEvents.PlayerCityFounded.Fire(KeeperSlot,120,0)
Expected(reborn,10,5)
World(false); local beforeIterations=iterations; LoadCovenant()
Check(not MapModData.CWC3_CovenantRegistered and iterations==beforeIterations,'absent Covenant zero processing')
for _,k in ipairs(names) do Check(#GameEvents[k].handlers==0,'no absent-Covenant handlers') end
print('PASS Covenant '..checks..' assertions; '..MajorCount..' majors; human slot '..KeeperSlot..'; Marathon mock; native game acceptance outstanding')
