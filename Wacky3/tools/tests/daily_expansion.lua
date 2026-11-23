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
ContextPtr = {SetHide=function(self,value) self.hidden=value end}
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
local mapCensuses, unitSweeps = 0, 0
Game = {GetGameTurn=function() return turn end, GetActivePlayer=function() return active end,
    GetGameSpeedType=function() return GameInfoTypes['GAMESPEED_'..Speed] end}
Teams = {}
for i=0,33 do
    Teams[i]={IsAtWar=function(_,other) return atWar and other~=i end, GetCurrentEra=function() return era end}
end
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
    GetCurrentResearch=function(self) return self.research or -1 end,
    ChangeOverflowResearch=function(self,value) self.science=self.science+value end,
    ChangeJONSCulture=function(self,value) self.culture=self.culture+value end,
    GetCapitalCity=function(self) return self.cities[1] end,
    Cities=function(self) return GameInfoIterator(self.cities) end,
    Units=function(self) unitSweeps=unitSweeps+1; return GameInfoIterator(self.units) end,
    GetCityByID=function(self,id) for _,c in ipairs(self.cities) do if c.id==id then return c end end end,
    GetUnitByID=function(self,id) return self.units[id] end,
    GetScriptData=function(self) return self.saved end,
    SetScriptData=function(self,value) self.saved=value end,
}
Players = {}
for i=0,33 do Players[i]=setmetatable({id=i,civ=-1,cities={},units={},science=0,culture=0,saved='[Others:17]'}, {__index=playerMethods}) end
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
    IsResourceConnectedByImprovement=function(self,id) return id==GameInfoTypes.IMPROVEMENT_MINE end,
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
    GetNumPlots=function() mapCensuses=mapCensuses+1; return #byIndex end, GetPlotByIndex=function(i) return byIndex[i+1] end}
function Map.PlotDistance(x1,y1,x2,y2)
    local dx,dy=x1-x2,y1-y2
    return math.max(math.abs(dx),math.abs(dy),math.abs(dx+dy))
