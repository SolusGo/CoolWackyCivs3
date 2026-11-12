# The Paleontological Directorate

**Leader:** Director Emeritus Othmar. **Capital:** Stratum Prime. **Victory focus:** Science / Culture. Human selectable only (`Playable=1`, `AIPlayable=0`). Requires Brave New World and standalone **Community Patch v151**, using the pack's existing exact-version dependency. No Vox Populi, new DLL, ModBuddy project or additional mod dependency.

Implemented in this directory with five ordered SQL actions, one hidden Lua context and 57 valid DDS textures. **Automated checks pass; native in-game acceptance has not been run.** The reproducible A–T checklist is in [TESTING.md](TESTING.md).

| Unique | Behavior |
| --- | --- |
| The Earth Remembers | Each city possessing any Library-class building receives +1 base Science. Independently, any University-class building supplies +1 base Culture. Replacements qualify; duplicate buildings or instances within one class do not stack. |
| Fossil Expedition | Replaces the active Archaeologist, preserving all scalar/companion effects except presentation and +1 base Movement. An exclusive promotion adds +1 Sight, with no combat/protection effect. |
| Field Discovery | The Directorate's human-owned Fossil Expedition completing a valid excavation receives 17/25/38/75 Science on Quick/Standard/Epic/Marathon, once per site. Paid at excavation completion, before the normal archaeology choice; Artifact and Landmark both qualify. |
| Natural History Museum | Replaces the active Museum, preserving all scalar and companion effects and adding unconditional +2 base Science and +1 base Culture. Empty slots qualify. |

A city with a Library, University and Natural History Museum has **+3 Science/+2 Culture** in unique base recurring yields; five cities have **+15 Science/+10 Culture**. These are ordinary additive building yields: normal city yield modifiers, resistance and other native settlement rules still apply. There are no population/era/technology multipliers in the unique mechanics, free technologies, new sites, resources, Artifacts or technologies.

Build Libraries and Universities across the republic, then Museums. Use the expedition's mobility and sight to plan routes to existing sites. Keep Artifact slots available and negotiate access through other civilizations. Field Discovery is modest and does not depend on the type of archaeological choice.

## Integration and inheritance

`tools/build_mod.py` appends `PALEO_Civilization`, `PALEO_Units`, `PALEO_Buildings`, `PALEO_Text` and `PALEO_Art` to the existing activation order, then registers `Lua/PALEO_Gameplay.xml` as an `InGameUIAddin`. Lua scripts, DDS files and the static leader-scene XML are imported into VFS. The context XML is an entry point, not a database update. All new identifiers, assets, save markers, temporary tables and context guards use `PALEO_`.

The SQL clones active `UNIT_ARCHAEOLOGIST` and `BUILDING_MUSEUM` rows with temporary `SELECT *` tables, changes only named unique/presentation fields and inserts with new IDs. It copies the complete **172-table** supported unit/building companion inventory (including `UnitGameplay2DScripts`) from pinned BNW/CP151 declarations. Empty companion tables remain harmless. No source unit/building, other civilization or VP-only data is edited. The generator never derives its table inventory from a modded cache.

Movement is `Moves=Moves+1` on the cloned active row. Sight is an additional `VisibilityChange=1` promotion, so existing base and promotion sight are preserved. The native Archaeologist AI, build list, archaeology mission, Antiquity/Hidden Antiquity targets, university requirement, costs, class restrictions, upgrades and world model remain inherited. Native archaeology resolves units by `UNITAI_ARCHAEOLOGIST`, not an exact Archaeologist unit type.

The Museum keeps cost, maintenance, prerequisites, slots, theming, specialists, art and all other active effects. The two unique yields update **one** inherited yield row per type (or insert one if absent), preserving duplicate baseline rows without multiplying the unique increment.

