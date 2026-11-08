# Changelog

## The Candlekeeper's Covenant — 9 November 2026

- Add human-only High Keeper Seraphine, Last Light, full supplied Dawn/diplomacy text, city/spy names and original candle/leader artwork within the existing GUID/package.
- Add a ScriptData-backed 12-Flame permanent destruction ledger using founding-turn/coordinate/lifetime identities, verified pre-removal CityRazed candidates, prompt capture/founding ownership updates and bounded city-list reconciliation. Captures do not award; last-owner minors/Covenants and Covenant-founded cities are excluded.
- Add twelve capital Culture, four capital Science and two Hall Science controllers with exact threshold yields, capital relocation, foreign/free-copy cleanup and idempotent reload/ownership repair. Nine Flames/six Halls reproduce +15 Culture/+15 Science.
- Clone the active CP Pikeman/Temple plus all 172 approved companions. Vigil Keeper adds permanent Sight/upgrade lineage and conditional DefenseMod=15, AttackMod=0 using native friendly territory. Verified pre-strength BattleStarted repairs defenders after silent diplomacy changes; no generic offensive friendly-land bonus is used. Hall adds exactly one permanent Culture, including duplicate inherited Culture rows.
- Add 30 legitimate DDS assets with retained original PNG masters/prompts, reproducible compilation, static leader scene, strategy, implementation report and manual native acceptance checklist.
- Extend pinned CP source evidence, clean/supplementary pristine/mutated SQLite, deterministic regeneration, production Lua51 lifecycle/ledger/combat/performance, and complete package tests. Existing civilizations' gameplay and SQL, schema pins, GUID/version/save minimum remain intact.
- Native Civ V acceptance has not been run. Unobservable scripted creation/transfer/destruction histories, economic settlement, engine save serialization, combat previews and runtime presentation remain documented acceptance limits.

## The Perpetual Timetable — 6 November 2026

- Add human-only Grand Stationmaster Veyl, Terminus Prime, The Grand Schedule, exact supplied diplomacy/Dawn narrative, city/spy names and navy/gold identity to the existing single pack.
- Add flat non-capital ordinary-connection Production/Science and post-Railroad Culture from a separate, continuous fully owned intact land-rail BFS; share one search across UA and Dispatch Office, excluding Roads, water, Mountains, impassable/pillaged/foreign/unowned segments.
- Clone the active CP Worker/Workshop and every approved companion. Line Surveyor adds +1 Movement/rounded 110% WorkRate; Dispatch Office adds exactly +1 permanent Gold, ordinary-connection Culture and strict railroad Production. Five invisible zero/one controllers use current-state reload/lifecycle repair and explicit post-economy next-payout timing.
- Add original PNG masters and 48 legitimate DDS assets, reproducible compilation, static leader scene, strategy/timing/native-acceptance documentation and complete changed-file inventory.
- Extend clean/supplementary SQLite, mutated stats/duplicate Gold, WorkRate rounding, Lua51 production behavior/performance, regeneration-contamination and package tests. Preserve schema pin, existing source hashes, GUID/version/save minimum, options and all previous civilizations' gameplay/source assets. Add one reviewed native map binding source and two separately hashed data-only fixture inputs.
- No native Civ V acceptance is claimed. Actual Road/Harbor cache refresh, economic settlement, save serialization, unit selection and presentation remain manual checks.

## Seventeenth Summer hardening audit — 6 November 2026

- Fix future saved-turn identifiers freezing cycle progression; safely repair malformed/overflow/duplicate records while preserving the existing namespace, valid record format, GUID and all mechanics.
- Filter ordinary unit events before phase work, eliminate repeated unit sweeps on duplicate callbacks and unrelated watched-city passes, and keep foreign owner-local recovery for illegal promotions/controllers.
- Add invalid-state, zero-city, liberation, Faith purchase, full transition reload, 25/34-major operation-budget and native/patched panel rendering regressions; extend source and fallback-art assertions. Document results separately from outstanding native in-game acceptance.

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
