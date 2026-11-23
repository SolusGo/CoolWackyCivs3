"""Generate the Qu's SQL using active parents and the pinned companion inventory."""
import os
from pathlib import Path

from baseline import ROOT, quote
from generate_timetable import literal
from target_schema import approved_companions, schema_database

PREFIX = 'TXT_KEY_CWC3_QU_'
CIV = 'CIVILIZATION_CWC3_QU'
LEADER = 'LEADER_CWC3_QU_FIRST_ARCHITECT'
TRAIT = 'TRAIT_CWC3_QU_DIVINE_RECONFIGURATION'
UNIT = 'UNIT_CWC3_QU_HARVESTER'
BUILDING = 'BUILDING_CWC3_QU_GENE_FOUNDRY'
PROMOTION = 'PROMOTION_CWC3_QU_BIOLOGICAL_HARVESTING'
CASTES = {
    'LABOR': {'PRODUCTION': 12, 'SCIENCE': -10},
    'COGNITIVE': {'SCIENCE': 12, 'PRODUCTION': -10},
    'BROOD': {'FOOD': 15, 'SCIENCE': -10},
}
CITIES = (
    'Genesis Spire', 'Veyr Ossuary', 'Thessal Shell', 'Vessel of Oroth',
    'Nacre Meridian', 'Serev Crucible', 'Vitrial Reach', 'Keth Ur',
    'The Seventh Vent', 'Auralis Vats', 'Ossic Terrace', 'Shale Chrysalis',
    'Nerith Vault', 'Sular Membrane', 'Cytara Basin', 'Ash of Vhal',
    'Molt of Irith', 'Serakh Canopy', 'The Last Carapace',
)
SPIES = ('Vessin', 'Olt', 'Rhel', 'Terekh', 'Sulash', 'Iritt', 'Othil', 'Meresh', 'Urrakh', 'Sevril')


def copy(table, column, old, new, changes=None):
    source = f'{quote(column)}={literal(old)}'
    assignments = {column: new, **(changes or {})}
    update = ','.join(f'{quote(key)}={literal(value)}' for key, value in assignments.items())
    return (f'CREATE TEMP TABLE CWC3_QuCopy AS SELECT * FROM {quote(table)} WHERE {source};\n'
            f'UPDATE CWC3_QuCopy SET {update};\n'
            f'INSERT INTO {quote(table)} SELECT * FROM CWC3_QuCopy;\nDROP TABLE CWC3_QuCopy;\n')


def companions(db, prefix, column, old, new):
    sql = ''
    for table in approved_companions(prefix, column):
        columns = [row[1] for row in db.execute(f'PRAGMA table_info({quote(table)})')]
        sql += copy(table, column, old, new, {'ID': None} if 'ID' in columns else None)
    return sql


