# Native acceptance for The Octopus Parliament

**NOT TESTED — native game execution unavailable during this implementation.**

1. Start a new sequential BNW game with standalone CP151 and this pack at Standard speed. Select The Octopus Parliament and compare leader, capital, icons, Dawn, Civilopedia and diplomacy with the guide.
2. Confirm Inkguard and Deliberation Chamber replace the intended classes and retain active CP restrictions and unrelated effects.
3. Start in Ancient and in a later era. Pick each of the three resolutions in separate eras. Save with a pending choice and after voting. Advance through a tech purchase or free tech and confirm one choice. Upgrade an Inkguard.
4. Save and reload during the qualifying state. Lose or capture a city and check that only the current owner receives its conditional yields. Where relevant, repeat with two cities and an upgraded or captured unit.
5. Repeat on Marathon. Record actual stores, save files, combat panels and Database.log/Lua.log. Compare endpoints on both sides of the economic settlement.
6. Mark any native mismatch **FAIL — observed or reproduced mismatch**. Attach evidence before marking **PASS — native gameplay observed**.

An outstanding vote grants no active resolution until a player chooses. UI rendering and callback dispatch still require native acceptance.

A pending vote survives load with no active resolution. Unchanged owner turns do not sweep the military again. Unit creation and conversion reconcile the selected resolution immediately. [Hardening evidence](../docs/DailyExpansion_HardeningReport.md)
