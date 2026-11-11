-- Lifecycle wiring for the four archived additions only. Existing civs are untouched.
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
    local function tracked()
        transaction(function()
            -- One preparation (e.g. route enumeration) per affected owner.
            local preparedByOwner = {}
            for key,coord in pairs(watched) do
                local plot = Map.GetPlot(coord.x,coord.y)
                local c = plot and plot:GetPlotCity()
                if c then
                    local id=c:GetOwner(); local p=Players[id]
                    if not preparedByOwner[id] then
                        preparedByOwner[id]={value=eligible(p) and config.prepare and config.prepare(p)}
                    end
                    city(c,preparedByOwner[id].value)
                else watched[key] = nil end
            end
            if config.cleanup then config.cleanup() end
        end)
    end
    local function all()
        transaction(function()
            for id=0,GameDefines.MAX_CIV_PLAYERS-1 do
                if eligible(Players[id]) then player(id) end
            end
        end)
        tracked()
    end
    local function at(x,y)
        transaction(function()
            local plot=Map.GetPlot(x,y)
            local c=plot and plot:GetPlotCity()
            -- Refresh the whole new owner to share a single prepared route set.
            if c then
                if eligible(Players[c:GetOwner()]) then player(c:GetOwner()) else city(c) end
            end
        end)
        tracked()
    end
    GameEvents.PlayerCityFounded.Add(function(id,x,y)
        if config.founded then config.founded(id,x,y) end
        at(x,y)
    end)
    GameEvents.CityCaptureComplete.Add(function(_,_,x,y) at(x,y) end)
    GameEvents.PlayerLiberated.Add(function(_,id) transaction(function() player(id) end); tracked() end)
    local function building(id)
        if eligible(Players[id]) then transaction(function() player(id) end) end
    end
    GameEvents.CityConstructed.Add(building)
    GameEvents.CitySoldBuilding.Add(building)
    if config.farms then
        GameEvents.TileImprovementChanged.Add(all)
        GameEvents.TileOwnershipChanged.Add(all)
    end
    Events.SerialEventCityInfoDirty.Add(tracked)
    Events.NewGameTurn.Add(all)
    Events.ActivePlayerTurnStart.Add(all)
    GameEvents.PlayerDoTurn.Add(function(id)
        -- Native CP151 economy has already settled: recovery affects NEXT payout.
        if eligible(Players[id]) then
            transaction(function() player(id) end)
            tracked()
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
    return {city=function(c) transaction(function() city(c) end) end, all=all, tracked=tracked, eligible=eligible}
end
