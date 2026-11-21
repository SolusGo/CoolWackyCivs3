-- City yield reconciliation shared by the archived and Daily additions.
include('CWC3_Runtime')
CWC3Archive = CWC3Archive or {}

function CWC3Archive.HasClass(city, ids)
    for _, id in ipairs(ids) do
        -- Native total includes both real and free representations. Boolean only.
        if city:GetNumBuilding(id) > 0 then return true end
    end
    return false
end

function CWC3Archive.ClassBuildings(class)
    local result = {}
    for building in GameInfo.Buildings() do
        if building.BuildingClass == class then result[#result+1] = building.ID end
    end
    return result
end

function CWC3Archive.Install(config)
    local watched, busy = {}, false
    local function eligible(player)
        return player and player:IsAlive() and player:GetCivilizationType() == config.civ
    end
    local function city(city, prepared)
        if not city then return end
        local x,y = city:GetX(),city:GetY()
        local player = Players[city:GetOwner()]
        local active = eligible(player)
        watched[x..':'..y] = active and {x=x,y=y} or nil
        local desired = active and config.calculate(city, player, prepared) or {}
        for suffix,id in pairs(config.controllers) do CWC3.SetBuilding(city,id,desired[suffix]) end
    end
    local function player(id)
        local p = Players[id]
        if not p then return end
        local prepared = eligible(p) and config.prepare and config.prepare(p)
        for c in p:Cities() do city(c,prepared) end
    end
    local function transaction(work)
        if busy then return end
        busy = true
        local ok,err = pcall(work)
        busy = false
        if not ok then error(err) end
    end
    local function trackChanges(processed)
        -- Owners swept in this transaction need no second city pass. A captured
        -- city still gets cleaned because its current owner is looked up anew.
        local preparedByOwner = {}
        for key,coord in pairs(watched) do
            local plot = Map.GetPlot(coord.x,coord.y)
            local c = plot and plot:GetPlotCity()
            if c then
                local id=c:GetOwner()
                if not processed or not processed[id] then
                    local p=Players[id]
                    if not preparedByOwner[id] then
                        preparedByOwner[id]={value=eligible(p) and config.prepare and config.prepare(p)}
                    end
                    city(c,preparedByOwner[id].value)
                end
            else
                watched[key] = nil
            end
        end
        if config.cleanup then config.cleanup() end
    end
    local function tracked()
        transaction(function() trackChanges() end)
    end
    local function all()
        transaction(function()
            local processed={}
            for id=0,GameDefines.MAX_CIV_PLAYERS-1 do
                if eligible(Players[id]) then player(id); processed[id]=true end
            end
            trackChanges(processed)
        end)
    end
    local function at(x,y,capture)
        transaction(function()
            local key=x..':'..y
            local plot=Map.GetPlot(x,y)
            local c=plot and plot:GetPlotCity()
            if c and eligible(Players[c:GetOwner()]) then
                local owner=c:GetOwner()
                player(owner)
                trackChanges({[owner]=true})
            elseif capture or watched[key] then
                city(c)
                trackChanges()
            end
        end)
    end
    GameEvents.PlayerCityFounded.Add(function(id,x,y)
        if config.founded then config.founded(id,x,y) end
        at(x,y)
    end)
    GameEvents.CityCaptureComplete.Add(function(_,_,x,y) at(x,y,true) end)
    GameEvents.PlayerLiberated.Add(function(_,id) transaction(function() player(id) end); tracked() end)
    local function building(id)
        if eligible(Players[id]) then transaction(function() player(id) end) end
    end
    GameEvents.CityConstructed.Add(building)
    GameEvents.CitySoldBuilding.Add(building)
    if config.farms then
        local function plotChanged(_,_,owner)
            if eligible(Players[owner]) then transaction(function() player(owner) end) end
        end
        GameEvents.TileImprovementChanged.Add(plotChanged)
        GameEvents.TileFeatureChanged.Add(plotChanged)
        GameEvents.TileOwnershipChanged.Add(function(_,_,owner,oldOwner)
            transaction(function()
                if eligible(Players[owner]) then player(owner) end
                if oldOwner~=owner and eligible(Players[oldOwner]) then player(oldOwner) end
            end)
        end)
    end
    Events.SerialEventCityInfoDirty.Add(tracked)
    Events.NewGameTurn.Add(all)
    Events.ActivePlayerTurnStart.Add(all)
    GameEvents.PlayerDoTurn.Add(function(id)
        -- Native CP151 economy has already settled: recovery affects NEXT payout.
        if eligible(Players[id]) then
            transaction(function()
                player(id)
                trackChanges({[id]=true})
            end)
        end
    end)
    GameEvents.CityCanConstruct.Add(function(_,_,buildingID)
        for _,id in pairs(config.controllers) do if id==buildingID then return false end end
        return true
    end)
    -- One bounded city scan at bootstrap/load strips all foreign/free copies.
    transaction(function()
        for id=0,GameDefines.MAX_CIV_PLAYERS-1 do player(id) end
    end)
    local function single(c)
        if not c then return end
        transaction(function()
            local p=Players[c:GetOwner()]
            city(c,eligible(p) and config.prepare and config.prepare(p))
        end)
    end
    return {city=single, all=all, tracked=tracked, eligible=eligible}
end
