-- Execute the production controller against hex-map/event doubles (Lua 5.1).
GameInfoTypes={CIVILIZATION_CWC3_HOLLOW_CHOIR=200,BUILDING_CWC3_RESONANCE_HALL=201,
 BUILDING_CWC3_CHOIR_HILL_PRODUCTION=202,BUILDING_CWC3_CHOIR_MOUNTAIN_FAITH_1=203,
 BUILDING_CWC3_CHOIR_MOUNTAIN_FAITH_2=204,BUILDING_CWC3_CHOIR_RESONANCE_SCIENCE_1=205,
 BUILDING_CWC3_CHOIR_RESONANCE_SCIENCE_2=206}
GameDefines={MAX_CIV_PLAYERS=4}
local checks, writes, reads = 0, 0, 0
local function check(value, message) checks=checks+1; assert(value, message) end
local function EventRegistry()
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
 MapModData={}; GameEvents=EventRegistry(); Events=EventRegistry()
end
ResetEvents()
local plots={}
local function Key(x,y) return x..':'..y end
local directions={{1,0},{1,-1},{0,-1},{-1,0},{-1,1},{0,1}}
Map={}
function Map.GetPlot(x,y) reads=reads+1; return plots[Key(x,y)] end
function Map.PlotDirection(x,y,d)
 local delta=directions[d+1]
 return Map.GetPlot(x+delta[1],y+delta[2])
end
function Map.PlotDistance(x,y,a,b)
 local dx,dy=a-x,b-y
 return math.max(math.abs(dx),math.abs(dy),math.abs(dx+dy))
end
for x=-8,14 do for y=-8,8 do
 local p={x=x,y=y,owner=-1,mountain=false,hill=false}
 function p:GetX() return self.x end
 function p:GetY() return self.y end
 function p:GetOwner() return self.owner end
 function p:IsMountain() return self.mountain end
 function p:IsHills() return self.hill end
 function p:GetPlotCity() return self.city end
 plots[Key(x,y)]=p
end end
Players={}
for i=0,3 do
 local p={civ=i==0 and 200 or 0,alive=true,cities={}}
 function p:IsAlive() return self.alive end
 function p:GetCivilizationType() return self.civ end
 function p:Cities() local n=0; return function() n=n+1; return self.cities[n] end end
 function p:GetCityByID(id) for _,c in ipairs(self.cities) do if c.id==id then return c end end end
 Players[i]=p
