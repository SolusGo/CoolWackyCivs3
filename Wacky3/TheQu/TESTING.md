# Qu verification

Run the pack validator from Wacky3 with the usual Python dependencies and BNW/CP151 game paths. The additional Qu source audit has three pinned inputs.

    python tools/audit_cp.py --fetch
    python tools/validate_qu.py --fetch
    python tools/build_mod.py --package
    python tools/validate_mod.py

The pack inventory records the automated results in [Validation.json](../tools/Validation.json). SQLite compares the Qu's Rifleman and Workshop clones with their active source rows, including upgrade and companion rows, and checks the five hidden city effects. The Lua 5.1 mock drives the production event handlers and UI with Standard and Marathon settings and an advanced-era start. Source, texture, manifest and ZIP checks are separate from native acceptance.

The event activation check inventories the subscriptions in Qu_State.lua and Qu_Combat.lua. It verifies their CP151 option gates in the full pack and in a clean fixture that runs only the shared options and the Qu registrations. The Qu registration explicitly enables EVENTS_UNIT_PREKILL for the prekill callback used to attribute Biomass.

Both local comparison caches returned a Rifling Rifleman with 34 Combat, 2 Movement, 225 base Production cost and a Great War Infantry upgrade. Both returned a Metal Casting Workshop with 120 base Production cost, 2 maintenance, one Engineer slot and a 10% Production modifier. The generated SQL clones whichever source rows the active game loads. The comparison caches are supplementary and are not certified CP-only native sessions.

## CP151 contracts

| Mechanic | Evidence |
| --- | --- |
| Lethal combat | The CP151 resolver supplies a committed CombatResult. Lethal damage supplies UnitPrekill with victim ID and killer ID before the four-argument UnitKilledInCombat callback. Match both notifications for the same casualty, consume the match once, and exclude delayed-death cleanup. City bombardment uses the attacking-city role because CombatResult has an empty unit attacker slot for that path. |
| Direct military overrun | Reason-0 UnitCaptured distinguishes kills from captures. A matching immediate prekill identifies the casualty. A city shoot-down of an Atomic Bomb can occur during generation before CombatResult and is matched to the joined city and attacking unit. |
| Promotions | AttackWoundedMod uses the opponent's damage in native strength calculation. CvCombatInfo joins both units before their strengths are calculated. The defender temporarily gets native DefenseMod only for a wounded hostile unit in the joined attacker role. CombatResult, BattleFinished and GameCoreUpdateEnd remove the modifier. UnitConverted and startup clear any transient copy. |
| City eligibility | CityCaptureComplete carries the conquest flag after recreation and building transfer. Coordinates, owner-local ID, founding and acquisition turns, original and previous owner, and a saved acquisition serial identify the city and confirmation. Noncombat transfer drops the claim. CityRazed and PlayerCityFounded remove claims, and owner-turn reconciliation prunes missing or mismatched cities. |
| Era and population | TeamSetEra publishes the new era. The stored highest entered era prevents repeats. SetPopulation publishes the new population after native reassignment. CityConstructed, CitySoldBuilding, acquisition and reconciliation keep the Foundry's exclusive zero/one/two Science tier current. |
| Signed yield calculation | The CP loader reads a signed integer from Building_YieldModifiers. CvCity applies that value to its local rate modifier and calculates native yields in hundredths, with Food consumption subtracted afterwards. |
| UI | The CP151 DiploCorner gathers additional menu entries via LuaEvents. One XML InGameUIAddin owns the controls, confirmation, and gameplay subscriptions. |

