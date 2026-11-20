"""Build the expansion's per-civilization guides and roster links."""
from baseline import ROOT
from generate_daily_expansion import ROSTER, code

ACCEPTANCE = {
    21: "Compare inland, lake-only and ocean cities. Add native, free and replacement Harbors. Compare defense and attack in own land, Open Borders and neutral territory.",
    22: "Compare a genuine military kill with disband, enemy city fire and barbarian deaths. Test both Lesson thresholds and cooldowns; save before spending and after partial expiry. Test melee survival, ranged survival, immediate attack, upgrade and unused expiry.",
    23: "Compare two, three and four neighboring Plains/Grassland plots with hills and features. Attack units on qualifying and nonqualifying target plots from the opposite terrain, then defend on both.",
    24: "Build the second, third, fifth, sixth and seventh Post Offices, including a free copy. Test initial movement, border crossing, same-turn return and upgrades while measuring remaining movement points.",
    25: "Compare lake-adjacent and ocean-adjacent land, inland, embarked and impassable defense. Compare attacks on the same plots. Captured/free replacement Walls count toward the coastal Science.",
    26: "Start in Ancient and in a later era. Pick each of the three resolutions in separate eras. Save with a pending choice and after voting. Advance through a tech purchase or free tech and confirm one choice. Upgrade an Inkguard.",
    27: "Work 0–5 Marsh plots with and without pillage. Test two and four owned Marsh plots in overlapping city radii. Measure feature movement and +10/+25 nominal defense on and off Marsh.",
    28: "Verify the friendly-territory modifier and debt-free Market yields. Advance, repayment and debt-dependent effects remain blocked pending the settlement hooks in the report.",
    29: "Work 0–5 Tundra and 0–4 Snow tiles. Change assignments without changing ownership. Test the third and sixth owned plots and cold-hill settlement. Upgrade the Stonewalker.",
    30: "Work two, three, four and five Desert tiles including pillaged tiles, Hills and Flood Plains. Use a wet and a dry city. Start/end major and minor wars. Attack and defend on Desert.",
    31: "Reveal 99, 100, 199 and 200 land plots by any source and confirm Atlas House thresholds. For unit-attributed rewards, compare your unit sight, externally supplied reveals, water and duplicate reveals. Test the era cap and reload.",
    32: "Assign and unassign Gold, Silver and Iron Mines. Pillage/repair, test multiple Mines and an unworked Lake. Distinguish a Lake from a river and Coast, and test Hill defense versus attack.",
    33: "Use an empty center, then a civilian, aircraft, embarked/naval unit, adjacent Spearman and land garrison. Move, kill, upgrade and replace the actual garrison, then compare all four yields.",
    34: "Compare flat and Hill founding, then add and remove both native and replacement Walls. Attack at range and defend on Hills. Validate that the fictional leader is identified as such.",
    35: "Observe the counter and actual production, science and treasury stores separately at 0, 1, renewed and extended WLTKD. Compare two cities in different states and a city without an Office. Test friendly-land attacks and defenses.",
}
BLOCKERS = {
    22: "Primary two-unit combat only. Independently attributed interceptor and collateral deaths are not covered. Native dispatch and attack consumption still require acceptance.",
    24: "Movement is sampled at the post-economy PlayerDoTurn hook, then deducted on leaving friendly land. Native spend order and Open Borders changes need acceptance.",
    25: "Native combat previews may lag a script-only plot mutation until state is repaired at BattleStarted.",
    26: "An outstanding vote grants no active resolution until a player chooses. UI rendering and callback dispatch still require native acceptance.",
    28: "Exact debt-neutral settlement is blocked. Only the active Pikeman/Market replacements, +15% friendly strength and debt-free Exchange yields are enabled.",
    31: "TileRevealed carries explicit unit provenance only. The ability credits verified in-session own-unit discoveries. City-only and pre-context starting reveals cannot be distinguished from external reveals and are excluded.",
    35: "Native production uses the counter before the city countdown step. Treasury and research use the state later in the same turn. One-turn boundary behavior requires native measurement.",
}

def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value.strip()+'\n',encoding='utf-8',newline='\n')

