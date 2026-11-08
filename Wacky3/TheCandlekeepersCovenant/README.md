# The Candlekeeper's Covenant

**High Keeper Seraphine · Last Light · Culture / Science · Defensive warfare · Complexity 4/5**

*No Flame Shall Be Forgotten.* Human selectable only. Requires Civilization V: Brave New World and standalone Community Patch **v151**, without Vox Populi, custom DLLs or ModBuddy. Included in the existing Wacky3 package and GUID. New sequential Windows single-player games only; any human player slot is supported. Native in-game acceptance is still outstanding.

## The Names We Carry

Each observed, permanently destroyed foreign major city supplies one Lost Flame, capped at **12**. Each Flame adds **+1 recurring Culture in the current Capital**. Every three add **+1 recurring Science in the current Capital**. There is no era, speed, empire-size, participation, diplomatic-contact or visibility multiplier. No instant income, Golden Ages or other yields are awarded. The implementation reads city state without revealing the map.

| Flames | Capital Culture | Capital Science | Each Hall's added Culture | Each Hall's conditional Science |
| --- | ---: | ---: | ---: | ---: |
| 0 | 0 | 0 | 1 | 0 |
| 1–2 | 1–2 | 0 | 1 | 0 |
| 3–5 | 3–5 | 1 | 1 | 1 |
| 6–8 | 6–8 | 2 | 1 | 1 |
| 9–11 | 9–11 | 3 | 1 | 2 |
| 12 | 12 | 4 | 1 | 2 |

Capture, annexation, puppeting, liberation and treaty cession alone award **nothing**. A surviving city at the same coordinates always defeats a missing-owner-list observation. The last reliably observed owner must be a foreign major, including a now-eliminated major. Last-owner city-states, Barbarians and all Covenant civilizations are excluded. A city-state-founded city later owned and destroyed by a foreign major qualifies; a major-founded city last owned by a city-state does not.

**Conservative anti-farming exclusion:** every city observed as founded by any Covenant is permanently ineligible, even after gift/capture and later foreign destruction. This additional exclusion prevents founding cities for someone else to burn. Ordinary foreign-founded cities retain the specified last-owner rule.

## Destruction detection and persistence

The pinned CP151 source proves `GameEvents.CityRazed(owner,x,y)` runs in `CvPlayer::disband` **before** `pCity->kill()`. It records a pending candidate and the owner, never an immediate Flame. At a subsequent `PlayerDoTurn` boundary, the candidate's coordinates must actually lack a city. A canceled/uncompleted candidate with a surviving city supplies nothing.

`CityCaptureComplete(oldOwner,wasCapital,x,y,newOwner,...)` runs after native acquisition has deleted and recreated the city, copied buildings and assigned ownership. It updates the existing snapshot, strips foreign controllers and repairs the current Capital. It never infers destruction. `PlayerCityFounded(owner,x,y)` establishes a new lifetime, settling an older destroyed lifetime at the plot before recording the new settlement. `PlayerLiberated` updates the resulting city. Hall construction (including Gold/Faith purchases) and sale use `CityConstructed`/`CitySoldBuilding`.

Once per `Events.NewGameTurn`, the system enumerates players' **city lists**, including minors and eliminated-player slots, compares all saved snapshots and confirms missing cities at their plots. Each `PlayerDoTurn` refreshes that player's surviving cities and resolves only pending razes. There are no per-frame handlers, map scans, population detectors or per-Covenant-city world scans. Pending candidates share one index. Serialized records are rebuilt only when the ledger/snapshots actually change; unchanged state causes no save writes.

Identity combines **coordinates + engine founding turn + original owner as first observed + persistent lifetime serial**. Local city ID is recorded for diagnostics/ownership updates, never treated as globally unique. Acquisition preserves founding turn; a change in OriginalOwner alone does not imply death. An observed founding callback can distinguish even a same-turn refounding with a recycled ID. The credited ledger retains at most 12 identities; removed snapshots are retired. Live snapshots are bounded by the number of existing cities plus pending removals until reconciliation.

The namespace `[CWC3_COVENANT_V1:...]` is stored in the lowest-slot human Covenant player's **Player ScriptData**, preserving all other ScriptData. CP151 registers its read/write bindings and serializes `m_strScriptData` with the player. The record contains Flame count, monotonic serial, awarded identities and city snapshots (coordinates, founding turn, original/last owner, local ID, anti-farming and pending flags). It survives capital loss, zero-city intervals, elimination, policies, eras and reload. Multiple human Covenants configured at game creation share this global ledger because the eligibility rules exclude every Covenant. Changing the civilization roster during a save is unsupported.

On reload the ledger is restored **before** the world is enumerated. Previously pending removals may award once; current cities are seeded without inventing earlier destroyed cities. All owned and foreign dummy counts are repaired from the restored count. No state depends solely on Lua globals or MapModData; MapModData only prevents duplicate context registration.

