# CP151 schema compatibility repair — 3 November 2026

## Root cause and exact correction

Both generators harvested `Building_`/`Unit_` tables from modded debug caches. Their tests inspected the same cache inventories, so they confirmed internal consistency while missing the external dependency. The complete audit found two unsupported required tables: **Building_JFD_District** and **Building_ConstructionAudio**. Neither has a declaration in the audited BNW or standalone CP151 sources. The precise original mod supplying each table was not established. Only their two clone blocks were removed from each building SQL file: eight lines per civilization. No unit SQL, civilization SQL, localization SQL or building bonus definition changed.

`tools/target_schema.py` now constructs the approved target from installed native base/G&K/BNW table definitions, native sound/localization schemas, and CP151 manifest-ordered XML/SQL DDL. Base/expansion table declarations supersede earlier definitions; CP table replacement/rename operations are applied rather than ignored. Defaults (including SQL NULL and booleans), primary/unique/not-null constraints, indexes and triggers are retained. Temporary schema tables must be cleaned up. CP schema input files must match the v151 package manifest MD5s; 260 installed input SHA256s and the derived column inventory are checked into `tools/cp151_schema_sources.json`. The separate existing 13-file DLL source pin remains unchanged.

The generators no longer inspect cache schemas at all. Both use the same verified target inventory, and changed source hashes/inventory cause an error until explicitly audited and repinned. `CWC3_DATABASE` is solely a supplementary validation input. `CWC3_SQL_ROOT` redirects generated output during regression tests. No optional third-party compatibility mechanism or missing-table SQL guard was introduced.

## Complete inventory and SQL audit

The target retains **145 building companion tables and 27 unit companion tables** (26 `Unit_` tables plus native `UnitGameplay2DScripts`). Every previous companion other than the two unsupported tables remains. Full table names, column types/defaults/constraints and source file hashes are in `tools/cp151_schema_sources.json`. Representative preserved CP tables include `Building_PlotYieldChanges`, `Building_InstantYield`, `Building_YieldPerXTerrainTimes100` and the CP-modified `Building_ThemingBonuses`; normal yield/prerequisite/Great Work/flavor/resource/free-promotion/upgrade companions and native unit selection sounds remain.

All ten database actions execute in existing order: shared options; Ministry civilization, units, buildings, text, art; Choir civilization, units, buildings, text. Scalar clones continue using the active row's full column order, then modify only the intended identity/unique deltas. Companion clones rekey the parent type and clear an auto-ID if present. Source/clone rows retain identical order because each temporary clone is created directly from its destination table. No new target-only columns are baked into runtime scalar copies. Clean-schema constraints and nonempty companion tests exercise duplicate-key and positional-copy safety. Every clone temporary table is dropped; original native rows remain unchanged.

The audit confirms both human-only civilization registrations, UU/UB overrides, nine controller buildings across the pack, three unique promotions, localization patterns, source sound inheritance, and complete approved companion copying. Generators remain deterministic. All existing Lua and artwork are unchanged.

## Actual validation results

| Validation | Result | Evidence and boundary |
| --- | --- | --- |
| Clean BNW + CP151 schema | PASS | All ten Wacky3 actions execute, pristine/mutated cases, in a source-derived 808-table schema fixture. Native XML sample data plus 329 synthetic companion records; not native final CP gameplay data. |
| Existing modded baselines | PASS | Pristine/mutated cases for both previous sources: 491-table legacy cache with overlay; 959-table CP-schema cache without overlay. Six SQL cases total including the clean fixture. |
| Third-party schema contamination | PASS | Add Building_JFD_District and an artificial unit table, rerun both generators; all seven generated SQL files remain byte-identical to checked-in output. Both generators also match under the uncontaminated fixture. |
| Inventory completeness | PASS | Both civs emit exactly 145 approved building and 27 approved unit companions. Synthetic records exercise otherwise-empty native/CP tables. Negative controls fail on both removed missing tables. |
| Hollow Choir regression | PASS | Original 365 assertions unchanged. |
| Ministry regression | PASS | Original 42 + 138 assertions unchanged, including timing safeguards/save repair/upgrade scenarios. |
| Lua syntax | PASS | All eight existing Lua files parse under Lua 5.1. |
| Source evidence | PASS | 13 pinned DLL-source files and API/order assertions; 260 pinned installed schema/sample source inputs. |
| Manifest and packaging | PASS | Existing GUID/version/save minimum/dependencies, ten actions, both contexts, VFS/checksums, existing 48 DDS assets; rebuilt ZIP entries match current source bytes. |
| Actual Civilization V runtime | NOT TESTED | No game was launched for this repair. |

