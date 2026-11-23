include('CWC3_Daily')

CWC3Qu = {}
local qu = CWC3Qu
local daily = CWC3Daily
local setBuilding = CWC3.SetBuilding
local types = GameInfoTypes
local civ = assert(types.CIVILIZATION_CWC3_QU)
local foundry = assert(types.BUILDING_CWC3_QU_GENE_FOUNDRY)
local courthouse = assert(types.BUILDING_COURTHOUSE)
local key = 'CWC3_QU_V1'

qu.capacity = 10
qu.cost = 5
qu.populationCost = 1
qu.castes = {
    {name='LABOR', tech=assert(types.TECH_METAL_CASTING), building=assert(types.BUILDING_CWC3_QU_LABOR)},
    {name='COGNITIVE', tech=assert(types.TECH_EDUCATION), building=assert(types.BUILDING_CWC3_QU_COGNITIVE)},
    {name='BROOD', tech=assert(types.TECH_CHEMISTRY), building=assert(types.BUILDING_CWC3_QU_BROOD)},
}
local foundryScience = {
    assert(types.BUILDING_CWC3_QU_FOUNDRY_1),
    assert(types.BUILDING_CWC3_QU_FOUNDRY_2),
}
local currentOwner, saved

local function humanQu(id)
    local player = Players[id or Game.GetActivePlayer()]
    if player and player:IsHuman() and player:GetCivilizationType() == civ then
        return player
    end
end

function qu.player(id)
    local player = humanQu(id)
    if player and player:IsAlive() then return player end
end

local function load(player)
    local biomass, era, turn, kills, serial, cities =
        (daily.Load(player, key) or ''):match('^(%d+):(%d+):(%d+):(%d+):(%d+);(.*)$')
    local state = {
        biomass=math.min(tonumber(biomass) or 0, qu.capacity),
        era=tonumber(era) or player:GetCurrentEra(),
        turn=tonumber(turn) or Game.GetGameTurn(),
        kills=math.min(tonumber(kills) or 0, 3),
        serial=tonumber(serial) or 0,
        cities={},
    }
    for plot, signature, acquisition, caste in (cities or ''):gmatch('(%d+)=([^;]+)@(%d+)@([0-3]);') do
        state.cities[tonumber(plot)] = {signature=signature, serial=tonumber(acquisition), caste=tonumber(caste)}
    end
    return state
end

local function state(player)
    if currentOwner ~= player:GetID() then
        currentOwner, saved = player:GetID(), load(player)
    end
    return saved
end

