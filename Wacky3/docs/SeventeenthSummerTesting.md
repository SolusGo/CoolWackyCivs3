# Seventeenth Summer: CP151 evidence and verification

## Hardening audit — 6 November 2026

### A. Confirmed defect

**File/function:** `TheSeventeenthSummer/Lua/SummerGameplay.lua`, `State` and its `PlayerDoTurn` consumer. A syntactically valid record such as `[CWC3_SUMMER:14:1:1050]` loaded at game turn 50 passed validation, but `turn > state.last` could never advance it until turn 1051. The original committed controller was run against the new future-timestamp regression and failed it. The correction preserves valid count/phase, clamps a finite future timestamp to the current turn, and waits for the next identifier before advancing. It never compensates yields or replays the load turn.

Other impossible/malformed records now recover safely: reject overflow, inconsistent count/phase and impossible count/last pairs; prefer an intact record over a malformed duplicate; replace closed malformed records in this namespace only. If no trustworthy record exists, persist zero-count Dormancy with the current turn marked consumed, then start Dormancy turn one on the next valid owner-turn. This is conservative corruption recovery, not reconstruction of lost history. Valid records keep their order among unrelated ScriptData and cause no load-time write. Tests cover seven malformed/overflow cases, duplicates, unrelated namespaces, recovery reloads and progression after repair. Missing state still counts the first valid callback as turn one.

### B. Preventive processing improvements

- `OnUnit` returns before guarded work for ordinary units with neither Summer promotion. `Unit` queries eligibility/phase only for lineage units, and still removes illegal Awakened from ordinary foreign units. Full sweeps receive the native unit object directly rather than looking up its ID again.
- `SweepUnits` performs at most one full unit recovery scan per owner/game-turn. Duplicate or stale callbacks do not repeat it. Bootstrap does not consume that allowance, because the first callback can change the phase. Creation, movement and post-transfer conversion remain immediate repairs. One foreign sweep per turn is deliberately retained to detect illegal promotions inserted without any lifecycle event; replacing it with ancestry-only tracking would lose that recovery behavior.
- City liberation reconciles cities rather than every unit. Unrelated owner turns retain their own city cleanup, including illegal real/free dummies, but no longer walk all watched Summer cities. Summer owner turns recover watched transfers without re-reading their own already-reconciled controller counts. Acquisition/founding and dirtiness remain prompt direct reconciliation paths; no new map scan or polling hook exists. Reentrancy protection and absolute guarded writes remain in place.

Measured Lua-mock API calls, with 20 ordinary foreign units per non-Summer owner and repeated movement/creation/conversion callbacks, compared the original commit with the hardened controller. Serialized gameplay state was identical after both event streams. These are operation counts, not native CPU benchmarks:

| Living majors | Irrelevant unit callbacks | Owner/phase reads before → after | Foreign full scans for duplicate turn callbacks before → after | Controller reads before → after | Watched-coordinate reads before → after |
| --- | ---: | ---: | ---: | ---: | ---: |
| 25 | 10,560 | 31,240 → 0 | 48 → 24 | 1,184 → 32 | 144 → 0 |
| 34 | 14,520 | 43,120 → 0 | 66 → 33 | 1,616 → 32 | 198 → 0 |

Controller/coordinate figures refer to the foreign-turn callback stream; irrelevant unit callbacks performed zero city visits, sweeps or writes in both versions. Persistent regression budgets cover both sizes and require no writes or extra unit scans during repeated same-phase reconciliation with a real Summer Nursery city.

### C. Mechanics verified without gameplay changes

The existing post-economy hook, Phase formula, four durations, first-turn convention, transitions 14/18/31, notifications and next-payout semantics remain intact. All four speeds run three cycles, reloading immediately before/after transitions. City controllers remain mutually exclusive and zero/one, clear free copies, suppress construction bonuses/refunds, cover puppet cities and disappear under foreign ownership. Nursery Gold/Faith purchase, sale, founding, capture/recapture, liberation, replaced city IDs, missed-transfer recovery and reload are exercised. A surviving foreign Nursery keeps its permanent Faith and inherited Granary effects; only controllers are removed.

Native source still shows promotion transfer before `UnitConverted` and old-unit death afterward. Creation, double upgrade, non-upgrade conversion, gifts/returns, illegal foreign Awakened and Dormancy removal are covered. The lineage marker grants no Sight; the unique unit alone changes BaseSightRange, so upgrading uses the destination unit's base Sight. Ordinary units sharing destinations never receive ancestry. Zero-city intervals, war and era fields do not reset valid records.

### D. Compatibility findings

