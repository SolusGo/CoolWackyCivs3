# Timetable verification and CP151 acceptance

**Native game status: NOT RUN.** Automated production Lua mocks and SQLite fixture passes do not certify actual Civ V economic collection, city-connection cache freshness, selection UI, save serialization or art/VFS presentation.

## Source evidence and timing contract

The existing CP151 commit `44c1e14ff75d80c1dba5c8a71e8289439a53aafb` remains pinned. All original 13 DLL source hashes are preserved; `CvLuaMap.cpp` is an additional reviewed source at that same commit. The 260-file schema pin, its 172 companion tables, GUID, version and save minimum are unchanged.

- [CvLuaPlayer.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/Lua/CvLuaPlayer.cpp): `lIsCapitalConnectedToCity` takes a city at Lua argument 2 and reads `city->IsConnectedToCapital()`. This preserves the game's ordinary connection system rather than rebuilding Roads/Harbors in Lua. Capital, human and team bindings are registered.
- [CvLuaPlot.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/Lua/CvLuaPlot.cpp): ownership, plot index, route type, native route pillage flag, water, Mountains, plot city and `IsImpassable(team)` bindings. The BFS uses actual player ownership, not friendly territory. [CvLuaMap.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/Lua/CvLuaMap.cpp) accepts x/y/direction (0–5) and invokes native wrapped hex adjacency.
- [CvPlayer.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvPlayer.cpp): `doTurnPostDiplomacy` processes cities and research before `PlayerDoTurn`. The source audit already rejects this event as pre-payout. No reliable general human pre-payout UI event has been demonstrated by Wacky3; Timetable uses the existing post-economy next-payout strategy, with no instant Science/Culture compensation or per-frame timing assumption.
- Existing audited event contracts: `PlayerCityFounded(owner,x,y)`; `CityCaptureComplete(oldOwner,capital,x,y,newOwner,population,conquest,...)` after building copy and ownership changes in all acquisition modes; `PlayerLiberated(liberator,owner,cityID)`; `CityConstructed(owner,cityID,building,gold,faith)`; `CitySoldBuilding(owner,cityID,building)` after sale. Existing pack options already enable these. Dummies use the shared verified real/free setters with construction bonuses/refunds suppressed.

At post-economy evaluation E, current eligibility determines counts for the **next payout after E**. Changes after E that have no direct callback (Road/Harbor/rail completion, pillage/repair, ownership of a route tile, Railroad research, scripted removal or Capital relocation) are caught at the next owner evaluation, whose payout has already occurred. Thus a road completed during owner turn T normally first pays at T+2 after evaluation on T+1. Direct lifecycle reconciliations and load can establish counts earlier for their following payout; no past payout is replayed. Native connection flag freshness at any callback is an engine acceptance item. There is no attempt to conceal that delay.

## Data provenance

Generators use only the existing source-approved schema and runtime `SELECT *` clones, with all 27 UnitType and 145 BuildingType companions. They never use a modded cache's table inventory. `timetable_fixture.py` adds native Worker/Workshop sample rows to the clean test fixture and verifies selected files against the existing pin plus two explicitly recorded data-only SHA256s: G&K and BNW `CIV5Units_Expansion*.xml`. Those files add Worker companion data; their addition does not change or repin schema inputs. This fixture still does **not** reconstruct CP's final gameplay migrations. Supplementary caches exercise active CP-shaped rows and mutations, not certified clean CP-only provenance. Installed game/CP files are read-only.

## Automated acceptance matrix

`python tools/validate_timetable.py` executes all pack SQL in the clean schema, checks every inherited scalar/companion, runs production SQL WorkRate variations (80→88, 85→94, 100→110), and runs the real controller with SQL-derived yield values under Lua51 in 4/34-player maps. `python tools/validate_mod.py` additionally runs pristine/mutated clean and supplementary database cases, schema contamination/regeneration, every previous civilization suite, source audit, localization/overrides, native source-row preservation, all DDS headers/alpha/mips, manifest and ZIP byte comparison.

