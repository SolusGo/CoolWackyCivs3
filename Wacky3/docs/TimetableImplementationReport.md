# The Perpetual Timetable — implementation report

6 November 2026. Implemented within the existing Cool Wacky Civs 3 pack. **Automated verification passes; genuine native-game acceptance has not been run.**

## A. File summary

The inventory below lists every added/modified deliverable and its purpose, relative to the repository. The ignored distributable is `Wacky3/dist/Cool Wacky Civs 3 (v 1).zip`. The ignored `tools/reference/CvLuaMap.cpp` is fetched audit evidence, recorded reproducibly by the added source hash; it is not part of the mod or redistributed ZIP. Original generated-image outputs remain in the imagegen output directory, with final PNG masters copied into this civilization's `Art/Sources`.

| Status | File | Purpose |
| --- | --- | --- |
| Modified | `Wacky3/CHANGELOG.md` | Record the civilization addition and verification limits. |
| Modified | `Wacky3/Cool Wacky Civs 3 (v 1).modinfo` | Regenerated single-pack actions, entry point, assets and MD5s; identifiers/dependencies unchanged. |
| Modified | `Wacky3/README.md` | Roster, mechanics, installation, timing and developer workflow. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Alpha128.dds` | Alpha128 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Alpha16.dds` | Alpha16 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Alpha24.dds` | Alpha24 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Alpha256.dds` | Alpha256 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Alpha32.dds` | Alpha32 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Alpha45.dds` | Alpha45 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Alpha48.dds` | Alpha48 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Alpha64.dds` | Alpha64 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Alpha80.dds` | Alpha80 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Civ128.dds` | Civ128 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Civ16.dds` | Civ16 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Civ24.dds` | Civ24 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Civ256.dds` | Civ256 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Civ32.dds` | Civ32 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Civ45.dds` | Civ45 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Civ48.dds` | Civ48 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Civ64.dds` | Civ64 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Civ80.dds` | Civ80 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Dawn.dds` | Dawn illustration, legacy RGBA DDS. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Leader.dds` | Leader illustration, legacy RGBA DDS. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Leader128.dds` | Leader128 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Leader16.dds` | Leader16 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Leader24.dds` | Leader24 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Leader256.dds` | Leader256 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Leader32.dds` | Leader32 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Leader45.dds` | Leader45 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Leader48.dds` | Leader48 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Leader64.dds` | Leader64 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Leader80.dds` | Leader80 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_LeaderScene.xml` | Static diplomacy scene referencing the unique leader DDS. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Map.dds` | Map illustration, legacy RGBA DDS. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Office128.dds` | Office128 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Office16.dds` | Office16 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Office24.dds` | Office24 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Office256.dds` | Office256 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Office32.dds` | Office32 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Office45.dds` | Office45 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Office48.dds` | Office48 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Office64.dds` | Office64 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Office80.dds` | Office80 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Unit128.dds` | Unit128 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Unit16.dds` | Unit16 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Unit24.dds` | Unit24 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Unit256.dds` | Unit256 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Unit32.dds` | Unit32 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Unit45.dds` | Unit45 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Unit48.dds` | Unit48 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Unit64.dds` | Unit64 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/CWC3_Timetable_Unit80.dds` | Unit80 one-cell icon, legacy RGBA DDS with alpha and complete mip chain. |
| Added | `Wacky3/ThePerpetualTimetable/Art/Sources/Alpha.png` | Deterministic original wheel-clock alpha glyph. |
| Added | `Wacky3/ThePerpetualTimetable/Art/Sources/ArtReview.png` | Visually reviewed compiled icon/illustration contact sheet. |
| Added | `Wacky3/ThePerpetualTimetable/Art/Sources/Dawn.png` | Original generated monumental terminus master. |
| Added | `Wacky3/ThePerpetualTimetable/Art/Sources/Emblem.png` | Original generated wheel-clock civilization master. |
| Added | `Wacky3/ThePerpetualTimetable/Art/Sources/GenerationPrompts.json` | Exact built-in imagegen prompts and transparency settings. |
| Added | `Wacky3/ThePerpetualTimetable/Art/Sources/Leader.png` | Original generated Veyl portrait master. |
| Added | `Wacky3/ThePerpetualTimetable/Art/Sources/Office.png` | Original generated clock-tower administration building master. |
| Added | `Wacky3/ThePerpetualTimetable/Art/Sources/README.md` | Artwork provenance, formats, regeneration and native model notes. |
| Added | `Wacky3/ThePerpetualTimetable/Art/Sources/Unit.png` | Original generated surveying engineer master. |
| Added | `Wacky3/ThePerpetualTimetable/Lua/CWC3_Timetable.xml` | Single InGameUIAddin entry point. |
| Added | `Wacky3/ThePerpetualTimetable/Lua/TimetableGameplay.lua` | Human eligibility, ordinary connections, shared owned-rail BFS and five-controller lifecycle repair. |
| Added | `Wacky3/ThePerpetualTimetable/README.md` | Civilization rules, combined yields, lifecycle, timing and status. |
| Added | `Wacky3/ThePerpetualTimetable/SQL/Timetable_Art.sql` | Generated one-cell atlases in nine supported icon sizes. |
| Added | `Wacky3/ThePerpetualTimetable/SQL/Timetable_Buildings.sql` | Generated full active Workshop clone, one extra Gold and five yield controllers. |
| Added | `Wacky3/ThePerpetualTimetable/SQL/Timetable_Civilization.sql` | Generated human-only civilization/leader/trait, colors, starts, names and overrides. |
| Added | `Wacky3/ThePerpetualTimetable/SQL/Timetable_Text.sql` | Generated namespaced localization, exact Dawn/diplomacy and Pedia. |
| Added | `Wacky3/ThePerpetualTimetable/SQL/Timetable_Units.sql` | Generated full active Worker clone and exact unique deltas. |
| Modified | `Wacky3/docs/Compatibility.md` | Document the extension without changing previous compatibility evidence. |
| Modified | `Wacky3/docs/Testing.md` | Link the separate Timetable native acceptance checklist. |
| Added | `Wacky3/docs/TimetableImplementationReport.md` | Complete file inventory, mechanics, results and limitations. |
| Added | `Wacky3/docs/TimetableTesting.md` | Source evidence, A-N test mapping, timing contract and native checklist. |
| Added | `Wacky3/docs/strategy/ThePerpetualTimetable.md` | Early/mid/late-game strategy and yield timing. |
| Modified | `Wacky3/tools/Validation.json` | Actual source/schema/SQLite/Lua/DDS/manifest/package evidence. |
| Modified | `Wacky3/tools/audit_cp.py` | Verify Timetable engine bindings and native hex adjacency. |
| Modified | `Wacky3/tools/build_mod.py` | Add five ordered SQL actions, one gameplay context, scene import and roster text. |
| Added | `Wacky3/tools/build_timetable_art.py` | Reproducible original-PNG to legacy DDS/atlas/scene compilation. |
| Modified | `Wacky3/tools/cp151_sources.json` | Add reviewed map binding hash at the existing commit; preserve original hashes. |
| Added | `Wacky3/tools/generate_timetable.py` | Authoritative civilization/unit/building/text SQL generator. |
| Modified | `Wacky3/tools/target_schema.py` | Load separately verified data samples; preserve authoritative schema pin. |
| Added | `Wacky3/tools/tests/timetable.lua` | Production-controller hex/lifecycle/yield/performance assertions. |
| Added | `Wacky3/tools/timetable_fixture.py` | Native Worker/Workshop samples, existing pins plus two data-only hashes. |
| Modified | `Wacky3/tools/validate_mod.py` | Run Timetable SQL/Lua/rounding and extended art/context/package checks. |
| Modified | `Wacky3/tools/validate_schema.py` | Include fourth generator in full-companion and contamination regressions. |
| Added | `Wacky3/tools/validate_timetable.py` | Execute inheritance/rounding checks and SQL-derived-yield Lua51 mocks. |

## B. Implemented mechanics

- **The Grand Schedule:** every eligible non-capital city's native ordinary Capital connection supplies +1 Production/+1 Science. Roads and valid Harbor connections qualify through the engine API. After Railroad research, a separate BFS gives +1 Culture to owned cities reached through continuous owned intact land Railroad, accepting owned city centers as junctions. Foreign/unowned, water, Mountains, impassable, Road-only and pillaged segments fail. One BFS is shared across every city and the Office, never one per city.
- **Line Surveyor:** runtime active Worker scalar clone and all 27 approved companion tables, +1 Movement, rounded WorkRate×1.10. Cost, maintenance, builds, AI, capture, prerequisites, purchase, selection sounds, flag/model and all other fields remain inherited. Identity/localization/portrait are intentional changes. Runtime engine trainability/selection still needs native acceptance.
- **Dispatch Office:** runtime active Workshop scalar clone and all 145 approved companions, including specialists and production modifiers. Adds exactly one Gold in total to inherited Gold entries, including duplicate source entries. Non-capital Timetable Offices add +1 Culture for ordinary connections and +1 Production for the shared strict rail network. The Capital only receives the permanent +1 Gold beyond inherited Workshop behavior.
- Five invisible, unbuildable/unpurchasable, noncapturable, maintenance-free city-yield controllers are reconciled to exact zero/one real counts; free copies are cleared. Lifecycle events, owner fallback, stable coordinates and bootstrap repair stale/free/foreign counts. Only this civilization's five controllers are touched. No ScriptData, instant yields, UI, custom resource, free construction, teleportation or combat mechanic was introduced.
- Supplied exact diplomacy and Dawn narrative are localized; city/spy names, Civilopedia and leader personality are registered. Human playable, ordinary AI selection excluded. Navy/antique-gold custom portraits, emblem, Dawn and Office assets compile into real DDS atlases and a static diplomacy scene. Native Worker/Workshop world assets are retained.

## C. Actual verification

Commands run from Wacky3 with the repository's Python environment (`..\.venv\\Scripts\\python.exe`; Python 3.11, pinned Pillow/lupa):

| Command | Result |
| --- | --- |
| `python tools/target_schema.py` | Initial extended-sample attempt correctly failed the unchanged source pin. Corrected with independently hashed data-only fixture loading; no schema repin. The final full validator verifies the original pin. |
| `python tools/generate_sql.py` / `generate_text.py` / `generate_hollow_choir.py` / `generate_seventeenth_summer.py` / `generate_timetable.py` | PASS; all pack generators use the pinned target inventory; previous civilization outputs remain byte-identical. |
| `python tools/generate_summer_ui.py` | PASS; existing generated UI remains unchanged. |
| `python tools/build_timetable_art.py` | PASS; 48 legacy DDS assets, 45 complete icon mip chains. First attempt had no SQL destination directory after the pin guard stopped generation; the compiler now creates it. |
| `python tools/validate_timetable.py` | PASS; complete scalar/172-companion inheritance, explicit 80→88/85→94/100→110 WorkRate checks and 5,642 production-Lua assertions in each of the 4/34-player fixtures (11,284 total). An initial test expected a disconnection despite leaving a valid alternate route; corrected the fixture to remove that route before testing capture. |
| `python tools/build_mod.py --package` | PASS; one manifest, existing GUID/version/save minimum/dependencies, 19 SQL actions and four entry points. |
| `python tools/validate_mod.py` | PASS; four pristine/mutated clean/supplementary SQLite runs, source/schema audits, all previous Lua suites, Timetable suite, Lua51 syntax, art, manifest and package byte checks. |
| `python tools/validate_mod.py --compare-database <existing CP-schema cache>` | PASS; six SQLite runs total, including pristine/mutated existing CP-schema cache with no schema overlay; full suites and final artifact checks. |
| `git diff --check` | PASS. |

The clean schema uses native XML samples and synthetic companion sentinels; it does not recreate final CP gameplay migrations. Supplementary caches are existing modded caches, not certified clean CP-only captures. Test evidence is in `tools/Validation.json`. Source audit preserves all original 13 DLL hashes, adds reviewed `CvLuaMap.cpp` at the same CP151 commit, and verifies the unchanged 260 schema hashes/172 companion inventory. The two new native Worker data-only inputs are pinned separately in `timetable_fixture.py`. Raw-source web/shell lookups failed in this environment; the connected GitHub fetch supplied the reviewed map source. No installed game/CP file was edited.

Static checks prove human-only registration, overrides, localization, exact dummy yields, full active source inheritance/native row preservation, generator determinism under schema contamination, atlas bounds/alpha/mips and manifest/VFS/ZIP consistency. Lua checks execute the actual gameplay controller with SQL-derived yield mappings; they are not string searches or native engine tests. Previous regression results: Ministry 42+138 assertions, Choir 365, Summer four game speeds plus 25/34-major performance and pinned-panel rendering checks.

## D. Remaining limitations

**Civ V was not launched.** Actual engine payouts, ordinary Road/Harbor flag refresh, capture/building conversion, save serialization, unit trainability/selection, artwork/VFS and native UI presentation remain unchecked. See [TimetableTesting.md](TimetableTesting.md) for the full unchecked native acceptance list and source links.

CP151 source confirms the chosen API signatures and that PlayerDoTurn is post-economy. Timetable samples at that evaluation and sets recurring city yields for the **next payout after evaluation**. A route change during owner turn T without a direct callback normally waits until evaluation on T+1 and first pays at T+2. Confirmed founding/acquisition/liberation/Office construction/sale callbacks can establish counts sooner for their next payout. Load also recomputes current state, so it may observe a pending route change sooner than turn fallback; it never replays income. Native connection-cache freshness at these boundaries needs game verification. No pre-payout or synchronous UI-delivery claim is made, and no compensating instant yields are awarded.

There are no temporary portrait assets. The unit/world-building models and flag deliberately use native Worker/Workshop assets, the leader uses a static scene, and the map panel shows a terminus detail. Custom animated models/voice recordings are outside the specified implementation. Other mods that change source rows after Wacky3 loads, alter DLL hooks, or replace UI/model behavior are not certified. Multiplayer, hotseat, autoplay and forced AI Timetable gameplay remain unsupported.

## E. Gameplay correctness

These confirmations describe **executed SQL/Lua mocks**, with native acceptance outstanding:

| Requirement | Automated result |
| --- | --- |
| Roads work for basic yields | PASS: native ordinary flag drives Production/Science and Office Culture |
| Harbors work for basic yields | PASS: Harbor ordinary flag qualifies without railroad rewards |
| Full Railroads work for special yields | PASS: owned continuous graph, technology gate and city junctions |
| Partial Railroads insufficient | PASS: Road/missing segment loses rail yields only |
| Foreign railroads excluded | PASS: actual owner check, including other Timetable/allied players |
| Pillaged railroads cease qualifying | PASS: native pillage flag; repair/alternative branch scenarios |
| Worker retains CP inheritance | PASS: every scalar/companion; exact Movement/WorkRate deltas |
| Dispatch retains CP Workshop | PASS: every scalar/companion; +1 total Gold, separate conditionals |
| Capital restrictions | PASS: all five conditional counts zero; permanent Office Gold remains |
| Five dummies reconcile correctly | PASS: exact zero/one real counts, no free copies, repeats/reload/transfers |
| Six-city economy | PASS: +10 Production, +5 Science, +10 Culture, +6 Gold |
| Larger game | PASS: 100 rail cities, 50 disconnected, many foreign cities, one 201-plot BFS / 1,206 neighbor calls |
| Other Wacky3 civilizations unaffected | Original civilization/source/UI/art bytes unchanged; all prior suites PASS; only pack/tool/documentation integration extended |

All bonuses are flat recurring city yields. No tile-yield substitution, ordinary-connection shortcut for railways or additional gameplay bonus was introduced.