def main():
    rows, tests = [], []
    for s in ROSTER:
        number, folder = s['id'], s['folder']
        note = BLOCKERS.get(number, "Native timing, combat and save acceptance remain outstanding.")
        design = f"https://github.com/SolusGo/Weekly-civs/blob/main/Civilizations/{code(s)[1:]}-{s['design']}.md"
        rows.append(f"| {number:03} | [{s['name']}]({folder}/README.md) | {s['leader']} | {s['capital']} |")
        tests.append(f"| {number:03} | [{s['name']}](../{folder}/TESTING.md) | {ACCEPTANCE[number]} |")
        write(ROOT/folder/'README.md',f"""
# {s['name']}

{s['leader']} leads this human-only civilization from {s['capital']}. {s['pedia']}

- **{s['ability']}**. {s['ability_help']}
- **{s['unit']}** replaces {s['unit_parent'].replace('_',' ').title()}. {s['unit_help']}
- **{s['building']}** replaces {s['building_parent'].title()}. {s['building_help']}

The replacements inherit the active standalone Community Patch v151 definitions and approved companion effects. Presentation uses stock art where an original illustration is outstanding.

{note}

[Canonical design]({design}) · [Strategy](../docs/strategy/{folder}.md) · [Acceptance](TESTING.md)
""")
        write(ROOT/'docs/strategy'/f'{folder}.md',f"""
# Playing {s['name']}

{s['strategy']}

For the exact eligibility and native acceptance notes, see the [civilization guide](../../{folder}/README.md).
""")
        write(ROOT/folder/'TESTING.md',f"""
# Native acceptance for {s['name']}

**NOT TESTED — native game execution unavailable during this implementation.**

1. Start a new sequential BNW game with standalone CP151 and this pack at Standard speed. Select {s['name']} and compare leader, capital, icons, Dawn, Civilopedia and diplomacy with the guide.
2. Confirm {s['unit']} and {s['building']} replace the intended classes and retain active CP restrictions and unrelated effects.
3. {ACCEPTANCE[number]}
4. Save and reload during the qualifying state. Lose or capture a city and check that only the current owner receives its conditional yields. Where relevant, repeat with two cities and an upgraded or captured unit.
5. Repeat on Marathon. Record actual stores, save files, combat panels and Database.log/Lua.log. Compare endpoints on both sides of the economic settlement.
6. Mark any native mismatch **FAIL — observed or reproduced mismatch**. Attach evidence before marking **PASS — native gameplay observed**.

{note}
""")
    path=ROOT/'README.md'
    readme=path.read_text(encoding='utf-8')
    first=readme.splitlines()[2]
    if 'Current roster:' in first:
        first=first.replace('Current roster:', 'Original roster:')
        readme='\n'.join(readme.splitlines()[:2]+[first]+readme.splitlines()[3:])
    marker='<!-- daily-expansion-start -->'
    block=marker+f"""
## Daily Surprise expansion

The pack includes {10+len(ROSTER)} registered civilizations. The original ten are listed above.

| Daily | Civilization | Leader | Capital |
| --- | --- | --- | --- |
"""+'\n'.join(rows)+"""

[Implementation report](docs/DailyExpansion_021_035_ImplementationReport.md) · [Native testing index](docs/DailyExpansion_021_035_Testing.md)

<!-- daily-expansion-end -->"""
    if marker in readme:
        start=readme.index(marker)
        end=readme.index('<!-- daily-expansion-end -->',start)+len('<!-- daily-expansion-end -->')
        readme=readme[:start]+block+readme[end:]
    else:
        readme=readme.replace('## Installation',block+'\n\n## Installation',1)
    write(path,readme)
    write(ROOT/'docs/DailyExpansion_021_035_Testing.md',"""
# Daily Surprise native acceptance

**NOT TESTED — native game execution unavailable during this implementation.** The Lua 5.1 fixtures and SQLite checks are automated source tests only. Start a new sequential game with BNW, standalone CP151 and Wacky3. Follow each checklist at Standard and Marathon, and record saves, actual yields, combat and relevant game logs.

| Daily | Checklist | Distinguishing case |
| --- | --- | --- |
"""+'\n'.join(tests))
    report=[]
    for s in ROSTER:
        n=s['id']
        state={22:'Player and unit ScriptData', 24:'Owner-turn grant marker and native promotion',
               26:'Player ScriptData',31:'Player ScriptData and reveal flags'}.get(n,'Reconstructed on load')
        ua='Implemented' if n not in {22,28,31,35} else {22:'Partial',28:'Blocked',31:'Partial',35:'Source implementation, phase boundary unverified'}[n]
        uu='Partial (debt bonus blocked)' if n==28 else 'Implemented'
        ub='Partial (debt branch blocked)' if n==28 else 'Implemented'
        report.append(f"| {n:03} | [{s['name']}](../{s['folder']}/README.md) | {ua} | {uu} | {ub} | Stock fallbacks | {state} | SQLite / Lua 5.1 | Not tested | {BLOCKERS.get(n,'Native acceptance outstanding.')} |")
    write(ROOT/'docs/DailyExpansion_021_035_ImplementationReport.md',"""
# Daily Surprise expansion implementation

Baseline main commit is `f745be8454e99d0e25d2b88574aa48e13dc31530`. The implementation targets the original version 1 package and standalone CP151. Canonical design blob IDs are in the build roster. Existing saves still require native compatibility acceptance.

| Daily | Sources | UA | UU | UB | Art | State | Automated checks | Native | Outstanding |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
"""+'\n'.join(report)+"""

See [validation output](../tools/Validation.json) for actual automated outcomes and [CP151 proof](DailyExpansion_021_035_SourceProof.md) for engine contracts. Use `git log --oneline f745be8..HEAD` on the feature branch for the stage commit references.
""")

if __name__ == '__main__':
    main()