def civilization():
    sql = f"""UPDATE CustomModOptions SET Value=1 WHERE Name IN
 ('EVENTS_BATTLES','EVENTS_RED_COMBAT','EVENTS_RED_COMBAT_RESULT','EVENTS_RED_COMBAT_ENDED','EVENTS_NEW_ERA','EVENTS_UNIT_CAPTURE');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES
 ('COLOR_CWC3_QU_GOLD',0.92,0.72,0.35,1),('COLOR_CWC3_QU_CRIMSON',0.28,0.045,0.068,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES
 ('PLAYERCOLOR_CWC3_QU','COLOR_CWC3_QU_GOLD','COLOR_CWC3_QU_CRIMSON','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES
 ('{TRAIT}','{PREFIX}TRAIT_HELP','{PREFIX}TRAIT');
"""
    sql += copy('Civilizations', 'Type', 'CIVILIZATION_AMERICA', CIV, dict(
        ID=None, Description=PREFIX+'CIV', ShortDescription=PREFIX+'SHORT',
        Adjective=PREFIX+'ADJECTIVE', Civilopedia=PREFIX+'CIV_PEDIA', CivilopediaTag=PREFIX+'CIV5',
        Strategy=PREFIX+'CIV_STRATEGY', Playable=1, AIPlayable=0, PackageID=None,
        DefaultPlayerColor='PLAYERCOLOR_CWC3_QU', IconAtlas='CWC3_QU_CIV_ATLAS',
        AlphaIconAtlas='CWC3_QU_ALPHA_ATLAS', PortraitIndex=0, DawnOfManQuote=PREFIX+'DAWN',
        DawnOfManAudio='', DawnOfManImage='CWC3_Qu_Dawn.dds', MapImage='CWC3_Qu_Map.dds'))
    sql += copy('Leaders', 'Type', 'LEADER_WASHINGTON', LEADER, dict(
        ID=None, Description=PREFIX+'LEADER', Civilopedia=PREFIX+'LEADER_PEDIA',
        CivilopediaTag=PREFIX+'LEADERPAGE', IconAtlas='CWC3_QU_LEADER_ATLAS', PortraitIndex=0,
        ArtDefineTag='CWC3_Qu_LeaderScene.xml', PackageID=None, Boldness=8, WarmongerHate=2,
        Meanness=8, Loyalty=4, Forgiveness=2, DoFWillingness=3))
    for table in ('Civilization_FreeBuildingClasses', 'Civilization_FreeTechs', 'Civilization_FreeUnits'):
        sql += copy(table, 'CivilizationType', 'CIVILIZATION_AMERICA', CIV)
    for table in ('Leader_MajorCivApproachBiases', 'Leader_MinorCivApproachBiases'):
        sql += copy(table, 'LeaderType', 'LEADER_WASHINGTON', LEADER)
    sql += f"""INSERT INTO Civilization_Leaders(CivilizationType,LeaderheadType) VALUES ('{CIV}','{LEADER}');
INSERT INTO Leader_Traits(LeaderType,TraitType) VALUES ('{LEADER}','{TRAIT}');
INSERT INTO Civilization_UnitClassOverrides(CivilizationType,UnitClassType,UnitType)
 SELECT '{CIV}',Class,'{UNIT}' FROM Units WHERE Type='UNIT_RIFLEMAN';
INSERT INTO Civilization_BuildingClassOverrides(CivilizationType,BuildingClassType,BuildingType)
 SELECT '{CIV}',BuildingClass,'{BUILDING}' FROM Buildings WHERE Type='BUILDING_WORKSHOP';
INSERT INTO Leader_Flavors(LeaderType,FlavorType,Flavor)
 SELECT '{LEADER}',Type,CASE Type WHEN 'FLAVOR_OFFENSE' THEN 10 WHEN 'FLAVOR_MILITARY_TRAINING' THEN 9
 WHEN 'FLAVOR_SCIENCE' THEN 9 WHEN 'FLAVOR_PRODUCTION' THEN 8 ELSE 5 END FROM Flavors;
"""
    for table, column, category, names in (
        ('Civilization_CityNames', 'CityName', 'CITY', CITIES),
        ('Civilization_SpyNames', 'SpyName', 'SPY', SPIES),
    ):
        for index, _ in enumerate(names, 1):
            sql += f"INSERT INTO {table}(CivilizationType,{column}) VALUES ('{CIV}','{PREFIX}{category}_{index}');\n"
    return sql


def unit(db):
    sql = copy('Units', 'Type', 'UNIT_RIFLEMAN', UNIT, dict(
        ID=None, Description=PREFIX+'UNIT', Help=PREFIX+'UNIT_HELP', Strategy=PREFIX+'UNIT_STRATEGY',
        Civilopedia=PREFIX+'UNIT_PEDIA', IconAtlas='CWC3_QU_UNIT_ATLAS', PortraitIndex=0,
        UnitFlagAtlas='CWC3_QU_FLAG_ATLAS', UnitFlagIconOffset=0))
    sql += companions(db, 'Unit_', 'UnitType', 'UNIT_RIFLEMAN', UNIT)
    sql += f"""INSERT INTO UnitPromotions
 (Type,Description,Help,Sound,CannotBeChosen,LostWithUpgrade,AttackWoundedMod,IconAtlas,PortraitIndex)
 VALUES ('{PROMOTION}','{PREFIX}PROMOTION','{PREFIX}PROMOTION_HELP','AS2D_IF_LEVELUP',1,0,15,'CWC3_QU_UNIT_ATLAS',0);
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('{UNIT}','{PROMOTION}');
INSERT INTO UnitPromotions(Type,Description,Help,CannotBeChosen,LostWithUpgrade,DefenseMod,IconAtlas,PortraitIndex)
 VALUES ('PROMOTION_CWC3_QU_BIOLOGICAL_DEFENSE','{PREFIX}PROMOTION','{PREFIX}PROMOTION_HELP',1,1,15,'CWC3_QU_UNIT_ATLAS',0);
"""
    return sql


