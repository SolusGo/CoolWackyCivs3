# The Candlekeeper's Covenant — implementation report

## Result and verification boundary

The fifth human-selectable civilization is implemented within Wacky3's existing GUID, version and save minimum. It includes Seraphine/Last Light, full narrative and diplomacy, active CP Pikeman/Temple inheritance, an accumulated destruction ledger, exact recurring capital/Hall yields, defensive veteran behavior and original static artwork. No independent mod manifest, VP dependency, custom DLL, ModBuddy project or custom gameplay UI was added.

**Native in-game acceptance has not been run.** SQL/source/packaging validation and Lua 5.1 simulations are distinct from native game evidence. The authoritative automated results are in `Wacky3/tools/Validation.json`; manual requirements are in `Wacky3/docs/CovenantTesting.md`. Unobservable script histories and native economic/combat/save/UI acceptance remain explicit limits. The implementation is ready for those tests; it is not described as natively verified.

## Destruction hooks and identity

Pinned CP commit: `44c1e14ff75d80c1dba5c8a71e8289439a53aafb` (DLL v151). `tools/cp151_sources.json` retains SHA-256 hashes and primary-source URLs. Existing source evidence is preserved; `CvCity.cpp` and `CvUnitCombat.cpp` are added.

- `GameEvents.CityRazed(owner,x,y)` is verified in `CvPlayer::disband` before `pCity->kill()`. It saves the last owner and a pending flag; it does not award. A subsequent stable player-turn or reload must find the city actually removed.
- `GameEvents.CityCaptureComplete(oldOwner,wasCapital,x,y,newOwner,...)` occurs after building/territory transfer and city recreation. It updates ownership at coordinates, never rewards capture and immediately strips transferred controllers.
- `GameEvents.PlayerCityFounded(owner,x,y)` starts a fresh observed lifetime and settles an older destroyed lifetime at the same coordinates. `PlayerLiberated` updates the resulting city.
- `GameEvents.PlayerDoTurn(owner)` refreshes only that owner's city list and checks indexed pending removals. `Events.NewGameTurn` supplies one shared city-list world reconciliation, including minor and eliminated-player slots. Missing entries are checked against the actual plot city; a surviving transfer is not destruction.

Identity is coordinates, engine `GetGameTurnFounded`, original owner as first observed, and a persisted monotonic lifetime serial. The local city ID is diagnostic data, not permanent identity. `acquireCity` is source-verified to preserve founding turn and can change OriginalOwner without destruction; that change alone never creates a Flame. Observed same-turn refounding with a recycled local ID creates a fresh serial. Last-owner major/minor classification does not require the old owner to remain alive. Covenant-founded lifetimes are conservatively excluded forever to prevent farming, including after later foreign ownership. Originally minor cities later destroyed under major ownership otherwise qualify.

The system cannot reconstruct a city created, transferred and killed entirely between observable hooks/snapshots. Bypassed capture hooks use the last reliably observed owner. Known script-killed cities without a raze callback are detected at the next global reconciliation/reload. There is no claimed raw CityDestroyed hook: `CvCity::kill` has none, and native captures also delete/recreate objects. Full discussion is in the civilization README.

## Save mechanism and yield reconciliation

`Player:GetScriptData` / `SetScriptData` hold `[CWC3_COVENANT_V1:...]` on the lowest-slot human Covenant player. CP151 binds both methods and serializes `m_strScriptData` in the player visitor. The namespace preserves other mods' data and stores Flames, sequence, at most twelve awarded identities, and current/pending city snapshots. Multiple human Covenants configured from game creation share these global rules and one discovery ledger. Eliminated storage players retain their record.

Load restores the saved state before comparing current cities, then repairs gameplay yields. No state depends solely on globals or unpersisted MapModData. There are no random calls, instant yields or visibility changes. Unchanged state avoids serialization and ScriptData writes. World enumeration happens once per global turn; owner-local lists and indexed candidates provide bounded recovery between those passes. The stored snapshot set is bounded by observed live cities plus pending removals, and the credited ledger by the twelve-Flame cap.