No SQL, generated UI behavior, art, options, GUID, mod version or valid save-record format needed changing. SQL still clones the active CP Spearman/Granary plus all 172 source-approved companion tables; no VP-only API or schema was introduced. Dependencies remain BNW and standalone CP151 only, human-selectable and AI-disabled. The Ministry and Choir gameplay/definitions are untouched.

The two UI scripts match their pinned CP151 originals after formatting and the single intended lineage-filter substitution. The validator compares native and patched rendering across all 16 promotion ownership combinations, trade status and enemy empty selection; Awakened and unrelated promotions are preserved. A narrower replacement was investigated: CP151's panels ignore the visibility fields, their rendering functions run in separate UI contexts, and the friendly panel's InstanceManager is local. No reliable supported addon hook was found for replacing those controls without the same VFS override. Retain both overrides. Their manifest imports and CP dependency are checked statically; actual native filename precedence remains a launch-time acceptance check. Other UI mods overriding these filenames require a separate merge/test.

### E. Verification categories

- **Static/source:** pinned DLL and installed-schema hashes, economic/event order, conversion-before-kill/gift path, native Sight calculation, Lua 5.1 syntax, unchanged valid save format and dependencies.
- **SQL fixtures:** pristine/mutated source-derived fixture plus two supplementary modded caches (six runs), full scalar/companion inheritance, controller/promotion fields, localization, starts, overrides and exact native fallback art references. These are not a clean native CP gameplay capture.
- **Lua mocks:** all four speed cycles and boundary reloads; additional invalid-state, zero-city, liberation, ownership, conversion and 25/34-major performance tests. Both panel functions are compared with their native equivalents. `tools/Validation.json` contains executed results.
- **Package:** regenerate/compare Summer SQL and UI through their generators, then rebuild the single manifest/ZIP and validate every path, import and checksum. No generated file is hand-edited.
- **In-game:** **not run**. No mock or source result is described as native execution.

### F. Outstanding native acceptance

Launch Civilization V to verify actual economic stores at the documented next payout, combat previews and the upgrade action window, engine save persistence, capture/liberation behavior, native UI/VFS precedence and fallback-art presentation. Other UI mods, direct third-party state replacement, custom speeds, changed durations mid-save, autoplay, multiplayer and hotseat remain uncertified. The existing checklist below is still required. Corrupted historical counts cannot be reconstructed; recovery intentionally waits one boundary rather than risk a duplicate payout.

## Authoritative source boundary

The existing source audit pins Community-Patch-DLL commit `44c1e14ff75d80c1dba5c8a71e8289439a53aafb`, whose `CustomMods.h` identifies DLL version **151**. `tools/audit_cp.py` verifies source hashes and call-site assertions. These are CP151 source conclusions, not evidence of a native game test:

- [`CvPlayer.cpp`](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvPlayer.cpp), `doTurnPostDiplomacy`: city `doTurn`, Culture/research processing, then `PlayerDoTurn`. Summer deliberately schedules **next-payout** yields here. It does not use Ministry's first-player `NewGameTurn` boundary, which still has an unresolved UI dispatch requirement.
- [`CvPromotionClasses.cpp`](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvPromotionClasses.cpp) reads `CombatPercent`. [`CvUnit.cpp`](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvUnit.cpp) applies it with `changeExtraCombatPercent`; `GetGenericMeleeStrengthModifier` feeds both `GetMaxAttackStrength` and `GetMaxDefenseStrength`. `GetMaxRangedCombatStrength` also starts with the extra combat percentage. There is no territory/terrain restriction on the added modifier. Native embarked/civilian defense rules remain native.
- `CvUnit::convert`: retainable promotions survive normal upgrades when `LostWithUpgrade=0`. The marker has no terrain-specific or ranged/melee conversion effects. `UnitCreated(player,id,type,x,y)` follows free promotions. `UnitUpgraded(player,oldID,newID,goody)` is **before** promotion transfer. `UnitConverted(oldPlayer,newPlayer,oldID,newID,isUpgrade)` is **after** transfer and before old-unit kill; Summer uses it to restore Awakened and repair ancestry on upgrades. Gifts also call conversion. Native captured units initialize through the creation path; conversion callbacks cover transferred promotion state. `UnitSetXY` and owner turns provide additional cleanup.
- Acquisition: `PlayerCityFounded(player,x,y)` and unconditional `CityCaptureComplete(oldOwner,capital,x,y,newOwner,population,conquest,...)` after copied buildings/ownership; gifts, cessions and conquest use that acquisition path. `CityConstructed(player,city,building,gold,faith)` and post-sale `CitySoldBuilding(player,city,building)` reconcile the Nursery. `PlayerLiberated(liberator,player,city)` repairs liberated ownership. All required custom event options were already enabled by the pack.
- `CvLuaPlayer.cpp` registers ScriptData read/write and notifications; `CvLuaCity.cpp` exposes real/free building counts, reward suppression and building lookup. `CvLuaGame.cpp` supplies game-turn identifiers. The native/CP schema pins include `BaseSightRange`, dummy flags and the two promotion visibility columns.

