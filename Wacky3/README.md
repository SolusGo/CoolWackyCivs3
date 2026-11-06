# Cool Wacky Civs 3 — version 1

An independent, modular civilization pack for **Civilization V: Brave New World + (1) Community Patch v151**, without Vox Populi. Current roster: **The Ministry of Almost**, led by Acting Chancellor Penultimate; **The Hollow Choir**, led by The First Note; **The Seventeenth Summer**, led by Chorus-Mother Ixa; and **The Perpetual Timetable**, led by Grand Stationmaster Veyl. All are human selectable (`Playable=1`), excluded from normal AI selection (`AIPlayable=0`). Windows single-player only.

Wacky3 has its own mod GUID, database prefix, save namespace, artwork and Lua context. It has no dependency on CoolWackyCivs or CoolWackyCivs2. Those projects can evolve separately. Nothing in their checkouts is changed by this pack.

## Installation

1. Install BNW and Community Patch **version 151**. Enable the standalone `(1) Community Patch`, without the Vox Populi balance components. The dependency deliberately rejects newer CP versions until separately audited.
2. Copy this `Wacky3` folder to `Documents/My Games/Sid Meier's Civilization 5/MODS/Cool Wacky Civs 3 (v 1)`. The `.modinfo` must sit directly inside that folder. Alternatively, extract the optional install ZIP produced by `tools/build_mod.py --package` into `MODS`.
3. Enable the patch and this pack in the Mods menu, then choose a civilization as the human in a **new sequential single-player game**. For **The Ministry of Almost**, use human player slot zero: its precise supported boundary requires the Ministry to be the **first living sequential player**, so a higher slot qualifies only after all earlier players are eliminated. The Ministry has mock coverage with 34 living major teams, subject to the installed DLL's player limits. The Choir's passive terrain reconciliation has no first-slot restriction; native timing still awaits acceptance. Summer and Timetable support any human slot using explicit post-economy, next-payout evaluation.
4. Do not add the mod to an existing save or remove it from a Ministry save. Existing version 1 saves retain their snapshot. Check `Database.log` and `Lua.log` when doing the acceptance tests.

## The Perpetual Timetable

**Capital:** Terminus Prime. **Motto:** “The World Shall Run on Time.” **Victory focus:** Science / Culture. **Complexity:** 3/5. The Grand Schedule gives non-capital cities with ordinary Capital connections **+1 Production and +1 Science**, including valid Harbor connections. After Railroad technology, a continuous, intact land railroad entirely within the owner's territory adds **+1 Culture**. Owned city centers serve as junctions; Road gaps, foreign/unowned territory, water and pillaged track fail the strict railway test.

The Worker-replacing **Line Surveyor** retains active CP rules, adding +1 Movement and rounded 110% Work Rate for all construction. The Workshop-replacing **Dispatch Office** retains all active Workshop effects and adds +1 permanent Gold; connected non-capital Offices add +1 Culture and qualifying railroad Offices add +1 Production. Six railway cities with six Offices add **10 Production, 5 Science, 10 Culture and 6 Gold**. One BFS serves both abilities per evaluation. Five bounded city-yield controllers reconcile ownership, buildings and reload without ScriptData or per-frame polling.

Owner-turn reconciliation is **post-economy** and governs the next payout after evaluation. Route changes without direct callbacks wait until that next owner evaluation and its following payout. Original PNG/DDS artwork supplies every portrait and the static leader scene; native Worker/Workshop world art is retained. See the [civilization guide](ThePerpetualTimetable/README.md), [strategy](docs/strategy/ThePerpetualTimetable.md), [testing/timing contract](docs/TimetableTesting.md) and [complete implementation report](docs/TimetableImplementationReport.md). **Native in-game acceptance remains outstanding.**

## The Seventeenth Summer

**Daily Civ V Surprise #17. Capital:** First Emergence. **Motto:** “We Were Never Gone.” **Victory focus:** Science / Culture. Every city alternates between Dormancy (+1 Food) and Emergence (+2 Production, +1 Culture). Dormancy/Emergence durations: Quick 9/3, Standard 13/4, Epic 20/6, Marathon 39/12. The Spearman-replacing **Shellguard** adds +1 Sight and permanent upgrade lineage; brood veterans gain +20% attack/defense during Emergence. The Granary-replacing **Brood Nursery** adds permanent +1 Faith and conditional +1 Production during Emergence, preserving all inherited effects.

