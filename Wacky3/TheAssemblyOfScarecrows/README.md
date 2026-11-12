# Assembly of Scarecrows

**Leader:** Old Man Thistle. **Capital:** First Harvest. **Focus:** Culture / Growth.
Canonical [Daily Surprise #007](https://github.com/SolusGo/Weekly-civs/blob/main/Civilizations/007-assembly-of-scarecrows.md), archive blob `b9b35f27561316ec1d9852c0a766c33fd256bc01`.

## Exact mechanics

**The Fields Have Eyes** counts owned, unpillaged Farms within three hexes of each owned city. At three Farms that city gains +2 Culture and +1 Production. At six it additionally gains +2 Food. The thresholds are cumulative: six Farms produce **+2 Culture, +1 Production, +2 Food**. No worked-plot condition exists. A Farm may independently support several overlapping cities. Native six-direction breadth-first traversal visits at most 37 distinct plots per city and deduplicates wrapped neighbors. City working-radius changes cannot reduce the specified three-hex radius.

**Wicker Sentinel:** replaces the active CP Spearman and inherits all other scalars, companions, resources, prerequisites, native art/audio and upgrade path. Its unique promotion adds +1 Sight and native `FriendlyLandsModifier=15`. This applies to attack and defense using CP's native combat-location rules. Friendly means own/team territory and qualifying Open Borders, consistent with the Covenant's native-friendly definition; the Ministry intentionally uses its separate own-team-only rule. For melee combat the native generic modifier tests the battle tile, including an attack's target. Ranged descendants use the native ranged branch's own-plot rule. Promotion benefits persist through normal upgrades and remain specific to this unit lineage.

**Harvest Bell:** replaces the active Granary, preserving its complete baseline. It adds +1 permanent Culture, then +1 Gold per three qualifying Farms, capped at +3. The Gold requires the Bell in a Scarecrow-owned city. Its permanent Culture remains part of the building; its conditional Gold does not follow a foreign capture.

| Qualifying Farms | UA Culture / Production / Food | Bell extra Gold |
| --- | --- | ---: |
| 0–2 | 0 / 0 / 0 | 0 |
| 3–5 | 2 / 1 / 0 | 1 |
| 6–8 | 2 / 1 / 2 | 2 |
| 9+ | 2 / 1 / 2 | 3 |

Permanent Bell Culture and normal Granary effects are additional to this table. Five binary controllers set exact desired values without stacking copies.

## Strategy and counterplay

Scout land that can support six accessible Farms per settlement. An opening Worker and safe settlement sites help reach the first threshold; a third Farm can be more valuable than an otherwise equal tile improvement. The Farms need not be worked for the unique bonus, so citizens can still work strong mines or specialist slots. Do not neglect normal tile yields and growth limits merely to reach a threshold.

In the midgame, exploit overlap between cities, build Bells, and defend the three-Farm and six-Farm thresholds. Nine Farms maximize Bell Gold, while further Farms add only their normal effects. Food supports population and specialists; Production supports cultural buildings and defenses. Open Borders can extend native friendly territory, but the actual combat location still determines Sentinel strength.

In the late game, turn population and policies into cultural infrastructure, specialists and Tourism. The ability supplies Culture rather than direct Tourism. Weaknesses include poor agricultural terrain, competing improvement needs and abrupt losses when pillaging drops a city below a threshold. Counterplay is to pillage or take the decisive Farms and force Sentinels to fight on nonfriendly battle tiles.

Amounts and Farm thresholds are identical on Quick, Standard, Epic and Marathon. Native yield modifiers and resistance apply normally; no instant compensation is used.

## Lifecycle, art and testing

Farm construction/replacement, pillaging/repair and ownership changes use source-verified tile callbacks; founding, capture, liberation, buildings, city dirtiness, load and owner-turn reconciliation repair city controllers. Foreign real/free controller copies are stripped. Derived Farm state is recalculated from the map and needs no custom saved currency. Post-economy owner-turn repairs apply to the next payout, with direct callbacks establishing state when delivered earlier.

`SQL/SCARECROW_{Civilization,Units,Buildings,Text}.sql` and `Lua/SCARECROW_Gameplay.xml` integrate one human-only civilization/context. Original green/harvest-gold art gives Thistle a crooked straw body, mismatched button/seed eyes, thistle-covered hat and crow. Six independent illustrations cover leader, emblem, Sentinel, Bell, Dawn and capital, with custom gold-rimmed portraits, bell-and-wheat alpha/flags and static diplomacy. Native world models remain inherited. See [the art guide](Art/README.md).

See [testing](TESTING.md), [strategy](../docs/strategy/TheAssemblyOfScarecrows.md) and [source/timing evidence](../docs/ArchivedDailyTesting.md). Lua51 mocks and SQL comparisons are available; native farm callbacks, economic payouts, combat previews, upgrades, save reloads and art presentation remain acceptance work. Native gameplay has not been run.
