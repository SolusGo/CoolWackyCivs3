# The Ministry of Almost

*Second Place Is Just First Place in Disguise.*

A fictional bureaucratic republic of silver medals, narrow defeats and improbable administrative competence. Acting Chancellor Penultimate has served for forty-seven years: she loses every election by one vote, then the winner resigns. The capital is **Runner-Up**. Human-only; Science / Culture; defensive secondary strength; complexity 3/5.

## Always the Challenger

At a valid owner-turn boundary, count technologies actually researched by each living rival major's **team**, excluding the Ministry's own team. Count each eligible team once. No rivals means gap zero. Diplomatic contact, war, era, score, research output and research progress do not affect the result. Repeatable technologies count as known technologies, not repeat-completion tallies.

`Gap = max(0, highest eligible rival team's known technologies − owner's team's known technologies)`

| Gap | Science / city | Culture / city |
| --- | ---: | ---: |
| 0–2 | 0 | 0 |
| 3–5 | 1 | 1 |
| 6+ | 2 | 1 |

Two separate +1 Science dummies and one +1 Culture dummy are switched to absolute zero/one counts. The second Science dummy adds one to the first; it does not yield two by itself. No accumulation, instant payouts, permanent technology ledger or new resource exists. Catching up lowers or removes the bonuses at the next valid boundary. Mid-turn discoveries and rival elimination wait for that boundary.

All Ministry cities qualify, including founded, annexed, captured and puppet cities. A new acquisition copies the **saved tier**, without recalculating technology or awarding past turns. Transfer to another civilization strips the dummies; `NeverCapture` and `ConquestProb=0` also prevent ordinary inheritance. Snapshot data belongs to the player, so losing the capital or all cities does not erase it. Save/load preserves the tier and existing UA counts.

## Second Wind Guard — Spearman replacement

*We're Not Finished Yet!*

Copies the active CP151 Spearman, all native companion entries and upgrades. Base strength, sight, production, resource requirements and technology remain unchanged. Movement is exactly the baseline plus one.

A permanent identity promotion survives normal upgrades. A separate `DefenseMod=15` promotion is present only on tiles owned by the unit owner's team. It contributes to defensive strength, never attack strength. Neutral, foreign and foreign Open Borders tiles do not qualify. This definition is deliberately stricter than CP's `IsFriendlyTerritory`, which includes foreign Open Borders land. Movement, ownership changes, creation, conversion, upgrade, owner-turn cleanup and reload reconcile the effect. The conditional promotion is lost on upgrade and immediately rebuilt for the veteran's current location. The extra Movement is a unit statistic and does not persist on the upgrade.

No healing, higher base strength or bonus against advanced units is added. Embarked defense uses the engine's separate embarked-defense calculation; this land-defense promotion does not override it.

## Runner-Up Academy — Library replacement

*Excellence Is a Work in Progress.*

Copies the **active** Library and all CP151 `BuildingType` companion tables, retaining class, production cost, maintenance, prerequisites, specialist effects, population Science and CP additions. It adds **one permanent Culture** directly. A separate dummy adds exactly **one Production** only if a Ministry-owned city has an Academy and the saved tier is six-plus. Academy construction/sale and city transfer reconcile it; city-info dirtiness covers scripted building removals without recalculating the UA.

At gap seven, one Academy city adds **2 Science + 2 Culture + 1 Production** beyond a normal Library. Four Academy cities at gap six add **8 Science + 8 Culture + 4 Production**. At gap four the same four cities add **4 Science + 8 Culture**; at gap two they add only the Academies' **4 Culture**. These are base building yields and follow normal yield multipliers and suppression rules.

## Winning, weaknesses and counterplay

Grow productive cities, improve tiles and follow the ordinary education infrastructure curve. Use the Guard's mobility to assemble a defense on home soil. Temporary support should accelerate Libraries, Universities and later research capacity. Academy Culture supplies policies while cities grow. When pursuing tourism, build actual Great Work and tourism infrastructure; Culture alone is not tourism.

The Ministry starts without a UA when near parity. It cannot force the world leader to stay ahead, and emergency support is flat per city rather than a percentage multiplier. A tiny or badly developed empire gains little. Defense is territorial, not a license to attack a more advanced army.

Opponents can pressure improvements, isolate trade and attack from several directions before education compounds. Ministry veterans lose their special defense outside team-owned territory. Its catch-up program closes naturally as the gap narrows. Do not delay valuable technologies merely to seek a small flat yield bonus.

## Implementation and limitations

See [Compatibility](../docs/Compatibility.md) for verified APIs and timing evidence. SQL clones are made after the CP dependency loads; a unique prefix and independent Lua context avoid Wacky2 dependencies. ScriptData stores only the last turn and tier, preserving other text in that field. A shared registration guard prevents duplicate callback registration. Writes use absolute counts, so repeated reconciliation cannot stack yields.

The supported setup is first-slot-human, sequential single-player with CP151 only. UI notification dispatch timing has not been observed inside Civilization V; this must pass the [manual tests](../docs/Testing.md) before an engine-complete claim. Forced AI Ministry, later-slot humans, multiplayer, hotseat, autoplay and mods that overwrite ScriptData or alter turn ordering require separate integration work. Other mods that alter inherited Library/Spearman effects **after** Wacky3 loads need explicit ordering. All English text has fallbacks, but no translations or custom voice recordings are provided. Static leader art and the standard Spearman model are intentional.
