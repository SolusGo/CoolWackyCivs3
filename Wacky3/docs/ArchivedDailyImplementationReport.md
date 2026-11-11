# Archived Daily expansion implementation report

Completed source/automated validation on **12 November 2026** for BNW + standalone CP151, Windows sequential single-player. Native Civilization V gameplay was **NOT RUN**. Baseline commit: `f772bb8` (already containing the Directorate). The feature branch is `feat/archived-daily-civilizations`; its final commit/push identifier is supplied in the delivery message so the report does not contain a self-referential commit hash.

## A. Civilization status

All five requested archived designs are present in the final ten-civilization roster. The four missing civilizations are new; the existing Directorate is retained and revalidated, with free-building class eligibility corrected. The five original civilizations' entire directories and shared original Runtime helper are byte-identical to baseline.

| Civilization | Implemented UA | Implemented UU | Implemented UB | Assumptions / outstanding acceptance |
| --- | --- | --- | --- | --- |
| Department of Lost Things | Saved city lifetime ledger, 0–4 Curios; +1 recurring Culture/+1 Science each; one nearest city per genuine nearby enemy combat kill; persisted victim deduplication | Active Spearman clone, +1 Sight/+15% native anti-Barbarian strength | Active Library clone, +1 Culture/+1 Gold per Curio; no reconstruction multiplication | Radius three, lowest city ID ties, full nearest city consumes kill, both combat sides; excludes civilians/disbands/aborted or collateral-only removals. Captures pause original collector's ledger, liberation restores, razing/refounding clears. Native combat dispatch/payout/save acceptance outstanding. |
| Assembly of Scarecrows | Three owned unpillaged radius-three Farms: +2 Culture/+1 Production; six additionally +2 Food; unworked/overlap supported | Active Spearman clone, +1 Sight/+15% native friendly-territory attack/defense | Active Granary clone, +1 permanent Culture; +1 Gold per three qualifying Farms capped at three | Native friendly rule includes own/team/qualifying Open Borders and uses native battle-location semantics. Pillage/repair/ownership/reload reconcile; native previews, tile-event timing and payouts outstanding. |
| Kingdom of Makuria | Any real/free Walls-class member gives its city +1 Culture/+1 Faith once | Active Composite Bowman clone, +1 Sight/+15% defense only, including ranged defense; no offensive modifier | Active Temple clone, +1 Culture/+1 Science | Normal and unique replacements qualify; independent local Boolean condition. No extra currency/system. Native actual combat, saves and payout acceptance outstanding. |
| The Salt Road Compact | Binary outgoing active land-route city condition: +2 Production/+1 Culture | Active Horseman clone, +1 Sight; native target-Desert +15% attack / defender-Desert +15% defense, including Desert Hills/features | Active Caravansary clone, permanent +1 Food/+1 Gold; conditional +1 Science | FromID/FromCity/Domain/owners/circuits/recall checks; no incoming/sea/expired/canceled qualification. Cancellation without a post-change hook waits for dirty/turn recovery. Normal mounted melee upgrade line supported; arbitrary ranged conversion has a documented CP source limitation. Native route/preview/payout acceptance outstanding. |
| The Paleontological Directorate | Library class +1 Science; independently University class +1 Culture; real/free/replacements once | Existing active Archaeologist clone, +1 Movement/+1 Sight; genuine successful PlayerBuilt excavation gives 17/25/38/75 Science by standard speed, once per saved site | Existing active Museum clone, +2 Science/+1 Culture; specialists, Great Work slots and all inherited companions retained | Successful finished-build source contract retained; no unit-death/site-disappearance inference. Native Artifact/Landmark choice, excavation dispatch, research overflow and engine save acceptance remain outstanding. |

Each new civilization creates four SQL files (`Civilization`, `Units`, `Buildings`, `Text`), one Lua gameplay file/XML context, README, TESTING and documented Art fallback README. Shared lifecycle wiring is new and used only by these additions. Per-civilization strategy guides, source fixture/audit, deterministic generator and integration tests are included. Directorate modifications are limited to total class checks, matching localization/generator/tests and guide corrections; its excavation mechanics and art are unchanged.

Full guides: [Department](../TheDepartmentOfLostThings/README.md), [Scarecrows](../TheAssemblyOfScarecrows/README.md), [Makuria](../TheKingdomOfMakuria/README.md), [Salt Road](../TheSaltRoadCompact/README.md), [Directorate](../ThePaleontologicalDirectorate/README.md). Each includes its original Weekly-civs archive reference, exact rules, opening/midgame/late-game priorities, weaknesses, counterplay, speed behavior, art and native testing limits. No changes were made to Weekly-civs, Wacky1 or Wacky2.

## B. Integration and package

