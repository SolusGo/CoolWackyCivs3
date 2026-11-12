# Department of Lost Things

**Leader:** Chief Registrar Nobody. **Capital:** Unclaimed. **Focus:** Culture / Science.
Canonical [Daily Surprise #002](https://github.com/SolusGo/Weekly-civs/blob/main/Civilizations/002-department-of-lost-things.md), archive blob `c1424144495ea132c5f0b4bde41896f82a73446e`.

## Exact mechanics

**Nothing Is Ever Truly Lost:** a Department combat unit killing an enemy combat unit within three hexes of an owned city recovers one Curio. Each city stores at most four; each Curio adds +1 recurring Culture and +1 recurring Science. The nearest city receives the recovery, with equal distance resolved by lowest native city ID. A full nearest city consumes the kill without moving the reward elsewhere. Ordinary Barbarian combat qualifies under the same combat contract. City attacks, civilian removal, disbands, aborted attacks, nonlethal combat and self-destruction do not qualify. Both attacking and defending Department combat kills qualify; mutual destruction is conservatively excluded.

**Retrieval Officer:** replaces the active CP Spearman. A civilization-specific promotion adds +1 Sight and +15% strength against Barbarian units. Native `BarbarianCombatBonus` checks the actual opposing unit; it is not a generic strength bonus. All other active Spearman scalars, prerequisites, resource needs, art, selection sound, inherited promotions and upgrade route are cloned at activation. The extra promotion survives normal upgrades; it does not spread to the Scarecrow Spearman.

**Lost Property Office:** replaces the active Library and preserves every approved companion effect. Each Curio supplies an additional +1 Culture and +1 Gold while the Office is present in a Department city. At four Curios the combined UA/UB bonus is **+8 Culture, +4 Science and +4 Gold** per city. Rebuilding an Office never creates Curios. Existing CP Library effects remain additional to this example.

## Ledger and ownership assumptions

The archive leaves detailed eligibility and transfer policy unspecified. This implementation uses actual enemy combat participants and lethal damage, matched across CP151 `CombatResult` and post-resolution `CombatEnded`, plus an absent/dead victim check. It does not infer kills from `UnitPrekill` or the less informative `UnitKilledInCombat` event. Nuclear/collateral victims and unrelated scripted removals without this participant contract do not award. These conservative exclusions avoid inventing combat evidence.

Curios belong to the collecting Department player's record for that city lifetime (coordinates, original founder, founding turn). Capture strips every Department yield controller immediately, while the saved collection pauses. Recapture/liberation to the same Department restores it; another Department player starts its own collection. Razing/deletion removes the lifetime record during bounded reconciliation. Founding explicitly clears old records at those coordinates, including same-turn refounding. No foreign city retains these conditional yields.

Each consumed victim has a persisted owner/full native unit ID/creation-turn marker. Kill deduplication and the updated city count are written together in namespaced player ScriptData, preserving unrelated records. Repeated callbacks or reloads cannot pay twice. Combat participant snapshots are transient within one synchronous native resolution; a fresh context cannot reward an unpaired completion. Only completed observations award, never speculative pending combat.

## Playing the civilization

Open with a defensible compact settlement pattern and scouting Officers. Fight genuine threats close to cities whose collections are incomplete. Their Sight makes approaches easier to monitor, while Barbarian strength helps clear nearby threats; dragging wars out after the local cap has no additional unique payoff. Do not sacrifice development or units for a fifth Curio that cannot exist.

Build Offices first in cities with established collections. In the midgame, balance protected expansion with libraries, infrastructure and research specialists. Culture helps reach policies supporting your chosen victory. Curio yields are flat, so large populations and ordinary science multipliers remain essential.

In the late game, convert the steady economy into laboratories and spacecraft research, or cultural infrastructure and Tourism. Curios themselves do not generate Tourism. Weaknesses are delayed value on peaceful maps, the per-city cap and exposure of incomplete collections to capture. Counterplay is to fight outside the three-hex recovery radius, pillage supporting infrastructure, and interrupt Office ownership.

The recurring amounts do not scale with game speed. Longer speeds provide more time to use the same unit advantages; no hidden instant Science/Culture reward is added. Like other real building yields, the bonuses follow native modifiers, resistance and settlement rules.

## Integration, presentation and acceptance

`SQL/LOST_{Civilization,Units,Buildings,Text}.sql` registers this human-only civilization. `Lua/LOST_Gameplay.xml` is its single gameplay context; the shared archive lifecycle helper provides exact real/free controller repair. Sixteen binary controllers implement the four Curio layers for UA and Office yields. There is no per-frame map scan or owner-turn global unit scan.

Original indigo/scarlet artwork presents Nobody as a headless spectral registrar with floating spectacles and an empty collar. Six independent illustrations provide the leader, emblem, Retrieval Officer, Office, Dawn and Unclaimed capital. Custom gold-rimmed portraits, keyhole-tag alpha/flags and static diplomacy replace the presentation fallbacks; native world models/audio remain inherited. See [the art guide](Art/README.md).

See [automated and native testing](TESTING.md), the [pack source/timing audit](../docs/ArchivedDailyTesting.md) and the [strategy guide](../docs/strategy/TheDepartmentOfLostThings.md). Combat dispatch, real save serialization, actual payout timing and the native presentation still require Civ V acceptance. No native gameplay pass is claimed. Owner-turn reconciliation is post-economy and governs the next payout; it never retroactively pays collected yields.
