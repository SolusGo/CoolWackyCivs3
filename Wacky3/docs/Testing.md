# Manual Civilization V acceptance checklist

For the fourth civilization use [TimetableTesting.md](TimetableTesting.md), including Road/Harbor versus strict railway eligibility and the post-economy next-payout contract. Its automated tests do not complete the native checklist below or change Ministry timing requirements.

**Engine status: NOT RUN. Statically verified but awaiting in-game acceptance.** SQL, mock and source passes are separately recorded in `tools/Validation.json`; they do not check off any item below. Use a disposable new sequential single-player game, human Ministry in slot zero, BNW and standalone CP151. Enable logging/FireTuner. Avoid VP and unrelated gameplay mods for the first run. No test here requires regenerating the existing artwork.

## Registration, load and artwork

- [ ] Both dependencies resolve; Wacky3 is one selectable pack. Database.log has no SQL errors and Lua.log no initialization/runtime errors.
- [ ] Ministry appears in human selection, and random AI selection excludes it. Acting Chancellor, trait text, capital Runner-Up, Academy and Guard are correct.
- [ ] Color and alpha emblems are visible at selection, diplomacy, map and Civilopedia sizes. No missing texture, opaque square or incorrect atlas cell appears.
- [ ] Dawn image is 1024×768 with the supplied text. Static diplomacy illustration, leader portrait, unit icon and Academy icon display properly. Native Spearman model/animations and normal unit flag work.
- [ ] Force the leader into a test AI slot only to inspect supplied greeting/war/defeat text and ordinary fallback dialogue. Forced AI gameplay is outside supported play.

## Optional timing diagnostics

In FireTuner's Lua console select the **CWC3_Almost** context and execute:

```lua
MapModData.CWC3_AlmostDiagnostics = true
```

This enables existing code; no local gameplay edit is necessary. `Lua.log` lines start with `CWC3_ALMOST_DIAG`. A bounded last-128-record trace is also available as `MapModData.CWC3_AlmostTrace`. Disable with `MapModData.CWC3_AlmostDiagnostics = false`. The flag/trace are session-only and do not change saves or mechanics.

Candidate snapshots record event name, game turn, player ID, sampled technology gap, saved turn/tier and every city's real/free controller counts. Read-only observations include lifetime Culture in hundredths, current technology and research progress in hundredths, city Production in hundredths and the current unit/building/project queue IDs. `PlayerDoTurn:post-economy` records native stores **before recovery reconciliation**. `AIProcessingStartedForPlayer` and `ActivePlayerTurnStart` only observe; they cannot set a tier. After reload, an unsampled gap is logged as `nil` rather than re-reading technologies or inventing saved history.

For a controlled settlement test keep the production queue and selected research unchanged, avoid policy spending, instant yields, growth and other economic changes, and choose projects/technologies that will not finish during the first comparison. Compare stored progress immediately before the boundary with `PlayerDoTurn:post-economy`. Repeat under matched gap-two and gap-six conditions and subtract ordinary yields/modifiers. A changed queue/technology can reset the displayed progress store, so its raw difference alone is insufficient. Run research-completion ordering as a separate scenario. The logger neither computes an authoritative attributable payout nor certifies success automatically.

An accepted trace must show `NewGameTurn:before`, then `NewGameTurn:after` with the correct counts, **then** native post-economy observations, together with the expected actual stored yield changes. If a late candidate appears after `PlayerDoTurn`/`ActivePlayerTurnStart`, it is rejected with a warning and no resnapshot. That is a timing failure, not a supported alternate behavior. Inspect both logs and raw stores; event names or UI yield rates alone are not proof.

## Required timing acceptance — do this first

- [ ] Enable the optional diagnostics above and compare snapshot installation with native city Production, player Culture and research settlement. Record turn, player, gap, saved tier, real/free counts and actual changes in stored progress.
- [ ] Before ending a turn, arrange a gap of **six**. The next owner-turn must install Science1=1, Science2=1, Culture=1 and Academy Production=1 **before** collecting that turn's native yields. Verify the actual stored yield increase, not just the UI rate after collection.
- [ ] Arrange gap three before the boundary and make the owner's ordinary research complete a technology during that boundary. Confirm the snapshot used the pre-research gap and remains tier one for the turn.
- [ ] Arrange gap two before the boundary and let a rival's later research increase it. Confirm no mid-turn recalculation. Duplicate turn notifications must not change the tier again.
- [ ] Save mid-turn after a tech gain, reload, and confirm neither tier nor existing UA counts are recomputed. Advance to the next boundary; then verify the tier changes exactly once.

**Stop acceptance if notification delivery occurs after native yield collection.** A displayed rate increase after collection does not pass. Record the trace and provide a verified pre-economy event before claiming completion; do not add compensating instant yields. The AI-processing status route is diagnostic-only and supplies no later-slot fallback.

## Player slots and saved state

- [ ] Player zero Ministry: candidate snapshots occur once per valid boundary.
- [ ] Higher-slot Ministry after all earlier players are eliminated: it is now first living, receives a valid boundary and compares team technology correctly.
- [ ] Ministry with an earlier living player: logs the exact unsupported-slot warning once, does not sample early on the rival's boundary, and does not use an AI-processing notification to update mid-turn. Its previous saved tier remains unchanged. This is a documented unsupported setup, not a gameplay acceptance pass.
- [ ] Save/reload after earlier-player elimination; confirm slot eligibility is rediscovered without changing the saved tier during initialization.
- [ ] Team-owned land qualifies for defense; same-team majors do not establish the technology rival maximum. Test a teammate in a higher slot. A living teammate in an earlier sequential slot still makes that Ministry slot unsupported.
- [ ] Stale or duplicate notifications cannot rewrite the same saved record or alter counts. No late candidate is applied after post-economy observations.

