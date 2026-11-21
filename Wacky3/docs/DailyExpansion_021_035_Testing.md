# Daily Surprise native acceptance

**NOT TESTED — native game execution unavailable during this implementation.** The Lua 5.1 fixtures and SQLite checks are automated source tests only. Start a new sequential game with BNW, standalone CP151 and Wacky3. Follow each checklist at Standard and Marathon, and record saves, actual yields, combat and relevant game logs.

| Daily | Checklist | Distinguishing case |
| --- | --- | --- |
| 021 | [Kingdom of Ryukyu](../KingdomOfRyukyu/TESTING.md) | Compare inland, lake-only and ocean cities. Add native, free and replacement Harbors. Compare defense and attack in own land, Open Borders and neutral territory. |
| 022 | [The Mirrorbound Republic](../TheMirrorboundRepublic/TESTING.md) | Compare a genuine military kill with disband, enemy city fire and barbarian deaths. Test both Lesson thresholds and cooldowns; save before spending and after partial expiry. Test melee survival, ranged survival, immediate attack, upgrade and unused expiry. |
| 023 | [Kingdom of a Thousand Kites](../KingdomOfAThousandKites/TESTING.md) | Compare two, three and four neighboring Plains/Grassland plots with hills and features. Attack units on qualifying and nonqualifying target plots from the opposite terrain, then defend on both. |
| 024 | [The Postal Sovereignty](../ThePostalSovereignty/TESTING.md) | Build the second, third, fifth, sixth and seventh Post Offices, including a free copy. Test initial movement, border crossing, same-turn return and upgrades while measuring remaining movement points. |
| 025 | [The Carapace Dominion](../TheCarapaceDominion/TESTING.md) | Compare lake-adjacent and ocean-adjacent land, inland, embarked and impassable defense. Compare attacks on the same plots. Captured/free replacement Walls count toward the coastal Science. |
| 026 | [The Octopus Parliament](../TheOctopusParliament/TESTING.md) | Start in Ancient and in a later era. Pick each of the three resolutions in separate eras. Save with a pending choice and after voting. Advance through a tech purchase or free tech and confirm one choice. Upgrade an Inkguard. |
| 027 | [The Fogbound Republic](../TheFogboundRepublic/TESTING.md) | Work 0–5 Marsh plots with and without pillage. Test two and four owned Marsh plots in overlapping city radii. Measure feature movement and +10/+25 nominal defense on and off Marsh. |
| 028 | [The Republic of Borrowed Tomorrows](../TheRepublicOfBorrowedTomorrows/TESTING.md) | Verify the friendly-territory modifier and debt-free Market yields. Advance, repayment and debt-dependent effects remain blocked pending the settlement hooks in the report. |
| 029 | [The Lichen Compact](../TheLichenCompact/TESTING.md) | Work 0–5 Tundra and 0–4 Snow tiles. Change assignments without changing ownership. Test the third and sixth owned plots and cold-hill settlement. Upgrade the Stonewalker. |
| 030 | [The Glass Orchard](../TheGlassOrchard/TESTING.md) | Work two, three, four and five Desert tiles including pillaged tiles, Hills and Flood Plains. Use a wet and a dry city. Start/end major and minor wars. Attack and defend on Desert. |
| 031 | [The Cartographers of Nowhere](../TheCartographersOfNowhere/TESTING.md) | Reveal 99, 100, 199 and 200 land plots by any source and confirm Atlas House thresholds. For unit-attributed rewards, compare your unit sight, externally supplied reveals, water and duplicate reveals. Test the era cap and reload. |
| 032 | [The Muisca Confederation](../TheMuiscaConfederation/TESTING.md) | Assign and unassign Gold, Silver and Iron Mines. Pillage/repair, test multiple Mines and an unworked Lake. Distinguish a Lake from a river and Coast, and test Hill defense versus attack. |
| 033 | [The Grand Duchy of Folding Chairs](../TheGrandDuchyOfFoldingChairs/TESTING.md) | Use an empty center, then a civilian, aircraft, embarked/naval unit, adjacent Spearman and land garrison. Move, kill, upgrade and replace the actual garrison, then compare all four yields. |
| 034 | [The Chachapoya](../TheChachapoya/TESTING.md) | Compare flat and Hill founding, then add and remove both native and replacement Walls. Attack at range and defend on Hills. Validate that the fictional leader is identified as such. |
| 035 | [The Calendar of Unofficial Holidays](../TheCalendarOfUnofficialHolidays/TESTING.md) | Observe the counter and actual production, science and treasury stores separately at 0, 1, renewed and extended WLTKD. Compare two cities in different states and a city without an Office. Test friendly-land attacks and defenses. |

## Hardening acceptance

**NOT TESTED — native acceptance.** The Windows automation tool denied access to the installed DX11 game. The entries below are reproducible scenarios, not observed outcomes.

Use the initial game or a save created with the same build. Keep yield readouts, before/after movement points, and the combat log or animation alongside any preview. Source/static/automated PASS does not imply a native PASS.

| Civ | Native reproduction and expected result |
| --- | --- |
| #028 | Confirm the debt-free Market and friendly-territory Pikeman effects. There is no advance control. Debt and repayment are **BLOCKED** in CP151. |
| #031 | Keep a partially revealed land map. Compare one unit sight expansion, a shared map, and an owned-city border expansion. Save at fewer than ten personal claims. Reload and complete the set. Compare Science/Culture, total Atlas thresholds, and overflow through a tech completion. Unitless border rewards remain **PARTIAL**. |
| #022 | Lose an aircraft to foreign-major interception and to ground AA on a sweep. Try an adjacent ranged casualty, an ordinary disband, and an enemy city attack. Defend with a Reflection Guard, then launch one nonlethal attack and compare its next attack. Repeat with upgrade and save/load. Move the Capital during Method and record five native tech settlements. |
| #035 | Use two celebrating cities with different counters and one without an Office. Record actual production progress, Treasury and the current tech at counters 2, 1, 0 and after extension. Verify the old-counter production and new-counter empire payouts. |
| #024 | Start in friendly land and measure current and maximum movement. Embark, return in the same turn, and compare points. Repeat on foreign land with expiring or canceled Open Borders and with an upgrade before spending the bonus. Save and reload between steps. |
| #025 | Defend from a land hex adjacent to a coast and to a lake. Compare attack, melee defense and ranged defense, including after an upgrade, embarkation, movement inland or ownership change. Check preview and actual damage separately. |
| #026 | Start in Ancient, check the pending vote, save/reload, and choose a motion once. Cross an era and choose Defence. Verify the modifier for a newly created military unit and its upgrade, then cross another era and verify cleanup. |
| #034 | Compare incoming melee on a Hill with incoming ranged, outgoing attacks and flat ground. An abort-capable debug scenario may exercise cancellation if available. Verify the scoped modifier is gone after combat or clean reload. Allow for a preview that omits the scoped pre-resolution effect. |
