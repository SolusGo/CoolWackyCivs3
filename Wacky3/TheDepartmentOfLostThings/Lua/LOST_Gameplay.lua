-- CombatResult records participants; CombatEnded proves resolution, not removal.
if MapModData.CWC3_LOST_Registered then return end
include('CWC3_ArchiveLifecycle')
local CIV=GameInfoTypes.CIVILIZATION_CWC3_LOST
assert(CIV,'CWC3 Lost: database registration missing')
MapModData.CWC3_LOST_Registered=true
local OFFICE=GameInfoTypes.BUILDING_CWC3_LOST
local controllers={}
for _,group in ipairs({'CURIO_CULTURE','CURIO_SCIENCE','OFFICE_CULTURE','OFFICE_GOLD'}) do
    for i=1,4 do
        local key=group..'_'..i
        controllers[key]=assert(GameInfoTypes['BUILDING_CWC3_LOST_'..key])
    end
end
local function lifetime(city)
    return city:GetX()..':'..city:GetY()..':'..city:GetOriginalOwner()..':'..city:GetGameTurnFounded()
end
local function count(player,city)
    return math.min(4,tonumber((player:GetScriptData() or ''):match('%[CWC3_LOST_CITY_V1:'..lifetime(city)..':(%d)%]')) or 0)
end
local function cleanup()
    for id=0,GameDefines.MAX_CIV_PLAYERS-1 do
        local p=Players[id]
        if p and p:GetCivilizationType()==CIV then
            local before=p:GetScriptData() or ''
            local after=before:gsub('%[CWC3_LOST_CITY_V1:(%d+):(%d+):(%d+):(%d+):%d%]',function(x,y,original,founded)
                local plot=Map.GetPlot(tonumber(x),tonumber(y)); local c=plot and plot:GetPlotCity()
                if c and c:GetOriginalOwner()==tonumber(original) and c:GetGameTurnFounded()==tonumber(founded) then
                    return '[CWC3_LOST_CITY_V1:'..x..':'..y..':'..original..':'..founded..':'..count(p,c)..']'
                end
                return ''
            end)
            if after~=before then p:SetScriptData(after) end
        end
    end
end
local lifecycle=CWC3Archive.Install{civ=CIV,controllers=controllers,cleanup=cleanup,
    founded=function(_,x,y)
        -- A refounded city is a new lifetime even at the same turn/coordinates.
        for id=0,GameDefines.MAX_CIV_PLAYERS-1 do
            local p=Players[id]
            if p and p:GetCivilizationType()==CIV then
                local before=p:GetScriptData() or ''
                local after=before:gsub('%[CWC3_LOST_CITY_V1:'..x..':'..y..':%d+:%d+:%d%]','')
                if after~=before then p:SetScriptData(after) end
            end
        end
    end,
    calculate=function(city,player)
        local desired={}; local n=count(player,city); local office=city:GetNumBuilding(OFFICE)>0
        for i=1,4 do
            desired['CURIO_CULTURE_'..i]=i<=n; desired['CURIO_SCIENCE_'..i]=i<=n
            desired['OFFICE_CULTURE_'..i]=office and i<=n; desired['OFFICE_GOLD_'..i]=office and i<=n
        end
        return desired
    end}
cleanup()
local pending
local function participant(owner,id)
    local p=Players[owner]; local u=p and p:GetUnitByID(id)
    if not u or not u:IsCombatUnit() then return nil end
    return {owner=owner,id=id,born=u:GetGameTurnCreated(),type=u:GetUnitType(),x=u:GetX(),y=u:GetY()}
end
local function signature(a,au,ad,af,am,d,du,dd,df,dm,ip,iu,damage,x,y)
    return table.concat({a,au,ad,af,am,d,du,dd,df,dm,ip,iu,damage,x,y},':')
end
GameEvents.CombatResult.Add(function(a,au,ad,af,am,d,du,dd,df,dm,ip,iu,damage,x,y)
    pending=nil
    local attacker,defender=participant(a,au),participant(d,du)
    if not attacker or not defender or a==d then return end
    local ap,dp=Players[a],Players[d]
    if ap:GetTeam()==dp:GetTeam() or not Teams[ap:GetTeam()]:IsAtWar(dp:GetTeam()) then return end
    pending={key=signature(a,au,ad,af,am,d,du,dd,df,dm,ip,iu,damage,x,y),a=attacker,d=defender}
end)
local function award(killer,victim,x,y)
    local p=Players[killer.owner]
    if not lifecycle.eligible(p) or not p:IsHuman() then return end
    -- Native lethal damage plus post-resolution dead/absent victim is required.
    local vp=Players[victim.owner]; local v=vp and vp:GetUnitByID(victim.id)
    if v and (v:GetGameTurnCreated()~=victim.born or not v:IsDead()) then return end
    local marker='[CWC3_LOST_KILL_V1:'..victim.owner..':'..victim.id..':'..victim.born..']'
    local data=p:GetScriptData() or ''
    if data:find(marker,1,true) then return end
    local best,distance
    for city in p:Cities() do
        local dist=Map.PlotDistance(x,y,city:GetX(),city:GetY())
        if dist<=3 and (not best or dist<distance or (dist==distance and city:GetID()<best:GetID())) then best,distance=city,dist end
    end
    if not best then return end
    local n=count(p,best)
    -- Kill marker and city record committed in the same serialized ScriptData write.
    -- A full nearest city consumes the kill; it does not spill to another city.
    data=data:gsub('%[CWC3_LOST_CITY_V1:'..lifetime(best)..':%d%]','')
    p:SetScriptData(data..marker..'[CWC3_LOST_CITY_V1:'..lifetime(best)..':'..math.min(4,n+1)..']')
    lifecycle.city(best)
end
GameEvents.CombatEnded.Add(function(a,au,ad,af,am,d,du,dd,df,dm,ip,iu,damage,x,y)
    local observed=pending; pending=nil -- consume before any city writes/reentrant callbacks
    if not observed or observed.key~=signature(a,au,ad,af,am,d,du,dd,df,dm,ip,iu,damage,x,y) then return end
    if df>=dm and af<am then award(observed.a,observed.d,x,y)
    elseif af>=am and df<dm then award(observed.d,observed.a,observed.a.x,observed.a.y) end
end)
