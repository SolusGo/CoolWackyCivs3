include('CWC3_Daily')
local daily=CWC3Daily
local desert=assert(GameInfoTypes.TERRAIN_DESERT)
local solar=assert(GameInfoTypes.BUILDING_CWC3_D030)

local function atPeace(player)
    local team=Teams[player:GetTeam()]
    for id=0,GameDefines.MAX_MAJOR_CIVS-1 do
        local other=Players[id]
        if id~=player:GetID() and daily.Major(other) and team:IsAtWar(other:GetTeam()) then return false end
    end
    return true
end

local lifecycle=daily.Install('D030', {'FOOD_1','FOOD_2','FOOD_3','FOOD_4','DESERT','PEACE','SOLAR_1','SOLAR_2',
    'SOLAR_CULTURE'}, function(city,_,peace)
    local worked, unpillaged=0,0
    daily.Worked(city,function(plot)
        if plot:GetTerrainType()==desert then
            worked=worked+1
            if not plot:IsImprovementPillaged() then unpillaged=unpillaged+1 end
        end
    end)
    local founded=city:Plot():GetTerrainType()==desert
    local conservatory=city:GetNumBuilding(solar)>0
    return {FOOD_1=unpillaged>=1,FOOD_2=unpillaged>=2,FOOD_3=unpillaged>=3,FOOD_4=unpillaged>=4,
        DESERT=founded,PEACE=peace and worked>=3,SOLAR_1=conservatory and worked>=2,
        SOLAR_2=conservatory and worked>=4,SOLAR_CULTURE=conservatory and founded}
end,atPeace,true)

-- The CP GameEvents.DeclareWar/MakePeace hooks precede the actual state change.
Events.WarStateChanged.Add(lifecycle.all)