def buildings(db):
    sql = copy('Buildings', 'Type', 'BUILDING_WORKSHOP', BUILDING, dict(
        ID=None, Description=PREFIX+'BUILDING', Help=PREFIX+'BUILDING_HELP', Strategy=PREFIX+'BUILDING_STRATEGY',
        Civilopedia=PREFIX+'BUILDING_PEDIA', IconAtlas='CWC3_QU_FOUNDRY_ATLAS', PortraitIndex=0))
    sql += companions(db, 'Building_', 'BuildingType', 'BUILDING_WORKSHOP', BUILDING)
    for suffix in (*CASTES, 'FOUNDRY_1', 'FOUNDRY_2'):
        name = 'BUILDING_CWC3_QU_' + suffix
        cls = 'BUILDINGCLASS_CWC3_QU_' + suffix
        text = PREFIX + (suffix if suffix in CASTES else 'FOUNDRY_EFFECT')
        sql += f"""INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('{cls}','{name}','{text}');
INSERT INTO Buildings(Type,BuildingClass,Description,Cost,GoldMaintenance,FaithCost,GreatWorkCount,
 NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('{name}','{cls}','{text}',-1,0,-1,-1,1,1,1,0,0,'CWC3_QU_FOUNDRY_ATLAS',0);
"""
        if suffix in CASTES:
            for yield_name, change in CASTES[suffix].items():
                sql += f"INSERT INTO Building_YieldModifiers(BuildingType,YieldType,Yield) VALUES ('{name}','YIELD_{yield_name}',{change});\n"
        else:
            sql += f"INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('{name}','YIELD_SCIENCE',{suffix[-1]});\n"
    return sql


