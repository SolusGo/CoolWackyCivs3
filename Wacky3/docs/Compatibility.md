# Community Patch v151 compatibility evidence

## Current ten-civilization extension — 12 November 2026

The current pack registers ten human-only civilizations, **49 unique database actions** and **ten gameplay contexts**. Four archived additions reuse the established pinned schema/clone/runtime architecture; the previously implemented Directorate is retained, with total real/free Library/University class eligibility corrected. The original five civilization gameplay files, all 260 schema pins, 172 approved companion definitions, mod GUID, CP151 dependency, version 1 and save minimum/format are preserved.

See [ArchivedDailyTesting.md](ArchivedDailyTesting.md) for exact combat, Farm, Walls, trade-route and excavation source contracts, clean/supplementary database provenance, complete automated and native matrices, economic timing and limitations. `archived_sources.json` adds one pinned CP151 trade source plus data-only native samples; no schema repinning or VP balance dependency is introduced. All five archived civilizations now use original portrait/atlas/flag/Dawn/capital/static-diplomacy artwork; native unit/building world models remain inherited. See [ArchivedArtReport.md](ArchivedArtReport.md). DDS validation and gameplay regressions remain active.

**Native Civ V acceptance has not been run.** The source fixture is a clean schema with selected sample data, not final CP gameplay data. Owner-turn reconciliation occurs after native economic collection and applies to the next payout. Existing saves have not been acceptance-tested with this roster; use a new game for the added civilizations. Historical sections below record earlier stages and their then-current counts.

## Timetable extension — 6 November 2026

The fourth civilization reuses the same CP151 schema inventory, runtime setter, options and single-pack build. No previous civilization mechanic changes. New source-verified bindings, independent strict rail search, data-only fixture additions and explicit post-economy next-payout timing are documented in [TimetableTesting.md](TimetableTesting.md). The original 13 DLL hashes remain; a reviewed `CvLuaMap.cpp` at the same commit makes 14. The existing 260 schema source hashes and all 172 companions remain byte-identical. Two additional native Worker sample-data files have separate hashes in `timetable_fixture.py`; no schema repinning was performed.

The current pack has four InGameUIAddin contexts and 19 database actions. Timetable loads after Summer (civilization → units → buildings → text → art), with each entry point once. Normal connections use the native capital-connection flag; rail rewards use owned intact land-track reachability only. Source-backed API tests and Lua behavior mocks pass; native ordinary-connection cache freshness and real payouts still need acceptance. No pre-payout or UI-dispatch timing claim is added by this extension. Historical evidence below describes its original audited roster.

Target: standalone `(1) Community Patch`, UUID `d1b6328c-ff44-4b0d-aad7-c657f83610cd`, mod version **151**. The installed manifest identifies its package as 5.4.6. BNW DLC UUID is `6DA07636-4123-4018-B643-6575B4EC336B`. Wacky3 uses GUID `70d794f7-4fb2-4196-9709-8193f8ee36a9`. The mod dependency constrains CP to min/max 151. No VP balance option is enabled.

