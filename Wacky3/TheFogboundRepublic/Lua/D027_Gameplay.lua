include('CWC3_Daily')
local daily = CWC3Daily
local marsh = assert(GameInfoTypes.FEATURE_MARSH)
local conservatory = assert(GameInfoTypes.BUILDING_CWC3_D027)
local mist = assert(GameInfoTypes.PROMOTION_CWC3_D027_MIST)

local lifecycle = daily.Install('D027', {'SCIENCE_1','SCIENCE_2','SCIENCE_3','SCIENCE_4','MIST','FOOD','RESEARCH'},
    function(city)
        local worked, owned = 0,0
        daily.Worked(city,function(plot)
            if plot:GetFeatureType() == marsh and not plot:IsImprovementPillaged() then worked=worked+1 end
        end)
        daily.Owned(city,function(plot) if plot:GetFeatureType() == marsh then owned=owned+1 end end)
        local building = city:GetNumBuilding(conservatory) > 0
        return {SCIENCE_1=worked>=1, SCIENCE_2=worked>=2, SCIENCE_3=worked>=3, SCIENCE_4=worked>=4,
            MIST=owned>=2, FOOD=building and owned>=2, RESEARCH=building and owned>=4}
    end, nil, true)

local function refresh(unit)
    if unit then
        local eligible = lifecycle.eligible(Players[unit:GetOwner()]) and daily.Military(unit)
        daily.Promotion(unit, mist, eligible and true or false)
    end
end

local function units(owner)
    local player=Players[owner]
    if lifecycle.eligible(player) then for unit in player:Units() do refresh(unit) end end
end

GameEvents.UnitCreated.Add(function(owner,id)
    if lifecycle.eligible(Players[owner]) then refresh(Players[owner]:GetUnitByID(id)) end
end)
GameEvents.UnitConverted.Add(function(_,owner,_,id)
    if Players[owner] then refresh(Players[owner]:GetUnitByID(id)) end
end)
GameEvents.PlayerDoTurn.Add(units)
for owner=0,GameDefines.MAX_CIV_PLAYERS-1 do units(owner) end
