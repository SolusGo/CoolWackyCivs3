# Hollow Choir implementation and acceptance

Implementation status: automated validation is recorded in `tools/Validation.json`. **Civilization V has not been launched for this addition.** Source/database inspection and simulated events are distinguished from native runtime acceptance below.

Latest results: **365 Choir assertions plus 180 existing Ministry assertions passed**, as did all four pristine/mutated SQLite cases across the two database sources, 13 pinned source-file hashes and API assertions, eight Lua51 syntax checks, and the 75-file/two-context manifest with existing DDS checks. Choir inheritance comparisons covered 174 companion tables. The install ZIP was rebuilt in ignored `dist/`. These are automated/static results only.

## Files and integration

New civilization files: `TheHollowChoir/SQL/Choir_Civilization.sql`, `Choir_Units.sql`, `Choir_Buildings.sql`, `Choir_Text.sql`; `TheHollowChoir/Lua/HollowChoirGameplay.lua` and `CWC3_Choir.xml`; civilization README and strategy guide. New developer files: `tools/generate_hollow_choir.py`, `tools/validate_hollow_choir.py`, `tools/tests/hollow_choir.lua` and this report.

Pack integration modifies only the manifest builder/manifest, shared validation/source-audit tools/results and pack README/changelog. Ministry civilization files and the shared runtime/options stay unchanged. GUID, version, CP151-only dependency and existing save minimum remain unchanged. The second gameplay context has a separate namespaced registration guard; the existing controller remains independent.

## Compatibility evidence

The same 13 hash-pinned CP151 source files documented in [Compatibility](Compatibility.md) establish the promotion, event and building APIs. New assertions verify `VisibilityChange`/`HillsDefense` loading, hill-conditional melee and defending ranged branches, absence of hill defense in melee attack, and `IsHills`/`IsMountain` plot bindings. Existing assertions establish promotion persistence through conversion, construction/sale and post-transfer acquisition ordering, tile ownership assignment before its event and real/free building setters. Installed CP151 Lua uses `Map.PlotDirection` in its map scripts/overrides and `Map.PlotDistance` in city-state diplomacy/InGame overrides. No VP-only fields, invented event, DLL change or external Lua dependency is introduced.

The source confirms `NewGameTurn` publication before first sequential activation and `PlayerDoTurn` after city yields/research. Choir bonuses are continuously reconciled passive state, with direct founding/building/border/acquisition hooks, bootstrap, pre-first-turn publication and post-economy recovery. **No source-only claim of synchronous closed-engine UI delivery is made.** A mutation bypassing every supported callback may remain stale until the next recovery point.

## Automated coverage

Run from `Wacky3` with the repository development requirements installed:

```powershell
python tools/generate_hollow_choir.py
python tools/build_mod.py --package
python tools/validate_mod.py --compare-database "$env:USERPROFILE\Documents\My Games\Sid Meier's Civilization 5\cache\Civ5DebugDatabase.db"
```

SQLite validation runs pristine and deliberately mutated active definitions against the BNW-derived cache with CP151 schema overlay and the existing CP-schema cache without overlay. Both caches are modded snapshots, **not certified clean CP-only data**. The tests compare every scalar and schema-inventoried companion effect for Swordsman/Amphitheater, preserve original native rows, verify overrides/start conditions, +1 Culture, exact promotion fields and five hidden yield definitions. All localization references, thematic diplomacy patterns, native art inheritance, XML entry points, VFS names and manifest checksums are checked. Existing Ministry SQL/Lua/art tests run in the combined pack.

The Lua51 suite executes the production Choir controller with hex-map/event doubles. It covers all hill/adjacency combinations (0-6 Mountains), enemy/unowned adjacency, non-adjacent Mountains, every Science threshold 0-6, range three/four, unowned/enemy ownership, overlapping cities, Hall presence/purchase/sale/scripted removal, border acquisition/loss, city founding/capture/gift/liberation/missed transfer, city removal/replacement, corrupted real/free counts, reload, registration deduplication, 30 repeated turns without writes/growth, nil/duplicate neighbors, multiple Choir owners including later slots, bounded plot work and speed-independent base yields. Mock APIs intentionally have no worked-city assignment, randomness or instant-yield methods.

## Manual engine matrix — all pending

- [ ] Load a clean BNW + standalone CP151 game; select The Hollow Choir / The First Note. Confirm only humans can select it, valid capital/city names, Dawn/diplomacy wording, native temporary art and no Database.log/Lua.log errors.
- [ ] Found Hill/flat cities with 0/1/2/3/6 adjacent Mountains. Confirm base Production 1/0 and Faith 0/1/2/2/2 independently; unowned/enemy Mountains count, Hills do not, ring-two Mountains do not.
- [ ] Build/purchase a Hall with 0/1/2/3/4/5/6 owned Mountains inside radius three. Confirm Science 0/0/1/1/2/2/2 and Culture exactly the active Amphitheater plus one. Confirm cost, maintenance, technology/prerequisites, Great Work/specialist slots and other native effects survive.
- [ ] Confirm radius-four, enemy/team-owned and unowned Mountains are excluded from Science; unworked Mountains count; two overlapping Halls count the same owned Mountains independently.
- [ ] Expand/purchase/transfer Mountain borders and inspect both city yields and actual stores at collection. Capture, gift, cede, liberate and raze cities in both directions; verify all five foreign dummy types disappear and no Hall is granted. Remove/sell/lose a Hall and confirm Science clears at the earliest safe reconciliation.
- [ ] Inspect Sentinel combat, cost, Moves, Iron, technology, free promotions, upgrades and selection sound against the active Swordsman. Check +1 Sight and +20% hill defense against melee/ranged attacks; verify no attack or flatland bonus. Upgrade normally and through a ruin; both benefits survive while ordinary Swordsmen remain unchanged.
- [ ] Save/reload before and after ownership/building changes and at multiple successive turns. Confirm counts stay zero/one with no free copies or growth. Repeat in Marathon; base bonuses remain identical.
- [ ] Observe native economic timing after border/building changes, first sequential activation and a later human slot. Compare actual Production/Faith/Science accumulation with control saves. UI notification order alone is insufficient proof of yield settlement.

## Remaining assets and limits

All custom crystal art/model/voice assets remain missing; guaranteed native assets are deliberate temporary fallbacks, detailed in the civilization README. No gameplay mechanic is omitted. Multiplayer/hotseat remain disabled by the pre-existing pack manifest and have no runtime certification. Other mods loading later and changing source unit/building rows, promotions or events require separate integration acceptance. An in-game test pass is required before claiming engine-complete verification.