The audited patch revision is [44c1e14](https://github.com/LoneGazebo/Community-Patch-DLL/tree/44c1e14ff75d80c1dba5c8a71e8289439a53aafb).

## Native acceptance checklist

Use a new sequential BNW game with only standalone CP151 and Wacky3 active. Start with Standard, then repeat the turn and transformation tests on Marathon. Capture before/after UI screenshots and record any Database.log or Lua.log errors.

1. Verify The Qu, the First Architect, Genesis Spire, selectable leader portrait, Dawn screen, civilization/alpha/flag textures, and both unique Civilopedia entries. Inspect the static diplomacy fallback in a leader-scene harness or equivalent test setup because the leader is human-only.
2. Open Additional Information on turn zero and verify **0/10** Biomass and the 5 Biomass/1 Population cost. Confirm a founded city is ineligible. Confirm the entry is absent in a different human civilization's game.
3. Kill a hostile major or minor military unit with melee, ranged, and city bombardment. Verify +1 for each, including retaliatory or interception kills. Repeat with a Barbarian, captured civilian, disband, and scripted damage outside battle. Verify zero for those four cases. Where possible, confirm military overrun and nuclear paths.
4. Kill at least four qualifying units in one turn. Verify no fourth combat award. Save after the third, reload, and repeat the blocked attempt. End the turn and confirm the allowance resets when the Qu next take their turn. Verify a defensive kill between Qu turns counts toward the last Qu turn's allowance, including a later-slot start.
5. Enter the next era and verify exactly +2 once, including save/load and additional technologies in the new era. Repeat at Biomass 9 and confirm cap 10. Try a later-era start and confirm the starting era awards nothing.
6. Conquer three foreign cities. Confirm a puppet, resistant, razing, Population 5, courthouse-less, or tech-locked city cannot transform. Gift or cede a city to the Qu and confirm it stays ineligible even with a Courthouse.
7. Annex the three military conquests, finish resistance, ensure 6+ Population, build Courthouses, and research the three prerequisites. Cancel a confirmation and check both reserves. Install Labor, Cognitive and Brood in distinct cities and verify exactly five Biomass and one citizen per purchase. Reopen the panel and attempt a second purchase in the same city.
8. Compare known local base yields with the city tooltip at the same Population before and after installation. Verify all six signed modifiers and unaffected neighboring cities. Separate post-modifier Food consumption and trade route yields from the base comparison. Save/reload, grow, starve, finish a building, and research again. Verify each caste persists.
9. Give away, liberate, or lose a caste city. Verify every bonus disappears. Reconquer its plot and verify no free caste, Biomass, or Population, then buy a new caste at full cost. Raze and found a new city at those coordinates. Verify the city stays ineligible and old confirmations cannot apply.
10. Build a Gene Foundry with a starting city at Population 4. Grow or reduce population through 5, 9, 10, and back through 9/4, checking base Science increments 0/1/1/2 and back again. Sell, rebuild, capture, transfer, and reload with the Foundry in place. Verify one tier applies at a time.
11. Compare Harvester melee attack results against healthy and previously wounded targets under otherwise equivalent modifiers. Repeat on defense with healthy and wounded enemy melee and ranged attackers. Damage during that same engagement must not enable the bonus. Check aborted combat, alternate the order of attacks, upgrade normally, and repeat as the upgraded unit.
12. Repeat items 3–11 on Marathon. Check normal build costs scale and all Qu-specific numbers remain the same. Start one game with another Wacky3 civilization to check that the Qu menu and controllers are inactive.

## Limits and exploit checks

- The Lua tests validate promotion setup and cleanup. Native combat numbers, persistence, UI layout and economic timing require a game run. A prebattle combat preview can omit the scoped defense bonus because CP emits BattleJoined during combat generation.
- The Biomass combat window covers the source-verified battle and overrun paths. Damage sources outside a verified battle, including ordinary scripted damage and attrition, are excluded.
- Check one purchase per acquisition serial, no double credit per prekill/combat notification, persistent caps across reloads, simultaneous city-local caste isolation, and immediate removal of gifted effects.
- The mod keeps the Wacky3 version, GUID and existing namespaces. Existing saves need native acceptance with the expanded roster. Begin a new game to play the Qu.
- The Harvester uses the native Rifleman world model. The custom unit portrait and flag show the Qu's nonhuman form.
