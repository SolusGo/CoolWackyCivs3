# Community Patch v151 compatibility evidence

Target: standalone `(1) Community Patch`, UUID `d1b6328c-ff44-4b0d-aad7-c657f83610cd`, mod version **151**. The installed manifest identifies its package as 5.4.6. BNW DLC UUID is `6DA07636-4123-4018-B643-6575B4EC336B`. Wacky3 uses GUID `70d794f7-4fb2-4196-9709-8193f8ee36a9`. The mod dependency constrains CP to min/max 151. No VP balance option is enabled.

Source pin: [`44c1e14ff75d80c1dba5c8a71e8289439a53aafb`](https://github.com/LoneGazebo/Community-Patch-DLL/tree/44c1e14ff75d80c1dba5c8a71e8289439a53aafb). `CustomMods.h` reports `MOD_DLL_VERSION_NUMBER ((uint) 151)`. `tools/cp151_sources.json` records individual raw source URLs and SHA256 hashes. `audit_cp.py --fetch` reconstructs ignored references, then verifies both hashes and concrete source assertions. This is the CP151 source identification used here; it is not a claim that the user's installed compiled DLL has been binary-reproduced from that commit.

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

The options file enables `EVENTS_CITY`, `EVENTS_TILE_IMPROVEMENTS`, `EVENTS_UNIT_CREATED`, `EVENTS_UNIT_UPGRADES`, `EVENTS_LIBERATION` and `EVENTS_UNIT_CONVERTS`. These are documented CP151 events. `UnitSetXY`, `CityCaptureComplete`, `PlayerCityFounded` and `PlayerDoTurn` use existing hooks. The pack adds one XML InGameUIAddin context and imports its Lua/helper/art through VFS. SQL activation order is options → civilization → unit → building → localization → art, after the CP dependency.

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

The hardening run tests two read-only source caches, each with both pristine and mutated source-definition cases:

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
