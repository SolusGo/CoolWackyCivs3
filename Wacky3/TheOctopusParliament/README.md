# The Octopus Parliament

[Civilization gallery](../../docs/Civilizations.md)

![Speaker Eightfold in the diplomacy scene](../../docs/artwork/leaders/TheOctopusParliament.jpg)

Speaker Eightfold leads this human-only civilization from Inkminster. Speaker Eightfold presides over an eight-armed parliament that takes its votes, and its procedural rules, very seriously.

- **The Eightfold Assembly**. Choose one resolution when beginning play and each time you enter a new technological era. Prosperity grants +1 Gold and +1 Production per city. Enlightenment grants +1 Science and +1 Culture per city. Defence grants military units +10% Combat Strength.
- **Inkguard** replaces Pikeman. +15% defensive strength, retained on upgrade.
- **Deliberation Chamber** replaces Library. +1 Culture. Also +1 Gold under Prosperity or +1 Science under Enlightenment.

The replacements inherit the active standalone Community Patch v151 definitions and approved companion effects. The pack includes original emblems, flags, portraits, diplomacy scenes, Dawn illustrations and setup maps. The replacement units and buildings inherit their in-world models. [Art and compilation notes](../docs/DailyExpansion_021_035_Art.md)

An outstanding vote grants no active resolution until a player chooses. UI rendering and callback dispatch still require native acceptance.

[Canonical design](https://github.com/SolusGo/Weekly-civs/blob/main/Civilizations/026-the-octopus-parliament.md) · [Strategy](../docs/strategy/TheOctopusParliament.md) · [Acceptance](TESTING.md)

A pending vote survives load with no active resolution. Unchanged owner turns do not sweep the military again. Unit creation and conversion reconcile the selected resolution immediately. [Hardening evidence](../docs/DailyExpansion_HardeningReport.md)