The cycle advances once per post-economy owner-turn, changing combat immediately and scheduling city bonuses for the **next payout**. It persists through saves and reconciles cities, upgrades and transfers. See the [Summer guide](TheSeventeenthSummer/README.md), [strategy](docs/strategy/TheSeventeenthSummer.md) and [source/acceptance report](docs/SeventeenthSummerTesting.md). Native art is a valid temporary fallback. Two narrowly modified CP151 panel overrides hide the internal lineage icon; alternate UI mods require a merge. Automated checks pass; **native in-game acceptance remains outstanding**.

## The Hollow Choir

**Capital:** Resonance. **Victory focus:** Culture / Science. Hill city centers gain +1 Production; independently, each adjacent Mountain supplies +1 Faith, capped at +2, regardless of ownership. The **Chorus Sentinel** inherits the active Swordsman and adds a persistent +1 Sight / +20% defense on Hills promotion. The **Resonance Hall** inherits the active Amphitheater, adds +1 Culture, and supplies +1 Science per two owned Mountains within three hexes, capped at +2. Shared Mountains count for every qualifying Hall. Five zero/one yield controllers reconcile map/building changes and reload without a saved ledger.

See the [Choir guide](TheHollowChoir/README.md), [strategy](docs/strategy/TheHollowChoir.md) and [implementation/testing report](docs/HollowChoirTesting.md). Custom crystal artwork is not yet supplied; valid native America/Washington/Swordsman/Amphitheater assets are temporary fallbacks. Automated coverage includes active-row inheritance and terrain/lifecycle Lua51 mocks; **no in-game test pass is claimed**.

## The Ministry of Almost

**Capital:** Runner-Up. **Victory focus:** Science / Culture. **Secondary strength:** defensive warfare. **Complexity:** intermediate, 3/5.

| Technologies behind the leading living rival major team | Science per city | Culture per city | Academy extra Production |
| --- | ---: | ---: | ---: |
| 0–2 | 0 | 0 | 0 |
| 3–5 | 1 | 1 | 0 |
| 6+ | 2 | 1 | 1 |

The **Second Wind Guard** replaces the active CP Spearman: same baseline except +1 Movement, and +15% **defense only** while occupying own/team-owned territory. Its identity survives ordinary upgrades. Foreign Open Borders territory does not qualify.

The **Runner-Up Academy** replaces the active CP Library, preserving its scalar and companion effects, adding permanent +1 Culture and conditional +1 Production at tier 6+. Every city gets the UA, including puppets; ordinary game rules such as resistance, razing, anarchy and yield modifiers still apply to these real building yields. Four cities with four Academies at gap six add **8 Science, 8 Culture, 4 Production** in base recurring yields.

See the [civilization guide](TheMinistryOfAlmost/README.md), [winning strategy](docs/strategy/TheMinistryOfAlmost.md), [CP audit](docs/Compatibility.md) and [manual acceptance checklist](docs/Testing.md).

## Verification status and limits

**Statically verified but awaiting in-game acceptance.** Checks cover a source-derived clean BNW + CP151 schema fixture plus both supplementary caches, pristine/mutated source definitions, contamination-proof regeneration, Lua 5.1 syntax, all four civilizations' behavior assertions, 14 DLL-source/260 installed-schema source pins, two additional Timetable data-only source hashes, two pinned Summer panel overrides, and DDS/manifest/ZIP integrity. **The clean schema fixture does not reconstruct native CP gameplay data; mocks do not demonstrate native economic timing or an in-game pass.** See `tools/Validation.json`, the [Timetable acceptance report](docs/TimetableTesting.md), the [Summer acceptance report](docs/SeventeenthSummerTesting.md) and the [schema repair report](docs/CP151SchemaRepair.md).

