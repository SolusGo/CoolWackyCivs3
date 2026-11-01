-- Shared infrastructure only; future civilizations may include this file.
CWC3 = CWC3 or {}
function CWC3.SetBuilding(city, building, count)
    count = (count == true or count == 1) and 1 or 0
    -- These controller buildings must never have a second, free copy. The CP151
    -- bindings support clearing it without refunds or construction bonuses.
    if city:GetNumFreeBuilding(building) ~= 0 then
        city:SetNumFreeBuilding(building, 0, false, false)
    end
    if city:GetNumRealBuilding(building) ~= count then
        city:SetNumRealBuilding(building, count, true)
    end
end

-- Small save-backed record, preserving other mods' Player ScriptData.
-- The tier and last valid boundary survive capital loss and zero-city intervals.
function CWC3.LoadSnapshot(player)
    local turn, tier = (player:GetScriptData() or ''):match('%[CWC3_ALMOST:(%-?%d+):(%d)%]')
    turn, tier = tonumber(turn), tonumber(tier)
    if not turn or turn < 0 or not tier or tier > 2 then return nil, nil end
    return turn, tier
end
function CWC3.SaveSnapshot(player, turn, tier)
    local data = (player:GetScriptData() or ''):gsub('%[CWC3_ALMOST:%-?%d+:%d%]', '')
    data = data .. '[CWC3_ALMOST:' .. turn .. ':' .. tier .. ']'
    if data ~= player:GetScriptData() then player:SetScriptData(data) end
end
