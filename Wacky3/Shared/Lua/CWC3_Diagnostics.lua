-- Optional read-only evidence. Enable MapModData.CWC3_AlmostDiagnostics=true in
-- FireTuner's CWC3_Almost context; output goes to Lua.log and a bounded trace.
-- Stored progress observations are NOT proof of yields attributable to this mod.
function CWC3.AlmostTrace(event, iPlayer, gap, detail)
    if not MapModData.CWC3_AlmostDiagnostics then return end
    local player = Players[iPlayer]
    if not player then return end
    local savedTurn, tier = CWC3.LoadSnapshot(player)
    local research = player:GetCurrentResearch()
    local record = {
        event=event, turn=Game.GetGameTurn(), player=iPlayer,
        gap=gap, savedTurn=savedTurn, tier=tier, detail=detail,
        culture100=player:GetJONSCultureEverGeneratedTimes100(),
        research=research,
        researchProgress100=research >= 0 and player:GetResearchProgressTimes100(research) or nil,
        cities={}
    }
    print('CWC3_ALMOST_DIAG event=' .. event .. ' turn=' .. record.turn .. ' player=' .. iPlayer
        .. ' gap=' .. tostring(gap) .. ' savedTurn=' .. tostring(savedTurn) .. ' tier=' .. tostring(tier)
        .. ' lifetimeCulture100=' .. record.culture100 .. ' research=' .. research
        .. ' researchProgress100=' .. tostring(record.researchProgress100) .. ' detail=' .. tostring(detail))
    for city in player:Cities() do
        local data = {id=city:GetID(), x=city:GetX(), y=city:GetY(),
            production100=city:GetProductionTimes100(),
            productionUnit=city:GetProductionUnit(), productionBuilding=city:GetProductionBuilding(),
            productionProject=city:GetProductionProject(), counts={}}
        local counts={}
        for _,suffix in ipairs({'SCIENCE_1','SCIENCE_2','CULTURE','ACADEMY_PRODUCTION'}) do
            local building=GameInfoTypes['BUILDING_CWC3_ALMOST_' .. suffix]
            local real, free=city:GetNumRealBuilding(building),city:GetNumFreeBuilding(building)
            data.counts[suffix]={real=real,free=free}
            counts[#counts+1]=suffix .. '=' .. real .. '+' .. free
        end
        record.cities[#record.cities+1]=data
        print('CWC3_ALMOST_DIAG city=' .. data.id .. ' player=' .. iPlayer .. ' production100='
            .. data.production100 .. ' queue=' .. data.productionUnit .. '/' .. data.productionBuilding
            .. '/' .. data.productionProject .. ' ' .. table.concat(counts,','))
    end
    local trace=MapModData.CWC3_AlmostTrace or {}
    trace[#trace+1]=record
    if #trace>128 then table.remove(trace,1) end
    MapModData.CWC3_AlmostTrace=trace
end
