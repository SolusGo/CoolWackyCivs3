-- Shared infrastructure only; future civilizations may include this file.
CWC3 = CWC3 or {}
function CWC3.SetBuilding(city, building, count)
    count = count and 1 or 0
    if city:GetNumRealBuilding(building) ~= count then
        city:SetNumRealBuilding(building, count)
    end
end

-- Small save-backed record, preserving other mods' Player ScriptData.
-- The tier and last valid boundary survive capital loss and zero-city intervals.
function CWC3.LoadSnapshot(player)
    local turn, tier = (player:GetScriptData() or ''):match('%[CWC3_ALMOST:(%-?%d+):(%d)%]')
    return tonumber(turn), tonumber(tier)
end
function CWC3.SaveSnapshot(player, turn, tier)
    local data = (player:GetScriptData() or ''):gsub('%[CWC3_ALMOST:%-?%d+:%d%]', '')
    player:SetScriptData(data .. '[CWC3_ALMOST:' .. turn .. ':' .. tier .. ']')
end