Source pin: [`44c1e14ff75d80c1dba5c8a71e8289439a53aafb`](https://github.com/LoneGazebo/Community-Patch-DLL/tree/44c1e14ff75d80c1dba5c8a71e8289439a53aafb). `CustomMods.h` reports `MOD_DLL_VERSION_NUMBER ((uint) 151)`. `tools/cp151_sources.json` records individual raw source URLs and SHA256 hashes. `audit_cp.py --fetch` reconstructs ignored references, then verifies both hashes and concrete source assertions. This is the CP151 source identification used here; it is not a claim that the user's installed compiled DLL has been binary-reproduced from that commit.

## Schema correction — 3 November 2026

The old generators and inheritance tests enumerated broad table prefixes from modded caches. This incorrectly made **Building_JFD_District** and **Building_ConstructionAudio** mandatory dependencies in both building SQL files. Neither table is declared by the audited BNW/standalone CP151 sources. Their original supplying mods are not established here; the JFD name alone is not provenance evidence. Only those two four-statement clone blocks were removed from each building file. All other generated civilization/unit SQL is byte-identical.

`tools/target_schema.py` now derives the target from native base/G&K/BNW XML table definitions, native selection-sound and localization declarations, and the installed CP151 manifest's XML/SQL DDL in activation order. It retains not-null/unique/primary-key constraints, defaults, SQL table replacements/renames, indexes and triggers. It verifies CP schema-file MD5s against the v151 package manifest and pins **260 installed source SHA256s** plus the resulting column inventory in `tools/cp151_schema_sources.json`. These installed-schema hashes are distinct from the 13 upstream DLL source pins above; upstream identity of every installed schema file is not claimed. Normal generation/auditing fails if source hashes or the derived inventory change. `--pin` is an explicit audit/update operation, not a routine build step.

The approved inventory is **145 BuildingType companions and 27 UnitType companions**, including native `UnitGameplay2DScripts`. No unfamiliar CP table was removed: legitimate instant yields, plot yields, Great Work effects, prerequisites, flavors, resources and unit promotion/upgrade tables remain. The complete names and column definitions are in the schema pin file. Both generators obtain their inventory from this target alone, independent of `CWC3_DATABASE`. See the [complete repair report](CP151SchemaRepair.md) for implementation, results and file purposes.

The new priority fixture reconstructs **808 tables** (including SQLite's sequence table) with only verified target schema, selected native XML rows and **329 synthetic companion records** exercising otherwise-empty tables. It does not import any cache schema or third-party table. It deliberately does not replay CP data migrations/balance SQL or reconstruct a final native gameplay database: this demonstrates clean **schema** compatibility, not clean native runtime acceptance. Both pristine and mutated fixtures execute all ten Wacky3 SQL actions. The previous four cache cases remain supplementary tests, for **six SQL runs total**.

Contamination regression adds `Building_JFD_District` and an artificial `Unit_ThirdPartySchemaRegression` table, reruns both generators, and compares all seven output files byte for byte. It also checks that every approved companion remains emitted. Missing-table negative controls demonstrate that the clean fixture detects the original defect. The 365 Choir and 180 Ministry assertions, eight Lua51 syntax checks, source audit, manifest/DDS checks and distributable byte checks remain intact.

An external CP package typo was observed: its activation list references `Database Changes/Text/en_US/CoreGameOptionTextChanges.xml`, which is absent; the corresponding `.sql` contains only a localization UPDATE. The schema builder explicitly skips this one absent text action. It does not invent or change the external file. This does not affect Wacky3's target schema, but native package loading/logs still need acceptance.

## APIs and tables

| Concern | Verified source | Implementation |
| --- | --- | --- |
| Researched technologies | `CvLuaTeam.cpp`: `Method(IsHasTech)`; binding calls `GetTeamTechs()->HasTech(eTech)` | Enumerate valid `GameInfo.Technologies` IDs once per distinct team at the snapshot; no guessed direct count binding |
| Persistent player state | `CvLuaPlayer.cpp`: Get/SetScriptData bindings | Namespace-delimited last-turn/tier only; preserve surrounding ScriptData |
| City building counts | `CvLuaCity.cpp`: GetNumBuilding / GetNumRealBuilding / SetNumRealBuilding / GetNumFreeBuilding / SetNumFreeBuilding | Real counts zero/one; free controller copies cleared; explicit bNoBonus=true, bRefund=false, bValidate=false; no instant yield calls |
| Defense-only modifier | `CvPromotionClasses.cpp`: reads `DefenseMod`; `CvUnit.cpp`: GetMaxDefenseStrength adds getDefenseModifier | Conditional `DefenseMod=15`; attack and generic friendly-land modifiers remain zero |
| Friendly territory ambiguity | `CvPlot.cpp`: IsFriendlyTerritory includes foreign Open Borders land | Compare actual tile owner's team to unit owner's team, excluding foreign/neutral tiles |
| Upgrade identity | `CvUnit.cpp`: UnitUpgraded is **before** convert; UnitConverted is after promotion transfer, before old-unit kill | Identity LostWithUpgrade=0; post-transfer conditional defense repaired by UnitConverted |
| Movement and ownership | `CvUnit.cpp`: UnitSetXY after movement; `CvPlot.cpp`: TileOwnershipChanged after m_eOwner assignment | Reconcile affected unit/tile only |
| Building sale | `CvDllNetMessageHandler.cpp`: DoSellBuilding precedes CitySoldBuilding | Remove Academy Production after sale |
| Founding/acquisition | `CvPlayer.cpp`: PlayerCityFounded / unconditional CityCaptureComplete inside acquireCity | Conquest, gifts, peace trades/cessions and liberation share completion; query actual plot city rather than old city IDs |
| Liberation | `CustomMods.h` / `CvPlayer.cpp`: PlayerLiberated | Reconcile the liberated player's city |
| Dummy visibility | Installed CP151 `BuildingTableChanges.sql`: IsDummy and ShowInPedia | IsDummy=1, ShowInPedia=0, Cost/FaithCost=-1, GreatWorkCount=-1, NeverCapture=1, ConquestProb=0 |
| Baseline preservation | Installed BNW database plus CP151 schema XML/SQL | Runtime SELECT * clone and inventory-generated companion copies |
| Unit selection sound | Native UnitGameplay2DScripts table | Explicit active-row clone outside the Unit_ table-name prefix |
| Optional economic observations | Verified player Culture/research stores and city queue/Production bindings | Read-only, disabled by default, bounded in-memory trace; never used to award or compensate yields |

The options file enables `EVENTS_CITY`, `EVENTS_TILE_IMPROVEMENTS`, `EVENTS_UNIT_CREATED`, `EVENTS_UNIT_UPGRADES`, `EVENTS_LIBERATION` and `EVENTS_UNIT_CONVERTS`. These are documented CP151 events. `UnitSetXY`, `CityCaptureComplete`, `PlayerCityFounded` and `PlayerDoTurn` use existing hooks. The pack has two XML InGameUIAddin contexts and imports Lua/helper/art through VFS. SQL activation order is options → Ministry civilization/unit/building/localization/art → Choir civilization/unit/building/localization, after the CP dependency. This repair changes no hook, GUID, version, save format, balance or artwork.

## Owner-turn timing: evidence and unresolved boundary

`CvPlayer::doTurnPostDiplomacy` processes every city's turn, collects Culture, calls `doResearch`, then calls the Lua `PlayerDoTurn` hook. **That event is too late to establish the requested pre-collection snapshot.** Wacky3 never recalculates the tier there.

`CvGame::doTurn` increments the turn, calls `PublishNewGameTurn`, then later activates the first sequential player through `setTurnActive(true)`. Wacky3 locates actual human Ministry owners, then permits a `NewGameTurn` snapshot only if the owner is the **first living sequential player**. Earlier dead slots are ignored. A higher-slot Ministry with an earlier living player gets a one-time warning; its previous saved tier is retained, with no early snapshot.

`CvPlayer::setTurnActive` publishes `TURN_START` before calling `doTurn`. However, this does **not** prove that `Events.AIProcessingStartedForPlayer` is delivered synchronously, or even as the needed human-owner boundary. The former snapshot fallback has been removed; the event is diagnostic-only. `ActivePlayerTurnStart` is published after `doTurn` and is also observation-only. `GameCoreUpdateBegin` is a direct hook before a game update, but is per-update rather than per-owner; players may advance within one update. Using it would require polling or sampling at a different boundary, so it was not substituted.

**The closed engine's delivery of UI notifications cannot be proven synchronous from these DLL sources.** An in-game trace must show that Lua snapshot and dummy changes precede Production, Culture and Science settlement. If `PlayerDoTurn` or `ActivePlayerTurnStart` has already been observed for the current owner-turn, a later candidate snapshot is rejected; it cannot change the tier mid-turn. Stale turn-number notifications are ignored. This rejection preserves the previous snapshot and is an explicit failed timing criterion, not a successful substitute. No instant-yield compensation is used. An exact general-purpose solution may need a verified additional pre-economy hook; custom DLL changes remain outside scope.

The initial turn normally has equal starting technologies and no UA. Reload never recalculates technologies. It now reconciles **all four** real/free controller counts against the saved turn/tier, including corrupted Ministry counts and foreign leaks. Missing/invalid records conservatively give tier zero until a valid boundary; legitimate version 1 records keep their format and turn. Turn/tier are saved before city writes, unchanged records are not rewritten, and repeated notifications cannot resnapshot. Mid-turn research and leader changes wait until the next valid boundary.

Reconciliation is guarded across the entire transaction. The native acquisition completion follows building copy and plot ownership updates for all acquireCity modes. Watched city **coordinates** recover missed transfers even when native acquisition replaces the city object/ID; dirty callbacks visit those coordinates, not the whole world. One owner-local city pass runs at PlayerDoTurn for recovery. An initial scan seeds tracked veteran IDs; movement/conversion callbacks update them, and owner turns revisit only tracked veterans. No per-frame callback is registered. Tech enumeration remains O(distinct eligible teams × technologies), once at a valid snapshot.

## Exact event contracts checked

These arguments are verified against invocation sites and/or CP151 declarations, not inferred from other events:

| Event | Signature and order |
| --- | --- |
| UnitSetXY | player, unit ID, x, y; invoked after position change |
| UnitCreated | player, unit ID, unit type, x, y; after initial free promotions |
| UnitUpgraded | player, old unit ID, new unit ID, goody-hut boolean; **pre-conversion** |
| UnitConverted | old player, new player, old unit ID, new unit ID, upgrade boolean; **post-promotion-transfer** |
| TileOwnershipChanged | x, y, new owner, old owner; after m_eOwner assignment |
| PlayerCityFounded | player, x, y |
| CityCaptureComplete | old owner, capital boolean, x, y, new owner, population, conquest boolean, great-work counters; all acquireCity modes |
| PlayerLiberated | liberator, liberated player, new city ID |
| CityConstructed | player, city ID, building type, Gold purchase boolean, Faith purchase boolean |
| CitySoldBuilding | player, city ID, building type; after sale |

Both ordinary and goody upgrades are exercised in source-ordered mocks. SQL retains identity LostWithUpgrade=0 and conditional defense LostWithUpgrade=1. `DefenseMod` is used by melee defense and by the non-attacking ranged-strength branch; melee attack does not read that modifier. The Guard's extra Movement remains only in its unit row.

## Database provenance and schema discrepancy

In addition to the source-derived clean schema fixture above, validation retains two read-only source caches, each with both pristine and mutated source-definition cases:

| Source | Original tables | Civilizations | Treatment |
| --- | ---: | ---: | --- |
| cache_backup/Civ5DebugDatabase.db | 491 | 120 | BNW-derived modded cache; CP151 schema overlay in memory only |
| cache/Civ5DebugDatabase.db | 959 | 194 | Existing CP-schema modded cache; **no schema overlay or option replacement** |

Neither is a clean CP-only capture. Both have the same relevant unmodified values: Library Cost 75, Maintenance 1, Writing, no specialists; Spearman Combat 11, Moves 2, Cost 56, Bronze Working. The emitted SQL works against the actual existing schema, and clones inherit source values rather than these numbers being hardcoded in gameplay. Mutation cases alter cost, maintenance, strength and Movement and add existing Library Culture, proving complete scalar/companion inheritance plus the intended unique deltas. Pristine cases also cover the no-existing-Culture insertion branch. Temporary clones are dropped, native rows remain unchanged, and selection sound rows are compared too. A fresh clean BNW+CP151 cache is still needed for final load acceptance.

## Explicit compatibility limits

- No game was launched for this implementation. Yield settlement timing, native ScriptData persistence and combat-preview/event order require the manual checklist.
- The two supplied database sources are modded caches, not a freshly captured clean CP-only gameplay database. Their exact provenance and differing schema sizes are reported above and in Validation.json.
- Other mods can replace ScriptData, remove identity promotions, alter event order or mutate inherited rows after this pack loads. Such combinations are untested.
- UI city-info dirtiness reconciles scripted Academy removal; ordinary building construction/sale and acquisition have direct hooks. Arbitrary direct native mutations bypassing all relevant hooks are outside certification.
- Embarked defense follows native separate rules. No multiplayer/hotseat determinism claim is made; those modes are disabled in the manifest.