The DLL publishes `NewGameTurn` before first-player activation; `PlayerDoTurn` follows city yields and research. Wacky3 finds the actual Ministry owner and uses `NewGameTurn` **only when that owner is the first living sequential player**. **Synchronous UI dispatch before native yield collection still needs in-game acceptance.** An event observed after that owner's `PlayerDoTurn` or `ActivePlayerTurnStart` is rejected without resnapshotting. `AIProcessingStartedForPlayer` is diagnostic-only because its human-owner timing is unverified. An owner with earlier living players gets a one-time Lua.log warning; the previous saved tier is preserved and new snapshots are suspended. Such later-slot setups, hotseat, multiplayer and autoplay are unsupported. No instant-yield compensation is used.

The hardening pass keeps the version 1 GUID and save record format. Reload repairs all four real/free dummy counts from the **saved tier**, without re-reading technologies. Ownership hooks cover conquest, gifts and peace-treaty cessions; watched city coordinates and one owner-local turn pass provide recovery. Guard veterans reconcile after promotion transfer through `UnitConverted`; unrelated units are not rescanned every turn. See [the corrective report](docs/ImplementationReport.md) for fixed defects and preventive changes.

Optional read-only diagnostics can be enabled in the `CWC3_Almost` FireTuner context with `MapModData.CWC3_AlmostDiagnostics = true`. They log candidate snapshots, dummy counts and observed economic stores. The [testing guide](docs/Testing.md#optional-timing-diagnostics) explains how to collect controlled runtime evidence; log order alone is insufficient.

Art includes original generated portraits and illustrations, retained PNG sources, DDS atlases and a deterministic compiler. Diplomacy uses a static illustrated scene and text, without animated custom models or recorded speech. The unit uses the native Spearman model/flag. The map panel shows the fictional capital rather than a geographical map.

## Developer workflow

Use Python 3.11+ and `python -m pip install -r requirements-dev.txt`. All tools run from this folder:

```powershell
python tools/audit_cp.py --fetch
python tools/generate_sql.py
python tools/generate_text.py
python tools/generate_hollow_choir.py
python tools/generate_seventeenth_summer.py
python tools/generate_timetable.py
python tools/generate_summer_ui.py
python tools/build_art.py
python tools/build_timetable_art.py
python tools/validate_timetable.py
python tools/build_mod.py --package
python tools/validate_mod.py
# Also test an existing CP-schema database without overlaying its schema:
python tools/validate_mod.py --compare-database "$env:USERPROFILE\Documents\My Games\Sid Meier's Civilization 5\cache\Civ5DebugDatabase.db"
```

Validation reads game files **read-only** and works in memory. Set `CWC3_GAME_DIR` to the installed Civilization V directory if Steam-library discovery cannot find BNW. Set `CWC3_CP_DIR` for a nonstandard `(1) Community Patch` location. `tools/target_schema.py` verifies installed source hashes and builds the authoritative clean target schema. `CWC3_DATABASE` selects only the supplementary BNW cache **without Wacky3**, defaulting to `cache_backup/Civ5DebugDatabase.db`; it cannot influence SQL generation. The existing CP-schema comparison cache is tested without manufacturing missing schema/options. Neither cache is certified CP-only. Art does not need regeneration for this repair; the Choir uses native temporary art.

The checked-in SQL uses `SELECT *` temporary clones, so gameplay inherits active definitions at load time. All four SQL generators enumerate companions exclusively from pinned native/CP declarations, never arbitrary cache prefixes. `tools/cp151_schema_sources.json` records all 172 approved tables and their columns. Normal generation fails on changed sources/inventory; `python tools/target_schema.py --pin` deliberately updates pins only after an audit. Timetable preserves this pin; its two additional native data-only fixture hashes live separately in `tools/timetable_fixture.py`. Unsupported JFD district/construction-audio extensions are not required or optionally cloned. Re-run the generators after audited schema changes. No build tool imports or needs Wacky2.

## Adding another civilization

Create a sibling folder with its own SQL, Lua, Art and README. Use unique `CWC3_` type suffixes and `TXT_KEY_CWC3_` localization. Add database files to `tools/build_mod.py:ORDER` in explicit load order and add an entry point only if its gameplay needs one. Keep shared infrastructure independent of individual civilizations. Preserve the existing mod GUID and save minimum unless there is an intentional save break. Add source evidence, meaningful behavior tests, a strategy guide and real DDS sources. Rebuild the **single pack manifest**, validate and perform in-game acceptance before release.