- **Ten** human-selectable, AI-unselectable civilizations; `Playable=1`, `AIPlayable=0`.
- Single `Cool Wacky Civs 3 (v 1).modinfo`, **45 unique UpdateDatabase actions**, explicit civilization → units → buildings → text order for each addition.
- **Ten** InGameUIAddin contexts: the six existing contexts plus LOST_Gameplay.xml, SCARECROW_Gameplay.xml, MAKURIA_Gameplay.xml and SALT_Gameplay.xml. Lua/helper files import into VFS; gameplay XML/SQL use the existing manifest conventions, with no duplicate imported basenames.
- Install ZIP: `Wacky3/dist/Cool Wacky Civs 3 (v 1).zip`, built without ModBuddy. It contains the single install folder, current manifest and every declared source/resource. Dist remains ignored under the repository's existing policy; the reproducible source and manifest are committed.
- Original GUID **70d794f7-4fb2-4196-9709-8193f8ee36a9**, BNW/standalone CP151 dependency, version **1**, save minimum **1**, existing record formats and original five gameplay remain intact. New Curio records are independently namespaced.
- **Existing-save compatibility has not been acceptance-tested. Start a new game for the new roster.** Preserving metadata/record formats is not a claim of old-save compatibility.
- Four additions use unique colors and valid native America/Washington and parent-unit/building atlases, Dawn/diplomacy/model/audio fallbacks. No fabricated texture reference or optional art dependency is introduced. Existing 183 DDS assets remain unchanged and validated.

## C. Actual test results

The full command `python tools/validate_mod.py --compare-database <existing CP-schema cache>` completed successfully. [Validation.json](../tools/Validation.json) records the machine-readable results; the [source and native acceptance matrix](ArchivedDailyTesting.md) explains their limits.

| Test category | Actual result |
| --- | --- |
| Static SQL execution | PASS: six pristine/mutated database runs across clean source-derived schema, supplementary BNW-derived cache with schema overlay and existing CP-schema cache without overlay. Caches are not certified clean CP-only gameplay data. |
| Inheritance / integrity | PASS: all active unit/building scalars and all 172 approved companions; mutated stats/slots/resources/upgrade data and exact duplicate-yield additions; unchanged native parent rows/companions, identifiers, localization, free starts, class/unit overrides and ten human-only registrations. |
| Lua syntax / mocks | PASS: 24 Lua files parse under Lua 5.1. All original suites pass. New archive scenarios total 5,416 assertions across four speeds and 4/34 occupied slots, 25+ cities per civ, 100 routes and 1,000+ units; Directorate totals 904 lifecycle/reward assertions across four speeds/two human slots. No global unit scan; bounded adjacency and shared route enumeration checked. |
| Source API verification | PASS: core/Directorate pins plus new pinned trade source; combat argument/order and lethal participant evidence, native promotion readers/consumers, real/free class counts, farm/pillage ownership callbacks, trade-origin/domain/circuit lifecycle, successful archaeology completion and serialized player state. Source inspection is not native runtime execution. |
| Regeneration | PASS: all **39** generated SQL outputs byte-identical with clean fixture and artificial third-party contamination. Original 260 schema pins and 172-table inventory unchanged. |
| Package / art | PASS: manifest identities/dependencies/order/contexts/imports, MD5s, XML, native fallback equality, 183 existing DDS textures/mips/transparency and ZIP byte integrity. Documentation finalization is followed by a rebuilt manifest/ZIP and another package-integrity check. |
| Actual native Civ V gameplay | **NOT RUN**. No native combat, economic, save/load, archaeology choice or rendering pass is claimed. |

## D. Limits requiring native acceptance

Source verifies the selected combat/archaeology/trade callbacks and actual promotion fields, but native delivery, quick-combat previews/resolution, ordinary upgrades and closed-engine UI timing need observation in Civ V. Combat mocks do not execute DLL strength formulas. The Dune Escort uses precise native melee target terrain, not a temporary generic approximation; CP's own-plot ranged attacking branch is documented for unsupported arbitrary ranged conversions.

Owner-turn reconciliation is **post-economy** and affects the **next payout**. Direct events update controllers when delivered. Missing script/cancel callbacks recover at bounded dirty/turn evaluations; no immediate payout is invented. Captures strip foreign controllers; destruction/refounding and serialized ledgers are mocked/source-audited but need native save files and logs.

The Directorate's successful-excavation observation is source-demonstrated through the finished branch of CvUnit::build/PlayerBuilt and native human choice queue. It is not inferred from a unit disappearing or merely arriving at a site. Both native choice paths, interruption/death exclusions, research overflow and actual save serialization still require its existing A–T acceptance checklist. Unknown custom speeds explicitly disable the reward rather than invent a value.

The clean fixture reconstructs schema and selected native samples/synthetic companions, not final CP gameplay balance. Multiplayer, hotseat, custom DLLs/VP, conflicting UI mods, arbitrary third-party gameplay mutations and ScriptData replacement remain outside certification. 34 slots is a mock stress case subject to installed DLL limits. The four native art fallbacks are usable but do not provide original historical/fantasy leader portraits.

## E. Complete changed-file inventory

