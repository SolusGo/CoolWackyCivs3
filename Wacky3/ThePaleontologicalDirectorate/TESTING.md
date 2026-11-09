# Directorate acceptance checklist

**Native in-game testing: NOT RUN.** Automated coverage uses the pinned BNW + standalone CP151 schema/native samples, synthetic companion sentinels, supplementary cache snapshots and production Lua under Lua 5.1 mocks. None reproduces the full engine. See [README.md](README.md) for the source proof, timing and persistence contracts.

## Automated verification

From `Wacky3` run `python tools/validate_paleo.py` and `python tools/validate_mod.py`. The repository `.venv` contains the pinned Pillow/lupa dependencies. The complete pack validation also runs all existing civilization suites, contaminated-schema regeneration, manifest checksums, VFS uniqueness and ZIP integrity. `tools/Validation.json` records results outside the manifest. `--compare-database <existing CP-schema Civ5DebugDatabase.db>` optionally adds another read-only in-memory cache comparison; caches are not authorities for generation or certified final CP-only gameplay data.

The Directorate Lua suite runs all four exact speed payouts in human slots 0 and 3, for **920 assertions**. It includes class replacements, duplicate counts, free-only exclusions, sales/removals, recursion, founding, capture/recapture, silent ownership recovery, liberation, reload, expected city totals, nonqualifying units/owners/builds/plots, both choice paths, handoffs, duplicate dispatch, current/no research, overflow, refused writes, API errors and unknown speeds. The SQLite suite compares every scalar and all 172 supported companion tables, including duplicate source Science/Culture rows. The full pack mutates parent movement, sight, cost, maintenance, slots and specialists before loading SQL.

## Native setup and observations

1. Use BNW and **only standalone `(1) Community Patch` v151**, plus this pack. Disable VP balance components. Extract `dist/Cool Wacky Civs 3 (v 1).zip` into the game's `MODS` folder. Enable logging and FireTuner if available. Start a new sequential single-player Standard game as Othmar; repeat speed tests on separate new Quick/Epic/Marathon games. Do not edit a live save's ledger.
2. Check `Database.log` for missing-table/column, uniqueness or SQL errors and `Lua.log` for PALEO errors. Inspect the selection screen, Dawn text, Civilopedia, portraits, unit map flag and static leader scene. Confirm no other civilization changes. Do not equate absence of log errors with gameplay success.
3. Use an editor/FireTuner to create a controlled city and units, research Archaeology, give real University access, create/reveal valid existing Antiquity and Hidden Antiquity sites and provide empty Artifact slots. Prefer native WorldBuilder/editor sites with genuine archaeological records. Merely placing the dig improvement is **not** a valid excavation. Make a save before each experiment.
4. In the `PALEO_Directorate` context, the following uses only verified APIs to inspect the owner's capital. Inspect base building yields rather than assuming UI totals equal unmodified yields; native University and other modifiers affect final Science.

```lua
local p = Players[Game.GetActivePlayer()]
local c = p:GetCapitalCity()
print(c:GetNumRealBuilding(GameInfoTypes.BUILDING_PALEO_LIBRARY_SCIENCE))
print(c:GetNumRealBuilding(GameInfoTypes.BUILDING_PALEO_UNIVERSITY_CULTURE))
print(p:GetCurrentResearch(), p:GetOverflowResearchTimes100())
```

5. To test replacements, remove real ordinary buildings in the class and use a different member. The pack's `BUILDING_CWC3_RUNNER_UP_ACADEMY` is a real Library-class replacement. Find University-class members in the active database with `for b in GameInfo.Buildings{BuildingClass='BUILDINGCLASS_UNIVERSITY'} do print(b.Type) end`. Use `city:SetNumRealBuilding(GameInfoTypes.<TYPE>, count, true)` in a controlled test; purely free copies must be tested separately. Dispatching a real construction or sale is preferable when verifying those native callbacks.
6. For Science experiments choose a tech far from completion, record `Teams[p:GetTeam()]:GetTeamTechs():GetResearchProgressTimes100(tech)` and `p:GetOverflowResearchTimes100()` **before the final work action**, then compare immediately after excavation, before selecting Artifact/Landmark. On Standard the increase is exactly 2500 hundredths. Turn-based normal research can otherwise obscure the difference. Repeat with exactly one Science remaining; native completion should preserve 24 Science plus any pre-existing overflow. With no selected research, compare overflow directly. Repeat with repeatable Future Tech and, if available, an exhausted custom tree.
7. For persistence, inspect the presence (not the editing) of `[PALEO_SITE_V1:x:y]` in `p:GetScriptData()` after the award. Save with archaeology selection pending, reload several times, then resolve it. Science must never pay a second time and ordinary Artifact/Landmark results must still occur. A full save rollback naturally rolls back the native reward and ledger together.

