# Kingdom of Makuria

**Leader:** Merkurios. **Capital:** Old Dongola. **Focus:** Culture / Religion.
Canonical [Daily Surprise #013](https://github.com/SolusGo/Weekly-civs/blob/main/Civilizations/013-kingdom-of-makuria.md), archive blob `c49a73aa75bfa0d674b76b29812f47da51b00872`.

## Mechanics and historical setting

Makuria's Christian Nubian setting, Old Dongola, painted churches and archers supply the historical flavor. This is a simple building-based civilization; it introduces no separate currency, historical event system or religious conversion rules. The archived design is a gameplay abstraction, and the regional city-name roster is flavor rather than a claim that every settlement was governed by Merkurios.

**The Walls of Dongola:** each owned city with a Walls BuildingClass member gains +1 recurring Culture and +1 recurring Faith. Normal Walls, valid unique replacements and free buildings qualify. A Boolean class condition counts once despite multiple members or simultaneous real/free representations. The bonus is local to that city and disappears after its final qualifying building is removed.

**Nubian Bowman:** replaces the active CP Composite Bowman with +1 Sight and +15% defensive Combat Strength. `DefenseMod=15` applies in native melee defense and the non-attacking ranged-strength branch, including defense against ranged attacks. Generic `CombatPercent`, `AttackMod` and friendly-land modifiers remain zero. Offensive ranged attacks receive no unique strength bonus. Range, ranged behavior, cost, Movement, resources, prerequisites and upgrade route remain inherited. Its unique promotion survives ordinary upgrades.

**Painted Church:** replaces the active Temple and adds +1 permanent Culture and +1 permanent Science. All inherited Temple scalar and companion effects remain active, including existing yields, maintenance, requirements and slots. If the parent already has Culture or Science, the addition occurs exactly once even with duplicate source yield records.

A city with Walls and a Painted Church therefore gains **+2 Culture, +1 Faith and +1 Science** in unique base yields. Ordinary Walls/Temple effects remain additional. Real building yield modifiers, resistance and normal native settlement rules still apply.

## Strategy

Settle defensible sites and build Walls as part of a sustainable opening economy. The local Faith and Culture reward protective investment; they do not substitute for growth, workers or research infrastructure. Use Bowmen's extra Sight to choose defensive positions and avoid unsupported offensive trades: the extra strength exists only while defending.

In the midgame, build Painted Churches and use Faith with the game's ordinary religious system. Combine policies, religious choices and cultural infrastructure according to the map. Bowmen can protect new cities while normal unit upgrades preserve their defensive promotion. A wider network of protected cities gains more flat yields, but expansion costs still matter.

In the late game, convert accumulated Faith and Culture into the usual religious and cultural tools, then build Tourism and diplomatic access for a cultural victory. The Church's flat Science helps maintain development but does not replace Universities or later research buildings. Counterplay is to deny growth, pressure unfortified new cities and force the Bowmen to attack. Removing the final Walls-class building disables the UA in that city.

The exact +1/+1 local UA and +1/+1 Church additions do not scale with game speed. There is no instant construction reward or duplicated free-building payout.

## Integration and acceptance

`SQL/MAKURIA_{Civilization,Units,Buildings,Text}.sql` registers human-only Merkurios, city/spy names, leader traits, diplomacy, civilopedia text and overrides. `Lua/MAKURIA_Gameplay.xml` supplies one context and one binary Walls controller carrying both yields. Construction, purchase, sale, capture, liberation, load and bounded owner-turn/dirty reconciliation update the condition. Native class IDs are indexed from the loaded building database, accepting replacements.

Original red-ochre/ivory/lapis art portrays Merkurios as a broad, clean-shaven Nubian king with a restrained cross diadem. Six original illustrations cover leader, emblem, Bowman, Church, Dawn and Dongola; custom gold-rimmed portraits, cross-and-walls alpha/flags and static diplomacy replace the fallbacks. The imagery is historically inspired, not a verified likeness or exact costume reconstruction. Native world models remain inherited. See [the art guide](Art/README.md).

See [testing](TESTING.md), [strategy](../docs/strategy/TheKingdomOfMakuria.md) and [source audit](../docs/ArchivedDailyTesting.md). Native combat defense/ranged previews, actual economic collection, save serialization and original art presentation remain untested in Civ V. Post-economy reconciliation applies to the next payout. Automated mocks are not a native gameplay pass.
