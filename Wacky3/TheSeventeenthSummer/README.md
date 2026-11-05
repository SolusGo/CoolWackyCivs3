# Daily Civ V Surprise #17: The Seventeenth Summer

**Leader:** Chorus-Mother Ixa. **Capital:** First Emergence. **Motto:** “We Were Never Gone.” **Victory focus:** Science / Culture. Human-only, sequential single-player, BNW + standalone Community Patch **151**. No DLL changes. Start a new game with this pack enabled; the existing pack GUID is preserved.

Intelligent cicada-like people alternate between patient underground growth and synchronized emergence. Ixa's translucent golden wings bear tree-ring markings above an amber-and-root throne. Native America/Washington/Spearman/Granary art, scene and model references are valid temporary fallbacks; this release does not depict custom cicada artwork or provide recorded speech.

## The Great Emergence

| Speed | Dormancy | Emergence | Total owner-turns |
| --- | ---: | ---: | ---: |
| Quick | 9 | 3 | 12 |
| Standard | 13 | 4 | 17 |
| Epic | 20 | 6 | 26 |
| Marathon | 39 | 12 | 51 |

Dormancy gives every owned city **+1 Food**. Emergence replaces that with **+2 Production and +1 Culture**. These are flat building yields, subject to normal native economic rules, with no era scaling or military/construction penalties. Puppets qualify. Durations are configurable in `CWC3_SummerCycles`; edit before starting a new game. Custom speeds need an explicit positive-duration row.

The first valid `PlayerDoTurn` callback is processed owner-turn one. At Standard speed, 1–13 are Dormancy, 14–17 Emergence, 18–30 Dormancy and 31–34 Emergence. Player ScriptData persists count, phase and last game-turn identifier, preserving other namespaces. Duplicate/stale callbacks and loads do not advance or notify. Era changes and war do not reset the cycle. This human-only implementation supports any human player slot in sequential single-player.

The hardening audit preserves existing valid save records and the mod GUID. Corrupt records recover to Dormancy and resume on the next owner-turn; a finite future timestamp is clamped without discarding a valid phase/count. Ordinary unit events avoid phase work, duplicate callbacks avoid repeated unit scans, and foreign owners still receive one recovery sweep per turn. See the [audit report](../docs/SeventeenthSummerTesting.md#hardening-audit--6-november-2026) for measured 25/34-major regressions and the corruption-recovery policy.

**Economic timing is explicitly next-payout.** CP151's source places `PlayerDoTurn` after city collection and research. At processed owner-turn 14, combat enters Emergence immediately and city controllers schedule Emergence yields for the **next** payout; the payout just collected used Dormancy. At processed 18, combat returns to Dormancy and the next payout uses Dormancy. Thus economic collection at callback 15–18 uses the phase established by callbacks 14–17. The phase, combat and displayed city yield rates agree throughout the interval between callbacks. Initial bootstrap supplies Dormancy without consuming a turn. No UI event is used as an assumed synchronous pre-collection hook, and no instant-yield compensation is awarded. Selection text and transition notifications explain this timing.

## Shellguard and Brood Nursery

The **Shellguard** clones the active CP Spearman row and every source-approved companion table, including selection sounds, resource needs, promotions and upgrades. Its only baseline change is **+1 BaseSightRange**. Sight belongs to the unit type and ends when upgraded, unless the destination independently grants it. A hidden nonselectable `PROMOTION_SUMMER_BROOD_LINEAGE` persists through ordinary and multiple upgrades. During Emergence, eligible brood veterans receive `PROMOTION_SUMMER_AWAKENED`, whose **CombatPercent=20** affects attacks and defense in any territory/terrain. Awakened is removed in Dormancy and under foreign or AI ownership. Ordinary Spearmen and ordinary descendants never acquire ancestry. `UnitConverted`, after native promotion transfer, repairs the temporary effect before the upgraded unit can act.

The **Brood Nursery** inherits the active Granary and all companion effects, then adds **+1 Faith permanently**. Under eligible Summer ownership it adds **+1 Production during Emergence**. Unique totals excluding inherited Granary effects:

| Phase | Food | Production | Culture | Faith |
| --- | ---: | ---: | ---: | ---: |
| Dormancy | 1 | 0 | 0 | 1 |
| Emergence | 0 | 3 | 1 | 1 |

Four invisible zero/one controllers implement these yields. Real counts are absolute; free copies are cleared without refunds/construction bonuses. Founding, acquisition completion, Nursery construction/sale, watched-city dirtiness, owner-turn recovery and reload reconcile current ownership/buildings. Foreign owners retain a surviving Nursery's permanent Faith as a normal building effect, but never Summer controllers. Native capture rules decide whether the Nursery survives.

CP151 declares hidden-promotion fields but its shipped friendly/enemy panels ignore them. Two pinned panel overrides change only the lineage-icon condition. Other panels/frameworks and mods replacing these same VFS files need a compatibility merge; no such combination is certified. See [source evidence and acceptance checklist](../docs/SeventeenthSummerTesting.md) and [strategy](../docs/strategy/TheSeventeenthSummer.md).

## Build

From `Wacky3`, after installing `requirements-dev.txt`:

```powershell
python tools/generate_seventeenth_summer.py
python tools/generate_summer_ui.py
python tools/build_mod.py --package
python tools/validate_mod.py
```

UI generation requires the pinned installed CP151 scripts. SQL generation uses the existing pinned native/CP schema inventory, never a modded cache inventory. The single pack manifest registers four SQL actions after CP and the two existing civs, plus one gameplay context. The ZIP includes all gameplay, UI and documentation files. Automated SQLite/Lua51/source/manifest/package checks are distinct from in-game acceptance: **no game was launched for this implementation**.
