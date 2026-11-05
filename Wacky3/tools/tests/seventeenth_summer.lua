-- Executes production gameplay; event order follows pinned CP151 invocation sites.
GameInfoTypes={CIVILIZATION_CWC3_SEVENTEENTH_SUMMER=100,UNIT_CWC3_SHELLGUARD=101,
 BUILDING_CWC3_BROOD_NURSERY=102,PROMOTION_SUMMER_BROOD_LINEAGE=103,PROMOTION_SUMMER_AWAKENED=104,
 BUILDING_SUMMER_DORMANT_FOOD=105,BUILDING_SUMMER_EMERGENCE_PRODUCTION=106,
 BUILDING_SUMMER_EMERGENCE_CULTURE=107,BUILDING_SUMMER_NURSERY_PRODUCTION=108}
GameInfo={GameSpeeds={[0]={Type='GAMESPEED_'..Speed}}}
GameInfo.CWC3_SummerCycles=function()
 local done=false
 return function()
  if done then return end
  done=true
  return {GameSpeedType='GAMESPEED_'..Speed,Dormancy=Dormant,Emergence=Emerged}
 end
end
GameDefines={MAX_CIV_PLAYERS=4}
NotificationTypes={NOTIFICATION_GENERIC=1}
Locale={ConvertTextKey=function(s) return s end}
local turn,checks,writes,notes=0,0,0,0
local function check(v,m) checks=checks+1; assert(v,m) end
Game={GetGameSpeedType=function() return 0 end,GetGameTurn=function() return turn end}
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
local function ResetEvents() MapModData={}; GameEvents=Registry(); Events=Registry() end
ResetEvents()
local plots={}
Map={GetPlot=function(x,y) return plots[x..':'..y] end}
Players={}
for i=0,3 do
 local p={cities={},units={},civ=i==2 and 100 or 0,human=i~=3,alive=true,data='unrelated:keep'}
 function p:IsAlive() return self.alive end
 function p:IsHuman() return self.human end
 function p:GetCivilizationType() return self.civ end
 function p:GetScriptData() return self.data end
 function p:SetScriptData(d) self.data=d end
 function p:Cities() local n=0; return function() n=n+1; return self.cities[n] end end
 function p:Units() local key; return function() key=next(self.units,key); return key and self.units[key] end end
 function p:GetCityByID(id) for _,c in ipairs(self.cities) do if c.id==id then return c end end end
 function p:GetUnitByID(id) return self.units[id] end
 function p:AddNotification(...) notes=notes+1 end
 Players[i]=p