## Hall of Remembrance

Replaces the **active CP Temple**, cloning every scalar and all 145 approved building companions at database activation. Adds exactly **+1 permanent Culture**, even if another supported active definition supplies multiple Culture records. Every Covenant-owned Hall receives independent invisible +1 Science controllers at 3 and 9 Flames. The Capital receives both UA and Hall yields. Nine Flames and six Halls add exactly **15 Culture and 15 Science** across the empire, separate from inherited Temple effects.

Twelve Culture and four Science controllers belong exclusively in the current Covenant Capital; two Hall Science controllers belong only in eligible Hall cities. All are bounded 0/1, nonconstructible, nonpurchasable, hidden CP dummies, free of maintenance/slots/Great Works/secondary effects, and never captured. Reconciliation clears illicit free copies, suppresses construction rewards/refunds, removes former-capital and foreign copies, and reapplies exact desired counts. If no valid Capital exists, only the UA's capital yields are inactive; the saved Flames and eligible Hall Science remain.

Direct lifecycle hooks repair immediately. Missed scripted Hall removal, acquisition or capital reassignment is recovered at the next player-turn/global reconciliation. `PlayerDoTurn` is **post-economy in CP151**: changes made there affect the next valid economic payout. `NewGameTurn` UI dispatch synchrony still needs native acceptance. Ordinary resistance, anarchy and city yield modifiers apply. There is no instant-yield compensation.

## Vigil Keeper and Eternal Vigil

Replaces the **active CP Pikeman**. All base scalars and 27 approved unit companions are cloned, preserving technology/resources/cost/maintenance/movement/strength/combat AI/obsolescence/upgrade requirements, native portrait, model and animations. The permanent, unchoosable **Eternal Vigil** promotion grants native **+1 Sight**, `LostWithUpgrade=0`.

A separate transient promotion has **DefenseMod=15**, **AttackMod=0**, **CombatPercent=0**, **FriendlyLandsModifier=0**. Lua toggles it using `Plot:IsFriendlyTerritory(unitOwner)`: own/team territory and native qualifying major/minor Open Borders qualify; neutral and enemy land do not. This is the engine's friendly rule, not the Ministry's stricter home-territory rule.

Movement, creation, post-transfer `UnitConverted`, tile ownership, reload and bounded veteran recovery update the conditional promotion. The verified CP151 **`BattleStarted(type,x,y)`** callback repairs units on the target plot **before** melee, ranged, city-ranged and air strength/damage calculations, including diplomacy changes while a defender remained stationary. The Covenant SQL enables only `EVENTS_BATTLES` in addition to the pack's existing options. No invented combat hook is used.

DLL source proves melee attack excludes `getDefenseModifier`, melee defense includes it, and ranged defense includes it only in the nonattacking branch. Attacks receive no bonus, including retaliation calculations for an attacking unit. The transient promotion is lost on upgrade and reconstructed once from permanent lineage after native promotion transfer; no Sight is added by Lua and nothing stacks. UI previews immediately after silent diplomacy changes may remain stale until movement/turn/combat reconciliation; actual native combat and preview presentation still require testing.

## Observable limits and manual acceptance

This is snapshot detection, not a claim of perfect destruction history. A city founded and script-killed entirely between observations, bypassing both founding and raze hooks, cannot be recovered. If a script also bypasses capture completion and destroys the city before the next snapshot, eligibility uses the last observed owner; unobservable ownership history cannot be reconstructed. An entirely unobserved destroy/refound at identical coordinates, founding turn and identity may be indistinguishable. Scripts that fabricate founding metadata or call ordinary founding hooks repeatedly without actually founding are outside the contract. Scripted kills of known cities without `CityRazed` are detected at the next global reconciliation or reload. This delay can defer bonuses by another economic payout.

Run `python tools/validate_covenant.py` and the complete `python tools/validate_mod.py` from Wacky3. The tests execute production SQL and Lua 5.1 with mocked engine objects; they do not execute the DLL or demonstrate native save serialization/economic timing. See [native checklist](../docs/CovenantTesting.md), [implementation report](../docs/CovenantImplementationReport.md) and [strategy](../docs/strategy/TheCandlekeepersCovenant.md).

Original Seraphine and candle medallion PNG masters, built-in generation prompts and a visual review are retained in `Art/Sources/`. `tools/build_covenant_art.py` reproducibly creates 30 real DDS assets, including full mip chains, alpha flag, portraits, Dawn, fictional emblem map panel and static leader scene. Native Pikeman/Temple portraits and world art are intentionally retained. There is no animated custom leader or voice recording. Supplied Dawn and four diplomacy lines are registered without truncation.