local function save(player, s)
    local entries = {}
    for plot, record in pairs(s.cities) do
        entries[#entries+1] = plot .. '=' .. record.signature .. '@' .. record.serial .. '@' .. record.caste .. ';'
    end
    table.sort(entries)
    daily.Save(player, key, table.concat({s.biomass,s.era,s.turn,s.kills,s.serial}, ':') .. ';' .. table.concat(entries))
end

local function notify()
    if qu.refresh then qu.refresh() end
end

function qu.biomass(player)
    return state(player).biomass
end

function qu.addKill(player)
    local s = state(player)
    if s.kills >= 3 or s.biomass >= qu.capacity then return end
    s.kills, s.biomass = s.kills + 1, s.biomass + 1
    save(player, s)
    notify()
end

local function eraReward(player, era)
    local s = state(player)
    if era <= s.era or era <= Game.GetStartEra() then return end
    s.era, s.biomass = era, math.min(qu.capacity, s.biomass + 2)
    save(player, s)
    notify()
end

local function cityAt(x, y)
    local plot = Map.GetPlot(x, y)
    return plot and plot:GetPlotCity()
end

local function plotIndex(city)
    return city:Plot():GetPlotIndex()
end

local function signature(city)
    return table.concat({city:GetID(),city:GetOriginalOwner(),city:GetGameTurnFounded(),
        city:GetGameTurnAcquired(),city:GetPreviousOwner()}, ',')
end

local function recordFor(player, city)
    if not city or city:GetOwner() ~= player:GetID() then return end
    local record = state(player).cities[plotIndex(city)]
    if record and record.signature == signature(city) then return record end
end

function qu.cityToken(player, city)
    local record = recordFor(player, city)
    return record and record.serial
end

local function syncFoundry(city, player)
    local tier = 0
    if player and city:GetNumBuilding(foundry) > 0 then
        tier = math.min(#foundryScience, math.floor(city:GetPopulation() / 5))
    end
    for i, building in ipairs(foundryScience) do setBuilding(city, building, tier == i) end
end

local function sync(city, player)
    local record = player and recordFor(player, city)
    for i, caste in ipairs(qu.castes) do setBuilding(city, caste.building, record and record.caste == i) end
    syncFoundry(city, player)
end

local function reconcile(player)
    local s, verified = state(player), {}
    for city in player:Cities() do
        local record = recordFor(player, city)
        if record then verified[plotIndex(city)] = record end
        sync(city, player)
    end
    s.cities = verified
    save(player, s)
end

function qu.status(player, city, index)
    if not city then return 'NO_CITY' end
    if city:GetOwner() ~= player:GetID() then return 'OWNERSHIP' end
    local record = recordFor(player, city)
    if not record then return 'NO_CONQUEST' end
    if record.caste > 0 then return 'INSTALLED', record.caste end
    if city:IsRazing() then return 'RAZING' end
    if city:IsPuppet() then return 'PUPPET' end
    if city:IsResistance() then return 'RESISTANCE' end
    if city:GetNumBuilding(courthouse) < 1 then return 'COURTHOUSE' end
    if city:GetPopulation() < 6 then return 'POPULATION', 6 end
    if qu.biomass(player) < qu.cost then return 'INSUFFICIENT', qu.cost end
    if not player:IsTurnActive() then return 'TURN' end
    local caste = qu.castes[index]
    if caste and not Teams[player:GetTeam()]:IsHasTech(caste.tech) then return 'TECH', caste.tech end
end

function qu.transform(x, y, token, index)
    local player = qu.player()
    local city = cityAt(x, y)
    if not player or not qu.castes[index] then return 'CHANGED' end
    local record = recordFor(player, city)
    if not record or record.serial ~= token then return 'CHANGED' end
    local reason, detail = qu.status(player, city, index)
    if reason then return reason, detail end

    -- Record the one-time purchase before invoking synchronous population callbacks.
    local s = state(player)
    s.biomass, record.caste = s.biomass - qu.cost, index
    save(player, s)
    city:SetPopulation(city:GetPopulation() - qu.populationCost, true)
    sync(city, player)
    notify()
end

GameEvents.CityCaptureComplete.Add(function(oldOwner, _, x, y, newOwner, _, conquest)
    local player = humanQu()
    if not player or (oldOwner ~= player:GetID() and newOwner ~= player:GetID()) then return end
    local city = cityAt(x, y)
    local plot = Map.GetPlot(x, y)
    if not plot then return end
    local s, id = state(player), plot:GetPlotIndex()
    if city and city:GetOwner() ~= newOwner then return end
    s.cities[id] = nil
    if city and conquest and newOwner == player:GetID() and oldOwner ~= newOwner
        and city:GetOriginalOwner() ~= newOwner then
        s.serial = s.serial + 1
        s.cities[id] = {signature=signature(city), serial=s.serial, caste=0}
    end
    save(player, s)
    if city then sync(city, qu.player(newOwner)) end
    notify()
end)

local function removeCityRecord(owner, x, y)
    local player, plot = qu.player(owner), Map.GetPlot(x, y)
    if not player or not plot then return end
    local s, id = state(player), plot:GetPlotIndex()
    if s.cities[id] then
        s.cities[id] = nil
        save(player, s)
    end
    notify()
end
GameEvents.PlayerCityFounded.Add(removeCityRecord)
GameEvents.CityRazed.Add(removeCityRecord)

local function cityBuilding(owner, id, building)
    local player = qu.player(owner)
    if not player or (building ~= foundry and building ~= courthouse) then return end
    local city = player:GetCityByID(id)
    if city then syncFoundry(city, player) end
    notify()
end
GameEvents.CityConstructed.Add(cityBuilding)
GameEvents.CitySoldBuilding.Add(cityBuilding)
GameEvents.SetPopulation.Add(function(x, y)
    local city = cityAt(x, y)
    local player = city and qu.player(city:GetOwner())
    if player then syncFoundry(city, player); notify() end
end)

GameEvents.TeamSetEra.Add(function(team, era)
    local player = qu.player()
    if player and player:GetTeam() == team then eraReward(player, era) end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
    local player = qu.player(owner)
    if not player then return end
    local s, turn = state(player), Game.GetGameTurn()
    if s.turn ~= turn then s.turn, s.kills = turn, 0 end
    reconcile(player)
    eraReward(player, player:GetCurrentEra())
    notify()
end)

local function initialize()
    local player = qu.player()
    if player then reconcile(player) end
    notify()
end
Events.SequenceGameInitComplete.Add(initialize)
initialize()
