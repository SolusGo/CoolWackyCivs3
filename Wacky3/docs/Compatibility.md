# Community Patch v151 compatibility evidence

Target: standalone `(1) Community Patch`, UUID `d1b6328c-ff44-4b0d-aad7-c657f83610cd`, mod version **151**. The installed manifest identifies its package as 5.4.6. BNW DLC UUID is `6DA07636-4123-4018-B643-6575B4EC336B`. Wacky3 uses GUID `70d794f7-4fb2-4196-9709-8193f8ee36a9`. The mod dependency constrains CP to min/max 151. No VP balance option is enabled.

Source pin: [`44c1e14ff75d80c1dba5c8a71e8289439a53aafb`](https://github.com/LoneGazebo/Community-Patch-DLL/tree/44c1e14ff75d80c1dba5c8a71e8289439a53aafb). `CustomMods.h` reports `MOD_DLL_VERSION_NUMBER ((uint) 151)`. `tools/cp151_sources.json` records individual raw source URLs and SHA256 hashes. `audit_cp.py --fetch` reconstructs ignored references, then verifies both hashes and concrete source assertions. This is the CP151 source identification used here; it is not a claim that the user's installed compiled DLL has been binary-reproduced from that commit.

## APIs and tables

| Concern | Verified source | Implementation |
| --- | --- | --- |
| Researched technologies | `CvLuaTeam.cpp`: `Method(IsHasTech)`; binding calls `GetTeamTechs()->HasTech(eTech)` | Enumerate valid `GameInfo.Technologies` IDs once per distinct team at the snapshot; no guessed direct count binding |
| Persistent player state | `CvLuaPlayer.cpp`: Get/SetScriptData bindings | Namespace-delimited last-turn/tier only; preserve surrounding ScriptData |
| Real city buildings | `CvLuaCity.cpp`: GetNumBuilding / GetNumRealBuilding / SetNumRealBuilding | Absolute zero/one dummies, no instant yield calls |
| Defense-only modifier | `CvPromotionClasses.cpp`: reads `DefenseMod`; `CvUnit.cpp`: GetMaxDefenseStrength adds getDefenseModifier | Conditional `DefenseMod=15`; attack and generic friendly-land modifiers remain zero |
| Friendly territory ambiguity | `CvPlot.cpp`: IsFriendlyTerritory includes foreign Open Borders land | Compare actual tile owner's team to unit owner's team, excluding foreign/neutral tiles |
| Upgrade identity | `CvUnit.cpp`: conversion retains non-lost promotions; UnitUpgraded fires after new-unit conversion | Identity LostWithUpgrade=0; conditional defense recomputed after upgrade |
| Movement and ownership | `CvUnit.cpp`: UnitSetXY after movement; `CvPlot.cpp`: TileOwnershipChanged after m_eOwner assignment | Reconcile affected unit/tile only |
| Building sale | `CvDllNetMessageHandler.cpp`: DoSellBuilding precedes CitySoldBuilding | Remove Academy Production after sale |
| Founding/acquisition | `CvPlayer.cpp`: PlayerCityFounded / CityCaptureComplete | Query actual plot city, use saved receiving-player tier; captured-away city is cleared |
| Liberation | `CustomMods.h` / `CvPlayer.cpp`: PlayerLiberated | Reconcile the liberated player's city |
| Dummy visibility | Installed CP151 `BuildingTableChanges.sql`: IsDummy and ShowInPedia | IsDummy=1, ShowInPedia=0, Cost/FaithCost=-1, GreatWorkCount=-1, NeverCapture=1, ConquestProb=0 |
| Baseline preservation | Installed BNW database plus CP151 schema XML/SQL | Runtime SELECT * clone and inventory-generated companion copies |

The options file enables `EVENTS_CITY`, `EVENTS_TILE_IMPROVEMENTS`, `EVENTS_UNIT_CREATED`, `EVENTS_UNIT_UPGRADES`, `EVENTS_LIBERATION` and `EVENTS_UNIT_CONVERTS`. These are documented CP151 events. `UnitSetXY`, `CityCaptureComplete`, `PlayerCityFounded` and `PlayerDoTurn` use existing hooks. The pack adds one XML InGameUIAddin context and imports its Lua/helper/art through VFS. SQL activation order is options → civilization → unit → building → localization → art, after the CP dependency.

## Owner-turn timing: evidence and unresolved boundary

`CvPlayer::doTurnPostDiplomacy` processes every city's turn, collects Culture, calls `doResearch`, then calls the Lua `PlayerDoTurn` hook. **That event is too late to establish the requested pre-collection snapshot.** Wacky3 never recalculates the tier there.

`CvGame::doTurn` increments the turn, calls `PublishNewGameTurn`, then later activates the first sequential player through `setTurnActive(true)`. The normal supported single-player human is in that first slot. Wacky3 snapshots this first living player on `Events.NewGameTurn`. `CvPlayer::setTurnActive` also publishes `TURN_START` before calling `doTurn`; `Events.AIProcessingStartedForPlayer` is used as an additional guarded turn-status route for an active Ministry owner. The game UI uses that notification to update player turn status.

**The closed engine's delivery of those UI notifications cannot be proven synchronous from these DLL sources.** An in-game trace must show that the Lua snapshot and dummy changes execute before city Production, Culture and Science settlement. If queued delivery occurs after settlement, this implementation fails that exact acceptance criterion and must not be represented as complete. It does not compensate with artificial payouts or silently adopt a one-turn lag. Later-slot humans and unusual turn modes are not certified. An exact general-purpose solution may need a verified additional pre-economy hook; custom DLL changes are outside this task's scope.

The initial turn normally has equal starting technologies and no UA. No reload initialization recalculates technologies. Turn/tier are saved before city writes and the last-turn guard suppresses repeated notifications. Building counts are native save state. Mid-turn tech gains, unmet rivals, elimination and changes in leadership affect only the next valid snapshot. Tech enumeration is O(distinct eligible teams × technology definitions), once at that boundary, rather than once per city. Reconciliation reads saved state only; no per-frame handler exists.

## Explicit compatibility limits

- No game was launched for this implementation. Yield settlement timing, native ScriptData persistence and combat-preview/event order require the manual checklist.
- The supplied database run uses a real BNW cache with installed CP151 schema overlay, not a freshly captured clean active CP-only gameplay database. Runtime clones preserve actual active values; the test additionally mutates source rows and verifies inheritance. Capture an active CP-only database for final integration verification.
- Other mods can replace ScriptData, remove identity promotions, alter event order or mutate inherited rows after this pack loads. Such combinations are untested.
- UI city-info dirtiness reconciles scripted Academy removal; ordinary building construction/sale and acquisition have direct hooks. Arbitrary direct native mutations bypassing all relevant hooks are outside certification.
- Embarked defense follows native separate rules. No multiplayer/hotseat determinism claim is made; those modes are disabled in the manifest.