## Mandatory A–T matrix

Every row's native status is **NOT RUN**. “Mock” means production Lua51 behavior; “SQL/source” means static database/native source evidence.

| ID | Scenario and native acceptance condition | Automated evidence |
| --- | --- | --- |
| A | Othmar appears, is human selectable and excluded from normal AI selection; capital is Stratum Prime. | SQL flags, identity/overrides, localization and atlas references pass; screen rendering awaits native. |
| B | A real unique Library-class replacement gives exactly one Science controller. | Mock replacement IDs, SQL controller yield pass. |
| C | A real unique University-class replacement gives exactly one Culture controller. | Mock replacement IDs, SQL controller yield pass. |
| D | Both classes give independent controllers; with Museum, +3 Science/+2 Culture base; five cities +15/+10. | SQL-derived Museum increments plus mock city totals pass. |
| E | Multiple class members and duplicate real counts still give one controller per class. | Mock counts 2/3/4 pass. |
| F | Sell/remove the final qualifying building; its controller clears. Removing one of several keeps the bonus. Free-only class copies do not qualify. | Post-sale source order, mock removal/free-only behavior pass. |
| G | Found, conquer, gift/cede, recapture and liberate cities; foreign owners have no real/free controller residue. | Source acquisition contract, founding/capture/recapture/liberation and silent-transfer recovery mocks pass. Test each native transfer mode. |
| H | Save/load repeatedly with real class buildings and corrupt/free controller copies; legitimate bonuses remain at 0/1. | Bootstrap/reentrancy/idempotence and reload mocks pass; real engine serialization awaits native. |
| I | Museum cost, maintenance, prerequisites, specialists, slots and theming match active Museum; empty Museum gains exactly +2 Science/+1 Culture. | All scalar/companion multisets and duplicate inherited-yield cases pass. Compare native empty/filled/themed states. |
| J | Expedition has baseline movement +1 and effective sight +1, same costs/prerequisites/class restrictions/AI/builds/normal excavation options, no combat protection. | Complete scalar/companion checks and exclusive +1 VisibilityChange promotion pass. Move/reveal and perform both normal/hidden site digs natively. |
| K | Complete a valid Artifact excavation; one exact payout precedes the selection; Artifact still enters normal storage. | Authoritative source path and completion/choice mock pass. Actual Artifact creation awaits native. |
| L | Complete a valid Landmark excavation; same one payout; normal Landmark remains. | Same source path and Landmark choice mock pass. Actual Landmark creation awaits native. |
| M | Start a dig, cancel before it finishes and move away; zero reward/ledger marker. | No mission-start/movement/BuildFinished reward handlers; negative mock pass. |
| N | Kill or capture the unit before completion; zero reward/marker. Do not confuse a death after earned completion with an unfinished dig. | No death/capture inference; missing-unit negative mock pass. |
| O | A forced ordinary Archaeologist belonging to the Directorate finishes a dig; no reward. | Exact completing-type mock pass. |
| P | Rival Archaeologist or rival-owned Fossil Expedition finishes a dig; no Directorate reward. | Exact owner/civilization checks pass. |
| Q | Start with ordinary, finish with Fossil Expedition: one reward. Reverse: zero. Test a long enough dig to swap units. | CP event passes completing `this` unit ID; both handoff mocks pass. |
| R | Repeat the completed site's event with another expedition, resolve a choice, save/load pending/resolved choices, revisit the tile: no duplicate reward. | Permanent ScriptData marker, duplicate dispatch/reload and choice mocks pass. Native ScriptData serialization awaits acceptance. |
| S | Separate new Quick/Standard/Epic/Marathon games produce exactly 17/25/38/75. | All four exact values in two slots pass. Unknown speed explicitly disabled. |
| T | All archaeology behavior functions with BNW + CP151 only, without VP/custom DLL extensions. | Pinned native/CP151 schemas and source flags pass; complete native configuration test awaits acceptance. |

Also compare owner-turn timing after a silent scripted class removal, razing auto-sale and capture while the UI is closed. Construction/sale hooks should reconcile immediately; post-economy recovery affects the next payout. Native UI/new-turn dispatch timing must be observed, not inferred from the mocks.

No fallback substitute mechanic or unresolved hook blocker is present. Any failing native archaeological dispatch should be reported with the active DLL/package version, selected unit type, event arguments, plot record and logs; do not replace it with disappearance detection.