## Technology scenarios

Use actual team research flags. Avoid comparing raw city yield totals without subtracting ordinary Library/population/specialist/terrain/modifier effects. UA-only expected base yields per city:

| Scenario | Science | Culture |
| --- | ---: | ---: |
| Gap 2 | 0 | 0 |
| Gap 3 | 1 | 1 |
| Gap 5 | 1 | 1 |
| Gap 6 | 2 | 1 |
| Gap 10 | 2 | 1 |
| Tied | 0 | 0 |
| Ministry ahead | 0 | 0 |

- [ ] Run all seven rows, including increasing and decreasing gaps. All three UA dummies stay in {0,1}; Science never becomes three, Culture never two.
- [ ] Eliminate the current leader, then let another living major become leader. Change is reflected only at the next snapshot.
- [ ] City-states, barbarians, dead majors and same-team players never establish the rival maximum. Two majors sharing a rival team count that team's technologies once. Unmet and hostile rivals still count.
- [ ] With no living eligible rival team, bonuses become zero. Confirm ordinary native yield suppression during resistance/anarchy/razing remains in force.
- [ ] Run a large game with more than twenty majors and check no repeated per-city technology enumeration or Lua errors.

## Cities, Academies and persistence

- [ ] Found a city after snapshot: current tier applied, no retroactive Science/Culture payout.
- [ ] Capture a city; puppet and annex it. Saved tier is applied without changing it. Academy Production exists only with a real Academy.
- [ ] Lose a city, including the capital; foreign owner has no four Ministry dummies. Remaining cities retain the saved tier.
- [ ] Gift/cede and liberate a city in both directions. Receiving Ministry copies its own tier; other owners receive no dummy yields.
- [ ] Build/buy an Academy at gap six: normal Library effects + one permanent Culture + one Production. Sell/remove it: Production dummy disappears immediately.
- [ ] Below gap six: no conditional Production. A city without an Academy has none at any gap. Captured/lost Academy state is handled correctly.
- [ ] Compare active CP Library and Academy costs, maintenance, prerequisites, specialists, population Science and companion effects. Only +1 direct Culture and conditional Production differ.
- [ ] Four cities with four Academies at six-plus add exactly **8 Science, 8 Culture, 4 Production** in base unique yields. At gap five they add **4 Science, 8 Culture, 0 Production**; at gap two only **4 Culture**.
- [ ] Save/reload at each tier after capital loss, founding, capture, Academy construction/sale and a mid-turn research change. Counts never duplicate. Reload keeps the old snapshot until the next valid boundary.
- [ ] In a diagnostic save, inject an incorrect Ministry real count and a free controller copy if supported by the test tools. Reload/dirty recovery repairs real counts to the saved tier and clears free copies, without changing surrounding ScriptData, the saved turn, research state or Culture stores.
- [ ] Inject foreign real/free controller copies and test reload/owner-local recovery; all four become zero. Exercise a transfer that recreates the city with a different owner-specific city ID and confirm cleanup uses its coordinates/current ownership.

## Guard combat and upgrades

- [ ] Spearman class resolves to Guard for Ministry; other civilizations retain their units. Cost/strength/sight/technology/resources/upgrades match active CP Spearman; Movement is exactly one higher.
- [ ] On own and teammate-owned land, inspect defense preview against melee and ranged attacks: exactly +15% additional defense.
- [ ] Attack from that land: no extra attack modifier from either Ministry promotion. Compare a baseline Spearman with identical ordinary promotions/terrain.
- [ ] Move to neutral, enemy and foreign Open Borders tiles: conditional defense absent. Move back: restored. Purchase/steal/cede ownership under a stationary veteran: promotion immediately follows actual ownership.
- [ ] Upgrade normally on qualifying land and foreign land: identity survives, defense follows location, +1 unit Movement does not persist.
- [ ] Observe both normal and goody upgrades: UnitCreated and UnitUpgraded can precede identity transfer. UnitConverted must repair the finished unit after promotion transfer. Use different old/new unit IDs and owners when testing gifts/conversion; do not assume a shared argument order.
- [ ] Reload with a veteran on foreign land and on own land. Check no stale conditional promotion. Gift/convert a unit and confirm its defense follows its current owner's team territory and identity.
- [ ] Embarked defense follows ordinary CP rules; no unrequested healing, general attack strength or advantage against advanced units appears.

Record the game build, CP DLL version, enabled mods, save and log evidence for every acceptance result. This document is intentionally unchecked until those observations exist.

## Automated evidence already available

`python tools/validate_mod.py --compare-database <existing CP-schema cache>` now runs six SQLite cases: pristine/mutated definitions in the source-derived clean BNW + CP151 schema fixture and both supplementary caches. All ten SQL actions execute in order. The clean fixture has native XML samples and synthetic records, not a recreated final CP gameplay database. Existing CP-schema caches are not overlaid to hide missing tables. Tests also cover both generators under clean/artificially contaminated schema, all 172 approved companions, byte-identical regeneration, 13 DLL-source/260 installed-schema source pins, 365 Choir plus 180 Ministry assertions, Lua51 syntax and manifest/DDS/ZIP integrity. Run `python tools/build_mod.py --package` first to refresh the ZIP. See [the repair report](CP151SchemaRepair.md).

Unsupported `Building_JFD_District` and `Building_ConstructionAudio` are absent from both required building SQL inventories; native unit sound and all 145 building/27 unit companion tables remain. The source fixture's negative controls would reject the old missing-table references. No Lua behavior, snapshot format, balance, GUID, version or art changes. Clean native CP-only loading is still unchecked. The mock suites cover recovery, every tier, source-ordered upgrades and 34 living major teams, but **cannot demonstrate closed-engine UI dispatch or observed combat**.