The two invisible buildings have independent classes, `Cost=-1`, `FaithCost=-1`, zero maintenance/specialists and no slots, `NeverCapture=1`, `ConquestProb=0`, `IsDummy=1`, `ShowInPedia=0`. `CityCanConstruct` also rejects them. CP's `IsDummy` excludes them from the ordinary building count. Their only companion record is the specified +1 flat yield. The shared runtime sets absolute real counts of 0/1, clears free dummy copies and suppresses construction rewards/refunds.

## Exact excavation hook and proof

The implementation uses **`GameEvents.PlayerBuilt(iPlayer, iUnit, iX, iY, iBuild)`**, enabled through CP151's existing `CustomModOptions.EVENTS_PLOT`. It does **not** use `BuildFinished`, movement, `UnitPrekill`, disappearing resources/units, mission starts or improvement appearance as completion detectors.

The pack pins CP151 commit [`44c1e14ff75d80c1dba5c8a71e8289439a53aafb`](https://github.com/LoneGazebo/Community-Patch-DLL/tree/44c1e14ff75d80c1dba5c8a71e8289439a53aafb). `tools/paleo_sources.json` adds four DLL-source hashes and twelve native-data hashes to the existing audit. `tools/paleo_fixture.py` checks the following call-path facts:

1. [`CvUnit::build`](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvUnit.cpp#L13410) obtains `bFinished` from `CvPlot::changeBuildProgress`. `PlayerBuilt` at line 13638 lies inside `if(bFinished)`, outside the unfinished branch. It passes **this completing unit's** owner, ID, coordinates and build, independent of who supplied earlier work.
2. [`CvPlot::changeBuildProgress`](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvPlot.cpp#L12750) enters completion only when accumulated work reaches the required build time. A prompt-when-complete improvement with a valid archaeological record increments choices and calls `AddDigCompletePlot(this)` at line 12808, before returning true. Human selection is deferred; the normal `BuildFinished` callback occurs later in this path but has no unit identity.
3. Native `BUILD_ARCHAEOLOGY_DIG` constructs `IMPROVEMENT_ARCHAEOLOGICAL_DIG`, has no `Kill` flag, and the improvement has `PromptWhenComplete=true`. No standalone CP data override was found changing these facts. [`DoArchaeologyChoice`](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvCultureClasses.cpp#L2837) applies the Artifact/Landmark result and consumes the expedition later. The finishing human unit is therefore available during `PlayerBuilt`. Autoplay/AI takeover is outside this human-only pack's support boundary.
4. The handler checks the exact build, living Directorate owner, human status, event's actual unit type/owner/coordinates, dig improvement and valid archaeological record. The last two are extra validity checks **in addition to the authoritative event**, never independent triggers. No native archaeology choice or outcome is intercepted or changed.

One authoritative completion event supplies every needed identity, so no inferred multi-signal state machine is necessary. Finishing the work is the reward boundary, even if the human has not yet clicked Artifact or Landmark. An unfinished cancellation/death/capture has no `PlayerBuilt` dispatch and earns nothing. A death **after** successful completion does not undo an already earned reward. Later choices and moving another expedition onto the tile have no payout path.

## Science and persistence

With selected research, `Teams[player:GetTeam()]:GetTeamTechs():ChangeResearchProgress(tech, amount, playerID)` grants the exact integer Science amount. [`CvLuaTeamTech`](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/Lua/CvLuaTeamTech.cpp#L172) binds the native method; [`SetResearchProgressTimes100`](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvTechClasses.cpp#L2406) completes research and transfers excess to the player's overflow. Existing progress and overflow are never overwritten or clamped to the remaining research cost.

With **no selected research**, `Player:ChangeOverflowResearch(amount)` banks the exact beakers in the native, serialized research overflow store. The handler verifies its hundredths increased by `amount*100` before recording payment. Native `doResearch` consumes that store when research resumes. With an exhausted custom tech tree, it remains banked; the mod does not select or invent technology. Normal repeatable Future Tech follows native research. Unknown custom game speeds are explicitly disabled with a Lua.log message; their percentages are never guessed.

Only after Science commits, the handler appends `[PALEO_SITE_V1:x:y]` to the owner's **Player ScriptData**, preserving all unrelated content. This follows the repository's save-backed ScriptData pattern. The marker prevents repeat events, unit handoffs, subsequent choices and reloads from paying twice. The ledger is a permanent once-per-coordinate ledger for that player's lifetime: deliberately respawning a new site on an already rewarded coordinate through another mod/editor does not pay again. Callback execution is synchronous; the award guard prevents reentrant payout while research callbacks run. No site is marked on refused overflow writes or thrown pre-award API errors. There is no speculative recovery that invents missing completion events.

## City reconciliation and timing

All buildings in each required class are indexed from the final game database, including other mods' replacements. `GetNumBuilding > 0` qualifies once per class, including purely free buildings. Duplicate real/free representations never multiply the bonus. Independent checks set each dummy absolutely. Founding, post-transfer `CityCaptureComplete`, liberation, post-construction and **post-sale** callbacks reconcile directly. CP151's sale network handler calls `DoSellBuilding` before `CitySoldBuilding`.

Bootstrap/load scans city lists once, repairing Directorate cities and stripping foreign copies. New-game-turn and active-player-turn events repair the Directorate; `PlayerDoTurn` and watched coordinates provide bounded recovery for silent scripted changes and ownership transfers. `SerialEventCityInfoDirty` repairs watched cities with a recursion guard. No full map, unit census or per-frame polling is used.

CP151 `PlayerDoTurn` is **post-economy**; repairs at that checkpoint govern the next payout. Direct callbacks/load establish ordinary ongoing yields sooner. Unobservable scripted changes or native auto-sales may wait for the next reconciliation; synchronous UI/new-turn dispatch and exact native settlement remain in-game acceptance items. No lump-sum Science/Culture simulates the recurring UA.

## Artwork and build

Six new original illustrations redesign Othmar and the Directorate: a stout bald scholar with enormous monocle, wild white side-whiskers, vermilion waistcoat and a treasured ammonite; plus a new emblem, expedition, Museum, separate Dawn and capital. Full prompts are retained in [Art/Sources/Prompts.json](Art/Sources/Prompts.json). The shared deterministic compiler produces all **57 DDS files**, six gold-rimmed/alpha/flag atlas families and three distinct scene images, using legacy BGRA8888 and full icon mips. Native Archaeologist/Museum **world models** remain inherited; diplomacy is static, without a custom animated model or recorded speech. See [the art guide](Art/README.md).

From `Wacky3`, using the repository environment or installed `requirements-dev.txt`:

```powershell
python tools/paleo_fixture.py --fetch  # only needed if ignored reference files are absent
python tools/generate_paleo.py
python tools/build_paleo_art.py
python tools/build_mod.py --package
python tools/validate_paleo.py
python tools/validate_mod.py
```

The installable ZIP is `dist/Cool Wacky Civs 3 (v 1).zip`. Extract its contained pack folder into Civ V's `MODS` directory, enable BNW/CP151 and the pack, and start a **new sequential single-player game** as Othmar. Do not add this expanded pack to an existing save for acceptance testing.

## Delivered files and remaining work

This directory contains the five SQL files, Lua/XML context, 57 DDS textures, leader-scene XML, six PNG masters, alpha/review PNGs, prompts and these two guides. New developer files are `generate_paleo.py`, `build_paleo_art.py`, `paleo_fixture.py`, `paleo_sources.json`, `validate_paleo.py` and `tests/paleo.lua`. Necessary shared changes are loader/manifest registration, fixture/test integration and the roster documentation. No other civilization implementation changed.

**No unresolved excavation-interface blocker remains.** Remaining work is native acceptance of selection/UI/art, actual archaeological event dispatch/choice preservation, economic timing and engine save serialization, following [TESTING.md](TESTING.md). Source proof and mocks do not constitute an in-game pass.
