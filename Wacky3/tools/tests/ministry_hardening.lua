-- Regressions for confirmed cleanup defects, conservative boundary handling,
-- real CP151 upgrade notification order and bounded optional observations.
local assertions=0
local function expect(ok,message) assert(ok,message); assertions=assertions+1 end
local function check(city,s,c,p) CheckCity(city,s,c,p); assertions=assertions+1 end
local function record(player,turn,tier)
 player.data='foreign=keep;[CWC3_ALMOST:'..turn..':'..tier..']'
end
local foreign=MakeCity(1,50,true)
LoadGameplay()

-- Every saved tier: repair corrupt real AND free counts without tech reads,
-- changing the saved boundary, or granting construction rewards. Exercise
-- synchronous dirty notifications during the writes to prove reentrancy safety.
for tier=0,2 do
 Turn=Turn+1; record(Players[0],Turn,tier)
 for _,city in ipairs(Cities) do
  city.buildings[102]=7; city.buildings[103]=-2; city.buildings[104]=4; city.buildings[105]=3
  for b=102,105 do city.free[b]=2 end
 end
 for b=102,105 do foreign.buildings[b]=5; foreign.free[b]=1 end
 local reads,saves,data=TechReads,SaveWrites,Players[0].data
 ResetEvents(); DirtyOnWrite=true; LoadGameplay(); DirtyOnWrite=false
 expect(TechReads==reads and SaveWrites==saves and Players[0].data==data,'reload must preserve snapshot')
 for _,city in ipairs(Cities) do
  check(city,tier,tier>0 and 1 or 0,tier==2 and city:GetNumBuilding(101)>0 and 1 or 0)
  for b=102,105 do expect(city:GetNumFreeBuilding(b)==0,'free dummy must be removed') end
 end
 check(foreign,0,0,0)
 for b=102,105 do expect(foreign:GetNumFreeBuilding(b)==0,'foreign free dummy leak') end
 local writes=BuildingWrites
 Events.SerialEventCityInfoDirty.Fire(); GameEvents.PlayerDoTurn.Fire(0); LoadGameplay()
 expect(writes==BuildingWrites and saves==SaveWrites and reads==TechReads,'repair must be idempotent')
 expect(#Events.NewGameTurn.handlers==1,'duplicate registration')
end

-- A missing capture callback is recoverable from watched coordinates, including
-- a native-style replacement city object with a different per-owner city ID.
local old=Cities[1]; local x=old:GetX()
Transfer(old,1)
local replacement=MakeCity(1,900,true)
function replacement:GetX() return x end
Plots[x..',0'].city=replacement
for b=102,105 do replacement.buildings[b]=1 end
Events.SerialEventCityInfoDirty.Fire(); check(replacement,0,0,0)

-- Native acquireCity uses the same completion hook for gifting, conquest and
-- cession. Exact ownership is read from the current plot, not captured IDs.
for _,conquest in ipairs({false,true}) do
 Transfer(foreign,0)
 GameEvents.CityCaptureComplete.Fire(1,false,50,0,0,5,conquest,0,0)
 check(foreign,2,1,1)
 local writes=BuildingWrites
 GameEvents.CityCaptureComplete.Fire(1,false,50,0,0,5,conquest,0,0)
 expect(writes==BuildingWrites,'duplicate transfer')
 Transfer(foreign,1)
 GameEvents.CityCaptureComplete.Fire(0,true,50,0,1,5,conquest,0,0)
 check(foreign,0,0,0)
end
Transfer(foreign,0); GameEvents.PlayerLiberated.Fire(1,0,50); check(foreign,2,1,1)
foreign.buildings[101]=0; foreign.free[101]=0
Events.SerialEventCityInfoDirty.Fire(); check(foreign,2,1,0)
for _,purchase in ipairs({{false,false},{true,false},{false,true}}) do
 foreign.buildings[101]=1; GameEvents.CityConstructed.Fire(0,50,101,purchase[1],purchase[2])
 check(foreign,2,1,1)
 foreign.buildings[101]=0; GameEvents.CitySoldBuilding.Fire(0,50,101); check(foreign,2,1,0)
end
-- A missed incoming transfer is repaired by one owner-local recovery pass.
local missed=MakeCity(1,51,false); Transfer(missed,0)
GameEvents.PlayerDoTurn.Fire(0); check(missed,2,1,0)

-- Every real count is bounded and zero means zero even in Lua (where numeric
-- zero is truthy). Save helpers must not rewrite an identical record.
CWC3.SetBuilding(missed,102,0); expect(missed:GetNumRealBuilding(102)==0,'numeric zero truthiness')
GameEvents.PlayerDoTurn.Fire(0); check(missed,2,1,0)
local saves=SaveWrites; CWC3.SaveSnapshot(Players[0],Turn,2)
expect(SaveWrites==saves,'identical snapshot rewrite')
record(Players[0],Turn,9); ResetEvents(); LoadGameplay(); check(missed,0,0,0)
expect(CWC3.LoadSnapshot(Players[0])==nil,'invalid persisted tier')

-- Follow actual normal and goody-upgrade order: new UnitCreated -> PRE-convert
-- UnitUpgraded -> promotion transfer -> POST-convert UnitConverted.
local home=MakePlot(80,1,0); local away=MakePlot(81,1,1); local neutral=MakePlot(82,1,-1)
for _,goody in ipairs({false,true}) do
 local oldID=goody and 84 or 80; local newID=oldID+1
 local oldUnit=MakeUnit(0,oldID,home,true,true)
 local upgraded=MakeUnit(0,newID,home,false,false)
 GameEvents.UnitCreated.Fire(0,newID,300,80,1)
 GameEvents.UnitUpgraded.Fire(0,oldID,newID,goody)
 expect(not upgraded:IsHasPromotion(107),'pre-convert unit has no veteran identity')
 upgraded.promos[106]=oldUnit.promos[106]; upgraded.promos[107]=false
 GameEvents.UnitConverted.Fire(0,0,oldID,newID,true)
 expect(upgraded:IsHasPromotion(106) and upgraded:IsHasPromotion(107),'post-convert defense')
 upgraded.plot=away; GameEvents.UnitSetXY.Fire(0,newID,81,1)
 expect(not upgraded:IsHasPromotion(107),'foreign/Open Borders land must not qualify')
 upgraded.plot=neutral; GameEvents.UnitSetXY.Fire(0,newID,82,1)
 expect(not upgraded:IsHasPromotion(107),'neutral defense')
 upgraded.plot=home; GameEvents.UnitSetXY.Fire(0,newID,80,1)
 expect(upgraded:IsHasPromotion(107),'own defense')
 home.units={upgraded}; home.owner=2; GameEvents.TileOwnershipChanged.Fire(80,1,2,0)
 expect(upgraded:IsHasPromotion(107),'teammate defense')
 home.owner=1; GameEvents.TileOwnershipChanged.Fire(80,1,1,2)
 expect(not upgraded:IsHasPromotion(107),'stationary ownership change')
 home.owner=0
end
local gifted=MakeUnit(18,180,home,true,true)
GameEvents.UnitConverted.Fire(0,18,81,180,false)
expect(not gifted:IsHasPromotion(107),'conversion argument order / owner change')
local leaked=MakeUnit(18,181,away,false,true)
GameEvents.UnitCreated.Fire(18,181,200,81,1)
expect(not leaked:IsHasPromotion(107),'orphan conditional promotion')
local iterations,writes=UnitIterations,PromotionWrites
GameEvents.PlayerDoTurn.Fire(18); GameEvents.PlayerDoTurn.Fire(19)
expect(UnitIterations==iterations and PromotionWrites==writes,'no full foreign unit sweeps or repeated promotion writes')

-- 34 major slots, distinct rival teams, later human and eliminated early slots.
GameDefines.MAX_MAJOR_CIVS=34
for i=0,33 do
 Players[i].alive=true; Players[i].civ=0; Players[i].human=false
 Players[i].minor=false; Players[i].barbarian=false; Players[i].team=i; Teams[i].known=10
end
Players[0].civ=100; Players[0].human=true; ActivePlayer=0
Teams[33].known=20; Turn=Turn+1
ResetEvents(); LoadGameplay(); TechReads=0; Events.NewGameTurn.Fire(Turn)
expect(TechReads==34*40,'34 living distinct major teams, counted once each')
local largeTurn,largeTier=CWC3.LoadSnapshot(Players[0])
expect(largeTurn==Turn and largeTier==2,'34-major maximum gap remains capped')
Players[0].civ=0; Players[0].human=false
Players[20].civ=100; Players[20].human=true; ActivePlayer=20
Turn=Turn+1; record(Players[20],Turn-1,1)
ResetEvents(); LoadGameplay()
local reads,saves,data=TechReads,SaveWrites,Players[20].data
Events.NewGameTurn.Fire(Turn); Events.AIProcessingStartedForPlayer.Fire(20)
expect(reads==TechReads and saves==SaveWrites and data==Players[20].data,'later owner must never snapshot at first rival boundary')
for i=0,19 do Players[i].alive=false end
Turn=Turn+1; TechReads=0; Events.NewGameTurn.Fire(Turn)
expect(TechReads==14*40,'distinct eligible teams counted once')
local savedTurn,tier=CWC3.LoadSnapshot(Players[20]); expect(savedTurn==Turn and tier==2,'first living later slot is supported')
-- Same-team major is excluded, including when its shared tech count leads.
Players[21].team=20; Teams[20].known=25; Turn=Turn+1; TechReads=0
Events.NewGameTurn.Fire(Turn); savedTurn,tier=CWC3.LoadSnapshot(Players[20])
expect(tier==0 and TechReads==13*40,'own team count/eligibility')
-- Defeated leader, replacement, then no living eligible rival teams.
Teams[20].known=10; Teams[33].known=20; Teams[32].known=13
Players[33].alive=false; Turn=Turn+1; Events.NewGameTurn.Fire(Turn)
savedTurn,tier=CWC3.LoadSnapshot(Players[20]); expect(tier==1,'replacement leader after elimination')
for i=22,32 do Players[i].alive=false end
Turn=Turn+1; Events.NewGameTurn.Fire(Turn)
savedTurn,tier=CWC3.LoadSnapshot(Players[20]); expect(tier==0,'no eligible rivals with teammate alive')

-- Reject stale-turn notifications and an economically late first notification.
Players[22].alive=true; Teams[22].known=16
Turn=Turn+1; reads=TechReads; saves=SaveWrites
Events.NewGameTurn.Fire(Turn-1); expect(reads==TechReads and saves==SaveWrites,'stale notification')
GameEvents.PlayerDoTurn.Fire(20); Events.NewGameTurn.Fire(Turn)
expect(reads==TechReads and saves==SaveWrites,'late notification may not recalculate mid-turn')
Turn=Turn+1; Events.NewGameTurn.Fire(Turn)
savedTurn,tier=CWC3.LoadSnapshot(Players[20]); expect(tier==2,'next valid boundary recovers')

-- Optional diagnostics observe genuine stores supplied by the mocked engine;
-- they never grant them or reinterpret rate displays as settlement proof.
MapModData.CWC3_AlmostDiagnostics=true
local observed=MakeCity(20,60,true); GameEvents.PlayerCityFounded.Fire(20,60,0)
Players[20].research=5; Players[20].progress={[5]=1200}; Players[20].culture100=700
Turn=Turn+1; Events.NewGameTurn.Fire(Turn)
local trace=MapModData.CWC3_AlmostTrace
expect(trace[#trace].event=='NewGameTurn:after' and trace[#trace].gap==6 and trace[#trace].tier==2,'snapshot diagnostic fields')
Players[20].progress[5]=1700; Players[20].culture100=900; observed.production100=350
GameEvents.PlayerDoTurn.Fire(20); trace=MapModData.CWC3_AlmostTrace
expect(trace[#trace].event=='PlayerDoTurn:post-economy' and trace[#trace].culture100==900
 and trace[#trace].researchProgress100==1700 and trace[#trace].cities[1].production100==350,'stored-progress observations')
reads=TechReads; saves=SaveWrites; writes=BuildingWrites
for i=1,140 do Events.AIProcessingStartedForPlayer.Fire(20) end
expect(#MapModData.CWC3_AlmostTrace==128,'diagnostic trace must be bounded')
expect(reads==TechReads and saves==SaveWrites and writes==BuildingWrites,'observation-only diagnostic notifications')
MapModData.CWC3_AlmostDiagnostics=false
local records=#MapModData.CWC3_AlmostTrace
Events.AIProcessingStartedForPlayer.Fire(20)
expect(#MapModData.CWC3_AlmostTrace==records,'disabled diagnostics')
print('PASS '..assertions..' hardening assertions: saved-state repair, free counts, cession/gifts, exact upgrade order, 34 living majors/slot restrictions, late-event rejection and diagnostic invariants (mock)')
