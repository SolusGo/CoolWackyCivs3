# The Salt Road Compact

**Leader:** First Broker Nahir. **Capital:** White Mile. **Focus:** Science / Diplomacy.
Canonical [Daily Surprise #016](https://github.com/SolusGo/Weekly-civs/blob/main/Civilizations/016-the-salt-road-compact.md), archive blob `305486be68f471c292f585f52823d1ac41289444`.

## Exact economy

**The Price of Passage:** a Compact-owned city originating one or more active land trade routes gains +2 recurring Production and +1 recurring Culture. The condition is binary: one route and five routes from that city give the same bonus. Incoming routes, sea routes, mere path crossings, completed circuits and recalled/canceled routes do not qualify. Domestic and international land routes can both qualify.

`Player:GetTradeRoutes()` supplies native nonempty connections belonging to the player's origin owner. The implementation checks `FromID`, `FromCity`, `Domain`, actual city owners, `IsRecalled` and `CircuitsCompleted < CircuitsToComplete`. Native completion is circuit-based; `TurnsLeft` is an estimate and is deliberately not used to expire an otherwise active connection. Recalled routes are excluded immediately upon the next observed reconciliation even if the native Caravan is still traveling home.

**Salt Exchange:** replaces the active Caravansary, preserving all scalars and approved companion data. It adds +1 permanent Food and +1 permanent Gold, then +1 conditional Science when its Compact city satisfies the same outgoing land-route condition. Expiration removes only conditional Science and the UA controller. It never deletes the Exchange or its permanent Food/Gold. Five route-active cities with Exchanges gain **+10 Production, +5 Culture, +5 Science, +5 Food and +5 Gold** in unique base recurring yields.

## Dune Escort and combat proof

The Horseman replacement inherits every active mounted property, resource requirement, cost, Movement, prerequisite, promotion, selection sound, art and upgrade route. It adds +1 Sight and +15% attack into Desert / +15% defense on Desert. Desert Hills and Desert tiles with Oasis/Flood Plains features qualify.

The implementation uses native **`UnitPromotions_TerrainModifiers`**, rather than `UnitPromotions_Terrains` (whose ordinary terrain branch can be suppressed by a feature). The pinned CP151 promotion loader and application code use this table without requiring VP balance. Melee attack reads **`pToPlot`**, while melee defense reads **`pInPlot`** and ranged defense reads **`pMyPlot`**. A Horseman's inherited no-terrain-defense property does not suppress this explicit promotion modifier. No temporary generic CombatPercent toggling or attacker-current-plot attack approximation is used.

The promotion survives the normal melee mounted upgrade lineage. The source's ranged attacking branch reads its own plot for this CP-specific table; arbitrary third-party conversion into a ranged attacker is outside the supported Horseman upgrade path and is not certified to preserve target-based attack semantics. Native ranged defense is supported by the defending-plot branch. Native actual combat previews and resolution remain acceptance tests despite the source proof.

## Strategy and counterplay

Establish safe land connections early, then spread route origins among productive cities when route economics are otherwise comparable. Stacking every route in the Capital forfeits additional city activations. Build Exchanges to add permanent support and conditional Science. Do not choose an unsafe or unprofitable route solely for these modest flat bonuses.

In the midgame, guard exposed corridors with Escorts and use Desert target tiles to choose battles. Starting an attack from Desert into Grassland grants no terrain bonus. Conversely, an attack from Grassland into Desert qualifies. Upgrades and route planning remain essential: the ability adds no extra route capacity or diplomatic votes.

In the late game, convert safer commerce and the Production bonus into research infrastructure, projects and diplomatic resources. Reassign routes as city ownership, diplomacy and hazards change. Weaknesses are vulnerable land corridors, a finite trade capacity and poor value on sea-oriented maps. Counterplay is to plunder land routes, force sea routes and lure Escorts off Desert defensive positions.

Flat unique yields are identical across all four standard speeds. Native route durations, research pacing and general economic modifiers still differ normally.

## Events, fallback art and limits

Source-verified route establishment precedes the original Caravan's `UnitPrekill`; that callback refreshes origins after the connection exists. Route completion fires before native clearing, but its already-completed circuits exclude it immediately. Plunder refresh runs after clearing; returned trade-unit creation supplies another recovery point. City transfer, construction/sale, load, UI dirtiness and bounded owner-turn passes reconcile all city conditions, sharing one route set per owner evaluation.

There is no universal post-cancel hook in the audited source. Cancellation and arbitrary scripted route changes without another callback wait for UI dirtiness or the next bounded evaluation. UI delivery timing and actual native economic settlement remain unverified. A post-economy owner-turn change affects the next payout, never retroactively changes collected yields.

`SQL/SALT_{Civilization,Units,Buildings,Text}.sql` and `Lua/SALT_Gameplay.xml` provide one human-only civilization/context and two exact binary controllers. Teal/sand colors use intentional native America/Washington/Horseman/Caravansary atlas, Dawn and diplomacy fallbacks. See [testing](TESTING.md), [strategy](../docs/strategy/TheSaltRoadCompact.md) and [source contracts](../docs/ArchivedDailyTesting.md). No native gameplay pass is claimed.
