# Ministry of Almost — corrective hardening report

Status: **statically verified but awaiting in-game acceptance**. The existing Wacky3 implementation was hardened in place. Original UA thresholds, Guard/Academy balance, civilization registration, mod GUID, version 1 save-record format, artwork and models are preserved. No earlier Wacky pack was modified.

## Confirmed code and test defects

| Finding | Exact correction |
| --- | --- |
| Reload repaired Academy Production but left incorrect Science/Culture counts in Ministry cities | All four real/free counts are reconciled against the saved tier; no technology lookup or new snapshot occurs |
| Dummy helper never cleared free copies, and numeric zero was truthy | Explicit 0/1 conversion, verified free-building removal, explicit construction-bonus suppression and no refunds |
| Dirty recovery ignored former Ministry cities after a missed transfer callback | Track coordinates, resolve the current city object/owner and clear foreign counts; retain a once-per-owner recovery pass |
| Unit table-prefix cloning omitted the existing Spearman selection-sound row | Clone UnitGameplay2DScripts at runtime and compare it in SQL regression checks |
| Audit/docs claimed UnitUpgraded was post-conversion; mocks supplied the identity too early | Verify the actual pre-conversion event order and exercise creation → upgrade notification → promotion transfer → UnitConverted |

These are code/database/test findings, not claims of bugs observed in a running game. The existing UnitConverted hook already protected the ordinary upgrade path; the hardening retains it as authoritative after transfer rather than claiming that every previous upgrade necessarily lost its identity. Normal gifts/cessions do invoke CityCaptureComplete in the pinned source; no separate missing native gift event was invented.

## Preventive timing and reliability changes

- Actual Ministry owners are discovered explicitly. A NewGameTurn candidate can establish a snapshot only for the first living sequential owner. Earlier eliminated slots are handled; a later owner with earlier living players logs a warning and retains its saved snapshot without taking an early substitute.
- AIProcessingStartedForPlayer no longer changes gameplay. Its human-owner dispatch is unverified, so it is diagnostic-only. PlayerDoTurn and ActivePlayerTurnStart mark an observed post-economy boundary; later candidates in that owner-turn are rejected. Stale turn numbers and duplicate snapshots are ignored.
- Optional diagnostics record event, turn, owner, sampled gap, saved tier, per-city real/free counts, lifetime Culture, research progress and production/queue stores. They are disabled by default, read-only and bounded to 128 in-memory records. They do not award yields or infer automatic acceptance from rate displays.
- Reconciliation guards the whole transaction against recursive dirty callbacks, writes only changed counts, and preserves unrelated ScriptData. An identical snapshot is not rewritten. Cached veteran IDs replace full unrelated-unit sweeps on every owner's turn; converted old IDs are removed from the cache.
- Native acquisition source proves completion follows building/ownership transfer for conquest, gifting and peace-treaty cession. Academy construction/purchase/sale retains direct hooks; dirty/owner recovery also removes dependent Production after scripted removal.

## Files modified or added

- `Shared/Lua/CWC3_Runtime.lua`: bounded real/free helper, explicit no-bonus flags, snapshot validation/idempotent saving.
- `Shared/Lua/CWC3_Diagnostics.lua` (new): optional read-only trace.
- `TheMinistryOfAlmost/Lua/Ministry_Gameplay.lua`: conservative event handling, full saved-tier reconciliation, coordinate recovery and veteran cache.
- `TheMinistryOfAlmost/SQL/Ministry_Units.sql` and `tools/generate_sql.py`: active selection-sound inheritance; no stat changes.
- `tools/audit_cp.py`, `tools/cp151_sources.json`: exact event order/signatures, free-count and diagnostic bindings, defense-only branches and timing evidence; 13 pinned source files.
- `tools/baseline.py`: report provenance; test existing CP-schema caches without manufacturing missing schema/options.
- `tools/validate_mod.py`, `tools/tests/ministry_mock.lua`, `tools/tests/ministry_hardening.lua` (new), `tools/Validation.json`: stronger SQL, source and isolated mock regressions.
- Pack README/changelog, Ministry README, Compatibility, Testing and this report; regenerated pack `.modinfo` checksums and diagnostic Lua VFS entry.

No Library/Academy SQL balance change, art regeneration, texture/model replacement, new gameplay resource, instant-yield award or custom DLL change was introduced.

## Tests and results

1. **CP151 source verification:** 13 source hashes and concrete API/order/signature assertions pass. DefenseMod is loaded natively, used in melee defense and the non-attacking ranged-strength branch, and excluded from melee attack. UnitUpgraded is before convert; UnitConverted is after promotions transfer. CitySoldBuilding follows sale; acquisition completion follows building and ownership copies. NewGameTurn publication precedes first sequential activation; PlayerDoTurn is after economic settlement.
2. **Static SQL:** pristine and deliberately mutated source definitions pass on both the BNW-derived schema-overlay fixture and the actual existing CP-schema cache. All inherited Library/Spearman scalar fields and companions, +1 Academy Culture, bounded dummy yields, class overrides, starting units, human-only registration, localization and selection sounds are checked. Native source rows remain unchanged and temporary clones are dropped.
3. **Lua51 mocks:** 42 original city-yield assertions plus 138 hardening assertions pass, including every threshold, saved-state/free-count repair, reload at every tier, gifts/cessions, replacement city IDs, Academy purchases/removal, exact normal/goody upgrade order, foreign/neutral/team defense, late/duplicate notification rejection, diagnostics and 34 living major teams. These are simulations, not engine execution.
4. **Package/art:** XML context, SQL order, dependency IDs, VFS uniqueness/imports, manifest checksums and all 48 DDS dimensions/formats/alpha/mips pass. Existing artwork remains byte-identical to the preceding commit. A regenerated install ZIP is available locally in ignored `dist/`.

Database discrepancy is explicit: the default source has 491 tables/120 civilizations before overlay, while the existing CP-schema cache has 959 tables/194 civilizations and is tested without overlay. Both are modded rather than certified CP-only. Relevant original Library/Spearman values agree. See Compatibility and Validation.json for exact fields and provenance. Runtime clones continue using actual active definitions, not a permanently copied vanilla baseline.

## Remaining engine acceptance and readiness

**Civilization V was not launched for this pass.** Source inspection cannot establish synchronous delivery of the closed engine's NewGameTurn UI notification. The optional trace must demonstrate correct dummy installation before native Production/Culture/Science collection and the expected actual stored yield changes in controlled comparisons. If delivery is late, the exact mechanic is not accepted; rejection and preservation of an old tier are conservative failure handling, not a complete pre-economy solution. No better verified general owner-boundary hook was established without changing the DLL or approximating the rules.

The precise unsupported slot is a Ministry owner with any earlier living sequential player. A higher slot becomes eligible after all earlier players die. Teams are handled through shared technology ownership and team-owned defense, but do not bypass that boundary restriction. Multiplayer, hotseat and autoplay remain unsupported.

Remaining manual checks are fully enumerated in [Testing.md](Testing.md): clean BNW+CP151 load/selection and error logs; actual economic timing at gaps two/three/six and same-boundary research completion; all threshold/leader/team scenarios; founding/conquest/annexation/puppeting/gift/cession/liberation and capital loss; Academy inheritance and dependent Production; native save/reload and zero/free-count cleanup; defensive-only combat, tile ownership changes, normal/goody upgrades and unit gifting; 22–34-major performance and in-game art/diplomacy presentation. Every engine checkbox remains unchecked.

The code is ready for controlled acceptance testing. It is **not certified ready for an unrestricted gameplay release** until the pre-economy boundary and clean CP151 runtime checks pass.
