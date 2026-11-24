# The Postal Sovereignty

[Civilization gallery](../../docs/Civilizations.md)

![Postmaster-General Elowen in the diplomacy scene](../../docs/artwork/leaders/ThePostalSovereignty.jpg)

Postmaster-General Elowen leads this human-only civilization from First Address. Elowen presides over a nation where delivery stops for no one. Each settlement eventually joins a network of ledgers, couriers and sorting halls.

- **The Unbroken Correspondence**. Each city with a Central Post Office gains +1 Science and +1 Culture per three participating cities, capped at +2 Culture.
- **Royal Courier** replaces Scout. +1 base Movement. Gains another +1 Movement when beginning the turn in friendly territory, for use while qualifying.
- **Central Post Office** replaces Market. +1 Gold and +1 Science.

The replacements inherit the active standalone Community Patch v151 definitions and approved companion effects. The pack includes original emblems, flags, portraits, diplomacy scenes, Dawn illustrations and setup maps. The replacement units and buildings inherit their in-world models. [Art and compilation notes](../docs/DailyExpansion_021_035_Art.md)

Movement is sampled at the post-economy PlayerDoTurn hook, then deducted on leaving friendly land. Native spend order and Open Borders changes need acceptance.

[Canonical design](https://github.com/SolusGo/Weekly-civs/blob/main/Civilizations/024-the-postal-sovereignty.md) · [Strategy](../docs/strategy/ThePostalSovereignty.md) · [Acceptance](TESTING.md)

The temporary point is removed from the native movement store on embarkation, exit and conversion. Open Borders changes refresh tracked Couriers. Same-turn reentry does not reissue the point. [Hardening evidence](../docs/DailyExpansion_HardeningReport.md)
