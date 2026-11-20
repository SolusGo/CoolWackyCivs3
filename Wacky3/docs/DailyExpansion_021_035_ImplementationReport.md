# Daily Surprise expansion implementation

Baseline main commit is `f745be8454e99d0e25d2b88574aa48e13dc31530`. The implementation targets the original version 1 package and standalone CP151. Canonical design blob IDs are in the build roster. Existing saves still require native compatibility acceptance.

| Daily | Sources | UA | UU | UB | Art | State | Automated checks | Native | Outstanding |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 021 | [Kingdom of Ryukyu](../KingdomOfRyukyu/README.md) | Implemented | Implemented | Implemented | Stock fallbacks | Reconstructed on load | SQLite / Lua 5.1 | Not tested | Native acceptance outstanding. |
| 022 | [The Mirrorbound Republic](../TheMirrorboundRepublic/README.md) | Partial | Implemented | Implemented | Stock fallbacks | Player and unit ScriptData | SQLite / Lua 5.1 | Not tested | Primary two-unit combat only. Independently attributed interceptor and collateral deaths are not covered. Native dispatch and attack consumption still require acceptance. |
| 023 | [Kingdom of a Thousand Kites](../KingdomOfAThousandKites/README.md) | Implemented | Implemented | Implemented | Stock fallbacks | Reconstructed on load | SQLite / Lua 5.1 | Not tested | Native acceptance outstanding. |
| 024 | [The Postal Sovereignty](../ThePostalSovereignty/README.md) | Implemented | Implemented | Implemented | Stock fallbacks | Owner-turn grant marker and native promotion | SQLite / Lua 5.1 | Not tested | Movement is sampled at the post-economy PlayerDoTurn hook, then deducted on leaving friendly land. Native spend order and Open Borders changes need acceptance. |
| 025 | [The Carapace Dominion](../TheCarapaceDominion/README.md) | Implemented | Implemented | Implemented | Stock fallbacks | Reconstructed on load | SQLite / Lua 5.1 | Not tested | Native combat previews may lag a script-only plot mutation until state is repaired at BattleStarted. |
| 026 | [The Octopus Parliament](../TheOctopusParliament/README.md) | Implemented | Implemented | Implemented | Stock fallbacks | Player ScriptData | SQLite / Lua 5.1 | Not tested | An outstanding vote grants no active resolution until a player chooses. UI rendering and callback dispatch still require native acceptance. |
| 027 | [The Fogbound Republic](../TheFogboundRepublic/README.md) | Implemented | Implemented | Implemented | Stock fallbacks | Reconstructed on load | SQLite / Lua 5.1 | Not tested | Native acceptance outstanding. |
| 028 | [The Republic of Borrowed Tomorrows](../TheRepublicOfBorrowedTomorrows/README.md) | Blocked | Partial (debt bonus blocked) | Partial (debt branch blocked) | Stock fallbacks | Reconstructed on load | SQLite / Lua 5.1 | Not tested | Exact debt-neutral settlement is blocked. Only the active Pikeman/Market replacements, +15% friendly strength and debt-free Exchange yields are enabled. |
| 029 | [The Lichen Compact](../TheLichenCompact/README.md) | Implemented | Implemented | Implemented | Stock fallbacks | Reconstructed on load | SQLite / Lua 5.1 | Not tested | Native acceptance outstanding. |
| 030 | [The Glass Orchard](../TheGlassOrchard/README.md) | Implemented | Implemented | Implemented | Stock fallbacks | Reconstructed on load | SQLite / Lua 5.1 | Not tested | Native acceptance outstanding. |

See [validation output](../tools/Validation.json) for actual automated outcomes and [CP151 proof](DailyExpansion_021_035_SourceProof.md) for engine contracts. Use `git log --oneline f745be8..HEAD` on the feature branch for the stage commit references.
