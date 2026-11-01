# Version 1 implementation report

Implemented in the independent `Wacky3/` pack for `SolusGo/CoolWackyCivs3`. No changes to either earlier pack were made by this implementation.

## Delivered files

- One pack `.modinfo` with a new GUID, exact CP151 dependency, BNW dependency, six ordered database actions and one invisible gameplay context.
- Shared SQL hook options and shared Lua bounded-building/save-record helpers.
- Five Ministry SQL files: civilization/leader/trait, active Spearman clone, active Library clone and dummies, English localization/diplomacy, icon atlases.
- Ministry Lua gameplay and its context XML.
- 48 DDS textures: 45 atlas variants with full mip chains, Dawn of Man, static diplomacy scene and capital-detail map panel. Five original generated illustrations, programmatic alpha source, review sheet, prompts and compiler are retained under `TheMinistryOfAlmost/Art/Sources`.
- Pack README/changelog, Ministry guide, winning strategy, compatibility evidence and precise manual acceptance checklist.
- Source-hash/API auditor, SQL/localization generators, DDS compiler, manifest/ZIP builder, SQLite/Lua51/DDS validator and mock engine tests. No ModBuddy solution, custom DLL or remote runtime dependency.

## Mechanics implemented

Real city yields use absolute 0/1 dummies: gap 0–2 gives 0/0 Science/Culture, 3–5 gives 1/1, six-plus gives 2/1. The saved player tier is established at the pre-first-player turn notification; late PlayerDoTurn only reconciles state. Actual researched team technologies are compared once per distinct eligible team at a boundary. Rival elimination, leadership changes, same-team players and the absence of rivals are handled. Newly founded/acquired cities copy the saved tier; foreign ownership clears dummies.

The Guard clones the active Spearman and companions, adds exactly one Movement, and gets a persistent veteran identity with a separate conditional +15 DefenseMod. No offensive modifier is set. The Academy clones the active Library and companions, adds one direct Culture and uses a separate one-Production dummy only at saved tier six-plus while the Academy exists.

## Executed verification

`python tools/validate_mod.py` passes source-hash assertions for 12 CP151 files; real SQLite execution over a BNW database with installed CP151 schema; active-source mutation tests proving Library/Spearman inheritance; original-row preservation; dummy and override/localization checks; Lua 5.1 parsing of all four Lua files; 42 city yield assertions plus mock ownership, reload, upgrade, territory and 25-major scenarios; XML/context/VFS/MD5/action/dependency checks; and all 48 DDS dimensions, formats, alpha and icon mip payloads. Full results are in `tools/Validation.json`.

The final DDS contact sheet was visually inspected. All five illustrated assets are present, with cohesive navy/silver/gold presentation. The compiler and generators reproduce their checked-in outputs from the retained masters. An installable folder ZIP is generated in ignored `dist/` for local use; source assets and build tools are committed.

## Unresolved acceptance

**Civilization V was not launched. This is not an observed in-game pass or an engine-certified complete release.** The DLL source establishes notification publication order but does not establish synchronous delivery by the closed game engine. The supported first-slot-human setup must demonstrate the NewGameTurn snapshot runs before native Production, Culture and research collection. A late queued notification would fail the exact mechanic; no instant-yield compensation or hidden late recalculation is used. Later-slot humans and other turn modes are not certified.

Remaining manual tests are itemized in [Testing.md](Testing.md): dependency/selection/SQL/Lua loading; pre-economy timing at gaps two/three/six; every yield threshold; team and rival eligibility, leader elimination/change, large games; founding/capture/annexation/loss/gifting/liberation; Academy construction/sale/removal and active Library equivalence; save/reload persistence and no stacking; Guard home defense versus attacks, foreign/neutral/Open Borders tiles, tile ownership changes and upgrades; and native artwork/diplomacy presentation.

Artwork limitations are intentional: static leader presentation and English text without custom voice recording; native Spearman model/flag; illustrated fictional capital in the map panel. There are no missing requested icon, leader or Dawn assets.