end
local function City(owner,id,x,y)
 local c={owner=owner,id=id,x=x,y=y,buildings={},free={}}
 function c:GetOwner() return self.owner end
 function c:GetX() return self.x end
 function c:GetY() return self.y end
 function c:GetNumBuilding(b) return math.max(self.buildings[b] or 0,self.free[b] or 0) end
 function c:GetNumRealBuilding(b) return self.buildings[b] or 0 end
 function c:GetNumFreeBuilding(b) return self.free[b] or 0 end
 function c:SetNumRealBuilding(b,n,noBonus)
  assert(n==0 or n==1); assert(noBonus==true)
  self.buildings[b]=n; writes=writes+1
  Events.SerialEventCityInfoDirty.Fire()
 end
 function c:SetNumFreeBuilding(b,n,refund,validate)
  assert(n==0 and refund==false and validate==false)
  self.free[b]=n; writes=writes+1
  Events.SerialEventCityInfoDirty.Fire()
 end
 Players[owner].cities[#Players[owner].cities+1]=c
 plots[Key(x,y)].city=c; plots[Key(x,y)].owner=owner
 return c
end
local function Transfer(c,owner)
 local old=Players[c.owner].cities
 for i,city in ipairs(old) do if city==c then table.remove(old,i); break end end
 c.owner=owner; Players[owner].cities[#Players[owner].cities+1]=c
 plots[Key(c.x,c.y)].owner=owner
end
local function ClearTerrain()
 for _,p in pairs(plots) do p.mountain=false; p.hill=false; p.owner=p.city and p.city.owner or -1 end
end
local function Mountain(x,y,owner)
 local p=plots[Key(x,y)]; p.mountain=true; p.owner=owner or -1; return p
end
local function Yield(c,p,f,s)
 check(c:GetNumRealBuilding(202)==p,'Hill Production')
 check(c:GetNumRealBuilding(203)+c:GetNumRealBuilding(204)==f,'adjacent Faith')
 check(c:GetNumRealBuilding(205)+c:GetNumRealBuilding(206)==s,'Hall Science')
 for b=202,206 do check(c:GetNumFreeBuilding(b)==0,'free dummy leak') end
end
local a=City(0,1,0,0)
local foreign=City(1,2,9,0)
for b=202,206 do foreign.buildings[b]=4; foreign.free[b]=2 end
LoadChoir()
Yield(a,0,0,0); Yield(foreign,0,0,0)
-- Every adjacency count, hills independent, unowned/enemy Mountains count.
for hill=0,1 do for count=0,6 do
 ClearTerrain(); plots['0:0'].hill=hill==1
 for i=1,count do local d=directions[i]; Mountain(d[1],d[2],i%2==0 and 1 or -1) end
 Events.NewGameTurn.Fire()
 Yield(a,hill,math.min(2,count),0)
end end
ClearTerrain(); Mountain(2,0,0); plots['1:0'].hill=true
Events.NewGameTurn.Fire(); Yield(a,0,0,0)
-- Exact Science thresholds, no worked/assigned-city API exists in this fixture.
local sciencePlots={{2,0},{2,-1},{2,-2},{1,-2},{0,-2},{-1,-1}}
for count=0,6 do
 ClearTerrain(); a.buildings[201]=1
 for i=1,count do Mountain(sciencePlots[i][1],sciencePlots[i][2],0) end
 GameEvents.CityConstructed.Fire(0,a.id,201,false,false)
 Yield(a,0,0,math.min(2,math.floor(count/2)))
end
-- Range/ownership, Hall absent, fractional thresholds and purchases.
ClearTerrain(); Mountain(3,0,0); Mountain(4,0,0); Mountain(2,0,1); Mountain(2,-1,-1)
GameEvents.CityConstructed.Fire(0,a.id,201,true,false); Yield(a,0,0,0)
Mountain(0,3,0); GameEvents.CityConstructed.Fire(0,a.id,201,false,true); Yield(a,0,0,1)
local changed=plots['0:3']; changed.owner=1
GameEvents.TileOwnershipChanged.Fire(0,3,1,0); Yield(a,0,0,0)
changed.owner=0; GameEvents.TileOwnershipChanged.Fire(0,3,0,1); Yield(a,0,0,1)
changed.owner=-1; GameEvents.TileOwnershipChanged.Fire(0,3,-1,0); Yield(a,0,0,0)
changed.owner=0
a.buildings[201]=0; Events.SerialEventCityInfoDirty.Fire(); Yield(a,0,0,0)
a.buildings[201]=1; GameEvents.CityConstructed.Fire(0,a.id,201,false,false); Yield(a,0,0,1)
a.buildings[201]=0; GameEvents.CitySoldBuilding.Fire(0,a.id,201); Yield(a,0,0,0)
-- Shared owned Mountains support both cities; foreign/team ownership doesn't.
ClearTerrain(); local b=City(0,3,1,0); a.buildings[201]=1; b.buildings[201]=1
Mountain(1,1,0); Mountain(1,-1,0); Mountain(0,1,0); Mountain(2,-2,0)
GameEvents.PlayerCityFounded.Fire(0,b.x,b.y)
Events.NewGameTurn.Fire(); Yield(a,0,2,2); Yield(b,0,2,2)
-- Acquisition strips all five even if native NeverCapture were bypassed.
Transfer(a,1); GameEvents.CityCaptureComplete.Fire(0,true,0,0,1,5,true)
Yield(a,0,0,0); check(a.buildings[201]==1,'capture must not create/remove Hall itself')
Transfer(a,0); GameEvents.CityCaptureComplete.Fire(1,true,0,0,0,5,false)
Yield(a,0,2,2)
a.buildings[201]=0; Transfer(a,1); GameEvents.CityCaptureComplete.Fire(0,true,0,0,1,5,false)
Transfer(a,0); GameEvents.PlayerLiberated.Fire(1,0,a.id)
Yield(a,0,2,0); check(a:GetNumBuilding(201)==0,'no free Hall on liberation')
-- Missed ownership callback: coordinates resolve the actual current city owner.
Transfer(a,1); Events.SerialEventCityInfoDirty.Fire(); Yield(a,0,0,0)
Transfer(a,0); GameEvents.PlayerDoTurn.Fire(0); Yield(a,0,2,0)
-- Razing/deletion safely forgets coordinates; new city later at same coordinates.
plots['0:0'].city=nil
for i=#Players[0].cities,1,-1 do if Players[0].cities[i]==a then table.remove(Players[0].cities,i) end end
Events.SerialEventCityInfoDirty.Fire()
local replacement=City(0,99,0,0)
GameEvents.PlayerCityFounded.Fire(0,0,0); Yield(replacement,0,2,0)
-- Reload repairs corrupted real/free state from current terrain, not a ledger.
plots['0:0'].hill=true; replacement.buildings[201]=1
for dummy=202,206 do replacement.buildings[dummy]=7; replacement.free[dummy]=3 end
ResetEvents(); LoadChoir(); Yield(replacement,1,2,2)
local registrations=#GameEvents.PlayerDoTurn.handlers
LoadChoir(); check(#GameEvents.PlayerDoTurn.handlers==registrations,'duplicate registrations')
local before=writes
for turn=1,30 do
 Events.NewGameTurn.Fire(); GameEvents.PlayerDoTurn.Fire(0); Events.ActivePlayerTurnStart.Fire()
end
check(writes==before,'repeated reconciliation must not write or accumulate')
for dummy=202,206 do check(GameEvents.CityCanConstruct.Fire(0,99,dummy)==false,'dummy build blocked') end
check(GameEvents.CityCanConstruct.Fire(0,99,201),'Hall can be constructed')
-- Border and wrapping simulations: nil neighbors and duplicate directions safe.
local normal=Map.PlotDirection
Map.PlotDirection=function(x,y,d) if d==0 then return nil end; return normal(x,y,d) end
Events.NewGameTurn.Fire(); check(true,'edge traversal survives nil plots')
Map.PlotDirection=function(x,y,d) return normal(x,y,d%3) end
Events.NewGameTurn.Fire()
check(replacement:GetNumRealBuilding(203)+replacement:GetNumRealBuilding(204)<=2,'duplicate neighbors bounded')
Map.PlotDirection=normal
-- Two simultaneous Choir players, including a later sequential slot.
Players[2].civ=200
local later=City(2,4,6,0); plots['6:0'].hill=true
Mountain(7,0,-1); Mountain(6,1,1)
GameEvents.PlayerCityFounded.Fire(2,6,0); Yield(later,1,2,0)
later.buildings[201]=1; Mountain(8,0,2); Mountain(8,-1,2)
GameEvents.CityConstructed.Fire(2,4,201,false,false); Yield(later,1,2,1)
local start=reads; GameEvents.PlayerDoTurn.Fire(2)
check(reads-start<1500,'bounded city-local plot work')
-- No game-speed scaling or random API is available to the production controller.
Game={GetGameSpeedType=function() return 'GAMESPEED_MARATHON' end}
Events.NewGameTurn.Fire(); Yield(later,1,2,1)
print('PASS Hollow Choir: '..checks..' assertions covering terrain matrix, shared radii, ownership/building changes, capture/gift/liberation, founding/raze, reload/free cleanup, repeated turns, later owners and speed-independent yields')
