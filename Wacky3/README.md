# Cool Wacky Civs 3 — version 1

An independent, modular civilization pack for **Civilization V: Brave New World + (1) Community Patch v151**, without Vox Populi. Current roster: **The Ministry of Almost**, led by Acting Chancellor Penultimate, and **The Hollow Choir**, led by The First Note. Both are human selectable (`Playable=1`), excluded from normal AI selection (`AIPlayable=0`). Windows single-player only.

Wacky3 has its own mod GUID, database prefix, save namespace, artwork and Lua context. It has no dependency on CoolWackyCivs or CoolWackyCivs2. Those projects can evolve separately. Nothing in their checkouts is changed by this pack.

## Installation

1. Install BNW and Community Patch **version 151**. Enable the standalone `(1) Community Patch`, without the Vox Populi balance components. The dependency deliberately rejects newer CP versions until separately audited.
2. Copy this `Wacky3` folder to `Documents/My Games/Sid Meier's Civilization 5/MODS/Cool Wacky Civs 3 (v 1)`. The `.modinfo` must sit directly inside that folder. Alternatively, extract the optional install ZIP produced by `tools/build_mod.py --package` into `MODS`.
3. Enable the patch and this pack in the Mods menu, then choose either civilization as the human in a **new sequential single-player game**. For **The Ministry of Almost**, use human player slot zero: its precise supported boundary requires the Ministry to be the **first living sequential player**, so a higher slot qualifies only after all earlier players are eliminated. The Ministry has mock coverage with 34 living major teams, subject to the installed DLL's player limits. The Choir's passive terrain reconciliation has no first-slot restriction; native timing still awaits acceptance.
4. Do not add the mod to an existing save or remove it from a Ministry save. Existing version 1 saves retain their snapshot. Check `Database.log` and `Lua.log` when doing the acceptance tests.

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

**Statically verified but awaiting in-game acceptance.** Checks cover SQLite execution against a BNW cache with CP151 schema and an existing CP-schema cache, pristine and deliberately mutated source definitions, Lua 5.1 syntax, 25-slot and 34-living-major mock scenarios, 13 pinned source files, and DDS/manifest integrity. **Mocks do not demonstrate economic turn timing or an in-game pass.** See `tools/Validation.json` for the actual run results and database provenance.

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
python tools/build_art.py
python tools/build_mod.py --package
python tools/validate_mod.py
# Also test an existing CP-schema database without overlaying its schema:
python tools/validate_mod.py --compare-database "$env:USERPROFILE\Documents\My Games\Sid Meier's Civilization 5\cache\Civ5DebugDatabase.db"
```

Validation reads game files **read-only** and works on in-memory copies. Set `CWC3_DATABASE` to a BNW debug database **without Wacky3**, and `CWC3_CP_DIR` to the installed `(1) Community Patch` folder. Defaults use the normal Documents game directory and `cache_backup/Civ5DebugDatabase.db`. A pre-CP snapshot receives the installed CP schema overlay; a snapshot already containing CP schema is tested **without** adding missing schema tables or overwriting its options. Neither supplied cache is certified as CP-only. A clean active BNW+CP151 cache is still required for final integration acceptance. Art does not need regeneration for gameplay or documentation edits; run its compiler only when rebuilding or changing assets. The Choir generator changes only Choir SQL; its native temporary art needs no compilation.

The checked-in SQL uses `SELECT *` temporary clones, so gameplay inherits the active definitions at load time, rather than freezing vanilla stats in generated columns. Companion tables are enumerated from the CP151 schema at generation time. Re-run the generator when changing the target schema; inspect the emitted inventory before supporting a new patch. No build tool imports or needs Wacky2.

## Adding another civilization

Create a sibling folder with its own SQL, Lua, Art and README. Use unique `CWC3_` type suffixes and `TXT_KEY_CWC3_` localization. Add database files to `tools/build_mod.py:ORDER` in explicit load order and add an entry point only if its gameplay needs one. Keep shared infrastructure independent of individual civilizations. Preserve the existing mod GUID and save minimum unless there is an intentional save break. Add source evidence, meaningful behavior tests, a strategy guide and real DDS sources. Rebuild the **single pack manifest**, validate and perform in-game acceptance before release.
