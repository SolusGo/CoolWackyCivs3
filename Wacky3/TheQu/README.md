# The Qu — Architects of Flesh

In C. M. Kösemen’s *All Tomorrows*, the Qu are ancient galactic nomads who use genetics and nanotechnology to reshape themselves and the worlds they visit. They come to believe that only they have the right to direct the future of life. They conquer the human Star People and leave behind altered descendants whose evolution continues long after the Qu depart. [All Tomorrows, “Qu” and “Man Extinguished”](https://marsh.speedrunwiki.com/Text/alltomorrows.pdf#page=15)

The mod imagines a Qu expedition led by **The First Architect** from **Genesis Spire**. Its three castes turn the book’s premise into a city mechanic. Domination is the strongest victory route, with Science as the alternative. The Qu are human-selectable in a new sequential single-player game of Brave New World with standalone Community Patch v151.

## Divine Reconfiguration

Gain **1 Biomass** for each eligible enemy military unit killed by the Qu, including city-state units and defensive kills. Combat can supply **3 Biomass per Qu game turn**. Entering a new era grants **2 Biomass** once, beginning with the first era after the starting era. The cap is **10 Biomass**. Era rewards have their own allowance, and Biomass does not decay.

Click **Biomass** on the right side of the world screen to open Genetic Reconfiguration. You can also use **Additional Information → Genetic Reconfiguration**. Choose a city with Previous City or Next City, then choose and confirm a caste. The panel lists required technologies, city eligibility, current Population, and both costs.

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

The new illustrations follow the supplied graphite reference. Short lateral eye stalks frame the Qu’s narrow face, four translucent wings form a steep X, and a single long tail curls beneath the body. Stark pyramids and grey washes carry the look into Genesis Spire and the Gene Foundry. Built-in ImageGen produced six original compositions guided by the reference. The pack’s DDS pipeline builds the portraits, scenes, map panel, alpha icon, and unit flag. [Art prompts](Art/Sources/Prompts.json)

See [testing and CP151 compatibility](TESTING.md) for engine behavior, verification status, and native acceptance.
