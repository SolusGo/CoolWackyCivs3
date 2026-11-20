-- Shared state and eligibility helpers for Daily Surprise #021–#035.
include('CWC3_ArchiveLifecycle')
CWC3Daily = CWC3Daily or {}
local daily = CWC3Daily

function daily.Install(code, suffixes, calculate, prepare, plots)
    local controllers = {}
    for _, name in ipairs(suffixes) do
        controllers[name] = assert(GameInfoTypes['BUILDING_CWC3_' .. code .. '_' .. name])
    end
    return CWC3Archive.Install{
        civ = assert(GameInfoTypes['CIVILIZATION_CWC3_' .. code]),
        controllers = controllers, calculate = calculate, prepare = prepare, farms = plots
    }
end

function daily.Worked(city, visit)
    local center = city:Plot()
    for i = 0, city:GetNumCityPlots() - 1 do
        local plot = city:GetCityIndexPlot(i)
        -- The city center is automatically worked and has no assigned citizen.
        if plot and plot:GetPlotIndex() ~= center:GetPlotIndex() and city:IsWorkingPlot(plot) then
            visit(plot)
        end
    end
end

function daily.Owned(city, visit)
    local center = city:Plot()
    local owner, id = city:GetOwner(), city:GetID()
    local seen = {}
    for dx = -3, 3 do
        for dy = -3, 3 do
            local plot = Map.PlotXYWithRangeCheck(center:GetX(), center:GetY(), dx, dy, 3)
            if plot and not seen[plot:GetPlotIndex()] then
                seen[plot:GetPlotIndex()] = true
                if plot:GetOwner() == owner and plot:GetCityPurchaseID() == id then visit(plot) end
            end
        end
    end
end

function daily.Military(unit)
    return unit and unit:IsCombatUnit() and not unit:IsDead() and not unit:IsDelayedDeath()
end

function daily.Major(player)
    return player and player:IsAlive() and not player:IsMinorCiv() and not player:IsBarbarian()
end

function daily.Load(storage, key)
    return (storage:GetScriptData() or ''):match('%[' .. key .. ':([^%]]*)%]')
end

function daily.Save(storage, key, record)
    local old = storage:GetScriptData() or ''
    local new = old:gsub('%[' .. key .. ':[^%]]*%]', '')
    if record then new = new .. '[' .. key .. ':' .. record .. ']' end
    if new ~= old then storage:SetScriptData(new) end
end

function daily.Promotion(unit, id, desired)
    if unit:IsHasPromotion(id) ~= desired then unit:SetHasPromotion(id, desired) end
end

function daily.Defend(lifecycle, code, predicate)
    local lineage = assert(GameInfoTypes['PROMOTION_CWC3_' .. code .. '_LINEAGE'])
    local defense = assert(GameInfoTypes['PROMOTION_CWC3_' .. code .. '_DEFEND'])
    local function update(unit)
        if not daily.Military(unit) then return end
        local plot = unit:Plot()
        local enabled = unit:IsHasPromotion(lineage) and lifecycle.eligible(Players[unit:GetOwner()])
            and not unit:IsEmbarked() and plot and predicate(plot, unit) or false
        daily.Promotion(unit, defense, enabled)
    end
    local function one(owner, id)
        local player = Players[owner]
        if player and lifecycle.eligible(player) then update(player:GetUnitByID(id)) end
    end
    local function plotUnits(x, y)
        local plot = Map.GetPlot(x,y)
        if plot then
            for i = 0, plot:GetNumUnits() - 1 do update(plot:GetUnit(i)) end
        end
    end
    local function units(id)
        local player = Players[id]
        if lifecycle.eligible(player) then for unit in player:Units() do update(unit) end end
    end
    GameEvents.UnitSetXY.Add(one)
    GameEvents.UnitCreated.Add(one)
    GameEvents.UnitConverted.Add(function(_, owner, _, id)
        if Players[owner] then update(Players[owner]:GetUnitByID(id)) end
    end)
    GameEvents.PlayerDoTurn.Add(units)
    GameEvents.BattleStarted.Add(function(_, x, y) plotUnits(x, y) end)
    GameEvents.TileOwnershipChanged.Add(plotUnits)
    for owner = 0, GameDefines.MAX_CIV_PLAYERS - 1 do units(owner) end
end

function daily.Friendly(plot, unit)
    return plot:IsFriendlyTerritory(unit:GetOwner())
end
