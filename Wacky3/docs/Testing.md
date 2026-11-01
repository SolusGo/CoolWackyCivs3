# Manual Civilization V acceptance checklist

**Status: NOT RUN.** Static and mock passes are recorded in `tools/Validation.json`. Every item below requires observing Civilization V with BNW and standalone Community Patch v151. Use a disposable new single-player game, human in slot zero. Enable logging/FireTuner as appropriate. Do not use a valuable existing save. Avoid VP and unrelated gameplay mods for the first run.

## Registration, load and artwork

- [ ] Both dependencies resolve; Wacky3 is one selectable pack. Database.log has no SQL errors and Lua.log no initialization/runtime errors.
- [ ] Ministry appears in human selection, and random AI selection excludes it. Acting Chancellor, trait text, capital Runner-Up, Academy and Guard are correct.
- [ ] Color and alpha emblems are visible at selection, diplomacy, map and Civilopedia sizes. No missing texture, opaque square or incorrect atlas cell appears.
- [ ] Dawn image is 1024×768 with the supplied text. Static diplomacy illustration, leader portrait, unit icon and Academy icon display properly. Native Spearman model/animations and normal unit flag work.
- [ ] Force the leader into a test AI slot only to inspect supplied greeting/war/defeat text and ordinary fallback dialogue. Forced AI gameplay is outside supported play.

## Required timing acceptance — do this first

- [ ] In a local diagnostic copy, add logging immediately before/after `Snapshot` writes and compare with native city Production, player Culture and research settlement. Record turn, saved tier, real dummy counts and the actual changes in stored Production/Culture/research progress.
- [ ] Before ending a turn, arrange a gap of **six**. The next owner-turn must install Science1=1, Science2=1, Culture=1 and Academy Production=1 **before** collecting that turn's native yields. Verify the actual stored yield increase, not just the UI rate after collection.
- [ ] Arrange gap three before the boundary and make the owner's ordinary research complete a technology during that boundary. Confirm the snapshot used the pre-research gap and remains tier one for the turn.
- [ ] Arrange gap two before the boundary and let a rival's later research increase it. Confirm no mid-turn recalculation. Duplicate turn notifications must not change the tier again.
- [ ] Save mid-turn after a tech gain, reload, and confirm neither tier nor existing UA counts are recomputed. Advance to the next boundary; then verify the tier changes exactly once.

**Stop acceptance if notification delivery occurs after native yield collection.** A displayed rate increase after collection does not pass. Record the trace and provide a verified pre-economy event before claiming completion; do not add compensating instant yields. The later-slot status route also needs independent ordering proof before supporting a non-first-slot human.

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

## Guard combat and upgrades

- [ ] Spearman class resolves to Guard for Ministry; other civilizations retain their units. Cost/strength/sight/technology/resources/upgrades match active CP Spearman; Movement is exactly one higher.
- [ ] On own and teammate-owned land, inspect defense preview against melee and ranged attacks: exactly +15% additional defense.
- [ ] Attack from that land: no extra attack modifier from either Ministry promotion. Compare a baseline Spearman with identical ordinary promotions/terrain.
- [ ] Move to neutral, enemy and foreign Open Borders tiles: conditional defense absent. Move back: restored. Purchase/steal/cede ownership under a stationary veteran: promotion immediately follows actual ownership.
- [ ] Upgrade normally on qualifying land and foreign land: identity survives, defense follows location, +1 unit Movement does not persist.
- [ ] Reload with a veteran on foreign land and on own land. Check no stale conditional promotion. Gift/convert a unit and confirm its defense follows its current owner's team territory and identity.
- [ ] Embarked defense follows ordinary CP rules; no unrequested healing, general attack strength or advantage against advanced units appears.

Record the game build, CP DLL version, enabled mods, save and log evidence for every acceptance result. This document is intentionally unchecked until those observations exist.
