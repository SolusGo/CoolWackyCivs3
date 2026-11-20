-- Gameplay sources run unchanged against a small model of CP151 Lua bindings.
local function event()
    local callbacks = {}
    return {Add=function(callback) callbacks[#callbacks+1]=callback end,
        fire=function(...) for _,callback in ipairs(callbacks) do callback(...) end end}
end
local function events()
    return setmetatable({}, {__index=function(t,k) local v=event(); rawset(t,k,v); return v end})
end
GameEvents, Events = events(), events()
local includes = {}
function include(name)
    if not includes[name] then includes[name]=true; LoadShared(name) end
end
function GameInfoIterator(rows)
    return coroutine.wrap(function() for _, row in ipairs(rows) do coroutine.yield(row) end end)
end
GameInfo = {Buildings=function() return GameInfoIterator(BuildingRows) end}
GameDefines = {MAX_CIV_PLAYERS=34, MAX_MAJOR_CIVS=34, MIN_WATER_SIZE_FOR_OCEAN=10, MOVE_DENOMINATOR=60}
DomainTypes = {DOMAIN_LAND=0, DOMAIN_SEA=1, DOMAIN_AIR=2}
Mouse = {eLClick=1}
ContextPtr = {SetHide=function() end}
Controls = setmetatable({}, {__index=function(t,k)
    local item = {
        SetText=function(self,text) self.text=text end,
        SetDisabled=function(self,value) self.disabled=value end,
        RegisterCallback=function(self,_,fn) self.click=fn end,
    }
    t[k]=item
    return item
end})
local turn, era, atWar, active = 0, 0, true, 0
Game = {GetGameTurn=function() return turn end, GetActivePlayer=function() return active end,
    GetGameSpeedType=function() return GameInfoTypes['GAMESPEED_'..Speed] end}
Teams = {[0]={IsAtWar=function() return atWar end,GetCurrentEra=function() return era end},
         [1]={IsAtWar=function() return atWar end}}
local playerMethods = {
    GetCivilizationType=function(self) return self.civ end,
    GetID=function(self) return self.id end,
    IsAlive=function() return true end,
    IsHuman=function(self) return self.id==0 end,
    IsTurnActive=function(self) return self.id==active end,
    IsMinorCiv=function(self) return self.id>=4 end,
    IsBarbarian=function() return false end,
    GetTeam=function(self) return self.id end,
    GetCurrentEra=function() return era end,
    GetCapitalCity=function(self) return self.cities[1] end,
    Cities=function(self) return GameInfoIterator(self.cities) end,
    Units=function(self) return GameInfoIterator(self.units) end,
    GetCityByID=function(self,id) for _,c in ipairs(self.cities) do if c.id==id then return c end end end,
    GetUnitByID=function(self,id) return self.units[id] end,
    GetScriptData=function(self) return self.saved end,
    SetScriptData=function(self,value) self.saved=value end,
}
Players = {}
for i=0,33 do Players[i]=setmetatable({id=i,civ=-1,cities={},units={},saved='[Others:17]'}, {__index=playerMethods}) end
local owner = Players[0]
local function id(kind, suffix)
    return assert(GameInfoTypes[kind..'_CWC3_D'..string.format('%03d', DailyNumber)..(suffix and '_'..suffix or '')])
end
local plotMethods = {
    GetX=function(self) return self.x end,
    GetY=function(self) return self.y end,
    GetPlotIndex=function(self) return self.index end,
    GetPlotCity=function(self) return self.city end,
    GetTerrainType=function(self) return self.terrain end,
    GetFeatureType=function(self) return self.feature end,
    GetOwner=function(self) return self.owner end,
    GetCityPurchaseID=function(self) return self.purchase end,
    GetResourceType=function(self) return self.resource end,
    GetImprovementType=function(self) return self.improvement end,
    IsImprovementPillaged=function(self) return self.pillaged end,
    IsFriendlyTerritory=function(self,p) return self.owner==p or self.openBorders end,
    IsWater=function(self) return self.water end,
    IsLake=function(self) return self.lake end,
    IsHills=function(self) return self.hills end,
    IsImpassable=function(self) return self.blocked end,
    IsRevealed=function(self) return self.revealed end,
    GetNumUnits=function(self) return #self.units end,
    GetUnit=function(self,i) return self.units[i+1] end,
}
local plots, byIndex = {}, {}
Map = {GetPlot=function(x,y) return plots[x..':'..y] end,
    GetNumPlots=function() return #byIndex end, GetPlotByIndex=function(i) return byIndex[i+1] end}
function Map.PlotXYWithRangeCheck(x,y,dx,dy,range)
    if math.max(math.abs(dx),math.abs(dy),math.abs(dx+dy)) <= range then return Map.GetPlot(x+dx,y+dy) end
end
local directions = {{1,0},{0,1},{-1,1},{-1,0},{0,-1},{1,-1}}
function Map.PlotDirection(x,y,i)
    return Map.GetPlot(x+directions[i+1][1],y+directions[i+1][2])
end
local function plot(x,y,attributes)
    local p = {x=x,y=y,index=#byIndex,owner=-1,terrain=-1,resource=-1,improvement=-1,feature=-1,units={},
        water=false,lake=false,hills=false,blocked=false,pillaged=false,revealed=false,openBorders=false}
    for k,v in pairs(attributes or {}) do p[k]=v end
    setmetatable(p,{__index=plotMethods})
    plots[x..':'..y]=p
    byIndex[#byIndex+1]=p
    return p
end
local cityMethods = {
    GetX=function(self) return self.plot.x end,
    GetY=function(self) return self.plot.y end,
    GetID=function(self) return self.id end,
    GetOwner=function(self) return self.owner end,
    Plot=function(self) return self.plot end,
    IsCapital=function(self) return self.id==1 end,
    IsCoastal=function(self, area) assert(area==10); return self.coast end,
    GetNumCityPlots=function(self) return #self.plots end,
    GetCityIndexPlot=function(self,i) return self.plots[i+1] end,
    IsWorkingPlot=function(self,p) return self.work[p.index] or false end,
    GetNumRealBuilding=function(self,key) return self.buildings[key] or 0 end,
    SetNumRealBuilding=function(self,key,count,suppress) assert(suppress); self.buildings[key]=count end,
    GetNumFreeBuilding=function(self,key) return self.free[key] or 0 end,
    SetNumFreeBuilding=function(self,key,count) self.free[key]=count end,
    GetNumBuilding=function(self,key) return self:GetNumRealBuilding(key)+self:GetNumFreeBuilding(key) end,
    GetWeLoveTheKingDayCounter=function(self) return self.celebration end,
    GetGarrisonedUnit=function(self) return self.garrison end,
}
local function city(n)
    local center = plot(10*n,0,{owner=0,purchase=n})
    local c = setmetatable({id=n,owner=0,plot=center,coast=false,celebration=0,
        plots={center},work={},buildings={},free={}}, {__index=cityMethods})
    center.city=c
    owner.cities[#owner.cities+1]=c
    return c
end
local unitMethods = {
    GetOwner=function(self) return self.owner end,
    GetID=function(self) return self.id end,
    GetTeam=function(self) return self.owner end,
    Plot=function(self) return self.plot end,
    GetX=function(self) return self.plot.x end,
    GetY=function(self) return self.plot.y end,
    IsCombatUnit=function(self) return self.combat end,
    IsDead=function(self) return self.dead end,
    IsDelayedDeath=function(self) return self.delayed end,
    IsEmbarked=function(self) return self.embarked end,
    IsGarrisoned=function(self) return self.plot.city and self.plot.city.garrison==self end,
    GetDomainType=function(self) return self.domain end,
    GetUnitType=function(self) return self.kind end,
    GetGameTurnCreated=function(self) return self.created end,
    IsHasPromotion=function(self,p) return self.promos[p] or false end,
    SetHasPromotion=function(self,p,value) self.promos[p]=value end,
    GetScriptData=function(self) return self.saved end,
    SetScriptData=function(self,value) self.saved=value end,
    MaxMoves=function(self) return 180+(self.bonus and self.promos[self.bonus] and 60 or 0) end,
    GetMoves=function(self) return self.moves end,
    SetMoves=function(self,value) self.moves=value end,
}
local function unit(player, p, lineage)
    local list = Players[player].units
    local u = setmetatable({id=#list+1,owner=player,plot=p,domain=DomainTypes.DOMAIN_LAND,combat=true,created=turn,
        kind=id('UNIT'),promos={},dead=false,delayed=false,embarked=false,moves=180,saved='…'}, {__index=unitMethods})
    if lineage then u.promos[id('PROMOTION','LINEAGE')]=true end
    list[u.id]=u
    p.units[#p.units+1]=u
    return u
end
local function move(u,p)
    for i,v in ipairs(u.plot.units) do if v==u then table.remove(u.plot.units,i); break end end
    u.plot=p
    p.units[#p.units+1]=u
    GameEvents.UnitSetXY.fire(u.owner,u.id,p.x,p.y)
end
local function nextTurn()
    turn=turn+1
    GameEvents.PlayerDoTurn.fire(0)
end
local function expect(c,suffix,count)
    assert(c:GetNumBuilding(id('BUILDING',suffix))==count, DailyNumber..' '..suffix..' expected '..count)
end
local function changed()
    Events.SerialEventCityInfoDirty.fire()
end
local function add(c, plot, worked)
    c.plots[#c.plots+1]=plot
    c.work[plot.index]=worked
    return plot
end
local cases = {}
cases[21]=function(c)
    local u=unit(0,c.plot,true)
    c.coast=true
    LoadDaily(21)
    expect(c,'COAST',1); expect(c,'HARBOR',0)
    c.free[GameInfoTypes.BUILDING_HARBOR]=1
    changed()
    expect(c,'HARBOR',1)
    assert(u:IsHasPromotion(id('PROMOTION','DEFEND')))
    local border=plot(5,0)
    move(u,border)
    assert(not u:IsHasPromotion(id('PROMOTION','DEFEND')))
    border.openBorders=true
    GameEvents.BattleStarted.fire(0,5,0)
    assert(u:IsHasPromotion(id('PROMOTION','DEFEND')))
    c.coast=false
    changed()
    expect(c,'COAST',0); expect(c,'HARBOR',0)
end
cases[22]=function(c)
    local guard=unit(0,c.plot,true)
    local enemy=unit(1,plot(9,0),false)
    c.buildings[id('BUILDING')]=1
    LoadDaily(22)
    local function fight(a,d,kill,kind,complete)
        GameEvents.BattleStarted.fire(kind,d.plot.x,d.plot.y)
        local args={a.owner,a.id,12,12,100,d.owner,d.id,20,kill and 100 or 20,100,-1,-1,0,d.plot.x,d.plot.y}
        GameEvents.CombatResult.fire(unpack(args))
        if complete then
            d.dead=kill
            GameEvents.CombatEnded.fire(unpack(args))
            GameEvents.CombatEnded.fire(unpack(args))
        end
    end
    fight(enemy,guard,false,1,true)
    assert(not guard:IsHasPromotion(id('PROMOTION','COUNTER')))
    fight(enemy,guard,false,0,true)
    assert(guard:IsHasPromotion(id('PROMOTION','COUNTER')))
    fight(guard,enemy,false,0,true)
    assert(not guard:IsHasPromotion(id('PROMOTION','COUNTER')))
    fight(enemy,guard,false,0,true)
    nextTurn()
    assert(guard:IsHasPromotion(id('PROMOTION','COUNTER')))
    GameEvents.PlayerDoneTurn.fire(0)
    assert(not guard:IsHasPromotion(id('PROMOTION','COUNTER')))
    for _=1,6 do fight(enemy,unit(0,c.plot,false),true,1,true) end
    expect(c,'CHAMBER',1)
    assert(Controls.Lessons.text=='Lessons: 5 / 5')
    Controls.Doctrine.click()
    assert(guard:IsHasPromotion(id('PROMOTION','DOCTRINE')))
    Controls.Doctrine.click()
    assert(Controls.Lessons.text=='Lessons: 3 / 5')
    Controls.Method.click()
    expect(c,'CHAMBER',0); expect(c,'METHOD',1)
    for i=1,5 do
        nextTurn()
        assert(guard:IsHasPromotion(id('PROMOTION','DOCTRINE'))==(i<3))
        expect(c,'METHOD',i<5 and 1 or 0)
    end
    assert(owner.saved:find('[Others:17]',1,true))
end
cases[23]=function(c)
    c.plot.terrain=GameInfoTypes.TERRAIN_PLAINS
    c.plot.hills=true
    c.buildings[id('BUILDING')]=1
    LoadDaily(23)
    expect(c,'OPEN',1); expect(c,'PAVILION',1)
    for i=1,3 do
        plot(c.plot.x+directions[i][1], directions[i][2], {terrain=GameInfoTypes.TERRAIN_GRASS,hills=true})
        changed()
        expect(c,'RING',i>=3 and 1 or 0)
    end
end
cases[24]=function(c)
    local u=unit(0,c.plot,false)
    u.bonus=id('PROMOTION','DEPOT')
    LoadDaily(24)
    expect(c,'MAIL',0)
    for n=1,7 do
        local here=n==1 and c or city(n)
        here.buildings[id('BUILDING')]=1
        GameEvents.CityConstructed.fire(0,n,id('BUILDING'))
        expect(c,'MAIL',1)
        expect(c,'CULTURE_1',n>=3 and 1 or 0)
        expect(c,'CULTURE_2',n>=6 and 1 or 0)
    end
    nextTurn()
    assert(u:GetMoves()==240)
    GameEvents.PlayerDoTurn.fire(0)
    assert(u:GetMoves()==240)
    move(u,plot(8,0))
    assert(u:GetMoves()==180 and not u:IsHasPromotion(u.bonus))
    move(u,c.plot)
    assert(u:GetMoves()==180)
end
cases[25]=function(c)
    c.coast=true
    c.buildings[id('BUILDING')]=1
    local u=unit(0,c.plot,true)
    LoadDaily(25)
    expect(c,'COAST',1); expect(c,'WALL',1); expect(c,'BASTION',1)
    assert(not u:IsHasPromotion(id('PROMOTION','DEFEND')))
    plot(11,0,{water=true})
    GameEvents.BattleStarted.fire(1,10,0)
    assert(u:IsHasPromotion(id('PROMOTION','DEFEND')))
    c.plot.blocked=true
    GameEvents.BattleStarted.fire(0,10,0)
    assert(not u:IsHasPromotion(id('PROMOTION','DEFEND')))
end
cases[26]=function(c)
    local inkguard=unit(0,c.plot,true)
    c.buildings[id('BUILDING')]=1
    LoadDaily(26)
    expect(c,'PROSPERITY',0); expect(c,'ENLIGHTENMENT',0)
    Controls.Prosperity.click()
    expect(c,'PROSPERITY',1); expect(c,'CHAMBER_GOLD',1)
    Controls.Enlightenment.click()
    expect(c,'ENLIGHTENMENT',0)
    era=1
    GameEvents.TeamSetEra.fire(0,era,true)
    expect(c,'PROSPERITY',0); expect(c,'CHAMBER_GOLD',0)
    Controls.Enlightenment.click()
    expect(c,'ENLIGHTENMENT',1); expect(c,'CHAMBER_SCIENCE',1)
    nextTurn()
    expect(c,'ENLIGHTENMENT',1); expect(c,'CHAMBER_SCIENCE',1)
    era=2
    GameEvents.TeamSetEra.fire(0,era,true)
    Controls.Defence.click()
    assert(inkguard:IsHasPromotion(id('PROMOTION','RESOLUTION')))
    local civilian=unit(0,c.plot,false)
    civilian.combat=false
    GameEvents.UnitCreated.fire(0,civilian.id)
    assert(not civilian:IsHasPromotion(id('PROMOTION','RESOLUTION')))
    expect(c,'PROSPERITY',0); expect(c,'ENLIGHTENMENT',0)
    assert(owner.saved:find('[CWC3_D026_V1:2:3]',1,true))
end
cases[27]=function(c)
    local fen=unit(0,c.plot,true)
    c.buildings[id('BUILDING')]=1
    LoadDaily(27)
    local marsh=GameInfoTypes.FEATURE_MARSH
    expect(c,'SCIENCE_1',0); expect(c,'MIST',0)
    for i=1,5 do
        local offset=directions[i]
        add(c,plot(c.plot.x+offset[1],offset[2],{feature=marsh,owner=0,purchase=1}),true)
        changed()
        expect(c,'RESEARCH',i>=4 and 1 or 0)
        expect(c,'FOOD',i>=2 and 1 or 0)
        expect(c,'MIST',i>=2 and 1 or 0)
        for j=1,4 do expect(c,'SCIENCE_'..j,i>=j and 1 or 0) end
    end
    c.plots[2].pillaged=true; c.plots[3].pillaged=true
    GameEvents.TileImprovementChanged.fire()
    expect(c,'SCIENCE_3',1); expect(c,'SCIENCE_4',0); expect(c,'RESEARCH',1)
    assert(fen:IsHasPromotion(id('PROMOTION','MIST')))
end
cases[28]=function(c)
    LoadDaily(28)
    expect(c,'NO_DEBT',0)
    c.buildings[id('BUILDING')]=1
    GameEvents.CityConstructed.fire(0,1,id('BUILDING'))
    expect(c,'NO_DEBT',1)
    c.buildings[id('BUILDING')]=0
    GameEvents.CitySoldBuilding.fire(0,1,id('BUILDING'))
    expect(c,'NO_DEBT',0)
end
cases[29]=function(c)
    local tundra,snow=GameInfoTypes.TERRAIN_TUNDRA,GameInfoTypes.TERRAIN_SNOW
    c.plot.terrain=tundra
    c.plot.hills=true
    c.buildings[id('BUILDING')]=1
    LoadDaily(29)
    expect(c,'COLD',1); expect(c,'FOOD_1',0)
    for i=1,9 do
        local x,y=i<=6 and directions[i][1] or i-5,i<=6 and directions[i][2] or -1
        add(c,plot(c.plot.x+x,y,{terrain=i<=5 and tundra or snow,owner=0,purchase=i<=6 and 1 or 2}),true)
        changed()
        expect(c,'GARDEN_SCIENCE',i>=2 and 1 or 0)
        expect(c,'GARDEN_CULTURE',i>=5 and 1 or 0)
        expect(c,'FOOD_4',i>=4 and 1 or 0)
        expect(c,'SCIENCE_3',i>=8 and 1 or 0)
    end
    c.work[c.plots[2].index]=false
    c.work[c.plots[3].index]=false
    changed()
    expect(c,'FOOD_4',0); expect(c,'FOOD_3',1); expect(c,'GARDEN_CULTURE',1)
end
cases[30]=function(c)
    local desert=GameInfoTypes.TERRAIN_DESERT
    c.plot.terrain=desert
    c.buildings[id('BUILDING')]=1
    LoadDaily(30)
    expect(c,'DESERT',1); expect(c,'SOLAR_CULTURE',1)
    for i=1,5 do
        add(c,plot(c.plot.x+i,0,{terrain=desert,pillaged=(i==1)}),true)
        changed()
        expect(c,'PEACE',0)
        expect(c,'SOLAR_1',i>=2 and 1 or 0)
        expect(c,'SOLAR_2',i>=4 and 1 or 0)
        expect(c,'FOOD_4',i>=5 and 1 or 0)
    end
    atWar=false
    Events.WarStateChanged.fire(0,1,false)
    expect(c,'PEACE',1)
    atWar=true
    Events.WarStateChanged.fire(0,1,true)
    expect(c,'PEACE',0)
end

-- Batch C adds scenarios below.

owner.civ=id('CIVILIZATION')
local capital=city(1)
assert(cases[DailyNumber],DailyNumber)(capital)
-- Repeated recovery and foreign capture strip both real and accidental free copies.
local controller = assert(Controller)
capital.free[id('BUILDING',controller)]=1
changed()
assert(capital:GetNumFreeBuilding(id('BUILDING',controller))==0)
capital.owner=1
owner.cities={}
Players[1].cities={capital}
GameEvents.CityCaptureComplete.fire(0,true,capital.plot.x,capital.plot.y,1)
expect(capital,controller,0)
assert(owner.saved:find('[Others:17]',1,true))
print('PASS Daily #'..DailyNumber..' '..Speed..' production Lua, eligibility and callback replay')
