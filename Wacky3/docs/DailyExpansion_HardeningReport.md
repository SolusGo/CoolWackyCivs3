# Daily expansion hardening

Baseline: [CoolWackyCivs3 main at 82b4525](https://github.com/SolusGo/CoolWackyCivs3/commit/82b452508b3860ced76af918feb2028790642879). The working branch is `fix/daily-expansion-hardening`. The canonical design blob IDs are unchanged. Before editing, the installed CP151 source/schema audit and full suite passed six SQLite configurations, including both supplementary caches. The suite did not exercise the engine's callbacks or UI.

| Civilization | Defect and cause | Correction or technical limit |
| --- | --- | --- |
| Borrowed Tomorrows #028 | **BLOCKED.** CP credits native yield and can complete or remove the current order or tech before Lua can debit that yield. | Retained the debt-free Exchange and friendly-territory Debt Collector. There is no advance, free resource award, or substitute penalty. See the settlement proof below. |
| Cartographers #031 | Pending claims lived only in memory until a later callback. Reveal attribution and threshold refresh also depended on the selected player and on unrelated movement or dirty callbacks. | Persist personal claims when observed and settle outside visibility traversal, including at the native end-of-update boundary. Route by receiving team and the source unit player. Census once per eligible player per load. **PARTIAL.** CP has no city provenance for unitless sight and no event history to backfill pre-context starting reveals. Atlas House still counts all land reveals. |
| Mirrorbound #022 | A successful air interception zeros primary final damage, and ground AA during sweeps can leave it unset. Primary role matching omitted scoped ranged casualties. The counter was consumed only at the end of resolution and every owner turn scanned the army. | Use pre-combat HP and the actual air damage source, plus lethal `UnitPrekill` during a known ranged resolver for nearby secondary victims. Consume the saved counter after damage calculation and after the abort gate, before applying damage. Transfer its existing expiry on same-owner conversion, clear other transfers, and track only armed units at end turn. **PARTIAL** for casualty mechanisms outside the verified direct, interception, sweep, and scoped ranged paths. |
| Unofficial Holidays #035 | A single global point at which all three yield types see the same countdown state does not exist. The original change callbacks already reconciled the right counter. | Kept native settlement and added numerical tests for start, 2→1, expiry, extension, reload, and simultaneous cities. No compensation payment. Native production and empire settlement see opposite sides of a natural transition. |
| Postal #024 | Removing by a change in `MaxMoves` fails after embarkation. Conversion copies the raw movement store even when it drops the promotion. Stationary units could keep their bonus when foreign Open Borders ended. | Book exactly one native move denominator each owner turn, remove those points on exit or conversion, clear before native reset, and recheck granted couriers after border and war notifications. Keep the existing turn marker and saved promotion. |
| Carapace #025 | Feature mutations did not refresh a stationary unit ahead of a preview, and cleanup was skipped for a nonmilitary unit that still carried the effect. | Observe CP feature changes and reconcile the scoped defense promotion. Preserve the pre-calculation `BattleStarted` guard and explicit water adjacency. Defense-only strength is unchanged. |
| Octopus #026 | Replayed era and ordinary turn callbacks swept the entire military even when Defence status was unchanged. | Apply city transitions only on epoch or vote change. Sweep units on load and Defence transitions, and update new/converted units individually. Pending votes are still saved with zero active motion. |
| Chachapoya #034 | An abort skips `BattleFinished`, allowing the Hill defense promotion to persist after calculation. | Clear at `CombatResult` after damage is fixed. Use `BattleFinished`, `GameCoreUpdateEnd`, conversion, and load to cover completion and cancellation. Melee Hill resolution retains its +15. Pre-battle preview can omit it. |

## CP151 feasibility and validation

`CvCity::doProduction` directly adds the order's actual yield and total production overflow, then clears overflow and feature production and calls `popOrder`. Its unit, building/wonder and project branches call `produce`, which can create objects, apply completion effects, and compute the next overflow. Without an order, the yield goes to overflow instead. `CvPlayer::doResearch` takes the selected tech's overflow, clears it, adds the current empire science, and calls `CvTeamTechs::ChangeResearchProgressTimes100`. Its progress setter can return unused overflow and unlock the tech in the same call. There is also a separate no-tech overflow path. The Lua production and research setters write these same stores, and do not provide a debt debit phase. `PlayerDoTurn` comes after those decisions. A percentage modifier cannot meter the lesser of half actual eligible yield and the balance in both paths.

An exact implementation needs a pre-credit callback in both paths. It must receive the owner, Capital or research target, and the actual eligible current yield in hundredths before adding stored overflow or applying completion. It must subtract a capped debit and report the credited amount atomically with the saved balance. It must also support immediately posting the advance through native progress/completion and carry-over rules. No such Lua hook was found in the production or research settlement bodies. The v151 binary and source pins were left intact.

For Cartographers, `CvPlot::setOwner` reports the ownership change before it calls unitless `changeAdjacentSight`. The ownership callback names the acquisition plot, while `TileRevealed` names the revealed plot. The reveal payload provides no originating plot, city, or reason. Allied territorial sight, improvement vision and direct non-unit reveal paths reuse it. Visibility alone cannot recover that source or replay initialization. The minimum missing API is an owned sight source on the native reveal event, plus initial reveal provenance before the Lua context starts.

For Mirrorbound, the +10 Science option remains one native city yield modifier, meaning +10 percentage points in the Capital's additive modifier stack. The engine multiplies its base yield by that stack and includes the city's result in `GetScienceFromCitiesTimes100`. Capital moves are reconciled by city dirty, capture and owner boundaries. The effect remains in place for five ensuing research settlements. A 150% preexisting stack becomes 160% while active. Ordinary attack and defense modifiers retain their native calculation order. Ranged secondary damage needs a resolved attacking unit, lethal HP at the prekill callback, a matching hostile killer, target or adjacent coordinates, and successful combat completion. A raw casualty from an unsupported resolver still lacks equivalent attribution.

For celebrations, `CvCity::doTurn` calls production before `DoTestResourceDemanded`. Changes to WLTKD then trigger reconciliation before the player later collects Gold and Science. At natural expiry production can use the final positive tick while Gold and Science see zero. Natural start has the reverse phase boundary. Lua does not extend it or issue extra yields.

## Regression and inventory

- **PASS — source/static/automated baseline.** The original ten and all fifteen expansion identities passed registration, active-baseline inheritance and the existing behavioral suites. The Ministry, Hollow Choir, Seventeenth Summer, Timetable, Candlekeeper, Paleontological Directorate, Lost Things, Scarecrows, Makuria and Salt Road retain their civilization files. The other seven Daily additions retain their individual balance data, and their production Lua ran through the shared lifecycle tests.
- Shared lifecycle changes deduplicate completed owner sweeps, supply prepared inputs to direct city refreshes, limit plot notifications to affected owners, and still clear real/free dummies on foreign capture. Tests cover liberation and reload for all fifteen, plus multiple eligible Cartographers, 26 Postal cities, and a 1,001-unit Parliament. Existing archive fixtures retain the 34-major coverage.
- Production changes are confined to `Shared/Lua/CWC3_ArchiveLifecycle.lua`, `Shared/Lua/CWC3_Daily.lua` and the D022, D024, D026, D031, D034 and D035 gameplay Lua files. Carapace uses the shared defense correction. Borrowed Tomorrows deliberately retains its independent gameplay.
- Verification changes are in `tools/daily_source_checks.py`, `tools/validate_daily_expansion.py`, `tools/tests/daily_expansion.lua`, `tools/tests/archived.lua` and the generated `tools/Validation.json`. The archived plot repair/transfer fixtures now pass the real CP owner and position arguments. The regenerated `.modinfo`, README, changelog, expansion reports and affected civilization guides document and package the result. `git diff --name-status 82b4525..HEAD` gives the exact committed inventory and `git log --format=oneline 82b4525..HEAD` records its commit IDs.
- Original emblem and alpha art stays in place. Leader, Dawn, map, diplomacy, and unique portraits retain stock references. No custom portrait was added. DDS, VFS and manifest verification are automated.
- Use the [testing index](DailyExpansion_021_035_Testing.md) for native scenarios and [source proof](DailyExpansion_021_035_SourceProof.md) for callback order. Lua and SQLite results are never interpreted as native combat, memory, or UI results.

**NOT TESTED — native acceptance.** The installed Civ V DX11 executable was present. Computer Use denied access to `civilizationv_dx11`, so the rebuilt mod was not installed or exercised in the game. No native yield, UI, combat, or screenshot result was collected.

## Reproduction

From Wacky3, with repository Python dependencies installed:

```powershell
python tools/validate_daily_expansion.py
python tools/validate_timetable.py
python tools/validate_covenant.py
python tools/validate_paleo.py
python tools/build_mod.py --package
python tools/validate_mod.py --compare-database "$env:USERPROFILE/Documents/My Games/Sid Meier's Civilization 5/cache/Civ5DebugDatabase.db"
```

| Command | Observed result |
| --- | --- |
| `validate_daily_expansion.py` | **PASS — Source/static/automated test.** 15 registrations and 32 gameplay scenarios. |
| `validate_timetable.py`, `validate_covenant.py`, `validate_paleo.py` | **PASS — Source/static/automated test.** Existing standalone suites, including 34-major fixtures where defined. |
| `build_mod.py --package` | **PASS.** Built the ZIP under `dist` for version 1. |
| `validate_mod.py --compare-database ...` | **PASS — Source/static/automated test.** Six SQLite configurations, pinned sources, Lua 5.1, deterministic SQL and art regeneration, 963 manifest files, 124 activation actions, 25 UI contexts, 681 DDS textures and byte-for-byte ZIP verification. The first corrective run found the obsolete empty event payload in the archived Farm fixture. The corrected fixture passed on rerun. |

The [validation log](../tools/Validation.json) records technical results. Native status is listed separately in the testing index.