The old table comparison count drops from 174 to **172** because two unsupported tables were removed; **no behavioral assertion was removed or reduced**. `tools/Validation.json` records the actual environment provenance and all results. The added report brings the pack manifest to 76 files; there remain ten database actions and two gameplay contexts.

Reproduce from `Wacky3` using the documented development requirements, the installed BNW assets and unmodified CP151 schema sources:

```powershell
python tools/target_schema.py
python tools/generate_sql.py
python tools/generate_hollow_choir.py
python tools/build_mod.py --package
python tools/validate_mod.py --compare-database "$env:USERPROFILE\Documents\My Games\Sid Meier's Civilization 5\cache\Civ5DebugDatabase.db"
```

Set `CWC3_GAME_DIR` if Steam library discovery cannot find the installed game and `CWC3_CP_DIR` if CP is elsewhere. `python tools/target_schema.py --pin` intentionally changes the trust record and is reserved for audited source changes. Generation does not require either cache. The full validation additionally reads the two existing caches without modifying them. Build/test artifacts remain under ignored `dist/` or temporary directories.

## Every changed file

Paths below are relative to `Wacky3`.

| File | Purpose |
| --- | --- |
| TheHollowChoir/SQL/Choir_Buildings.sql | Remove only unsupported district/construction-audio clone blocks. |
| TheMinistryOfAlmost/SQL/Ministry_Buildings.sql | Same compatibility correction for the Academy. |
| tools/target_schema.py (new) | Source-derived target schema, pin verification, approved inventories and clean fixture. |
| tools/cp151_schema_sources.json (new) | All 260 source SHA256s and 172 approved companion column definitions. |
| tools/generate_sql.py | Use verified schema inventory and support isolated output for regeneration tests. |
| tools/generate_hollow_choir.py | Same source-controlled inventory/output changes. |
| tools/baseline.py | Require source verification and identify old cache overlay as supplementary, never authoritative. |
| tools/validate_schema.py (new) | Exact inventory checks, nonempty companion sentinels, negative controls and clean/contaminated regeneration tests. |
| tools/validate_mod.py | Prioritize clean schema fixture, retain all prior cache/Lua checks, use approved inventory, verify ZIP bytes. |
| tools/validate_hollow_choir.py | Compare only approved target companions; preserve all gameplay checks. |
| tools/audit_cp.py | Verify/report installed schema pins alongside existing DLL-source checks. |
| tools/Validation.json | Record actual six-environment-case, source, regeneration and regression results. |
| Cool Wacky Civs 3 (v 1).modinfo | Refresh checksums and include this report; preserve registration/dependency/action/context metadata. |
| README.md | Explain schema generation trust, inputs, workflow and verification limits. |
| CHANGELOG.md | Record this correction without a version/balance change. |
| docs/Compatibility.md | Root cause, schema inventory/provenance, fixture boundaries and external package finding. |
| docs/HollowChoirTesting.md | Updated actual results and corrected 172-table inheritance scope. |
| docs/Testing.md | Expanded reproduction/test coverage while retaining all pending engine acceptance checks. |
| docs/CP151SchemaRepair.md (new) | This complete technical report. |

## Gameplay preservation and remaining risks

Choir retains independent +1 Hill Production and adjacency Faith capped at +2; Sentinel active Swordsman inheritance, +1 Sight, +20% defending-on-Hills promotion with upgrade persistence; Hall active Amphitheater inheritance, additional +1 Culture and owned-Mountain Science per two within hex radius three capped at +2. All five Choir dummy/reconciliation rules remain byte-identical.

Ministry retains exact technology-gap thresholds, four dummies, active Spearman/Library inheritance, +1 Guard Movement, persistent identity/conditional home defense, Academy Culture/conditional Production, snapshot format, upgrade handling, timing/slot restrictions and human-only registration. GUID, version 1, save minimum, event hooks, runtime helper and all art remain unchanged.

This establishes target **schema** compatibility. The fixture intentionally does not simulate the full engine's XML/DML loader, CP data sweeps, foreign-reference validation against a complete gameplay dataset or native economic processing. Installed native/schema sources are hash-pinned local inputs, not a fresh Steam depot/binary reproduction. Existing modded caches remain supplementary and not certified clean. Native clean-game initialization, actual yield/combat/save behavior and the Ministry's known UI-dispatch timing boundary still require acceptance; this repair does not attempt to change them. Choir custom crystal artwork remains pending, with valid native placeholders.

One external installed-package issue was observed and left unchanged: CP151's manifest references absent `Database Changes/Text/en_US/CoreGameOptionTextChanges.xml`; a matching `.sql` contains only a localization UPDATE. The schema fixture explicitly skips that absent text action. This is not a missing Wacky3 schema dependency; native CP log/packaging acceptance should check it separately. No installed game or CP file was edited.
