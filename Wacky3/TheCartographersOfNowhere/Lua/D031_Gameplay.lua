include('CWC3_Daily')
local daily = CWC3Daily
local key = 'CWC3_D031_V1'
local atlas = assert(GameInfoTypes.BUILDING_CWC3_D031)
local rewardBySpeed = {
    [GameInfoTypes.GAMESPEED_QUICK]={10,7}, [GameInfoTypes.GAMESPEED_STANDARD]={15,10},
    [GameInfoTypes.GAMESPEED_EPIC]={23,15}, [GameInfoTypes.GAMESPEED_MARATHON]={45,30}
}
local reward = rewardBySpeed[Game.GetGameSpeedType()]
local charts, teamPlayers, queued = {}, {}, {}

local function chart(player)
    local id = player:GetID()
    if charts[id] then return charts[id] end
    local record = daily.Load(player, key) or ''
    local epoch, progress, paid, claims = record:match('^(%d+):(%d+):(%d+):([%d,]*)$')
    local data = {era=tonumber(epoch) or player:GetCurrentEra(), progress=tonumber(progress) or 0,
                  paid=tonumber(paid) or 0, claims=claims or '', claimed={}, seen={}, total=0}
    for index in data.claims:gmatch('%d+') do data.claimed[tonumber(index)] = true end
    -- One map census on initialization or reload for total (not personal) reveals.
    for index=0,Map.GetNumPlots()-1 do
        local plot = Map.GetPlotByIndex(index)
        if plot and not plot:IsWater() and plot:IsRevealed(player:GetTeam()) then
            data.seen[index] = true
            data.total = data.total + 1
        end
    end
    charts[id] = data
    return data
end

local lifecycle = daily.Install('D031', {'ATLAS_CULTURE','ATLAS_GOLD'},function(city,_,data)
    local built=city:GetNumBuilding(atlas)>0
    return {ATLAS_CULTURE=built and data.total>=100,ATLAS_GOLD=built and data.total>=200}
end,chart)

local function save(player, data)
    daily.Save(player,key,table.concat({data.era,data.progress,data.paid,data.claims},':'))
end

local function flush(player)
    if not lifecycle.eligible(player) then return end
    local data=chart(player)
    if data.flushing then return end
    data.flushing=true
    queued[player:GetID()] = nil
    if data.dirty then
        data.dirty=false
        lifecycle.all()
    end
    local era=player:GetCurrentEra()
    if era>data.era then data.era,data.paid=era,0 end
    while reward and data.progress>=10 and data.paid<10 do
        data.progress,data.paid=data.progress-10,data.paid+1
        -- Write the receipt before awarding. Research can reenter TeamSetEra.
        save(player,data)
        player:ChangeJONSCulture(reward[2])
        local tech=player:GetCurrentResearch()
        if tech and tech>=0 then
            Teams[player:GetTeam()]:GetTeamTechs():ChangeResearchProgress(tech,reward[1],player:GetID())
        else
            player:ChangeOverflowResearch(reward[1])
        end
        era=player:GetCurrentEra()
        if era>data.era then data.era,data.paid=era,0 end
    end
    save(player,data)
    data.flushing=false
end

-- One index of alive Cartographers, independent of the selected player.
-- CP151 keeps teams fixed in ordinary single-player games.
local function indexTeams()
    teamPlayers = {}
    for id=0,GameDefines.MAX_CIV_PLAYERS-1 do
        local p=Players[id]
        if lifecycle.eligible(p) then
            local team=p:GetTeam()
            teamPlayers[team]=teamPlayers[team] or {}
            teamPlayers[team][id]=p
            local data=chart(p)
            if data.progress>=10 and (data.paid<10 or data.era<p:GetCurrentEra()) then queued[id]=true end
        end
    end
end
indexTeams()

local function reveal(player, index, own)
    local data=chart(player)
    if data.seen[index] then return end
    data.seen[index]=true
    data.total=data.total+1
    if data.total==100 or data.total==200 then
        data.dirty=true
        queued[player:GetID()]=true
    end
    if own and reward and not data.claimed[index] then
        data.claimed[index]=true
        local separator=data.claims=='' and '' or ','
        data.claims=data.claims .. separator .. index
        data.progress=data.progress+1
        -- Persist the unspent claim now. A reload before the next movement
        -- or end-of-update callback must not lose this discovery.
        save(player,data)
        queued[player:GetID()]=true
    end
end

-- Unit provenance is native. Shared maps and unitless visibility have no
-- authenticated owner/city source in the payload and only count for the Atlas.
GameEvents.TileRevealed.Add(function(x,y,team,fromTeam,_,unitOwner,unitID)
    local owners=teamPlayers[team]
    if not owners then return end
    local plot=Map.GetPlot(x,y)
    if not plot or plot:IsWater() then return end
    local index=plot:GetPlotIndex()
    for id,player in pairs(owners) do
        if lifecycle.eligible(player) then
            reveal(player,index,fromTeam<0 and unitOwner==id and unitID>=0)
        end
    end
end)

local function ownerEvent(owner)
    local player=Players[owner]
    if lifecycle.eligible(player) then flush(player) end
end
local function dirtyOwner(owner)
    if queued[owner] then ownerEvent(owner) end
end
GameEvents.UnitSetXY.Add(dirtyOwner)
GameEvents.UnitCreated.Add(dirtyOwner)
GameEvents.PlayerDoTurn.Add(ownerEvent)
GameEvents.TeamSetEra.Add(function(team)
    indexTeams()
    for id in pairs(teamPlayers[team] or {}) do ownerEvent(id) end
end)
-- Full research mutation stays outside the sight loop. This also handles
-- non-movement line-of-sight changes and reloads that saved unspent progress.
GameEvents.GameCoreUpdateEnd.Add(function()
    local work=queued
    queued={}
    for id in pairs(work) do ownerEvent(id) end
end)
Events.ActivePlayerTurnStart.Add(function() ownerEvent(Game.GetActivePlayer()) end)
