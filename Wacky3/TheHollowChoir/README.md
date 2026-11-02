# The Hollow Choir

Led by **The First Note**, an ancient sentient crystal suspended among orbiting crystals in an underground cathedral. Capital: **Resonance**. Human selectable only (`Playable=1`, `AIPlayable=0`). Culture / Science, with defensive warfare as a secondary strength. Requires BNW and standalone Community Patch **v151**, without VP components.

## Songs Beneath Stone

Every owned city whose center is a Hill gains **+1 Production**, including captured cities. Independently, every city gains **+1 Faith per directly adjacent Mountain, capped at +2**. Mountains can be unowned or foreign-owned. Flatland cities receive the same adjacency Faith. No population, era or game-speed multiplier changes these base amounts.

## Chorus Sentinel

Replaces the active CP Swordsman. Runtime `SELECT *` cloning preserves every baseline scalar, including Combat, Moves, Cost, resource/technology requirements, class, upgrade behavior and art. All schema-inventoried `UnitType` companion tables, including free promotions, upgrades, resources and `UnitGameplay2DScripts` selection sounds, are copied at mod load.

One additional promotion provides **+1 Sight** and **+20% defense on Hills**. CP151 natively reads `VisibilityChange=1` and `HillsDefense=20`. Both melee defense and the defending ranged-strength branch check the occupied plot's hills. Attack excludes the hill-defense modifier; flatland grants no unique defense. `LostWithUpgrade=0` preserves both benefits on upgrades. Normal Swordsmen never receive the promotion. No general DefenseMod, offensive strength, extra Movement or mountain movement is added. Embarked combat follows native separate rules.

## Resonance Hall

Replaces the active Amphitheater, preserving all scalars and all inventoried `BuildingType` companion tables: existing yields, maintenance, cost, specialists, Great Work slots, technology, prerequisites, flavors and CP additions. It adds **one Culture** to the inherited Culture yield.

Only a Hollow Choir city possessing a Hall gains **`min(2, floor(owned Mountains within hex distance 3 / 2))` Science**. Counts 0/1/2/3/4/5/6 therefore give 0/0/1/1/2/2/2. Mountains need not be worked or assigned to this city. The same owned Mountain counts independently for every Hall in range. Teammate-owned, enemy-owned and unowned Mountains do not count. Losing the Hall or Mountain ownership removes the corresponding Science at reconciliation. Conquest never grants a free Hall; native capture/conversion rules determine the actual building.

## Controller and lifecycle

`Lua/HollowChoirGameplay.lua` reuses `CWC3.SetBuilding`. Five invisible, unbuildable, unpurchasable, maintenance-free dummy buildings each yield one Production, Faith or Science. Each real count is exactly zero or one; free copies are cleared with reward/refund suppression. No unconditional compensation, random calls, instant yields or saved Lua ledger exists. Native building modifiers still apply normally.

Bootstrap and reload derive all counts from current cities, terrain, ownership and Hall presence. Direct verified CP151 hooks cover founding, acquisition (including gifts/cessions), liberation, building construction/purchase/sale and tile ownership changes. Acquisition cleans all five dummy types from foreign cities and refreshes nearby empires' ownership-dependent Science. Coordinate tracking handles scripted building removal, missed transfers and removed cities through city-info dirtiness. One owner-local `PlayerDoTurn` pass supplies recovery, including foreign cleanup. All writes are idempotent and guarded against nested dirty notifications.

`NewGameTurn` publication precedes first sequential activation and reconciles all Choir owners. `ActivePlayerTurnStart` supplies additional recovery. **CP151 PlayerDoTurn is after economic collection**, so it is explicitly a fallback, not a pre-yield owner hook. Direct state-change callbacks normally maintain these passive yields before collection; no turn-frozen snapshot or first-slot restriction is needed. Closed-engine UI notification delivery and actual yield timing still need in-game acceptance. Arbitrary external building mutations that emit no dirty/native event recover at the next reconciliation.

Plot work is bounded to six neighbors for Faith and at most 37 unique plots per Hall for Science. Hex traversal uses actual mountain properties and `Map.PlotDistance`, deduplicating wrapping neighbors. Border callbacks visit the old/new Choir owners' cities, not the world map. No existing civilization gameplay/SQL/art file is changed.

## Presentation and limits

All identity, help, strategy, Civilopedia, city/spy names and diplomacy use `TXT_KEY_CWC3_CHOIR_`. The supplied Dawn of Man, greeting, declaration and defeat wording are preserved, with Civ V paragraph markers. The leader has restrained war bias and science/culture/defense flavors; there are no AI bonuses.

**Custom artwork is not supplied.** Temporary native America civilization/alpha/map/Dawn assets and Washington leader portrait/scene are inherited from guaranteed base-game rows. The Sentinel uses native Swordsman graphics, flag and audio; the Hall uses the native Amphitheater icon. The player colors are violet and silver. Native music/art references remain valid; custom Dawn speech is disabled. No missing DDS, custom atlas, model or audio is referenced. Future replacements needed: crystal emblem/alpha atlas, First Note portrait/scene, underground cathedral Dawn/map, Sentinel portrait/model and Hall portrait. No generated-art claim is made.

The pack retains its existing Windows single-player manifest restrictions because the Ministry has separate timing constraints. Choir calculations contain no randomness, UI selection dependency or persistent cache of ownership; multiplayer is **not certified or enabled** for the pack. Save/reload and Marathon have mock coverage, not engine certification. Start a new game to select this new civilization; adding the expanded pack to old saves is unverified.

See [testing/report](../docs/HollowChoirTesting.md) and [strategy](../docs/strategy/TheHollowChoir.md).
