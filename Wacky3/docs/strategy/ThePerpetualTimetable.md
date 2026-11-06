# Playing The Perpetual Timetable

Veyl converts practical infrastructure into flat Science, Production and Culture. The bonuses reward connected cities without growing exponentially by era or population. Science is the primary victory focus; a developed network also supports Culture.

## Ancient–Classical

Improve food and production tiles and establish economically sensible settlements. Line Surveyors move one point farther than active Workers and perform all normal construction at 110% Work Rate. Use that advantage for resources, farms and mines as well as routes. Standard Worker capture and terrain rules apply, so escort surveyors where needed. Roads have normal costs: a long connection to a weak settlement may still be a poor investment.

## Medieval

Connect non-capital cities to Terminus Prime. An ordinary connection supplies +1 Production and +1 Science. Coastal Harbor connections qualify under the native game's rules and can make distant cities useful without an expensive overland corridor. Build Dispatch Offices when you would benefit from Workshops: every Office retains the active Workshop's industry and specialists, adds permanent Gold, and adds Culture in an ordinarily connected non-capital city. The Capital receives the Office's Gold but none of the conditional bonuses.

## Industrial

Research Railroad and upgrade existing connections. Own the whole corridor, keep every non-city segment as intact Railroad, and use owned city centers as junctions. A Road gap, unowned tile or foreign Open Borders corridor prevents the special rail bonuses. Harbors still give ordinary bonuses but cannot join two land railroad fragments. Overseas cities need an actual qualifying land path for the additional effects; a coastal sea link alone is insufficient.

An Office city with both ordinary and full railroad eligibility adds +2 Production, +1 Science, +2 Culture and +1 Gold beyond its inherited Workshop. Prioritize valuable corridors and junctions. Alternative owned tracks can keep an otherwise vulnerable branch connected when one segment is pillaged. Repair damaged lines with Surveyors; there is no military bonus protecting them.

## Modern–Information

Use your established economy to pursue Science. Consider Culture if the empire's existing policies, wonders and tourism support it; the Timetable adds Culture, not a new tourism mechanic. Develop useful cities, protect infrastructure and avoid expansion purely to chase small bonuses. Six developed railway cities with Offices add 10 Production, 5 Science, 10 Culture and 6 Gold across the empire.

## Reading the yields

Bonuses are recurring city yields. After each owner `PlayerDoTurn` evaluation they govern the **following payout**, because CP151 has already settled that turn's economy. A track repair or connection loss waits until the next documented evaluation; founding/acquisition and Office construction/sale have additional confirmed callbacks. Reload repairs current eligibility but grants no instant yields. Allow the documented evaluation and following payout when comparing income; native modifiers and resistance can affect what is actually collected. The [testing guide](../TimetableTesting.md) separates source evidence and mocks from native acceptance.
