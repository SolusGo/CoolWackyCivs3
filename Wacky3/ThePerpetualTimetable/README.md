# The Perpetual Timetable

**Grand Stationmaster Veyl · Capital: Terminus Prime · Science / Culture · Complexity: 3/5**

*The World Shall Run on Time.* A human-only civilization for Windows single-player, Brave New World and standalone Community Patch v151. It loads within the existing Cool Wacky Civs 3 pack and needs no Vox Populi or ModBuddy project.

## The Grand Schedule

Every non-capital city with an ordinary connection to its owner's Capital receives **+1 Production and +1 Science**. The native CP connection flag decides eligibility: Roads, Railroads, valid Harbor connections and other legitimate CP connections qualify. Routes never stack the bonus.

After **Railroad technology**, a non-capital city reached by a **continuous, fully owned land railroad** also receives **+1 Culture**. Every intervening non-city plot must have an intact Railroad; owned city centers are junctions even without a route. Water, Mountains, impassable terrain, ordinary Roads, pillaged track, foreign territory (including allies/Open Borders) and unowned plots cannot bridge the network. A valid alternative owned rail path preserves the bonus. A Harbor alone cannot complete a land railway.

These are flat city building yields, never tile yields or instant payments. The strict rail calculation is independent of the native ordinary connection flag.

## Line Surveyor — Worker replacement

Inherits the **active CP Worker**, including every scalar and all 27 approved companion tables, build actions/prerequisites, AI, selection sounds, model/flag, cost, maintenance and capture rules. It changes only identity/portrait, **+1 Movement** and **110% Work Rate, rounded to the nearest integer** (100 → 110; 80 → 88). The faster rate affects all ordinary construction. Standard tech and terrain rules still govern Roads and Railroads.

## Dispatch Office — Workshop replacement

Inherits the **active CP Workshop** and all 145 approved companions, preserving its cost, maintenance, prerequisite, base yields, specialist slots/effects and production modifiers. Adds **+1 permanent Gold** wherever it exists, including the Capital. An existing Workshop Gold change is retained and increased by exactly one in total.

In a non-capital Timetable city, the Office also supplies **+1 Culture** for an ordinary Capital connection and **+1 Production** for the same strict railroad eligibility used by the UA. Conditional effects require the Office and eligible ownership. The five invisible controllers have exact real counts zero/one, no free copies, maintenance, purchase, construction or capture inheritance.

| Unique bonuses beyond normal Workshop/game yields | Production | Science | Culture | Gold |
| --- | ---: | ---: | ---: | ---: |
| Ordinary connection, no Office | 1 | 1 | 0 | 0 |
| Complete railroad, no Office | 1 | 1 | 1 | 0 |
| Disconnected, with Office | 0 | 0 | 0 | 1 |
| Ordinary connection, with Office | 1 | 1 | 1 | 1 |
| Complete railroad, with Office | 2 | 1 | 2 | 1 |
| Capital with Office | 0 | 0 | 0 | 1 |

Six cities, complete qualifying railways and six Offices give **+10 Production, +5 Science, +10 Culture, +6 Gold**. Normal game yield modifiers, resistance and other native rules still apply to base city yields.

## Updates, saves and economic timing

CP151 source places `PlayerDoTurn` after city economic processing and research. At that owner's callback, the controller samples current native ordinary connections, technology, Capital, map and buildings. It sets city yields for the **next economic payout after that evaluation**; it cannot change the payout that just occurred. For example, a road finished during owner turn T is caught at the post-economy evaluation on T+1 and its reconciled yields apply at T+2. The same bounded timing applies to missed pillage/repair/technology/Capital/removal changes. This explicit delay is the pack's supported post-economy fallback.

Founding, acquisition (conquest/gift/cession), liberation, Office construction/purchase and sale also reconcile affected owners when their confirmed callbacks arrive. The next payout after such a reconciliation uses those counts, subject to native connection-cache freshness. Capture cleanup immediately clears these five controllers from a transferred foreign city. Watched city coordinates and owner-local turns recover missed transfer callbacks. Arbitrary scripted building removal is caught on the owner's next evaluation.

Load/bootstrap computes directly from current state and repairs corrupt/free/foreign controllers for the next payout. Reload can observe a connection change before the ordinary turn fallback would; it never replays an economic payout or awards compensating yields. No Timetable ScriptData, turn counter, economic cycle or large persistent ledger exists. Repeated evaluation is idempotent. All other civilizations' state is preserved.

One BFS is shared across every city and both abilities per eligible-owner evaluation, skipped before Railroad. There is no per-frame handler, custom UI, full-map-per-city scan, free construction, resource, teleportation or military bonus. Human Timetable players may occupy any supported single-player slot; forced AI play is unsupported.

## Presentation and acceptance status

Original generated PNG masters supply the golden wheel-clock emblem, Veyl's navy uniform and pocket watch, monumental terminus, surveying engineer and clock-tower Office. `tools/build_timetable_art.py` compiles 48 legacy RGBA8888 DDS assets, including 45 icon textures with full mip chains. A monochrome wheel/clock map glyph is reproducible. Diplomacy uses a static illustrated scene and supplied exact lines; the unit uses the inherited native Worker model/animations/flag and the Office inherits native Workshop world art. The map panel uses an illustrated terminus detail. There is no custom animated leader or voiced dialogue.

Automated SQLite and production Lua51 mocks cover these rules; **Civ V has not been launched for native acceptance**. Engine payouts, route/Harbor cache refresh, real save persistence, trainability/selection and art presentation still require the [manual checklist](../docs/TimetableTesting.md). See the [strategy guide](../docs/strategy/ThePerpetualTimetable.md) and [implementation report](../docs/TimetableImplementationReport.md).