def localization():
    text = {
        'CIV': 'The Qu — Architects of Flesh', 'SHORT': 'The Qu', 'ADJECTIVE': 'Qu',
        'LEADER': 'The First Architect', 'TRAIT': 'Divine Reconfiguration',
        'TRAIT_HELP': 'Gain 1 Biomass from eligible enemy military kills (up to 3 per turn) and 2 Biomass when entering a new era. Store up to 10. Spend 5 Biomass and 1 Population to install one genetic caste in an annexed conquest. Open Genetic Reconfiguration in Additional Information.',
        'DAWN': 'First Architect, the vaults of Genesis Spire open at your approach. Across the stars, countless civilizations have risen and fallen. You have learned to shape the one material they all carry with them: life itself. Where a conqueror might leave a ruin, your people leave descendants remade to serve a design.[NEWLINE][NEWLINE]The world still calls flesh its own. What form will you give it?',
        'CIV_PEDIA': 'The Qu are ancient extraterrestrial engineers who regard living forms as mutable. Their four narrow wings and searching tails are the product of their own long history of redesign. From Genesis Spire, the First Architect directs a campaign to reshape the societies the Qu conquer.',
        'CIV_STRATEGY': 'Build Gene Foundries in established cities. Secure a defensible conquest, let resistance end, and build a Courthouse before spending Biomass. Use Labor Forms for industrial centers, Cognitive Forms for research hubs, and Brood Forms where gross Food is high.',
        'LEADER_PEDIA': 'The First Architect is the original sovereign of Genesis Spire in this adaptation. The Architect settles arguments over the purpose of a city by choosing the design its people must inhabit.',
        'UNIT': 'Qu Harvester',
        'UNIT_HELP': 'Replaces the Rifleman and retains its active statistics and upgrade path. Biological Harvesting grants +15% Combat Strength against already-wounded enemy units and stays through upgrades.',
        'UNIT_PEDIA': 'Harvester formations follow fractures in an enemy line. A field instrument, guided by the operator’s long prehensile tail, reads the traces left by an earlier engagement.',
        'UNIT_STRATEGY': 'Soften enemy units before committing Harvesters. Capture ground with their ordinary Rifleman movement and retain the promotion as they upgrade.',
        'PROMOTION': 'Biological Harvesting',
        'PROMOTION_HELP': '+15% Combat Strength when attacking or defending against an enemy unit already wounded at the start of combat. Retained on upgrade.',
        'BUILDING': 'Gene Foundry',
        'BUILDING_HELP': 'Replaces the Workshop and retains its effects. Provides +1 base [ICON_RESEARCH] Science at Population 5–9 and +2 at Population 10 or higher.',
        'BUILDING_PEDIA': 'Within pyramidal banks of living ceramic, the Foundry grows tools, maintains culture vaults, and records experiments carried out by the city’s researchers.',
        'BUILDING_STRATEGY': 'Build Gene Foundries wherever you would build Workshops. Growing a Foundry city to Population 5 or 10 increases its base Science.',
        'LABOR': 'Labor Forms', 'COGNITIVE': 'Cognitive Forms', 'BROOD': 'Brood Forms',
        'LABOR_EFFECT': '+12% [ICON_PRODUCTION] Production, −10% [ICON_RESEARCH] Science',
        'COGNITIVE_EFFECT': '+12% [ICON_RESEARCH] Science, −10% [ICON_PRODUCTION] Production',
        'BROOD_EFFECT': '+15% [ICON_FOOD] Food, −10% [ICON_RESEARCH] Science',
        'FOUNDRY_EFFECT': 'Gene Foundry Population Science',
        'OPEN': 'Genetic Reconfiguration', 'BIOMASS': 'Biomass {1_Num}/{2_Num}',
        'COST': 'Each caste costs {1_Num} Biomass and {2_Num} Population.',
        'CITY_STATUS': '{1_City} • Population {2_Num}', 'CITY_COUNT': '{1_Num} of {2_Num}',
        'NO_CITY': 'No city available.', 'NO_CONQUEST': 'Requires a city gained by military conquest.',
        'OWNERSHIP': 'This city is no longer under Qu control.',
        'PUPPET': 'Annex this city first.', 'RESISTANCE': 'Wait until resistance ends.',
        'RAZING': 'Stop razing this city first.', 'COURTHOUSE': 'Requires a Courthouse.',
        'POPULATION': 'Requires at least {1_Num} Population.', 'INSUFFICIENT': 'Requires {1_Num} Biomass.',
        'INSTALLED': '{1_Caste} installed. The caste is permanent while you control this city.',
        'TECH': 'Requires {1_Tech}', 'AVAILABLE': 'Ready for reconfiguration.',
        'TURN': 'Reconfigure during your own turn.', 'CHANGED': 'The selected conquest has changed. Choose a city again.',
        'CONFIRM': 'Install {1_Caste} in {2_City}? This spends {3_Num} Biomass and {4_Num} Population.',
        'APPLY': 'Install caste', 'CANCEL': 'Cancel', 'CLOSE': 'Close',
        'PREVIOUS': 'Previous city', 'NEXT': 'Next city',
        'GREETING_1': 'You stand within Genesis Spire. Tell me what your people intend to become.',
        'WAR_1': 'Your cities will endure, though their descendants will have a different purpose.',
        'ATTACKED_1': 'We shall record the form you chose and the form that succeeds it.',
        'DEFEAT_1': 'Seal the vaults. Leave a record of our first design.',
        'PEACE_1': 'We will put away the instruments of conquest. The terms will stand.',
        'FALLBACK_1': 'I have considered the terms. Let us speak plainly about what they require.',
    }
    text.update(CIV5_HEADING_1='Architects of Flesh', CIV5_TEXT_1=text['CIV_PEDIA'],
                CIV5_HEADING_2=text['TRAIT'], CIV5_TEXT_2=text['TRAIT_HELP'],
                LEADERPAGE_NAME=text['LEADER'], LEADERPAGE_SUBTITLE='Architects of Flesh',
                LEADERPAGE_LIVED='Fictional sovereign of the Qu', LEADERPAGE_TITLES_1='The First Architect',
                LEADERPAGE_HEADING_1='Genesis Spire', LEADERPAGE_TEXT_1=text['LEADER_PEDIA'])
    for tag, names in (('CITY', CITIES), ('SPY', SPIES)):
        text.update({f'{tag}_{index}': name for index, name in enumerate(names, 1)})
    sql = 'INSERT INTO Language_en_US(Tag,Text) VALUES\n' + ',\n'.join(
        f' ({literal(PREFIX+key)},{literal(value)})' for key, value in text.items()) + ';\n'
    for response, tag in {
        'FIRST_GREETING': 'GREETING', 'DECLAREWAR': 'WAR', 'ATTACKED': 'ATTACKED',
        'DEFEATED': 'DEFEAT', 'PEACE_OFFER': 'PEACE',
        'PEACE_MADE_BY_HUMAN_GRACIOUS': 'PEACE', 'PEACE_MADE_BY_HUMAN_UNGRACIOUS': 'PEACE',
    }.items():
        sql += f"INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('{LEADER}','RESPONSE_{response}','{PREFIX}{tag}_%',1);\n"
    sql += f"""INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias)
 SELECT DISTINCT '{LEADER}',Native.ResponseType,'{PREFIX}FALLBACK_%',1 FROM Diplomacy_Responses AS Native
 WHERE Native.LeaderType='LEADER_WASHINGTON' AND NOT EXISTS
 (SELECT 1 FROM Diplomacy_Responses AS Qu WHERE Qu.LeaderType='{LEADER}' AND Qu.ResponseType=Native.ResponseType);
"""
    return sql


def main():
    destination = Path(os.environ.get('CWC3_SQL_ROOT', ROOT)) / 'TheQu/SQL'
    destination.mkdir(parents=True, exist_ok=True)
    db = schema_database()
    for kind, sql in (
        ('Civilization', civilization()), ('Units', unit(db)),
        ('Buildings', buildings(db)), ('Text', localization()),
    ):
        (destination / f'Qu_{kind}.sql').write_text(
            '-- Generated by tools/generate_qu.py.\n' + sql, encoding='utf-8', newline='\n')
    db.close()


if __name__ == '__main__':
    main()
