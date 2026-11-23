local qu = CWC3Qu
local keys = 'TXT_KEY_CWC3_QU_'
local buttons = {Controls.Labor, Controls.Cognitive, Controls.Brood}
local details = {Controls.LaborDetails, Controls.CognitiveDetails, Controls.BroodDetails}
local shown, selected, confirmation, failure

local function text(key, ...)
    return Locale.ConvertTextKey(keys .. key, ...)
end

local function techName(id)
    return Locale.ConvertTextKey(GameInfo.Technologies[id].Description)
end

local function status(reason, detail)
    if not reason then return text('AVAILABLE') end
    if reason == 'INSTALLED' then return text(reason, text(qu.castes[detail].name)) end
    if reason == 'TECH' then return text(reason, techName(detail)) end
    if detail then return text(reason, detail) end
    return text(reason)
end

local function citiesFor(player)
    local cities = {}
    for city in player:Cities() do
        cities[#cities+1] = {id=city:GetID(), plot=city:Plot():GetPlotIndex(), conquered=qu.cityToken(player, city) ~= nil}
    end
    table.sort(cities, function(a, b)
        if a.conquered ~= b.conquered then return a.conquered end
        return a.id < b.id
    end)
    return cities
end

local function selectCity(player, cities)
    for index, entry in ipairs(cities) do
        if entry.plot == selected then return player:GetCityByID(entry.id), index end
    end
    if cities[1] then
        selected = cities[1].plot
        return player:GetCityByID(cities[1].id), 1
    end
end

local function close()
    shown, selected, confirmation, failure = nil, nil, nil, nil
    Controls.Confirm:SetHide(true)
    Controls.Panel:SetHide(true)
end

local function paint()
    if not shown then return end
    local player = qu.player()
    if not player then close(); return end
    local cities = citiesFor(player)
    local city, index = selectCity(player, cities)
    Controls.Biomass:SetText(text('BIOMASS', qu.biomass(player), qu.capacity))
    Controls.City:SetText(city and text('CITY_STATUS', city:GetName(), city:GetPopulation()) or text('NO_CITY'))
    Controls.CityCount:SetText(index and text('CITY_COUNT', index, #cities) or '')
    local reason, detail = qu.status(player, city)
    Controls.Status:SetText(failure or status(reason, detail))
    local disableNav = #cities <= 1 or confirmation ~= nil
    Controls.Prev:SetDisabled(disableNav)
    Controls.Next:SetDisabled(disableNav)
    for i, caste in ipairs(qu.castes) do
        local why, argument = qu.status(player, city, i)
        buttons[i]:SetDisabled(why ~= nil or confirmation ~= nil)
        buttons[i]:SetToolTipString(status(why, argument))
        details[i]:SetText(text(caste.name .. '_EFFECT') .. '  •  ' .. text('TECH', techName(caste.tech)))
    end
    Controls.Confirm:SetHide(not confirmation)
end

local function open()
    if not qu.player() then return end
    local city = UI.GetHeadSelectedCity()
    selected = city and city:Plot():GetPlotIndex()
    shown, confirmation, failure = true, nil, nil
    Controls.Panel:SetHide(false)
    paint()
end

local function navigate(step)
    local player = qu.player()
    if not shown or not player or confirmation then return end
    local cities = citiesFor(player)
    local _, index = selectCity(player, cities)
    if not index then return end
    selected, failure = cities[(index - 1 + step) % #cities + 1].plot, nil
    paint()
end

local function choose(index)
    local player = qu.player()
    if not shown or not player or confirmation then return end
    local city = selectCity(player, citiesFor(player))
    local reason, detail = qu.status(player, city, index)
    if reason then failure = status(reason, detail); paint(); return end
    confirmation = {x=city:GetX(), y=city:GetY(), token=qu.cityToken(player, city), index=index}
    failure = nil
    Controls.ConfirmText:SetText(text('CONFIRM', text(qu.castes[index].name), city:GetName(),
        qu.cost, qu.populationCost))
    paint()
end

local function apply()
    local request = confirmation
    if not request then return end
    confirmation = nil
    local reason, detail = qu.transform(request.x, request.y, request.token, request.index)
    failure = reason and status(reason, detail)
    paint()
end

Controls.Title:SetText(text('OPEN'))
Controls.Cost:SetText(text('COST', qu.cost, qu.populationCost))
for i = 1, #qu.castes do
    buttons[i]:RegisterCallback(Mouse.eLClick, function() choose(i) end)
end
Controls.Prev:RegisterCallback(Mouse.eLClick, function() navigate(-1) end)
Controls.Next:RegisterCallback(Mouse.eLClick, function() navigate(1) end)
Controls.Close:RegisterCallback(Mouse.eLClick, close)
Controls.Cancel:RegisterCallback(Mouse.eLClick, function() confirmation = nil; paint() end)
Controls.Apply:RegisterCallback(Mouse.eLClick, apply)
Controls.Launcher:RegisterCallback(Mouse.eLClick, open)
Controls.Launcher:SetToolTipString(text('OPEN'))
ContextPtr:SetInputHandler(function(message, key)
    if shown and message == KeyEvents.KeyDown and key == Keys.VK_ESCAPE then
        if confirmation then confirmation = nil; paint() else close() end
        return true
    end
end)

local menuBalance
function qu.refresh()
    paint()
    local player = qu.player()
    local balance = player and qu.biomass(player)
    Controls.Launcher:SetHide(not player)
    if player then Controls.LauncherBalance:SetText(text('BIOMASS', balance, qu.capacity)) end
    if balance ~= menuBalance then
        menuBalance = balance
        LuaEvents.RequestRefreshAdditionalInformationDropdownEntries()
    end
end
LuaEvents.AdditionalInformationDropdownGatherEntries.Add(function(entries)
    local player = qu.player()
    if player then
        entries[#entries+1] = {
            text=text('OPEN') .. ' — ' .. text('BIOMASS', qu.biomass(player), qu.capacity),
            tip=keys .. 'TRAIT_HELP', call=open,
        }
    end
end)
local function resetPanel()
    close()
    qu.refresh()
end

Events.ActivePlayerTurnStart.Add(qu.refresh)
Events.ActivePlayerTurnEnd.Add(close)
Events.GameplaySetActivePlayer.Add(resetPanel)
Events.LoadScreenClose.Add(resetPanel)
Events.SerialEventCityScreenDirty.Add(paint)
resetPanel()