| Required test | Behavior asserted |
| --- | --- |
| A | Disconnected Office has only permanent Gold; no conditional yields |
| B/C | Independent native Road and Harbor flags give Production/Science and Office Culture; no rail reward |
| D | Complete owned Railroad gives exact UA and UB yields, independent of ordinary flag |
| E/F | Road/missing segments, foreign (even another Timetable owner) and unowned plots fail strict rail |
| G | Pillage removes rail effects; repair and alternative path restore/preserve them; cycles terminate |
| H | Technology gates BFS and rail yields; no pre-tech neighbor calls |
| I | Capital excluded from all five controllers, permanent Office Gold retained |
| J | Every active Worker scalar/companion, builds, AI, sounds, capture/model/cost preserved; +1 Move and rounded 110% WorkRate |
| K | Every Workshop scalar/companion preserved; exactly +1 Gold including inherited duplicate Gold entries; no duplicate copied companions |
| L | Founding, building production/Gold/Faith callback, sale/scripted removal fallback, capital relocation/capture, gift/cession/conquest/liberation, replacement IDs, missed callbacks, eliminated/no-capital state, multiple human owners, AI exclusion, corrupt/free controllers, reload and duplicate-registration protection |
| M | Six-city total exactly 10 Production / 5 Science / 10 Culture / 6 Gold |
| N | 100 rail cities and 50 disconnected cities amid many foreign cities; one 201-plot BFS, exactly 1,206 adjacency calls, no BFS on unrelated turns |

## Native checklist — leave unchecked until actually performed

- [ ] Start a clean BNW + standalone CP151 game with only Wacky3; verify no Database.log/Lua.log errors. Human selection includes Veyl and random AI excludes him. Repeat in a later human slot if available through the single-player setup.
- [ ] Train/select a Line Surveyor; compare Movement, construction rates for a farm and route, costs, purchases, build prerequisites, Worker capture and upgrade/automation behavior with the native Worker. No early Railroad construction.
- [ ] Build/select/sell a Dispatch Office; verify active CP Workshop specialist slots and effects, cost, prerequisite, maintenance and exactly one extra Gold, including in the Capital.
- [ ] Check the six bonus-table rows in the civilization README, with and without Offices; identify all five controller counts in FireTuner. No visible/constructible/purchasable dummy assets.
- [ ] Establish and break a valid Road connection, then a genuine Harbor-only connection. Compare native `IsCapitalConnectedToCity(city)` and actual yields. Harbor alone never grants rail bonuses.
- [ ] Research Railroad, construct full owned tracks and verify UA Culture/Office Production. Replace a necessary segment with a Road, unowned/foreign track, pillaged track, or water/Harbor gap. Repair it and build an alternative branch. Check each state at the documented evaluation and following payout.
- [ ] Capture/recapture, gift/cede and liberate cities, including the Capital. Conditional yields clear under foreign ownership and the new Capital has no conditional bonuses. A surviving Office's permanent yield follows normal building survival/conversion rules.
- [ ] Save/reload before and after connection/Office/tech changes and owner evaluations; no instant grants, duplicate income, ScriptData loss or inherited stale controllers. Confirm current-state bootstrap behavior described above.
- [ ] Measure actual Production/research/Culture/Gold stores over controlled payouts, keeping queues, technology, population and modifiers stable. Record post-economy evaluation counts and following collection. Repeat with an event deliberately missed so owner fallback timing is exercised. UI yield rates and callback log order alone are insufficient proof.
- [ ] Inspect every icon size, civilization colors, map glyph, Dawn text/image, static leader, exact four diplomatic lines, Office/Surveyor portraits and native world models. No missing textures or atlas misindexing.
- [ ] Complete the original Ministry, Choir and Summer acceptance checklists in the same pack. Their source bytes and automated behavior remain unchanged; native acceptance of any civilization is not inferred from mocks.