end
local function City(owner,id,x)
 local c={owner=owner,id=id,x=x,real={},free={}}
 function c:GetOwner() return self.owner end
 function c:GetX() return self.x end
 function c:GetY() return 0 end
 function c:GetNumBuilding(b) return math.max(self.real[b] or 0,self.free[b] or 0) end
 function c:GetNumRealBuilding(b) return self.real[b] or 0 end
 function c:GetNumFreeBuilding(b) return self.free[b] or 0 end
 function c:SetNumRealBuilding(b,n,noBonus)
  check((n==0 or n==1) and noBonus==true,'absolute real counts/no rewards')
  self.real[b]=n; writes=writes+1; Events.SerialEventCityInfoDirty.Fire()
 end
 function c:SetNumFreeBuilding(b,n,refund,validate)
  check(n==0 and refund==false and validate==false,'clear free copies without rewards')
  self.free[b]=n; writes=writes+1; Events.SerialEventCityInfoDirty.Fire()
 end
 Players[owner].cities[#Players[owner].cities+1]=c
 plots[x..':0']={GetPlotCity=function() return c end}
 return c
end
local function Transfer(c,owner)
 local old=c.owner
 for i,item in ipairs(Players[old].cities) do if item==c then table.remove(Players[old].cities,i); break end end
 c.owner=owner; Players[owner].cities[#Players[owner].cities+1]=c
 GameEvents.CityCaptureComplete.Fire(old,false,c.x,0,owner,5,false)
end
local function Unit(owner,id,kind)
 local u={owner=owner,id=id,kind=kind or 101,promos={}}
 function u:GetUnitType() return self.kind end
 function u:GetID() return self.id end
 function u:IsHasPromotion(b) return self.promos[b]==true end
 function u:SetHasPromotion(b,value) self.promos[b]=value; writes=writes+1 end
 if u.kind==101 then u.promos[103]=true end -- native free promotion before UnitCreated
 Players[owner].units[id]=u
 GameEvents.UnitCreated.Fire(owner,id,u.kind,0,0)
 return u
end
local function Converted(old,owner,id,kind,upgrade)
 local new=Unit(owner,id,kind)
 GameEvents.UnitUpgraded.Fire(old.owner,old.id,id,false) -- before conversion; deliberately no handler
 for p,v in pairs(old.promos) do
  if p~=104 then new.promos[p]=v end -- LostWithUpgrade=1 on Awakened
 end
 new.promos[104]=nil
 GameEvents.UnitConverted.Fire(old.owner,owner,old.id,id,upgrade)
 Players[old.owner].units[old.id]=nil
 return new
end
local function Yield(c,phase,eligible)
 check(c:GetNumRealBuilding(105)==(eligible and phase==0 and 1 or 0),'Dormant Food')
 check(c:GetNumRealBuilding(106)==(eligible and phase==1 and 1 or 0),'Emergence Production')
 check(c:GetNumRealBuilding(107)==(eligible and phase==1 and 1 or 0),'Emergence Culture')
 check(c:GetNumRealBuilding(108)==(eligible and phase==1 and c:GetNumBuilding(102)>0 and 1 or 0),'Nursery Production')
 for b=105,108 do check(c:GetNumFreeBuilding(b)==0,'foreign/free leak') end
end
local function Record()
 local n,p,last=Players[2].data:match('%[CWC3_SUMMER:(%d+):([01]):(%-?%d+)%]')
 return tonumber(n),tonumber(p),tonumber(last)
end
local function Reload()
 local data,n=Players[2].data,notes
 ResetEvents(); LoadSummer()
 check(Players[2].data==data and notes==n,'load must neither progress nor notify')
end
local a=City(2,1,1); a.real[102]=1
local foreign=City(0,2,2)
for b=105,108 do foreign.real[b]=3; foreign.free[b]=2 end
local shell=Unit(2,1)
local ordinary=Unit(2,2,999)
local leaked=Unit(0,3,999); leaked.promos[104]=true
LoadSummer()
Yield(a,0,true); Yield(foreign,0,false)
check(shell:IsHasPromotion(103) and not shell:IsHasPromotion(104),'initial lineage, no Awakened')
check(not leaked:IsHasPromotion(104),'bootstrap foreign promotion cleanup')
check(Record()==nil,'bootstrap does not count as owner-turn')
local initialWrites=writes; LoadSummer(); check(writes==initialWrites,'duplicate context inert')
-- Another player's turn and UI notifications never advance this owner.
GameEvents.PlayerDoTurn.Fire(0); Events.NewGameTurn.Fire(); Events.ActivePlayerTurnStart.Fire()
check(Record()==nil,'other callbacks cannot advance owner')
local total=Dormant+Emerged
local expectedNotes=0
for count=1,total*3 do
 turn=count-1 -- game turn zero is valid; owner slot 2 with earlier living players
 if count==Dormant or count==Dormant+1 or count==total or count==total+1 then Reload() end
 local previousPhase=count>1 and ((count-2)%total>=Dormant and 1 or 0) or 0
 local phase=(count-1)%total>=Dormant and 1 or 0
 -- Simulated collection sees the prior phase; PlayerDoTurn schedules NEXT payout.
 Yield(a,previousPhase,true)
 GameEvents.PlayerDoTurn.Fire(2)
 if phase~=previousPhase then expectedNotes=expectedNotes+1 end
 local n,p,last=Record()
 check(n==count and p==phase and last==turn,'owner count, phase, last turn persist')
 check(notes==expectedNotes,'exactly one notification per transition')
 Yield(a,phase,true)
 check(shell:IsHasPromotion(104)==(phase==1),'phase combat coherence')
 check(not ordinary:IsHasPromotion(103) and not ordinary:IsHasPromotion(104),'ordinary unit never gains ancestry')
 local data=Players[2].data
 GameEvents.PlayerDoTurn.Fire(2); GameEvents.PlayerDoTurn.Fire(2)
 check(Players[2].data==data and notes==expectedNotes,'repeated callbacks cannot advance/notify')
 check(data:find('unrelated:keep',1,true)~=nil,'preserve other ScriptData')
 if count==Dormant+1 or count==total+1 then
  Reload(); GameEvents.PlayerDoTurn.Fire(2)
  check(Players[2].data==data and notes==expectedNotes,'reload on transition is idempotent')
  local b=City(2,10+count,10+count); GameEvents.PlayerCityFounded.Fire(2,b.x,0)
  Yield(b,phase,true)
  b.real[102]=1; GameEvents.CityConstructed.Fire(2,b.id,102,false,false); Yield(b,phase,true)
  b.real[102]=nil; Events.SerialEventCityInfoDirty.Fire(); Yield(b,phase,true)
  b.free[102]=1; GameEvents.CityConstructed.Fire(2,b.id,102,true,false); Yield(b,phase,true)
  b.free[102]=nil; GameEvents.CitySoldBuilding.Fire(2,b.id,102); Yield(b,phase,true)
  Transfer(b,0); Yield(b,0,false); Transfer(b,2); Yield(b,phase,true)
  -- Corruption recovery, with reentrant city-info callbacks from every write.
  a.real[105]=9; a.free[106]=5; Reload(); Yield(a,phase,true)
 end
 if count==Dormant+1 then
  local created=Unit(2,30); check(created:IsHasPromotion(104),'new Shellguard immediately awakened')
  shell=Converted(shell,2,31,998,true)
  check(shell:IsHasPromotion(103) and shell:IsHasPromotion(104),'first upgrade after native transfer')
  shell=Converted(shell,2,32,997,true)
  check(shell:IsHasPromotion(103) and shell:IsHasPromotion(104),'second upgrade preserves lineage')
  ordinary=Converted(ordinary,2,33,997,true)
  check(not ordinary:IsHasPromotion(103) and not ordinary:IsHasPromotion(104),'same upgrade target does not imply lineage')
  local gift=Converted(created,0,34,101,false)
  check(gift:IsHasPromotion(103) and not gift:IsHasPromotion(104),'gift loses temporary combat bonus')
  gift=Converted(gift,2,35,101,false)
  check(gift:IsHasPromotion(103) and gift:IsHasPromotion(104),'returned brood reconciles immediately')
 end
end
-- Reverse/stale event identifiers never progress a saved cycle.
local data=Players[2].data; turn=turn-1; GameEvents.PlayerDoTurn.Fire(2)
check(Players[2].data==data,'stale callback rejected')
-- Explicitly unsupported AI ownership gets neither UA nor temporary combat.
Players[3].civ=100
local ai=City(3,90,90); local aiUnit=Unit(3,91)
GameEvents.PlayerDoTurn.Fire(3); Yield(ai,0,false)
check(not aiUnit:IsHasPromotion(104),'AI cannot receive Emergence')
for b=105,108 do check(not GameEvents.CityCanConstruct.Fire(2,1,b),'controllers never constructible') end
check(GameEvents.CityCanConstruct.Fire(2,1,102),'Nursery remains constructible')
print('PASS Summer '..Speed..': '..checks..' assertions; cycles, next-payout order, reloads, transfers, Nurseries, creation, multi-upgrades and foreign cleanup')
