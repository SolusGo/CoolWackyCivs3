local assertions=0
local function check(c,s,culture,prod) CheckCity(c,s,culture,prod); assertions=assertions+1 end
LoadGameplay()
-- Native-event mock: snapshot occurs before the mocked native yield collection.
for _,case in ipairs({{2,0,0},{3,1,1},{5,1,1},{6,2,1},{10,2,1},{0,0,0},{-3,0,0}}) do
 Turn=Turn+1; Teams[1].known=10+case[1]
 Events.NewGameTurn.Fire(Turn)
 for _,city in ipairs(Cities) do
  check(city,case[2],case[3],case[2]==2 and city:GetNumBuilding(101)>0 and 1 or 0)
 end
end
-- No living eligible rivals: city states, barbarians, dead leader, teammates ignored.
Players[1].alive=false; Turn=Turn+1; Events.NewGameTurn.Fire()
check(Cities[1],0,0,0)
-- New leader and >20 majors; shared teams counted once.
for i=4,24 do Players[i].alive=true; Players[i].team=4 end
Teams[4].known=16; Turn=Turn+1; TechReads=0; Events.NewGameTurn.Fire()
assert(TechReads==80,'must enumerate only two distinct eligible teams')
check(Cities[1],2,1,1)
-- Repeated notifications, reconciliation and research changes cannot resnapshot.
local data=Players[0].data; local reads=TechReads; local writes=BuildingWrites
Teams[4].known=10
Events.NewGameTurn.Fire(); Events.AIProcessingStartedForPlayer.Fire(0)
GameEvents.PlayerDoTurn.Fire(0); Events.SerialEventCityInfoDirty.Fire()
assert(Players[0].data==data and TechReads==reads and BuildingWrites==writes)
check(Cities[1],2,1,1)
local founded=MakeCity(0,4,false); GameEvents.PlayerCityFounded.Fire(0,4,0)
check(founded,2,1,0)
founded.buildings[101]=1; GameEvents.CityConstructed.Fire(0,4,101,false,false)
check(founded,2,1,1)
founded.buildings[101]=0; GameEvents.CitySoldBuilding.Fire(0,4,101)
check(founded,2,1,0)
-- Direct scripted removal uses city-info dirtiness, without a tech comparison.
Cities[1].buildings[101]=0; Events.SerialEventCityInfoDirty.Fire()
check(Cities[1],2,1,0)
local captured=MakeCity(1,5,true); Transfer(captured,0)
GameEvents.CityCaptureComplete.Fire(1,false,5,0,0,7,true)
check(captured,2,1,1)
Transfer(captured,1); GameEvents.CityCaptureComplete.Fire(0,false,5,0,1,7,true)
check(captured,0,0,0)
-- Capital loss does not affect player snapshot. Liberation uses saved tier.
Transfer(Cities[1],1); GameEvents.CityCaptureComplete.Fire(0,true,0,0,1,7,true)
check(Cities[1],0,0,0)
Transfer(captured,0); GameEvents.PlayerLiberated.Fire(1,0,5)
check(captured,2,1,1)
assert(Players[0].data:find('other%-mod=preserved;'))
-- New context reload retains script data/buildings, even after the rival changes.
Teams[4].known=40; local saved=Players[0].data
ResetEvents(); LoadGameplay()
assert(Players[0].data==saved and TechReads==reads)
check(captured,2,1,1)
-- Duplicate registration guard must keep exactly one handler per event.
LoadGameplay(); assert(#Events.NewGameTurn.handlers==1)
-- Next boundary actually shrinks the gap, and removes all catch-up bonuses.
Teams[4].known=10; Turn=Turn+1; Events.NewGameTurn.Fire()
check(captured,0,0,0)
-- Zero-city interval: snapshot survives a capital-independent player save.
local oldCities=Players[0].cities; Players[0].cities={}
Turn=Turn+1; Teams[4].known=16; Events.NewGameTurn.Fire()
Players[0].cities=oldCities
local revived=MakeCity(0,6,true); GameEvents.PlayerCityFounded.Fire(0,6,0)
check(revived,2,1,1)
-- Conditional veteran defense, foreign/neutral/team-owned tiles, movement/reload.
local home=MakePlot(10,1,0); local foreign=MakePlot(11,1,1)
local neutral=MakePlot(12,1,-1); local teammate=MakePlot(13,1,2)
local guard=MakeUnit(0,10,home,true,false)
GameEvents.UnitCreated.Fire(0,10,200,10,1); assert(guard:IsHasPromotion(107))
guard.plot=foreign; GameEvents.UnitSetXY.Fire(0,10,11,1); assert(not guard:IsHasPromotion(107))
guard.plot=neutral; GameEvents.UnitSetXY.Fire(0,10,12,1); assert(not guard:IsHasPromotion(107))
guard.plot=teammate; GameEvents.UnitSetXY.Fire(0,10,13,1); assert(guard:IsHasPromotion(107))
teammate.units={guard}; teammate.owner=1; GameEvents.TileOwnershipChanged.Fire(13,1,1,2)
assert(not guard:IsHasPromotion(107))
local upgraded=MakeUnit(0,11,home,true,false)
GameEvents.UnitUpgraded.Fire(0,10,11,false); assert(upgraded:IsHasPromotion(107))
local leak=MakeUnit(1,12,home,false,true); GameEvents.UnitConverted.Fire(0,1,2,12,false)
assert(not leak:IsHasPromotion(107))
upgraded.plot=foreign; ResetEvents(); LoadGameplay(); assert(not upgraded:IsHasPromotion(107))
-- Dummy construction veto affects nobody else's buildings.
assert(not GameEvents.CityCanConstruct.Fire(1,5,102)); assert(GameEvents.CityCanConstruct.Fire(1,5,101))
-- Nil/removed handles are harmless.
GameEvents.UnitSetXY.Fire(0,999); GameEvents.CityConstructed.Fire(0,999,101)
GameEvents.PlayerDoTurn.Fire(38); GameEvents.CityCaptureComplete.Fire(0,false,99,99,1,1,true)
print('PASS '..assertions..' city yield assertions plus snapshot, ownership, reload, 25-major and veteran event scenarios (mock)')
