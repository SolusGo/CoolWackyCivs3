if MapModData.CWC3_SALT_Registered then return end
include('CWC3_ArchiveLifecycle')
local CIV=assert(GameInfoTypes.CIVILIZATION_CWC3_SALT)
local EXCHANGE=assert(GameInfoTypes.BUILDING_CWC3_SALT)
MapModData.CWC3_SALT_Registered=true
local lifecycle=CWC3Archive.Install{civ=CIV,
    controllers={PASSAGE=assert(GameInfoTypes.BUILDING_CWC3_SALT_PASSAGE),EXCHANGE=assert(GameInfoTypes.BUILDING_CWC3_SALT_EXCHANGE)},
    prepare=function(player)
        local origins={}
        -- GetTradeRoutes enumerates nonempty owned-origin native connections.
        -- Circuits, not the estimated TurnsLeft, govern actual native expiry.
        for _,route in ipairs(player:GetTradeRoutes()) do
            local from,to=route.FromCity,route.ToCity
            if route.FromID==player:GetID() and route.Domain==DomainTypes.DOMAIN_LAND
               and not route.IsRecalled and route.CircuitsCompleted<route.CircuitsToComplete
               and from and to and from:GetOwner()==player:GetID() and to:GetOwner()==route.ToID then
                origins[from:GetID()]=true
            end
        end
        return origins
    end,
    calculate=function(city,player,origins)
        -- Lifecycle passes one prepared set per owner evaluation.
        local active=origins and origins[city:GetID()] or false
        return {PASSAGE=active,EXCHANGE=active and city:GetNumBuilding(EXCHANGE)>0}
    end}
-- Completion is pre-clear: native circuits already mark this connection finished.
GameEvents.PlayerTradeRouteCompleted.Add(lifecycle.all)
GameEvents.PlayerPlunderedTradeRoute.Add(lifecycle.all)
-- Establishment occurs before the original Caravan's delayed kill. Both prekill
-- calls are safe: later call sees the new connection; see source audit/report.
GameEvents.UnitPrekill.Add(function(id) if lifecycle.eligible(Players[id]) then lifecycle.all() end end)
GameEvents.UnitCreated.Add(function(id) if lifecycle.eligible(Players[id]) then lifecycle.all() end end)
Events.SerialEventGameDataDirty.Add(lifecycle.all)
