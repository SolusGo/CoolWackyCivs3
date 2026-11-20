# Native acceptance for The Postal Sovereignty

**NOT TESTED — native game execution unavailable during this implementation.**

1. Start a new sequential BNW game with standalone CP151 and this pack at Standard speed. Select The Postal Sovereignty and compare leader, capital, icons, Dawn, Civilopedia and diplomacy with the guide.
2. Confirm Royal Courier and Central Post Office replace the intended classes and retain active CP restrictions and unrelated effects.
3. Build the second, third, fifth, sixth and seventh Post Offices, including a free copy. Test initial movement, border crossing, same-turn return and upgrades while measuring remaining movement points.
4. Save and reload during the qualifying state. Lose or capture a city and check that only the current owner receives its conditional yields. Where relevant, repeat with two cities and an upgraded or captured unit.
5. Repeat on Marathon. Record actual stores, save files, combat panels and Database.log/Lua.log. Compare endpoints on both sides of the economic settlement.
6. Mark any native mismatch **FAIL — observed or reproduced mismatch**. Attach evidence before marking **PASS — native gameplay observed**.

Movement is sampled at the post-economy PlayerDoTurn hook, then deducted on leaving friendly land. Native spend order and Open Borders changes need acceptance.
