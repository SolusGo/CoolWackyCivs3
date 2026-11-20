include('CWC3_Daily')
local daily = CWC3Daily
local key = 'CWC3_D031_V1'
local atlas = assert(GameInfoTypes.BUILDING_CWC3_D031)
local rewardBySpeed = {
    [GameInfoTypes.GAMESPEED_QUICK]={10,7}, [GameInfoTypes.GAMESPEED_STANDARD]={15,10},
    [GameInfoTypes.GAMESPEED_EPIC]={23,15}, [GameInfoTypes.GAMESPEED_MARATHON]={45,30}
}
local reward = rewardBySpeed[Game.GetGameSpeedType()]
local charts = {}

local function chart(player)
    local id = player:GetID()
    if charts[id] then return charts[id] end
    local record = daily.Load(player, key) or ''
    local epoch, progress, paid, claims = record:match('^(%d+):(%d+):(%d+):([%d,]*)$')
    local data = {era=tonumber(epoch) or player:GetCurrentEra(), progress=tonumber(progress) or 0,
                  paid=tonumber(paid) or 0, claims=claims or '', newClaims={}, claimed={}, seen={}, total=0}
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
    if #data.newClaims>0 then
        local separator = data.claims=='' and '' or ','
        data.claims=data.claims .. separator .. table.concat(data.newClaims,',')
        data.newClaims={}
    end
    daily.Save(player,key,table.concat({data.era,data.progress,data.paid,data.claims},':'))
end

local function flush(player)
    if not lifecycle.eligible(player) then return end
    local data=chart(player)
    if data.flushing then return end
    data.flushing=true
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

-- The native event fires only on a change to revealed. The unit owner/ID
-- distinguish own-unit LOS from sharing and ambiguous unitless reveal sources.
GameEvents.TileRevealed.Add(function(x,y,team,fromTeam,_,unitOwner,unitID)
    local player=Players[Game.GetActivePlayer()]
    if not lifecycle.eligible(player) or player:GetTeam()~=team then return end
    local plot=Map.GetPlot(x,y)
    if not plot or plot:IsWater() then return end
    local index=plot:GetPlotIndex()
    local data=chart(player)
    if data.seen[index] then return end
    data.seen[index]=true
    data.total=data.total+1
    if data.total==100 or data.total==200 then data.dirty=true end
    if fromTeam<0 and unitOwner==player:GetID() and unitID>=0 and not data.claimed[index] then
        data.claimed[index]=true
        data.newClaims[#data.newClaims+1]=index
        data.progress=data.progress+1
    end
end)

local function ownerEvent(owner)
    if lifecycle.eligible(Players[owner]) then flush(Players[owner]) end
end
GameEvents.UnitSetXY.Add(ownerEvent)
GameEvents.UnitCreated.Add(ownerEvent)
GameEvents.PlayerDoTurn.Add(ownerEvent)
GameEvents.TeamSetEra.Add(function(team)
    local player=Players[Game.GetActivePlayer()]
    if lifecycle.eligible(player) and player:GetTeam()==team then flush(player) end
end)
Events.ActivePlayerTurnStart.Add(function() ownerEvent(Game.GetActivePlayer()) end)
Events.SerialEventGameDataDirty.Add(function()
    local player=Players[Game.GetActivePlayer()]
    if lifecycle.eligible(player) and chart(player).dirty then lifecycle.all() end
end)
