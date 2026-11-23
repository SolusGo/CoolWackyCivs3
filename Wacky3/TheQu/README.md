# The Qu — Architects of Flesh

The First Architect leads the Qu from **Genesis Spire**. Their strongest victory route is Domination, with Science as the alternative. The Qu are human-selectable in a new sequential single-player game of Brave New World with standalone Community Patch v151.

## Divine Reconfiguration

Gain **1 Biomass** for each eligible enemy military unit killed by the Qu, including city-state units and defensive kills. Combat can supply **3 Biomass per Qu game turn**. Entering a new era grants **2 Biomass** once, beginning with the first era after the starting era. The cap is **10 Biomass**. Era rewards have their own allowance, and Biomass does not decay.

Open **Additional Information → Genetic Reconfiguration** at the upper right of the world screen. Its menu entry displays the current reserve. Choose a city with Previous City or Next City, then choose and confirm a caste. The panel lists required technologies, city eligibility, current Population, and both costs.

The city must be a foreign-founded military conquest under Qu control. Annex it, end resistance, stop any razing, and build a Courthouse. You need at least 6 Population and 5 Biomass. Installation consumes **5 Biomass and 1 Population**. Only one caste can be installed, and it disappears when you lose the city. A military reconquest starts a new claim and costs the full amount again.

| Caste | Technology | City yield modifiers |
| --- | --- | --- |
| Labor Forms | Metal Casting | +12% Production, −10% Science |
| Cognitive Forms | Education | +12% Science, −10% Production |
| Brood Forms | Chemistry | +15% Food, −10% Science |

The percentages use CP151's native city yield calculation. Brood applies to base Food before consumption. CP applies some other sources, such as trade route yields, after city modifiers.

## Qu Harvester and Gene Foundry

The **Qu Harvester** replaces the Rifleman at Rifling. Costs, resources, movement, strength, the world model, and upgrade destinations inherit the active Rifleman. **Biological Harvesting** adds 15 percentage points of combat strength when the opposing unit starts combat wounded. The promotion survives upgrades. Use ranged fire to soften targets before committing Harvesters.

The **Gene Foundry** replaces the Workshop at Metal Casting and inherits its active effects, including maintenance, specialists, and construction rules. It adds **1 base Science at Population 5–9** and **2 at Population 10+**. Build it in developed founded or captured cities.

## Strategy and Marathon

In the early game, build a stable economy and fight only where you can pay for annexation, happiness, and defense. Labor Forms develop a production center, Cognitive Forms reward established science cities, and Brood Forms work best where gross Food is high enough to justify sacrificing a citizen and Science. A five-Biomass price and a one-caste limit make sustained conquest useful without making every occupation an immediate investment.

Biomass amounts, costs, cap, combat allowance, population thresholds, and city modifiers are the same at every speed. The combat allowance resets on the Qu's owner-turn callback. Defensive kills between Qu turns count toward the previous Qu turn's allowance. The engine supplies normal Marathon scaling for Riflemen, Workshops, and other native costs.

## Artwork

The portrait and diplomacy scene depict a nonhuman, four-winged flier with a long prehensile tail, leaf-like wings, and an inverted triangular body. Genesis Spire and the Gene Foundry use monumental pyramidal forms in ochre, crimson, and muted blue-green. Six original raster masters were made with built-in ImageGen from written prompts. The icon crops, map panel, alpha icon, and unit flag are built by the pack’s DDS pipeline. [Original prompts](Art/Sources/Prompts.json) · [C. M. Kösemen’s All Tomorrows](https://d3arts.cz/wp-content/uploads/2025/06/All-Tomorrows_C-M-Kosemen_book.pdf)

See [testing and CP151 compatibility](TESTING.md) for engine behavior, verification status, and native acceptance.