Twelve distinct +1 Culture controllers and four +1 Science controllers exist solely in the current valid Covenant Capital. Two independent Hall Science controllers activate at 3 and 9 Flames in every eligible Covenant Hall. Each reconciliation writes exact zero/one desired counts, clears illicit free copies without refunds and suppresses construction rewards. Dummies cannot be built/purchased, are hidden via CP `IsDummy`, cost no maintenance, have no secondary companions and never capture. Former Capitals, transferred Hall cities, Hall removal/purchase and reload are repaired through direct hooks plus periodic recovery. Capital loss never resets Flames. No valid Capital means inactive UA yields until one exists.

Hall permanent Culture is a SQL delta of exactly one across inherited records. At nine Flames/six Halls, capital UA 9 Culture/3 Science plus Halls 6 Culture/12 Science equals **15 Culture and 15 Science**, independently of normal Temple yields. PlayerDoTurn reconciliation is explicitly post-economy and controls the next valid payout; NewGameTurn UI dispatch synchrony remains unverified. No instant compensation is attempted.

## Eternal Vigil and active CP inheritance

The SQL clones `SELECT *` from **active `UNIT_PIKEMAN` / `BUILDING_TEMPLE`** at mod activation, then clones every one of the schema audit's 27 unit/145 building companions, including native unit selection sounds. No vanilla scalar approximation is substituted. Only unique presentation, one extra Hall Culture and the Keeper's extra promotion differ. Resources, maintenance, production, technology, obsolescence, upgrade path, specialists, requirements, class interactions, AI and native unit world art remain inherited.

Permanent Eternal Vigil has `VisibilityChange=1`, `LostWithUpgrade=0`. A distinct transient promotion has `DefenseMod=15`, `AttackMod=0`, `CombatPercent=0`, `FriendlyLandsModifier=0`. Lua uses verified `Plot:IsFriendlyTerritory(owner)`, including native own/team/Open Borders rules. Neutral/enemy territory does not activate it. `UnitSetXY`, `UnitCreated`, post-promotion-transfer `UnitConverted`, tile ownership, reload and bounded veteran recovery repair the toggle. Native conversion preserves the lineage; the transient promotion is reconstructed after upgrade without adding Sight or stacking modifiers.

The verified `BattleStarted(type,x,y)` macro runs at the start of melee/unit-ranged/city-ranged/air combat generation, before strength/damage evaluation. It refreshes target veterans after silent diplomacy changes. SQL enables `EVENTS_BATTLES`; no VP option is enabled. Pinned source proves attack strength excludes `getDefenseModifier`, melee defense includes it, and ranged strength reads it only in the nonattacking branch. The Lua mock verifies conditional activation; this source audit establishes modifier branch separation. Actual game combat/preview testing remains required, especially previews after diplomacy changes before the next repair.

## Automated checks and art

The complete pack validator covers clean/pristine/mutated source-derived schema fixtures and supplementary caches, unchanged native records, all approved companions, artificial third-party schema contamination and byte-identical regeneration of all nineteen generated SQL outputs, all Lua syntax under Lua 5.1, all five civilization suites, DDS dimensions/alpha/mips and exact manifest/ZIP contents. Covenant cases cover thresholds, ownership/destruction timing, multiple/pending/remapped lifetimes, namespace persistence/reload, elimination, capital/Hall changes, idempotence, source-backed defense registration, nonzero human slot and 34 majors with a Marathon binding. Mocks do not emulate native economic settlement or final active CP balance data.

Build/check commands from Wacky3:

Final automated result on 9 November 2026:

| Check | Result |
| --- | --- |
| Pinned CP151 source audit and unchanged 260-source schema inventory | PASS |
| Pristine/mutated clean fixture and both supplementary caches | PASS — six SQLite baselines |
| Active Pikeman/Temple scalar and all 172 companion inheritance | PASS, including duplicate inherited Culture rows |
| Clean/contaminated regeneration | PASS — nineteen SQL outputs byte-identical |
| Lua 5.1 syntax | PASS — sixteen Lua files |
| Covenant production Lua | PASS — 2,103 assertions each at 4 majors/slot 0 and 34 majors/slot 3; 4,206 total |
| Ministry, Choir, Summer and Timetable regressions | PASS — all existing suites |
| Manifest, contexts, checksums, DDS and installable ZIP | PASS — 189 manifest files, 24 DB actions, five contexts, 126 DDS assets |
| Native CP151 Civ V | NOT RUN — checklist remains outstanding |

