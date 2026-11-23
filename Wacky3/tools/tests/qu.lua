local types = {
    CIVILIZATION_CWC3_QU=1, BUILDING_COURTHOUSE=2, BUILDING_CWC3_QU_GENE_FOUNDRY=3,
    BUILDING_CWC3_QU_LABOR=4, BUILDING_CWC3_QU_COGNITIVE=5, BUILDING_CWC3_QU_BROOD=6,
    BUILDING_CWC3_QU_FOUNDRY_1=7, BUILDING_CWC3_QU_FOUNDRY_2=8,
    TECH_METAL_CASTING=9, TECH_EDUCATION=10, TECH_CHEMISTRY=11,
    PROMOTION_CWC3_QU_BIOLOGICAL_HARVESTING=12, PROMOTION_CWC3_QU_BIOLOGICAL_DEFENSE=13,
}
GameInfoTypes = types
GameInfo = {Technologies={[9]={Description='Metal Casting'},[10]={Description='Education'},[11]={Description='Chemistry'}}}
Locale = {ConvertTextKey=function(key, ...) return table.concat({key,...}, ' ') end}
Mouse, KeyEvents, Keys = {eLClick=1}, {KeyDown=2}, {VK_ESCAPE=27}
ContextPtr = {SetInputHandler=function(self, f) self.input=f end}
local function iterate(items)
    return coroutine.wrap(function() for _, item in pairs(items) do coroutine.yield(item) end end)
