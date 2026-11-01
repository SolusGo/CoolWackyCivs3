-- Lightweight engine doubles. Event tests execute the production gameplay file.
GameInfoTypes = {
 CIVILIZATION_CWC3_ALMOST=100,BUILDING_CWC3_RUNNER_UP_ACADEMY=101,
 BUILDING_CWC3_ALMOST_SCIENCE_1=102,BUILDING_CWC3_ALMOST_SCIENCE_2=103,
 BUILDING_CWC3_ALMOST_CULTURE=104,BUILDING_CWC3_ALMOST_ACADEMY_PRODUCTION=105,
 PROMOTION_CWC3_SECOND_WIND=106,PROMOTION_CWC3_HOME_DEFENSE=107}
GameDefines={MAX_MAJOR_CIVS=25,MAX_CIV_PLAYERS=40}
Turn=1; TechReads=0; BuildingWrites=0
Game={GetGameTurn=function() return Turn end}
GameInfo={Technologies=function()
 local n=-1; return function() n=n+1; if n<40 then return {ID=n} end end
end}
Players={}; Teams={}; Plots={}
for i=0,39 do
 Teams[i]={known=0,IsHasTech=function(self,tech) TechReads=TechReads+1; return tech<self.known end}
 local p={id=i,team=i,alive=i<3,civ=i==0 and 100 or 0,human=i==0,minor=i==25,barbarian=i==39,
          data='other-mod=preserved;',cities={},units={},active=i==0}
 function p:IsAlive() return self.alive end
 function p:IsHuman() return self.human end
 function p:IsMinorCiv() return self.minor end
 function p:IsBarbarian() return self.barbarian end
 function p:IsTurnActive() return self.active end
 function p:GetCivilizationType() return self.civ end
 function p:GetTeam() return self.team end
 function p:GetScriptData() return self.data end
 function p:SetScriptData(data) self.data=data end
 function p:Cities() local i=0; return function() i=i+1; return self.cities[i] end end
 function p:Units() local i=0; return function() i=i+1; return self.units[i] end end
 function p:GetCityByID(id) for _,c in ipairs(self.cities) do if c.id==id then return c end end end
 function p:GetUnitByID(id) for _,u in ipairs(self.units) do if u.id==id then return u end end end
 Players[i]=p
end
Players[2].team=0
Players[3].alive=false; Teams[3].known=40
Players[25].alive=true; Teams[25].known=40
Players[39].alive=true; Teams[39].known=40
Map={GetPlot=function(x,y) return Plots[x..','..y] end}
function MakePlot(x,y,owner)
 local p={x=x,y=y,owner=owner,units={}}
 function p:GetOwner() return self.owner end
 function p:GetPlotCity() return self.city end
 function p:GetNumUnits() return #self.units end
 function p:GetUnit(i) return self.units[i+1] end
 Plots[x..','..y]=p; return p
end
function MakeCity(owner,id,academy)
 local c={owner=owner,id=id,buildings={[101]=academy and 1 or 0}}
 function c:GetOwner() return self.owner end
 function c:GetNumRealBuilding(b) return self.buildings[b] or 0 end
 function c:GetNumBuilding(b) return self.buildings[b] or 0 end
 function c:SetNumRealBuilding(b,n)
  assert(n==0 or n==1,'unbounded count'); self.buildings[b]=n; BuildingWrites=BuildingWrites+1
 end
 Players[owner].cities[#Players[owner].cities+1]=c
 local plot=MakePlot(id,0,owner); plot.city=c
 return c
end
function Transfer(city,owner)
 local old=Players[city.owner]
 for i,c in ipairs(old.cities) do if c==city then table.remove(old.cities,i); break end end
 city.owner=owner; Players[owner].cities[#Players[owner].cities+1]=city
 Plots[city.id..',0'].owner=owner
end
function MakeUnit(owner,id,plot,identity,defense)
 local u={owner=owner,id=id,plot=plot,promos={[106]=identity or false,[107]=defense or false}}
 function u:GetOwner() return self.owner end
 function u:GetPlot() return self.plot end
 function u:IsHasPromotion(p) return self.promos[p] or false end
 function u:SetHasPromotion(p,value) self.promos[p]=value end
 Players[owner].units[#Players[owner].units+1]=u; plot.units[#plot.units+1]=u
 return u
end
function ResetEvents()
 MapModData={}
 local function registry()
  return setmetatable({}, {__index=function(self,key)
   local event={handlers={}}
   function event.Add(handler) event.handlers[#event.handlers+1]=handler end
   function event.Fire(...) local result=true
    for _,handler in ipairs(event.handlers) do if handler(...)==false then result=false end end
    return result
   end
   rawset(self,key,event); return event
  end})
 end
 GameEvents=registry(); Events=registry()
end
ResetEvents()
Cities={MakeCity(0,0,true),MakeCity(0,1,false),MakeCity(0,2,true),MakeCity(0,3,true)}
Teams[0].known=10; Teams[1].known=12

function CheckCity(c,s,culture,production)
 assert(c:GetNumRealBuilding(102)+c:GetNumRealBuilding(103)==s,'Science mismatch')
 assert(c:GetNumRealBuilding(104)==culture,'Culture mismatch')
 assert(c:GetNumRealBuilding(105)==production,'Production mismatch')
end