end
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
    IsCapital=function(self) return self.capital end,
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
    local c = setmetatable({id=n,owner=0,plot=center,coast=false,celebration=0,capital=n==1,
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
    GetCurrHitPoints=function(self) return self.hp or 100 end,
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
    MaxMoves=function(self) return self.embarked and 120 or 180+(self.bonus and self.promos[self.bonus] and 60 or 0) end,
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
local function reload()
    GameEvents, Events = events(), events()
    CWC3, CWC3Archive, CWC3Daily = nil,nil,nil
    includes = {}
    assert(LoadDaily(DailyNumber))
end
local function nextTurn()
    turn=turn+1
    GameEvents.PlayerDoTurn.fire(0)
end
local function expect(c,suffix,count)
    assert(c:GetNumBuilding(id('BUILDING',suffix))==count, DailyNumber..' '..suffix..' expected '..count)
end
-- Model the sourced combat additive fields and city yield ordering. These
-- formulas use the installed SQL rows; the production callbacks decide when
-- the rows contribute, and native calculations still need game acceptance.
local function strength(u, defending)
    local extra = 0
    for promo,enabled in pairs(u.promos) do
        local row=enabled and PromotionStats[promo]
        if row then
            extra=extra+row.CombatPercent
            if defending then
                extra=extra+row.DefenseMod+(u.plot.hills and row.HillsDefense or 0)
            else
                extra=extra+row.AttackMod
            end
        end
    end
    return 100+extra
end

local function cityYield(c, kind, base, percent)
    local key='YIELD_'..kind
    for building,amount in pairs(c.buildings) do
        local flat,modifier=FlatYields[building],PercentYields[building]
        if flat then base=base+(flat[key] or 0)*amount*100 end
        if modifier then percent=percent+(modifier[key] or 0)*amount end
    end
    return math.floor(base*percent/100)
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
    local interceptor=unit(2,plot(8,1),false)
    local minor=unit(4,plot(8,2),false)
    c.buildings[id('BUILDING')]=1
    LoadDaily(22)
    local function fight(a,d,kind,v)
        v=v or {}
        local x,y=d and d.plot.x or 20,d and d.plot.y or 0
        GameEvents.BattleStarted.fire(kind,x,y)
        if v.attack then assert(strength(a,false)==v.attack) end
        if v.abort then GameEvents.GameCoreUpdateEnd.fire(); return end
        local i=v.interceptor
        local args={a.owner,a.id,v.ad or 0,v.af or 0,100,d and d.owner or 1,d and d.id or -1,
            v.dd or 0,v.df or 0,100,i and i.owner or -1,i and i.id or -1,v.damage or 0,x,y}
        GameEvents.CombatResult.fire(unpack(args))
        if v.removeA then a.dead=true end
        if v.removeD then d.dead=true end
        if v.collateral then v.collateral() end
        GameEvents.CombatEnded.fire(unpack(args))
        GameEvents.CombatEnded.fire(unpack(args))
    end
    fight(enemy,guard,1,{dd=20,df=20})
    assert(strength(guard,false)==100)
    fight(enemy,guard,0,{dd=20,df=20})
    assert(strength(guard,false)==115 and strength(guard,true)==100)
    fight(guard,enemy,0,{abort=true,attack=115})
    assert(strength(guard,false)==115)
    fight(guard,enemy,0,{dd=20,df=20,attack=115})
    fight(guard,enemy,0,{dd=15,df=35,attack=100})
    fight(enemy,guard,0,{dd=10,df=30})
    local upgraded=unit(0,c.plot,true)
    GameEvents.UnitConverted.fire(0,0,guard.id,upgraded.id,true)
    assert(strength(guard,false)==100 and strength(upgraded,false)==115)
    reload()
    GameEvents.PlayerDoneTurn.fire(0)
    nextTurn()
    assert(strength(upgraded,false)==115)
    GameEvents.PlayerDoneTurn.fire(0)
    reload()
    assert(strength(upgraded,false)==100)

    local plane=unit(0,c.plot,false)
    plane.domain=DomainTypes.DOMAIN_AIR
    plane.hp=72
    fight(plane,nil,2,{interceptor=interceptor,damage=71})
    assert(Controls.Lessons.text=='Lessons: 0 / 5')
    fight(plane,nil,2,{interceptor=interceptor,damage=72,removeA=true})
    assert(Controls.Lessons.text=='Lessons: 1 / 5')
    local otherPlane=unit(0,c.plot,false)
    fight(otherPlane,nil,2,{interceptor=minor,damage=100,removeA=true})
    local civilian=unit(0,c.plot,false)
    civilian.combat=false
    fight(enemy,civilian,1,{dd=100,df=100,removeD=true})
    local unrelated=unit(0,c.plot,false)
    fight(enemy,unrelated,1,{dd=30,df=30,removeD=true})
    assert(Controls.Lessons.text=='Lessons: 1 / 5')

    local sweeper=unit(0,c.plot,false)
    sweeper.hp=21
    fight(sweeper,interceptor,3,{ad=21,removeA=true})
    assert(Controls.Lessons.text=='Lessons: 2 / 5')
    local victim=unit(0,plot(11,0),false)
    local otherTarget=unit(3,plot(12,0),false)
    local disband=unit(0,victim.plot,false)
    fight(enemy,otherTarget,1,{dd=20,df=20,collateral=function()
        victim.dead=true
        GameEvents.UnitPrekill.fire(0,victim.id,victim.kind,11,0,true,1)
        GameEvents.UnitPrekill.fire(0,victim.id,victim.kind,11,0,true,1)
        GameEvents.UnitPrekill.fire(0,disband.id,disband.kind,11,0,false,-1)
        disband.dead=true
    end})
    assert(Controls.Lessons.text=='Lessons: 3 / 5')
    for _=1,5 do fight(enemy,unit(0,c.plot,false),1,{dd=80,df=100,removeD=true}) end
    expect(c,'CHAMBER',1)
    assert(Controls.Lessons.text=='Lessons: 5 / 5')
    Controls.Doctrine.click()
    assert(strength(upgraded,false)==110 and strength(upgraded,true)==110)
    Controls.Doctrine.click()
    assert(Controls.Lessons.text=='Lessons: 3 / 5')
    local successor=city(2)
    Controls.Method.click()
    reload()
    assert(Controls.Lessons.text=='Lessons: 0 / 5')
    expect(c,'CHAMBER',0); expect(c,'METHOD',1)
    -- 10 points are added to the existing 150% native modifier. Exercise
    -- integer hundredths independently of the Chamber's permanent yields.
    c.buildings[id('BUILDING')]=0
    assert(cityYield(c,'SCIENCE',1234,150)==1974)
    c.capital,successor.capital=false,true
    changed()
    expect(c,'METHOD',0); expect(successor,'METHOD',1)
    for i=1,5 do
        assert(cityYield(successor,'SCIENCE',1234,150)==1974)
        nextTurn()
        assert(strength(upgraded,false)==(i<3 and 110 or 100))
        expect(successor,'METHOD',i<5 and 1 or 0)
    end
    assert(cityYield(successor,'SCIENCE',1234,150)==1851)
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
    for n=8,26 do city(n).buildings[id('BUILDING')]=1 end
    nextTurn()
    assert(u:GetMoves()==240)
    reload()
    GameEvents.PlayerDoTurn.fire(0)
    assert(u:GetMoves()==240)
    u:SetMoves(95)
    u.embarked=true -- In CvUnit::move, this happens before UnitSetXY.
    move(u,plot(8,0,{water=true}))
    assert(u:MaxMoves()==120 and u:GetMoves()==35 and not u:IsHasPromotion(u.bonus))
    u.embarked=false
    move(u,c.plot)
    assert(u:GetMoves()==35)
    GameEvents.PlayerDoneTurn.fire(0)
    u:SetMoves(u:MaxMoves()) -- DoUnitReset calls restoreFullMoves next.
    local foreign=plot(7,0,{owner=1,openBorders=true})
    move(u,foreign)
    nextTurn()
    assert(u:GetMoves()==240)
    foreign.openBorders=false
    Events.SerialEventScoreDirty.fire()
    Events.SerialEventScoreDirty.fire()
    assert(u:GetMoves()==180)
    foreign.openBorders=true
    Events.SerialEventScoreDirty.fire()
    assert(u:GetMoves()==180)
    nextTurn()
    assert(u:GetMoves()==240)
    local upgraded=unit(0,foreign,false)
    upgraded.kind=-1
    upgraded.moves=u.moves
    GameEvents.UnitConverted.fire(0,0,u.id,upgraded.id,true)
    GameEvents.UnitConverted.fire(0,0,u.id,upgraded.id,true)
    assert(not upgraded:IsHasPromotion(u.bonus) and upgraded:GetMoves()==180)
end
cases[25]=function(c)
    c.coast=true
    c.buildings[id('BUILDING')]=1
    local u=unit(0,c.plot,true)
    LoadDaily(25)
    expect(c,'COAST',1); expect(c,'WALL',1); expect(c,'BASTION',1)
    assert(strength(u,true)==100)
    local shore=plot(11,0,{water=true})
    for kind=0,1 do
        GameEvents.BattleStarted.fire(kind,10,0)
        assert(strength(u,true)==120 and strength(u,false)==100)
    end
    shore.lake=true
    GameEvents.BattleStarted.fire(1,10,0)
    assert(strength(u,true)==120)
    c.plot.blocked=true
    GameEvents.BattleStarted.fire(0,10,0)
    assert(strength(u,true)==100)
    c.plot.blocked=false
    u.embarked=true
    GameEvents.BattleStarted.fire(0,10,0)
    assert(strength(u,true)==100)
    u.embarked=false
    move(u,plot(7,0))
    assert(strength(u,true)==100)
    move(u,c.plot)
    assert(strength(u,true)==120)
    local veteran=unit(0,c.plot,true)
    GameEvents.UnitConverted.fire(0,0,u.id,veteran.id,true)
    assert(strength(veteran,true)==120 and strength(veteran,false)==100)
    local foreign=unit(1,c.plot,true)
    foreign.promos[id('PROMOTION','DEFEND')]=true
    GameEvents.UnitConverted.fire(0,1,veteran.id,foreign.id,false)
    assert(strength(foreign,true)==100)
end
cases[26]=function(c)
    local inkguard=unit(0,c.plot,true)
    for i=1,1000 do unit(0,c.plot,false) end
    c.buildings[id('BUILDING')]=1
    LoadDaily(26)
    assert(not ContextPtr.hidden)
    active=1
    Events.GameplaySetActivePlayer.fire()
    assert(ContextPtr.hidden)
    active=0
    Events.LoadScreenClose.fire()
    assert(not ContextPtr.hidden)
    expect(c,'PROSPERITY',0); expect(c,'ENLIGHTENMENT',0)
    reload()
    assert(not ContextPtr.hidden)
    Controls.Prosperity.click()
    assert(ContextPtr.hidden)
    expect(c,'PROSPERITY',1); expect(c,'CHAMBER_GOLD',1)
    Controls.Enlightenment.click()
    expect(c,'ENLIGHTENMENT',0)
    local scans=unitSweeps
    nextTurn()
    assert(unitSweeps==scans)
    era=1
    GameEvents.TeamSetEra.fire(0,era,true)
    expect(c,'PROSPERITY',0); expect(c,'CHAMBER_GOLD',0)
    assert(not ContextPtr.hidden)
    Controls.Enlightenment.click()
    expect(c,'ENLIGHTENMENT',1); expect(c,'CHAMBER_SCIENCE',1)
    reload()
    assert(ContextPtr.hidden)
    Controls.Prosperity.click()
    nextTurn()
    expect(c,'ENLIGHTENMENT',1); expect(c,'CHAMBER_SCIENCE',1)
    era=2
    GameEvents.TeamSetEra.fire(0,era,true)
    Controls.Defence.click()
    assert(strength(inkguard,false)==110)
    scans=unitSweeps
    GameEvents.TeamSetEra.fire(0,era,true)
    nextTurn()
    assert(unitSweeps==scans)
    local civilian=unit(0,c.plot,false)
    civilian.combat=false
    GameEvents.UnitCreated.fire(0,civilian.id)
    assert(strength(civilian,false)==100)
    local veteran=unit(0,c.plot,true)
    GameEvents.UnitConverted.fire(0,0,inkguard.id,veteran.id,true)
    assert(strength(veteran,false)==110)
    expect(c,'PROSPERITY',0); expect(c,'ENLIGHTENMENT',0)
    assert(owner.saved:find('[CWC3_D026_V1:2:3]',1,true))
    era=3
    GameEvents.TeamSetEra.fire(0,era,true)
    assert(strength(veteran,false)==100 and not ContextPtr.hidden)
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
    GameEvents.TileImprovementChanged.fire(11,0,0,-1,-1,true)
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

cases[31]=function(c)
    c.buildings[id('BUILDING')]=1
    local scout=unit(0,c.plot,true)
    local secondary=Players[1]
    secondary.civ=owner.civ
    for i=1,89 do plot(100+i,0,{revealed=true}) end
    LoadDaily(31)
    assert(mapCensuses==2)
    local function reveal(p, fromTeam, unitOwner, unitID, team)
        p.revealed=true
        GameEvents.TileRevealed.fire(p.x,p.y,team or 0,fromTeam,false,unitOwner,unitID)
    end
    reveal(plot(101,1,{water=true}),-1,0,scout.id)
    for i=1,10 do reveal(plot(101+i,1),1,-1,-1) end
    GameEvents.GameCoreUpdateEnd.fire()
    expect(c,'ATLAS_CULTURE',0)
    reveal(plot(100,2),-1,-1,-1) -- Unitless and therefore Atlas only.
    active=1
    GameEvents.GameCoreUpdateEnd.fire()
    expect(c,'ATLAS_CULTURE',1)
    assert(owner.science==0 and owner.culture==0)
    local prospect=plot(100,1)
    reveal(prospect,-1,0,scout.id)
    reveal(prospect,-1,0,scout.id)
    assert(owner.saved:find('[CWC3_D031_V1:0:1:0:',1,true))
    reload() -- Save between the sight callback and move completion.
    reveal(prospect,-1,0,scout.id)
    for i=1,109 do reveal(plot(900+i,1),-1,0,scout.id) end
    GameEvents.GameCoreUpdateEnd.fire()
    expect(c,'ATLAS_GOLD',1)
    local rewards={QUICK={10,7},STANDARD={15,10},EPIC={23,15},MARATHON={45,30}}
    local b,culture = unpack(rewards[Speed])
    assert(owner.science==b*10 and owner.culture==culture*10)
    assert(secondary.science==0 and secondary.culture==0 and mapCensuses==4)
    reload()
    era=1
    GameEvents.TeamSetEra.fire(0,era,true)
    assert(owner.science==b*11 and owner.culture==culture*11)
    assert(owner.saved:find('[CWC3_D031_V1:1:0:1:',1,true))
    GameEvents.PlayerDoTurn.fire(0)
    assert(owner.science==b*11 and owner.culture==culture*11)
    local secondScout=unit(1,c.plot,true)
    for i=1,10 do reveal(plot(1100+i,0),-1,1,secondScout.id,1) end
    GameEvents.UnitSetXY.fire(1,secondScout.id,c.plot.x,c.plot.y)
    assert(secondary.science==b and secondary.culture==culture)
    assert(owner.science==b*11)
    -- Native awarded beakers can finish the selected tech and advance the
    -- era while flushing. Model that callback and the resulting overflow.
    owner.research=7
    Teams[0].GetTeamTechs=function()
        return {ChangeResearchProgress=function(_,tech,amount,player)
            assert(tech==7 and player==0 and amount==b)
            owner.techProgress=b-2
            owner.science=owner.science+amount-owner.techProgress
            owner.research=-1
            era=2
            GameEvents.TeamSetEra.fire(0,era,true)
        end}
    end
    for i=1,20 do reveal(plot(1200+i,0),-1,0,scout.id) end
    GameEvents.GameCoreUpdateEnd.fire()
    GameEvents.GameCoreUpdateEnd.fire()
    assert(owner.techProgress==b-2 and owner.science==12*b+2 and owner.culture==13*culture)
    assert(owner.saved:find('[CWC3_D031_V1:2:0:1:',1,true))
    active=0
    secondary.civ=-1
end

cases[32]=function(c)
    local mine,gold,silver=GameInfoTypes.IMPROVEMENT_MINE,GameInfoTypes.RESOURCE_GOLD,GameInfoTypes.RESOURCE_SILVER
    c.buildings[id('BUILDING')]=1
    LoadDaily(32)
    expect(c,'METALS',0); expect(c,'LAKE',0); expect(c,'MINE_1',0)
    local m1=add(c,plot(11,0,{owner=0,purchase=1,improvement=mine,resource=gold}),false)
    local m2=add(c,plot(12,0,{owner=0,purchase=1,improvement=mine}),true)
    local m3=add(c,plot(13,0,{owner=1,purchase=1,improvement=mine,resource=silver}),true)
    local lake=add(c,plot(10,1,{owner=0,purchase=2,water=true,lake=true}),false)
    changed()
    expect(c,'METALS',0); expect(c,'LAKE',0); expect(c,'MINE_1',1); expect(c,'MINE_2',0)
    lake.purchase=1
    c.work[m1.index]=true
    changed()
    expect(c,'METALS',1); expect(c,'LAKE',1); expect(c,'MINE_2',1)
    m1.pillaged=true
    GameEvents.TileImprovementChanged.fire(11,0,0,-1,-1,true)
    expect(c,'METALS',0); expect(c,'MINE_2',0)
    m3.owner=0
    GameEvents.TileOwnershipChanged.fire(13,0,0,1)
    expect(c,'METALS',1); expect(c,'MINE_2',1)
    assert(m2.improvement==mine)
end
cases[33]=function(c)
    local adjacent=plot(11,0,{owner=0,purchase=1})
    local marshal=unit(0,adjacent,true)
    local civilian=unit(0,c.plot,false)
    local ship=unit(0,c.plot,false)
    civilian.combat=false
    ship.domain=DomainTypes.DOMAIN_SEA
    c.garrison=ship
    c.buildings[id('BUILDING')]=1
    LoadDaily(33)
    expect(c,'GARRISON',0); expect(c,'HALL',0)
    move(marshal,c.plot)
    expect(c,'GARRISON',1); expect(c,'HALL',1)
    move(marshal,adjacent)
    expect(c,'GARRISON',0); expect(c,'HALL',0)
    marshal.embarked=true
    move(marshal,c.plot)
    expect(c,'GARRISON',0)
    marshal.embarked=false
    changed()
    expect(c,'GARRISON',1)
    GameEvents.UnitPrekill.fire(0,marshal.id,marshal.kind,10,0,false,1)
    expect(c,'GARRISON',0); expect(c,'HALL',0)
    marshal.dead=true
    changed()
    expect(c,'GARRISON',0)
end
cases[34]=function(c)
    local sentinel=unit(0,c.plot,true)
    c.plot.hills=true
    LoadDaily(34)
    -- No attack or preview state is seeded outside actual battle generation.
    assert(strength(sentinel,false)==100 and strength(sentinel,true)==100)
    GameEvents.BattleStarted.fire(1,10,0)
    assert(strength(sentinel,true)==100)
    GameEvents.BattleStarted.fire(0,10,0)
    assert(strength(sentinel,true)==115 and strength(sentinel,false)==100)
    GameEvents.CombatResult.fire(1,1,15,15,100,0,sentinel.id,25,25,100,-1,-1,0,10,0)
    assert(strength(sentinel,true)==100)
    GameEvents.BattleStarted.fire(0,10,0)
    assert(strength(sentinel,true)==115)
    -- An abort returns through ResolveCombat without Result or Finished.
    GameEvents.GameCoreUpdateEnd.fire()
    assert(strength(sentinel,true)==100)
    GameEvents.BattleStarted.fire(0,10,0)
    reload()
    assert(strength(sentinel,true)==100)
    expect(c,'HILL',1); expect(c,'WALL',0); expect(c,'TERRACE',0)
    c.free[id('BUILDING')]=1
    c.free[GameInfoTypes.BUILDING_WALLS]=1
    changed()
    expect(c,'HILL',1); expect(c,'WALL',1); expect(c,'TERRACE',1)
    c.plot.hills=false
    GameEvents.BattleStarted.fire(0,10,0)
    assert(strength(sentinel,true)==100)
    changed()
    expect(c,'HILL',0); expect(c,'WALL',1); expect(c,'TERRACE',0)
end

cases[35]=function(c)
    local second=city(2)
    local third=city(3)
    c.buildings[id('BUILDING')]=1
    LoadDaily(35)
    local prod=cityYield(c,'PRODUCTION',900,100)
    local science=cityYield(c,'SCIENCE',1103,100)
    local gold=cityYield(c,'GOLD',1036,100)
    local culture=cityYield(c,'CULTURE',0,100)
    local function event(name,city,counter,delta)
        city.celebration=counter
        GameEvents[name].fire(0,city.plot.x,city.plot.y,delta)
    end
    event('CityBeginsWLTKD',c,2,2)
    event('CityBeginsWLTKD',second,1,1)
    assert(cityYield(c,'PRODUCTION',900,100)==prod+200)
    assert(cityYield(c,'SCIENCE',1103,100)==science+100)
    assert(cityYield(c,'GOLD',1036,100)==gold+200)
    assert(cityYield(second,'PRODUCTION',900,100)==1100)
    assert(cityYield(second,'GOLD',1036,100)==1036)
    assert(cityYield(third,'SCIENCE',1103,100)==1103)
    c.celebration=1 -- Native 2 -> 1 tick changes no eligibility.
    assert(cityYield(c,'PRODUCTION',900,100)==prod+200)
    -- Native last production pays at 1. Science and treasury read 0 later.
    event('CityEndsWLTKD',c,0,0)
    assert(cityYield(c,'PRODUCTION',900,100)==prod)
    assert(cityYield(c,'SCIENCE',1103,100)==science)
    assert(cityYield(c,'GOLD',1036,100)==gold)
    assert(cityYield(second,'SCIENCE',1103,100)==1203)
    event('CityBeginsWLTKD',c,3,3)
    event('CityExtendsWLTKD',c,5,2)
    event('CityExtendsWLTKD',c,5,2)
    reload()
    assert(cityYield(c,'SCIENCE',1103,100)==science+100)
    assert(cityYield(c,'GOLD',1036,100)==gold+200)
    assert(cityYield(c,'CULTURE',0,100)==culture)
end

owner.civ=id('CIVILIZATION')
local capital=city(1)
assert(cases[DailyNumber],DailyNumber)(capital)
-- Repeated recovery and foreign capture strip both real and accidental free copies.
local controller = assert(Controller)
capital.free[id('BUILDING',controller)]=1
local before=capital:GetNumRealBuilding(id('BUILDING',controller))
reload()
assert(capital:GetNumRealBuilding(id('BUILDING',controller))==before)
assert(capital:GetNumFreeBuilding(id('BUILDING',controller))==0)
capital.owner=1
owner.cities={}
Players[1].cities={capital}
GameEvents.CityCaptureComplete.fire(0,true,capital.plot.x,capital.plot.y,1,1,true,0,0)
expect(capital,controller,0)
capital.owner=0
owner.cities={capital}
Players[1].cities={}
GameEvents.PlayerLiberated.fire(1,0,capital.id)
expect(capital,controller,before)
assert(owner.saved:find('[Others:17]',1,true))
print('PASS Daily #'..DailyNumber..' '..Speed..' production Lua, eligibility and callback replay')
