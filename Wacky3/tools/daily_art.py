"""Art-only metadata for the five archived civilizations. No gameplay fields."""
CATALOG = [
    dict(code='LOST', folder='TheDepartmentOfLostThings', prefix='CWC3_LOST',
         civ='CIVILIZATION_CWC3_LOST', leader='LEADER_CWC3_LOST', unit='UNIT_CWC3_LOST', building='BUILDING_CWC3_LOST',
         building_kind='Building', background=(14,22,60), portrait=(.25,0,.78,.72),
         identity='Headless spectral registrar; floating spectacles, empty collar, indigo coat and scarlet seals.'),
    dict(code='SCARECROW', folder='TheAssemblyOfScarecrows', prefix='CWC3_SCARECROW',
         civ='CIVILIZATION_CWC3_SCARECROW', leader='LEADER_CWC3_SCARECROW', unit='UNIT_CWC3_SCARECROW', building='BUILDING_CWC3_SCARECROW',
         building_kind='Building', background=(29,43,19), portrait=(.15,.01,.72,.77),
         identity='Crooked living scarecrow; mismatched seed/button eyes, straw whiskers, thistle hat and a crow.'),
    dict(code='MAKURIA', folder='TheKingdomOfMakuria', prefix='CWC3_MAKURIA',
         civ='CIVILIZATION_CWC3_MAKURIA', leader='LEADER_CWC3_MAKURIA', unit='UNIT_CWC3_MAKURIA', building='BUILDING_CWC3_MAKURIA',
         building_kind='Building', background=(82,20,20), portrait=(.23,0,.78,.73),
         identity='Broad clean-shaven Nubian king; short coiled hair, restrained cross diadem, ivory and red-ochre robes.'),
    dict(code='SALT', folder='TheSaltRoadCompact', prefix='CWC3_SALT',
         civ='CIVILIZATION_CWC3_SALT', leader='LEADER_CWC3_SALT', unit='UNIT_CWC3_SALT', building='BUILDING_CWC3_SALT',
         building_kind='Building', background=(9,65,71), portrait=(.26,0,.81,.73),
         identity='Older merchant matriarch; knowing smile, white eyebrow streak, low turquoise wrap and coral robe.'),
    dict(code='PALEO', folder='ThePaleontologicalDirectorate', prefix='PALEO',
         civ='CIVILIZATION_PALEO_DIRECTORATE', leader='LEADER_PALEO_OTHMAR', unit='UNIT_PALEO_FOSSIL_EXPEDITION', building='BUILDING_PALEO_NATURAL_HISTORY_MUSEUM',
         building_kind='Museum', background=(29,52,46), portrait=(.20,0,.77,.76),
         identity='Stout bald fossil scholar; wild white side-whiskers and eyebrows, huge monocle, vermilion waistcoat and ammonite.'),
]

def spec(code):
    return next(s for s in CATALOG if s['code']==code)