```powershell
python tools/generate_covenant.py
python tools/build_covenant_art.py
python tools/validate_covenant.py
python tools/build_mod.py --package
python tools/validate_mod.py --compare-database "$env:USERPROFILE\Documents\My Games\Sid Meier's Civilization 5\cache\Civ5DebugDatabase.db"
```

Original Seraphine and candle-emblem art was produced with the **built-in image_gen tool**. Final PNG masters, complete prompts and `ArtReview.png` are retained under `Wacky3/TheCandlekeepersCovenant/Art/Sources/`. The deterministic compiler creates 27 full-mip portrait/alpha atlases plus three scene/Dawn/map DDS images. The static leader XML resolves a real imported texture. Native Pikeman/Temple portraits and world art are intentional; no art requirement is left referencing a nonexistent DDS. No custom animated leader/voice is required.

## Native tests still necessary

Run the full [acceptance checklist](CovenantTesting.md): human selection and new-game initialization; controlled repeated capture/raze/script/ownership/refound/elimination cases; real save/reload and capital relocation; all threshold economic payouts; six-Hall totals; active Pikeman/Temple inheritance; actual melee/ranged defensive and offensive modifiers on own/team/Open Borders/neutral/enemy land; normal upgrade persistence; diplomacy changes; all icons/Dawn/leader/diplomacy presentation; large Marathon operation; and all prior civilizations. Do not mark these native tests passed based on source assertions or mocks.

## Files created and modified

All paths below are repository relative. Existing civilizations' gameplay/SQL/art files are unchanged. The shared fixture helper only gains parameterized sample selection; the core schema/source inventory pin and prior companion inventories are unchanged. The existing manifest keeps its GUID/version/save minimum.

<!-- FILE_INVENTORY -->

```text
Wacky3/CHANGELOG.md
Wacky3/Cool Wacky Civs 3 (v 1).modinfo
Wacky3/README.md
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Alpha128.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Alpha16.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Alpha24.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Alpha256.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Alpha32.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Alpha45.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Alpha48.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Alpha64.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Alpha80.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Civ128.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Civ16.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Civ24.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Civ256.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Civ32.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Civ45.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Civ48.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Civ64.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Civ80.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Dawn.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Leader.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Leader128.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Leader16.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Leader24.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Leader256.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Leader32.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Leader45.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Leader48.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Leader64.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Leader80.dds
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_LeaderScene.xml
Wacky3/TheCandlekeepersCovenant/Art/CWC3_Covenant_Map.dds
Wacky3/TheCandlekeepersCovenant/Art/Sources/Alpha.png
Wacky3/TheCandlekeepersCovenant/Art/Sources/ArtReview.png
Wacky3/TheCandlekeepersCovenant/Art/Sources/Emblem.png
Wacky3/TheCandlekeepersCovenant/Art/Sources/GenerationPrompts.json
Wacky3/TheCandlekeepersCovenant/Art/Sources/Leader.png
Wacky3/TheCandlekeepersCovenant/Art/Sources/README.md
Wacky3/TheCandlekeepersCovenant/Lua/CWC3_Covenant.xml
Wacky3/TheCandlekeepersCovenant/Lua/CovenantGameplay.lua
Wacky3/TheCandlekeepersCovenant/README.md
Wacky3/TheCandlekeepersCovenant/SQL/Covenant_Art.sql
Wacky3/TheCandlekeepersCovenant/SQL/Covenant_Buildings.sql
Wacky3/TheCandlekeepersCovenant/SQL/Covenant_Civilization.sql
Wacky3/TheCandlekeepersCovenant/SQL/Covenant_Text.sql
Wacky3/TheCandlekeepersCovenant/SQL/Covenant_Units.sql
Wacky3/docs/CovenantImplementationReport.md
Wacky3/docs/CovenantTesting.md
Wacky3/docs/strategy/TheCandlekeepersCovenant.md
Wacky3/tools/Validation.json
Wacky3/tools/audit_cp.py
Wacky3/tools/build_covenant_art.py
Wacky3/tools/build_mod.py
Wacky3/tools/cp151_sources.json
Wacky3/tools/generate_covenant.py
Wacky3/tools/target_schema.py
Wacky3/tools/tests/covenant.lua
Wacky3/tools/timetable_fixture.py
Wacky3/tools/validate_covenant.py
Wacky3/tools/validate_mod.py
Wacky3/tools/validate_schema.py
```
