# Archived Daily civilizations: source contracts and acceptance

Target: Windows sequential single-player, BNW plus standalone Community Patch **v151**. No VP balance components or new DLL. Daily designs #002/#007/#013/#016/#020 remain the canonical mechanics. The Directorate already existed at task baseline `f772bb8`; this extension supplies the other four and corrects the Directorate's free-building class eligibility.

## Source proof

All core source references are pinned to [CP151 commit 44c1e14](https://github.com/LoneGazebo/Community-Patch-DLL/tree/44c1e14ff75d80c1dba5c8a71e8289439a53aafb). `tools/cp151_sources.json` and `tools/paleo_sources.json` retain their existing hashes. `tools/archived_sources.json` adds only the reviewed `CvTradeClasses.cpp` hash and data-only native XML/sample hashes. The original 260-file schema pin and all 172 approved companion tables are unchanged. Missing references can be restored with the existing audit commands and `python tools/archived_fixture.py --fetch`.

| Concern | Source and contract | Implementation consequence |
| --- | --- | --- |
| Genuine combat | `CvUnitCombat::ResolveCombat`: `CombatResult` follows abort testing and precedes resolution; `CombatEnded` follows melee/ranged/air resolution. Both push the same 15 arguments. | Snapshot two combat participants before resolution; require matching completion, native lethal final damage and absent/dead victim. No speculative reward on start, disband or canceled combat. |
| Combat arguments | attacking player/unit, attacker damage/final/maxHP, defending player/unit, defender damage/final/maxHP, interceptor player/unit/damage, plot X/Y | Explicit signature matching; city-only and noncombat participants cannot masquerade as combat units. |
| Kill identity | `CvLuaUnit` registers `GetGameTurnCreated`, `IsCombatUnit`, `IsDead`, `GetUnitType`, coordinates and owner APIs. | Persist victim owner/full unit ID/creation turn; city ledger and consumed marker written together. Repeated completions/reloads cannot accumulate Curios. |
| Anti-Barbarian | `CvPromotionClasses` reads `BarbarianCombatBonus`; generic melee and ranged strength check the opposing unit's `isBarbarian()`. | Retrieval Officer has only Sight and +15 against Barbarians. |
| Friendly territory | Generic melee strength uses battle plot `IsFriendlyTerritory`; ranged strength uses own plot. `CvPlot::IsFriendlyTerritory` includes own/team and qualifying Open Borders. | Native +15 attack/defense for the Wicker Sentinel. This matches the Covenant's native-friendly definition; the Ministry keeps its intentionally narrower custom rule. |
| Defense only | Promotion `DefenseMod`; melee defense and non-attacking ranged branch consume it, attack excludes it. | Nubian Bowman +15 only while defending, including against ranged attacks. No CombatPercent or AttackMod delta. |
| Desert strength | `UnitPromotions_TerrainModifiers` loader/application is unconditional CP code. Melee attack reads `pToPlot`; defense reads `pInPlot`; ranged defense reads `pMyPlot`. | Desert Hills and feature tiles qualify. Avoid ordinary `UnitPromotions_Terrains`, whose feature branch can suppress its terrain bonus. Native Horseman no-terrain-defense does not suppress this explicit modifier. |
| Upgrade effects | Native `convert` transfers promotions unless LostWithUpgrade; source-ordered original pack upgrade mocks remain. | New unique promotions have `LostWithUpgrade=0`. Scalars/upgrade rows and inherited promotions are copied from active parents. Dune target semantics cover normal melee mounted descendants, not arbitrary third-party ranged conversions. |
| Farm state | `CvPlot` emits `TileImprovementChanged` after construction/replacement and after pillage/repair state changes, with x/y/owner/old/new/pillaged; tile ownership callback follows owner assignment. | Recount exactly owned/unpillaged Farms in radius three, independent of working status/radius, using at most 37 distinct native hex neighbors. |
| Building classes | `CvLuaCity::GetNumBuilding` queries native total building counts. | Walls and Directorate Library/University accept free and real buildings/replacements, with one Boolean controller per condition. |
| Outgoing route list | `CvLuaPlayer::GetTradeRoutes` skips empty connections and foreign origins; returns `FromID`, actual `FromCity`, `Domain`, actual destination and circuit/recall state. | Binary outgoing land-route origin set prepared once per owner evaluation, excluding sea/incoming/canceled/completed connections. Estimated TurnsLeft does not replace native circuit expiry. |
| Route establishment | `CvUnit::makeTradeRoute` completes `CreateTradeRoute` before `kill(true)`. | Original Caravan `UnitPrekill` refresh observes established connections; returned unit creation is another recovery point. |
| Completion/plunder | `PlayerTradeRouteCompleted` follows completed-circuit detection but precedes clearing. `PlayerPlunderedTradeRoute` follows successful clearing. | Circuit filter removes the finishing route inside the completion callback; plunder recomputes after deletion. Cancellation lacks a universal post-change callback, so dirtiness and bounded reconciliation recover it. |
| Archaeology | Existing `paleo_fixture.py` proves `CvUnit::build` invokes `PlayerBuilt(player,unit,x,y,build)` only in its successful finished branch, before later human artifact/landmark choice and archaeologist consumption. | Retain exact successful-build reward, native artifact record checks, four-speed values, research overflow handling and saved site deduplication. Merely entering a site, canceled digging, death and unrelated changes do not reward. |
| Economic timing | `CvPlayer::doTurnPostDiplomacy` settles cities/research before `PlayerDoTurn`. | Recovery at that event changes the **next payout**. No instant compensation or pre-payout timing claim is introduced. |

The source audit verifies concrete expressions/order against hash-pinned files. It does not compile/run a replacement DLL or prove closed-engine UI dispatch. The extra clean fixture supplies native sample rows and synthetic companion sentinels; it does not replay final CP balance migrations or certify a native clean gameplay cache.

## Automated matrix

Run from Wacky3 with the repository virtual environment or requirements-dev installed:

```powershell
python tools/generate_archived.py
python tools/generate_paleo.py
python tools/build_mod.py --package
python tools/validate_mod.py --compare-database "$env:USERPROFILE\Documents\My Games\Sid Meier's Civilization 5\cache\Civ5DebugDatabase.db"
```

`tools/Validation.json` records actual results. `validate_mod.py` retains all five original civilization suites plus the Directorate suite and adds `validate_archived.py`. It executes clean/pristine and mutated schemas and the available two supplementary caches (neither cache is certified CP-only), checks unchanged native parent/scalar/companion data, every approved inherited table, exact duplicate-yield additions, localization, ten human-only registrations, 49 unique SQL actions and ten gameplay contexts.

Regeneration uses the same schema with and without artificial third-party tables. All 39 generated SQL outputs must match checked-in bytes. SQL generators never enumerate an arbitrary debug database. Lua syntax is parsed under actual Lua 5.1 (`lupa.lua51`). Package checks validate every manifest path, MD5, import flag, VFS basename, XML context, existing DDS dimensions/mip payloads/transparency and ZIP bytes.

| Civilization | Production Lua mock cases |
| --- | --- |
| Department | Zero through four Curios; fifth rejected; duplicate completion/full callback/reload; civilians, no resolution, nonlethal/live victim, distant kill and disband excluded; nearest/tie attribution independent of iterator order; defensive kills; Office remove/rebuild; saved ledger/unrelated ScriptData; capture/liberation/razing/refounding. |
| Scarecrows | Farm counts 0/2/3/5/6/8/9/12, cumulative thresholds, pillage/repair, ownership/border changes, unworked Farms, overlap, capped Bell Gold, Bell removal and foreign controller cleanup. |
| Makuria | No Walls, native Walls, free unique Walls, duplicate real/free representations, final removal; inherited Temple data and defense-only promotion fields. |
| Salt Road | No route, outgoing land, five same-origin routes, incoming, sea, recalled, expired/completed circuits, negative estimated TurnsLeft with still-active circuits, plunder, capture, Exchange conditional removal/permanent preservation. |
| Directorate | Independent Library/University, free/real/replacement inclusion, construction/removal/reload/ownership; successful excavation, cancellation, death, invalid sites/builds/units, duplicates and persisted once-per-site rewards; all four speeds, artifact/landmark choices, research/overflow. |

New archive mocks run all four speeds with four and 34 occupied major slots, 25+ cities per civilization, 100 routes, 1,000+ units and large Farm sets. Adjacency/route call bounds and a failing global unit iterator detect unnecessary map/unit work. New native promotion behavior is checked through SQL invariants and source consumers; mocks do **not** execute native combat calculations. Original suites continue exercising upgrade/conversion order.

## Required native acceptance — NOT RUN

Use a **new game**. Preserve GUID/version/save format, but do not infer compatibility of existing saves with newly added civilizations. The original five gameplay files are unchanged. Existing format/version preservation is not old-save acceptance evidence.

1. Load only BNW, standalone CP151 and Wacky3. Confirm ten selectable human civilizations, no normal AI selection and clean Database.log/Lua.log. Check original leader/civ/unit/building/Dawn/diplomacy presentation for all four additions; inspect Othmar's existing custom art.
2. Department: save at zero, one and four Curios; make real melee, ranged and defensive kills against major enemies and Barbarians inside/outside radius three. Confirm one nearest city per kill and tie behavior, no disband/civilian/aborted reward. Reload, reconstruct the Office, capture/recapture/liberate, raze/refound, and compare actual recurring stores across economic collection.
3. Scarecrows: build, replace, pillage, repair and transfer Farms at every tested threshold; leave Farms unworked and test overlapping radii and map wrapping. Capture a Bell city. Compare actual Culture/Production/Food/Gold. Test Sentinel attack/defense on own/team, qualifying Open Borders, neutral and enemy tiles; verify native battle-location semantics and upgrades.
4. Makuria: construct/purchase/free-grant native and unique Walls, then sell/remove the final member. Confirm per-city Culture/Faith once. Compare Nubian Bowman offensive ranged, defensive melee and defensive ranged previews/resolution. Upgrade and ensure only the intended promotion persists.
5. Salt: establish land/domestic/international routes, stack several origins, use sea/incoming-only routes, recall/cancel/plunder/expire and capture either endpoint. Compare actual controller removal and Exchange permanent yields. Test Escort attacks from Grassland into Desert and Desert into Grassland, defend Desert/Hills/Oasis/Flood Plains and non-Desert, then upgrade along the native mounted line. Test UI timing where cancellation has no direct post-change hook.
6. Directorate: follow [the existing A–T guide](../ThePaleontologicalDirectorate/TESTING.md), including ordinary and hidden sites, both choice outcomes, canceled missions/death, save/reload/deduplication, no selected research and overflow. Add free-only and mixed real/free Library/University cases. Check Quick 17, Standard 25, Epic 38, Marathon 75 Science exactly once per successful completion.
7. Exercise a realistic Marathon game with 25+ cities and as many major slots as the installed DLL actually supports (34 is a mock scenario, not a capacity certification). Preserve saves, logs, turn-by-turn stores and combat evidence. Native serialization, yields, dispatch timing and UI/art require observed results before any native pass is claimed.

Known observation limits: wholly unobservable scripted state changes wait for the next bounded reconciliation; unsupported mod combinations and arbitrary ranged conversion of a Dune Escort are not certified. A third party replacing ScriptData can destroy namespaced records. Unknown custom Directorate speeds disable the excavation reward with an explicit log rather than inventing a payout.