- `Wacky3/CHANGELOG.md` (modified)
- `Wacky3/Cool Wacky Civs 3 (v 1).modinfo` (modified)
- `Wacky3/README.md` (modified)
- `Wacky3/Shared/Lua/CWC3_ArchiveLifecycle.lua` (created)
- `Wacky3/TheAssemblyOfScarecrows/Art/README.md` (created)
- `Wacky3/TheAssemblyOfScarecrows/Lua/SCARECROW_Gameplay.lua` (created)
- `Wacky3/TheAssemblyOfScarecrows/Lua/SCARECROW_Gameplay.xml` (created)
- `Wacky3/TheAssemblyOfScarecrows/README.md` (created)
- `Wacky3/TheAssemblyOfScarecrows/SQL/SCARECROW_Buildings.sql` (created)
- `Wacky3/TheAssemblyOfScarecrows/SQL/SCARECROW_Civilization.sql` (created)
- `Wacky3/TheAssemblyOfScarecrows/SQL/SCARECROW_Text.sql` (created)
- `Wacky3/TheAssemblyOfScarecrows/SQL/SCARECROW_Units.sql` (created)
- `Wacky3/TheAssemblyOfScarecrows/TESTING.md` (created)
- `Wacky3/TheDepartmentOfLostThings/Art/README.md` (created)
- `Wacky3/TheDepartmentOfLostThings/Lua/LOST_Gameplay.lua` (created)
- `Wacky3/TheDepartmentOfLostThings/Lua/LOST_Gameplay.xml` (created)
- `Wacky3/TheDepartmentOfLostThings/README.md` (created)
- `Wacky3/TheDepartmentOfLostThings/SQL/LOST_Buildings.sql` (created)
- `Wacky3/TheDepartmentOfLostThings/SQL/LOST_Civilization.sql` (created)
- `Wacky3/TheDepartmentOfLostThings/SQL/LOST_Text.sql` (created)
- `Wacky3/TheDepartmentOfLostThings/SQL/LOST_Units.sql` (created)
- `Wacky3/TheDepartmentOfLostThings/TESTING.md` (created)
- `Wacky3/TheKingdomOfMakuria/Art/README.md` (created)
- `Wacky3/TheKingdomOfMakuria/Lua/MAKURIA_Gameplay.lua` (created)
- `Wacky3/TheKingdomOfMakuria/Lua/MAKURIA_Gameplay.xml` (created)
- `Wacky3/TheKingdomOfMakuria/README.md` (created)
- `Wacky3/TheKingdomOfMakuria/SQL/MAKURIA_Buildings.sql` (created)
- `Wacky3/TheKingdomOfMakuria/SQL/MAKURIA_Civilization.sql` (created)
- `Wacky3/TheKingdomOfMakuria/SQL/MAKURIA_Text.sql` (created)
- `Wacky3/TheKingdomOfMakuria/SQL/MAKURIA_Units.sql` (created)
- `Wacky3/TheKingdomOfMakuria/TESTING.md` (created)
- `Wacky3/ThePaleontologicalDirectorate/Lua/PALEO_Gameplay.lua` (modified)
- `Wacky3/ThePaleontologicalDirectorate/README.md` (modified)
- `Wacky3/ThePaleontologicalDirectorate/SQL/PALEO_Text.sql` (modified)
- `Wacky3/ThePaleontologicalDirectorate/TESTING.md` (modified)
- `Wacky3/TheSaltRoadCompact/Art/README.md` (created)
- `Wacky3/TheSaltRoadCompact/Lua/SALT_Gameplay.lua` (created)
- `Wacky3/TheSaltRoadCompact/Lua/SALT_Gameplay.xml` (created)
- `Wacky3/TheSaltRoadCompact/README.md` (created)
- `Wacky3/TheSaltRoadCompact/SQL/SALT_Buildings.sql` (created)
- `Wacky3/TheSaltRoadCompact/SQL/SALT_Civilization.sql` (created)
- `Wacky3/TheSaltRoadCompact/SQL/SALT_Text.sql` (created)
- `Wacky3/TheSaltRoadCompact/SQL/SALT_Units.sql` (created)
- `Wacky3/TheSaltRoadCompact/TESTING.md` (created)
- `Wacky3/docs/ArchivedDailyImplementationReport.md` (created)
- `Wacky3/docs/ArchivedDailyTesting.md` (created)
- `Wacky3/docs/Compatibility.md` (modified)
- `Wacky3/docs/strategy/TheAssemblyOfScarecrows.md` (created)
- `Wacky3/docs/strategy/TheDepartmentOfLostThings.md` (created)
- `Wacky3/docs/strategy/TheKingdomOfMakuria.md` (created)
- `Wacky3/docs/strategy/TheSaltRoadCompact.md` (created)
- `Wacky3/tools/Validation.json` (modified)
- `Wacky3/tools/archived_fixture.py` (created)
- `Wacky3/tools/archived_sources.json` (created)
- `Wacky3/tools/build_mod.py` (modified)
- `Wacky3/tools/generate_archived.py` (created)
- `Wacky3/tools/generate_paleo.py` (modified)
- `Wacky3/tools/target_schema.py` (modified)
- `Wacky3/tools/tests/archived.lua` (created)
- `Wacky3/tools/tests/paleo.lua` (modified)
- `Wacky3/tools/validate_archived.py` (created)
- `Wacky3/tools/validate_mod.py` (modified)
- `Wacky3/tools/validate_schema.py` (modified)