The two installed CP151 panels are separately SHA-256 pinned by `tools/generate_summer_ui.py`. The generated copies normalize line endings, indentation and trailing whitespace, and change exactly one promotion-filter condition per script. Native CP panels do not honor `ShowInUnitPanel` themselves. The generated friendly and enemy functions are executed against UI doubles to verify the marker is hidden and Awakened remains visible. Native VFS precedence and actual appearance remain manual acceptance items.

## Automated coverage

`tools/validate_mod.py` includes Summer in the required pack checks:

- Clean source-derived BNW/CP151 schema fixture and supplementary modded database caches, with pristine and mutated source rows. The fixture is not a reconstructed native CP gameplay database. No clean CP-only database capture is claimed.
- Spearman and Granary scalar equality except intended changes, every approved companion table, synthetic nonempty companion sentinels, no native-row mutations, permanent Faith insertion/addition, four zero/one dummy definitions, promotion fields, human-only registration, starting data and localization.
- Deterministic SQL regeneration despite contaminating third-party schema; Summer's generator is included in the inventory check.
- Production Lua 5.1 execution at all four speeds for three complete cycles, including Standard transitions 14/18/31, initial game-turn zero, duplicate/stale events, saves before/after transitions and owner slot two with earlier living players. Mocks simulate economic collection **before** the callback and verify the previous phase pays while the next payout is scheduled.
- Founding, capture/recapture, Nursery construction/purchase/sale/scripted removal in both phases; foreign real/free dummy cleanup; reentrant dirty events; Shellguard creation, two upgrades, ordinary units sharing upgrade targets, gifts/return, Dormancy removal, AI ineligibility and reload cleanup.
- Source hashes/event ordering, promotion rendering functions, all Lua syntax, dependency/order/entrypoint checks, localization, native fallback inheritance, VFS basenames, manifest hashes and exact ZIP bytes.

Mocks cannot prove native event dispatch, economic settlement, save serialization or UI override loading. They verify the production code under the source-derived contracts. `tools/Validation.json` records the executed checks; it explicitly records in-game checks as not run.

## Manual acceptance remaining

Run a **new** BNW + standalone CP151 sequential single-player game with only this pack. Check Database.log/Lua.log first. Test slot zero and a later human slot. Observe count/phase/last-turn record `[CWC3_SUMMER:count:phase:lastGameTurn]` in player ScriptData without editing it.

1. At Standard processed owner-turn 13 save/reload, then cross 14. Confirm one Emergence notification, no Dormancy Food controller, Production/Culture controllers, Awakened combat immediately, and next collection receives Emergence. Reload at 14; no extra count or notification. Repeat at 17/18 and 30/31. Check the final Emergence payout collected at callback 18 before Dormancy is applied, consistent with the documented offset. Test the 9/3, 20/6 and 39/12 schedules too.
2. Compare actual stores/production queues across callbacks using otherwise equivalent cities, with no growth, worked-tile changes, resistance, anarchy or modifiers obscuring the flat deltas. The first bootstrap is Dormancy, not a counted turn. Confirm saving/loading preserves the namespace and other ScriptData content.
3. Found, conquer, gift, cede and recapture cities in both phases. Check real and free controller counts are exactly zero or one, no foreign yields remain, and all cities receive the phase bonus. Construct/purchase/sell the Nursery, remove it using FireTuner, and reload after each case. Verify native Granary resource/food effects survive and the Nursery's extra Faith is permanent.
4. Create a Shellguard during Emergence, inspect attack **and defense** previews in friendly/neutral/enemy territory and open/rough terrain, then upgrade twice during Emergence. Verify no unbuffed action window; marker remains; Awakened ends in Dormancy. Upgrade an ordinary Spearman along the same path: it must never gain either promotion. Gift and return veterans; test capture/conversion when the game rules permit it. Inspect +1 Sight on Shellguard and destination baseline Sight after upgrade.
5. Inspect civ selection, Civilopedia, both transition notifications, leader lines, valid fallback art, unit models/flags and both promotion panels. The lineage icon must be absent and Awakened visible. Confirm CP151's two generated VFS panel overrides win load order. Any alternate UI mod needs a separate compatibility merge/test.

No game was launched during development; every item above remains an in-game acceptance task. Custom-speed rows, changing durations mid-save, other mods that replace ScriptData/promotions/events/UI, autoplay, hotseat and multiplayer are outside the tested scope.
