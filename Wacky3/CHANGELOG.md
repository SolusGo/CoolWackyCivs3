# Changelog

## Version 1 hardening — 2 November 2026

Fixed defects:

- Repair every UA/Academy dummy on reload and recovery from the saved tier, instead of repairing only Academy Production in Ministry cities.
- Clear illegal free dummy copies as well as real counts; explicitly suppress construction bonuses and refunds. Fixed numeric zero being treated as true by the shared building helper.
- Recover missed foreign transfers using stable city coordinates, even when acquisition replaces the city object/ID.
- Restore the Spearman's `UnitGameplay2DScripts` selection and first-selection sounds on the Guard.
- Correct the source audit and upgrade tests: `UnitUpgraded` fires before conversion, `UnitConverted` after promotion transfer.

Preventive improvements:

- Remove the unverified AI-processing snapshot fallback; use it for diagnostics only. Find actual Ministry owners and restrict snapshots to the first living sequential owner. Log unsupported slots and reject stale/observably post-economy notifications.
- Add disabled-by-default bounded timing diagnostics with raw Culture/research/production stores, event names, gap, saved tier and real/free counts.
- Guard complete reconciliation transactions against nested dirty callbacks; avoid redundant save/building writes and full unrelated unit sweeps.
- Verify exact CP151 event argument order and diagnostic bindings against 13 pinned source files. Add reload-at-every-tier, corrupt/free state, gifted/ceded city, native upgrade order and 34-living-major regressions.
- Test pristine and mutated Library/Spearman definitions against both a schema-overlay fixture and an existing CP-schema cache, without manufacturing missing tables in the latter.
- Preserve GUID, version 1 save format, all balance numbers, art, models and dependency identifiers. Regenerate manifest checksums only for changed content.

Unresolved: no Civilization V execution was performed. Pre-economy UI dispatch, clean CP-only loading, actual combat/save behavior and presentation await the manual acceptance checklist. Status remains **statically verified but awaiting in-game acceptance**.

## Version 1 — 2 November 2026

- Established independent Wacky3 pack, unique GUID, exact CP151/BNW dependencies and modular shared infrastructure.
- Registered the human-only Ministry of Almost, Acting Chancellor Penultimate, Runner-Up capital and 24 city names.
- Implemented capped, save-backed technology-gap snapshots and real city Science/Culture yields, including city transfer cleanup.
- Added active Spearman inheritance, +1 Movement, persistent Second Wind identity and conditional defense-only promotion.
- Added active Library/companion inheritance, permanent Academy Culture and snapshot-dependent Production.
- Added original leader, capital, medal, Guard and Academy artwork; legacy DDS atlases, mipmaps, retained PNGs and reproducible compilation.
- Added localization, supplied Dawn of Man text, diplomacy fallbacks, strategy and technical documentation.
- Added SQLite, Lua 5.1/mock-event, source audit, texture and manifest validation.
- In-game acceptance remains required, especially pre-economy UI event dispatch. No engine test result is claimed.
