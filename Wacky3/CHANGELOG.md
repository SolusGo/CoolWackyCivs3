# Changelog

## Daily Civ V Surprise #17 — The Seventeenth Summer — 5 November 2026

- Added Chorus-Mother Ixa, First Emergence, the human-only Summer civilization, localization and valid native fallback art.
- Added configurable four-speed, save-backed Dormancy/Emergence phases; explicit CP151 post-economy next-payout timing, exclusive city controllers and one-time transition notifications.
- Added active Spearman/Granary and complete companion inheritance, Shellguard Sight and upgrade lineage, universal Emergence CombatPercent, and Nursery permanent Faith/conditional Production.
- Added direct city/unit lifecycle reconciliation, narrowly pinned CP151 panel filters for the hidden marker, four-speed production Lua tests, source/SQLite/regeneration/package coverage and strategy/manual acceptance documentation. No native game pass is claimed.

## Version 1 schema compatibility correction — 3 November 2026

- Replace cache-derived companion inventories in both generators with pinned native BNW/standalone CP151 schema declarations. Preserve 145 building and 27 unit companion tables, including native unit selection audio.
- Remove unsupported Building_JFD_District and Building_ConstructionAudio clone blocks from both unique-building SQL files; no other generated gameplay SQL changes.
- Add a clean target-schema fixture with native XML samples and synthetic inheritance records, both existing cache regressions, artificial schema-contamination/byte-identical regeneration tests and ZIP byte validation.
- Preserve all 365 Choir/180 Ministry assertions, gameplay Lua, exact bonuses, GUID/version/save format, event hooks, art, dependencies and activation order. Native engine acceptance remains outstanding.
- Document the external CP manifest localization typo and full schema provenance/limitations in docs/CP151SchemaRepair.md.

## Version 1 roster addition — 2 November 2026

- Add The Hollow Choir, led by The First Note, with Resonance as capital; human-only registration, supplied Dawn/diplomacy wording, Civilopedia, strategy and violet/silver colors.
- Add independent Hill +1 Production and adjacent-Mountain Faith capped at +2; desired-state city reconciliation handles founding, transfers, borders, Hall changes and reload with five bounded dummies.
- Add active Swordsman/companion inheritance and a persistent +1 Sight / +20% native HillsDefense promotion for the Chorus Sentinel.
- Add active Amphitheater/companion inheritance, +1 Culture and Hall-dependent Science per two owned Mountains within radius three, capped at +2; shared Mountains count independently per city.
- Extend manifest, pinned CP151 audit, SQLite inheritance checks and Lua51 terrain/lifecycle tests. Existing Ministry civilization files and shared runtime/options are unchanged.
- Use documented native art placeholders. Custom crystal artwork and in-game acceptance remain pending; pack multiplayer/hotseat restrictions remain in effect.

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