end
local function events()
    return setmetatable({}, {__index=function(self, name)
        local listeners = {}
        local event = setmetatable({Add=function(f) listeners[#listeners+1]=f end}, {
            __call=function(_,...) for _, f in ipairs(listeners) do f(...) end end})
        self[name] = event
        return event
    end})
end
local function controls()
    return setmetatable({}, {__index=function(self, name)
        local control = {
            SetText=function(c, v) c.text = v end,
            SetHide=function(c, v) c.hidden = v end,
            SetDisabled=function(c, v) c.disabled = v end,
            SetToolTipString=function(c, v) c.tooltip = v end,
            RegisterCallback=function(c, _, f) c.click = f end,
        }
        self[name] = control
        return control
    end})
end

local function scenario(speed, startingEra)
    local turn, current = 0, 0
    local selected, plots, allies = nil, {}, {}
    local function player(id, human, civilization, minor, barbarian)
        return {
            id=id, human=human, civ=civilization, era=startingEra, data='[OTHER:keep]', alive=true,
            units={}, cities={}, active=true, minor=minor, barbarian=barbarian,
            GetID=function(p) return p.id end, IsHuman=function(p) return p.human end,
            IsAlive=function(p) return p.alive end, GetTeam=function(p) return p.id end,
            IsMajorCiv=function(p) return not p.minor and not p.barbarian end,
            IsMinorCiv=function(p) return p.minor end, IsBarbarian=function(p) return p.barbarian end,
            GetCivilizationType=function(p) return p.civ end, IsTurnActive=function(p) return p.active end,
            GetCurrentEra=function(p) return p.era end, GetScriptData=function(p) return p.data end,
            SetScriptData=function(p, v) p.data=v end, GetUnitByID=function(p, i) return p.units[i] end,
            Cities=function(p) return iterate(p.cities) end, Units=function(p) return iterate(p.units) end,
            GetCityByID=function(p,i) return p.cities[i] end,
        }
    end
    local qu, rival, barb, minor = player(0,true,1), player(1,false,20), player(2,false,21,false,true), player(3,false,22,true)
    Players = {[0]=qu, [1]=rival, [2]=barb, [3]=minor}
    Teams = {[0]={
        IsAtWar=function(_, i) return i ~= 0 and not allies[i] end,
        IsHasTech=function(_, tech) return allies[tech] or false end,
    }}
    Game = {GetActivePlayer=function() return current end, GetGameTurn=function() return turn end,
        GetStartEra=function() return startingEra end, GetGameSpeedType=function() return speed end}
    Map = {GetPlot=function(x) return plots[x] end}
    UI = {GetHeadSelectedCity=function() return selected end}
    local function city(x, original, owner, population)
        local p = {GetPlotIndex=function() return x end, GetPlotCity=function(self) return self.city end}
        local c = {
            id=x, x=x, original=original, owner=owner, population=population, prev=-1,
            builds={}, free={}, puppet=false, resistance=false, razing=false, acquired=turn, founded=0,
            GetOwner=function(a) return a.owner end, GetOriginalOwner=function(a) return a.original end,
            GetID=function(a) return a.id end, GetX=function(a) return a.x end, GetY=function() return 0 end,
            GetGameTurnFounded=function(a) return a.founded end, GetGameTurnAcquired=function(a) return a.acquired end,
            GetPreviousOwner=function(a) return a.prev end, Plot=function() return p end,
            GetName=function(a) return 'City ' .. a.id end, GetPopulation=function(a) return a.population end,
            SetPopulation=function(a,n)
                local previous=a.population; a.population=n
                GameEvents.SetPopulation(a.x,0,previous,n)
            end,
            IsPuppet=function(a) return a.puppet end, IsRazing=function(a) return a.razing end,
            IsResistance=function(a) return a.resistance end,
            GetNumRealBuilding=function(a,b) return a.builds[b] or 0 end,
            GetNumFreeBuilding=function(a,b) return a.free[b] or 0 end,
            GetNumBuilding=function(a,b) return (a.builds[b] or 0)+(a.free[b] or 0) end,
            SetNumRealBuilding=function(a,b,n,noBonus) assert(noBonus); a.builds[b]=n end,
            SetNumFreeBuilding=function(a,b,n,reward,refund) assert(not reward and not refund); a.free[b]=n end,
        }
        plots[x], p.city, Players[owner].cities[x] = p, c, c
        return c
    end
    local function transfer(city, new, conquest)
        local old = city.owner
        Players[old].cities[city.id], Players[new].cities[city.id] = nil, city
        city.prev, city.owner, city.acquired = old, new, turn
        GameEvents.CityCaptureComplete(old,false,city.x,0,new,city.population,conquest,0,0)
    end
    local function reload()
        GameEvents, Events, LuaEvents, Controls = events(), events(), events(), controls()
        include('Qu_Gameplay')
        Events.SequenceGameInitComplete()
    end
    local function reward(amount)
        qu.era=qu.era+1
        GameEvents.TeamSetEra(0,qu.era,false)
        GameEvents.TeamSetEra(0,qu.era,true)
        assert(CWC3Qu.biomass(qu)==amount)
    end
    local function unit(owner, id, military, hp)
        local u = {id=id, owner=owner, military=military, kind=501, hp=hp, marks={}, dead=false,
            IsCombatUnit=function(a) return a.military == true end, IsDead=function(a) return a.hp==0 end,
            IsCanAttackRanged=function(a) return a.military == 'air' end,
            CanNuke=function(a) return a.military == 'nuke' end,
            IsDelayedDeath=function(a) return a.dead end, IsEmbarked=function() return false end,
            GetDamage=function(a) return 100-a.hp end, GetGameTurnCreated=function() return 0 end,
            IsHasPromotion=function(a,p) return a.marks[p] == true end,
            SetHasPromotion=function(a,p,v) a.marks[p]=v end}
        Players[owner].units[id]=u
        return u
    end
    local function beginAttack(attacker, victim, kind)
        GameEvents.BattleStarted(kind or 0,10,0)
        GameEvents.BattleJoined(attacker.owner,attacker.id,0,false)
        GameEvents.BattleJoined(victim.owner,victim.id,1,false)
    end
    local function result(attacker, victim)
        GameEvents.CombatResult(attacker.owner,attacker.id,0,0,100,victim.owner,victim.id,0,100,100,-1,-1,0,10,0)
    end
    local attacker = unit(0,10,true,100)
    local function kill(owner,id,military)
        local victim = unit(owner,id,military,100)
        beginAttack(attacker,victim)
        result(attacker,victim)
        victim.hp = 0
        GameEvents.UnitPrekill(owner,id,victim.kind,10,0,true,0)
        victim.dead = true
        GameEvents.UnitKilledInCombat(0,owner,victim.kind,10)
        GameEvents.UnitKilledInCombat(0,owner,victim.kind,10)
        GameEvents.UnitPrekill(owner,id,victim.kind,10,0,false,-1)
        GameEvents.CombatEnded()
    end

    local own, donated, a, b, c = city(1,0,0,10), city(2,1,1,7), city(3,1,1,6),
        city(4,1,1,9), city(5,3,3,10)
    reload()
    assert(CWC3Qu.biomass(qu)==0)
    kill(1,1,true)
    assert(CWC3Qu.biomass(qu)==1)
    kill(2,2,true); kill(1,3,false)
    allies[3]=true; kill(3,4,true); allies[3]=nil
    local scripted = unit(1,15,true,0)
    GameEvents.UnitPrekill(1,15,scripted.kind,10,0,true,0)
    GameEvents.UnitKilledInCombat(0,1,scripted.kind,-1)
    GameEvents.UnitPrekill(1,15,scripted.kind,10,0,true,-1)
    assert(CWC3Qu.biomass(qu)==1)
    kill(3,6,true); kill(1,7,'air'); kill(1,8,true)
    assert(CWC3Qu.biomass(qu)==3)
    reward(5)
    reload()
    kill(1,9,true)
    assert(CWC3Qu.biomass(qu)==5 and qu.data:find('[OTHER:keep]',1,true))
    GameEvents.TeamSetEra(0,qu.era,false)
    GameEvents.PlayerDoTurn(0)
    assert(CWC3Qu.biomass(qu)==5)

    transfer(donated,0,false)
    transfer(a,0,true); transfer(b,0,true); transfer(c,0,true)
    assert(CWC3Qu.status(qu,own,1)=='NO_CONQUEST')
    assert(CWC3Qu.status(qu,donated,1)=='NO_CONQUEST')
    a.puppet=true
    assert(CWC3Qu.status(qu,a,1)=='PUPPET')
    a.puppet=false
    a.razing=true
    assert(CWC3Qu.status(qu,a,1)=='RAZING')
    a.razing=false
    a.resistance=true
    assert(CWC3Qu.status(qu,a,1)=='RESISTANCE')
    a.resistance=false
    assert(CWC3Qu.status(qu,a,1)=='COURTHOUSE')
    a.builds[2], b.builds[2], c.builds[2] = 1,1,1
    local token = CWC3Qu.cityToken(qu,a)
    assert(CWC3Qu.transform(3,0,token,1)=='TECH')
    assert(a.population==6 and CWC3Qu.biomass(qu)==5)
    allies[9],allies[10],allies[11]=true,true,true
    a:SetPopulation(5)
    assert(CWC3Qu.status(qu,a,1)=='POPULATION')
    a:SetPopulation(6)
    selected=a
    local entries={}
    LuaEvents.AdditionalInformationDropdownGatherEntries(entries)
    assert(#entries==1 and entries[1].text:find('5 10'))
    entries[1].call()
    assert(not Controls.Panel.hidden and not Controls.Labor.disabled)
    Controls.Labor.click()
    Events.LoadScreenClose()
    assert(Controls.Panel.hidden and Controls.Confirm.hidden)
    entries[1].call()
    Controls.Labor.click(); Controls.Cancel.click()
    assert(a.population==6 and CWC3Qu.biomass(qu)==5)
    Controls.Labor.click(); qu.active=false; Controls.Apply.click(); qu.active=true
    assert(a.population==6 and CWC3Qu.biomass(qu)==5 and Controls.Status.text:find('TURN'))
    Controls.Labor.click(); Controls.Apply.click(); Controls.Apply.click()
    assert(a.population==5 and CWC3Qu.biomass(qu)==0 and a:GetNumBuilding(4)==1)
    assert(CWC3Qu.transform(3,0,token,2)=='INSTALLED')
    assert(b:GetNumBuilding(4)==0 and own:GetNumBuilding(4)==0)
    reload()
    assert(a:GetNumBuilding(4)==1 and CWC3Qu.biomass(qu)==0)

    turn=turn+1
    kill(1,10,true)
    assert(CWC3Qu.biomass(qu)==0)
    GameEvents.PlayerDoTurn(0)
    kill(1,11,true)
    local overrun=unit(1,12,true,100)
    GameEvents.UnitCaptured(0,attacker.id,1,overrun.id,true,0)
    GameEvents.UnitPrekill(1,overrun.id,overrun.kind,10,0,false,0)
    GameEvents.UnitPrekill(1,overrun.id,overrun.kind,10,0,false,0)
    local bomb=unit(1,13,'nuke',100)
    GameEvents.BattleStarted(5,10,0)
    GameEvents.BattleJoined(1,bomb.id,0,false)
    GameEvents.BattleJoined(0,own.id,1,true)
    GameEvents.UnitPrekill(1,bomb.id,bomb.kind,10,0,true,0)
    GameEvents.GameCoreUpdateEnd()
    reward(5)
    assert(CWC3Qu.transform(4,0,CWC3Qu.cityToken(qu,b),2)==nil)
    assert(b.population==8 and b:GetNumBuilding(5)==1)
    turn=turn+1
    GameEvents.PlayerDoTurn(0)
    kill(1,14,true); kill(1,15,true); kill(1,16,true)
    reward(5)
    assert(CWC3Qu.transform(5,0,CWC3Qu.cityToken(qu,c),3)==nil)
    assert(c.population==9 and c:GetNumBuilding(6)==1 and b:GetNumBuilding(6)==0 and a:GetNumBuilding(4)==1)
    transfer(a,1,false)
    assert(a:GetNumBuilding(4)==0)
    transfer(a,0,true)
    assert(CWC3Qu.cityToken(qu,a)~=token and CWC3Qu.transform(3,0,token,1)=='CHANGED')
    assert(a:GetNumBuilding(4)==0 and a.population==5 and CWC3Qu.biomass(qu)==0)
    GameEvents.CityRazed(0,3,0)
    qu.cities[3]=nil
    local reuse=city(3,0,0,10)
    GameEvents.PlayerCityFounded(0,3,0)
    assert(CWC3Qu.status(qu,reuse,1)=='NO_CONQUEST')
    transfer(b,1,false); transfer(b,0,false)
    assert(b:GetNumBuilding(5)==0 and CWC3Qu.status(qu,b,1)=='NO_CONQUEST')
    reload()
    assert(c:GetNumBuilding(6)==1 and b:GetNumBuilding(5)==0)

    own.builds[3]=1
    GameEvents.CityConstructed(0,1,3,false,false)
    for _, case in ipairs({{4,0},{5,1},{9,1},{10,2},{14,2},{4,0}}) do
        own:SetPopulation(case[1])
        assert(own:GetNumBuilding(7)+own:GetNumBuilding(8)*2==case[2])
    end
    own:SetPopulation(10)
    reload()
    assert(own:GetNumBuilding(8)==1)
    own.builds[3]=0
    GameEvents.CitySoldBuilding(0,1,3)
    assert(own:GetNumBuilding(8)==0)
    own.builds[3]=1
    GameEvents.CityConstructed(0,1,3,false,false)
    transfer(own,1,true)
    assert(own:GetNumBuilding(8)==0)
    transfer(own,0,true)
    assert(own:GetNumBuilding(8)==1 and CWC3Qu.cityToken(qu,own)==nil)

    local harvester = unit(0,40,true,100)
    local wounded, healthy = unit(1,41,true,49), unit(1,42,true,100)
    harvester.marks[12]=true
    beginAttack(wounded,harvester)
    assert(harvester.marks[13])
    result(wounded,harvester)
    assert(not harvester.marks[13])
    beginAttack(healthy,harvester)
    assert(not harvester.marks[13])
    healthy.hp=50
    result(healthy,harvester)
    assert(not harvester.marks[13])
    beginAttack(wounded,harvester,1)
    assert(harvester.marks[13])
    GameEvents.GameCoreUpdateEnd()
    assert(not harvester.marks[13])
    harvester.marks[13]=true
    GameEvents.UnitConverted(0,0,10,40,true)
    assert(not harvester.marks[13] and harvester.marks[12])

    for i=1,5 do
        qu.era=qu.era+1
        GameEvents.TeamSetEra(0,qu.era,false)
    end
    assert(CWC3Qu.biomass(qu)==10)
    turn=turn+1
    GameEvents.PlayerDoTurn(0)
    kill(1,61,true)
    assert(CWC3Qu.biomass(qu)==10)
    reload(); reload()
    assert(CWC3Qu.biomass(qu)==10 and c:GetNumBuilding(6)==1)
    current=1
    Events.GameplaySetActivePlayer()
    assert(Controls.Panel.hidden)
    entries={}
    LuaEvents.AdditionalInformationDropdownGatherEntries(entries)
    assert(#entries==0)
end

scenario(0,0)
scenario(3,0)
scenario(3,2)
