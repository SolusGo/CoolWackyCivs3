"""Four archived Daily civilizations; active-row cloning from the pinned inventory.

The already implemented PALEO civilization remains owned by generate_paleo.py.
Native America/Washington and parent unique art are intentional valid fallbacks.
"""
import os
from pathlib import Path
from baseline import ROOT
from target_schema import schema_database
from generate_hollow_choir import clone, companions, literal

SPECS = [
 dict(code='LOST', folder='TheDepartmentOfLostThings', name='Department of Lost Things', leader='Chief Registrar Nobody',
      capital='Unclaimed', adjective='Departmental', ua='Nothing Is Ever Truly Lost', unit='Retrieval Officer', parent_unit='SPEARMAN',
      building='Lost Property Office', parent_building='LIBRARY', colors=((.10,.14,.33),(.83,.20,.18)),
      ua_help='Enemy combat units killed by Department combat units within 3 tiles of an owned city recover one Curio for the nearest city (ties: lowest city ID). Maximum 4 per city; each supplies +1 Culture and +1 Science every turn. Ordinary Barbarian combat qualifies. Captures pause that Department\'s ledger until recapture; destroyed cities lose their Curios.',
      unit_help='+1 Sight and +15% Combat Strength against Barbarians. Unique promotion persists through upgrades.',
      building_help='+1 Culture and +1 Gold per Recovered Curio, in addition to all active Library effects. At four Curios: UA +4 Culture/+4 Science, Office +4 Culture/+4 Gold.',
      strategy='Defend compact city clusters, recover Curios from genuine combat, and build Offices in mature collections. Convert recurring Science into technology and Culture into policies and later Tourism.',
      pedia='A supernatural lost-property administration catalogs the things the world forgets. Chief Registrar Nobody turns battlefield recoveries into an enduring civic collection.',
      promotion={'VisibilityChange':1,'BarbarianCombatBonus':15}, permanent={},
      dummies={**{f'CURIO_{k}_{i}':{k:1} for k in ['CULTURE','SCIENCE'] for i in range(1,5)},
               **{f'OFFICE_{k}_{i}':{k:1} for k in ['CULTURE','GOLD'] for i in range(1,5)}},
      cities=['Unclaimed','Mislaid','Last Seen','Return Address','The Sorting Hall','Forgotten Drawer','Second Shelf','Unopened','Receipt End','Found Again','The Registry','Overdue','Lost Corner','Parcel Gate','Uncatalogued','Dead Letter','The Attic','Recovered Reach','Claim Pending','Final Notice'],
      spies=['Receipt','Label','Tag','Parcel','Drawer','Cabinet','Index','Docket','Counterfoil','Key']),
 dict(code='SCARECROW', folder='TheAssemblyOfScarecrows', name='Assembly of Scarecrows', leader='Old Man Thistle',
      capital='First Harvest', adjective='Scarecrow', ua='The Fields Have Eyes', unit='Wicker Sentinel', parent_unit='SPEARMAN',
      building='Harvest Bell', parent_building='GRANARY', colors=((.25,.32,.10),(.94,.72,.28)),
      ua_help='Owned cities with at least 3 owned, unpillaged Farms within 3 tiles gain +2 Culture and +1 Production. At 6 Farms they also gain +2 Food. Farms need not be worked; overlapping cities count independently.',
      unit_help='+1 Sight and +15% Combat Strength in native friendly territory, including qualifying Open Borders. Native melee combat uses the battle tile. Promotion persists through upgrades.',
      building_help='+1 permanent Culture, plus +1 Gold per 3 qualifying owned, unpillaged Farms within 3 tiles (maximum +3 Gold). Retains all active Granary effects.',
      strategy='Plan clusters of three, six and nine Farms. Overlapping city radii share agricultural investment. Repair pillaged fields quickly, defend them with Sentinels, and use Food to support cultural specialists.',
      pedia='Living scarecrows gather beneath the harvest bells, keeping watch over the fields that sustain their assembly. Old Man Thistle speaks for the patient guardians of each furrow.',
      promotion={'VisibilityChange':1,'FriendlyLandsModifier':15}, permanent={'CULTURE':1},
      dummies={'FIELDS':{'CULTURE':2,'PRODUCTION':1},'GROWTH':{'FOOD':2},**{f'BELL_GOLD_{i}':{'GOLD':1} for i in range(1,4)}},
      cities=['First Harvest','Thistle Row','Wicker Gate','Barley Watch','Straw Cross','Last Furrow','Amber Field','Old Orchard','Crows End','Hayward','Green Stile','Pumpkin Hill','The Gleaning','Rye Hollow','Hearth Acre','Rootstead','Wheatbell','Flax Corner','Sunward','Sickle Rest'],
      spies=['Husk','Twine','Stalk','Chaff','Briar','Wren','Reed','Nettle','Flax','Sedge']),
 dict(code='MAKURIA', folder='TheKingdomOfMakuria', name='Kingdom of Makuria', leader='Merkurios',
      capital='Old Dongola', adjective='Makurian', ua='The Walls of Dongola', unit='Nubian Bowman', parent_unit='COMPOSITE_BOWMAN',
      building='Painted Church', parent_building='TEMPLE', colors=((.40,.14,.12),(.94,.83,.57)),
      ua_help='Each owned city possessing a Walls BuildingClass building, including a unique replacement or free Walls, gains +1 Culture and +1 Faith. The condition counts once per city.',
      unit_help='+1 Sight and +15% defensive Combat Strength, including defense against ranged attacks. No offensive strength bonus. Promotion persists through upgrades.',
      building_help='+1 Culture and +1 Science beyond every inherited active Temple effect.',
      strategy='Build Walls where you settle and combine their Faith and Culture with Painted Churches. Protect these investments with watchful Bowmen; turn religious infrastructure into cultural influence.',
      pedia='Makuria was a medieval Christian Nubian kingdom centered on Old Dongola. Its churches and painted religious art provide the historical setting for this civilization. Merkurios leads its defense and cultural patronage; the bonus values are game abstractions.',
      promotion={'VisibilityChange':1,'DefenseMod':15}, permanent={'CULTURE':1,'SCIENCE':1},
      dummies={'WALLS':{'CULTURE':1,'FAITH':1}},
      cities=['Old Dongola','Banganarti','Faras','Qasr Ibrim','Sai','Kulubnarti','Abdallah Nirqi','Meinarti','Tamit','Serra','Sedeinga','Kawa','Ghazali','Soba','Debira','Arminna','Buhen','Ikhmindi','Sabagura','Nuri'],
      spies=['Menas','Georgios','Ioannes','Petros','Stephanos','Mariam','Anna','Michael','Theodoros','Gabriel']),
 dict(code='SALT', folder='TheSaltRoadCompact', name='The Salt Road Compact', leader='First Broker Nahir',
      capital='White Mile', adjective='Compact', ua='The Price of Passage', unit='Dune Escort', parent_unit='HORSEMAN',
      building='Salt Exchange', parent_building='CARAVANSARY', colors=((.08,.38,.40),(.84,.30,.20)),
      ua_help='Each owned city originating at least one active land trade route gains +2 Production and +1 Culture, once per city regardless of route count. Sea, incoming, canceled and finished routes do not qualify.',
      unit_help='+1 Sight. +15% Combat Strength attacking into Desert terrain or defending on Desert terrain, including Desert Hills and tiles with features. Promotion persists through the normal melee mounted upgrade path.',
      building_help='+1 permanent Food and +1 permanent Gold beyond all active Caravansary effects. +1 Science while the city originates at least one active land trade route.',
      strategy='Spread outgoing land routes across cities to activate more city bonuses. Protect caravan corridors with Escorts and use Exchanges to turn safe commerce into Science and diplomatic capacity.',
      pedia='Desert merchants bind the settlements of the Salt Road into a compact of safe passage and shared accounts. First Broker Nahir values reliable contracts, guarded caravans and knowledge carried between distant markets.',
      promotion={'VisibilityChange':1}, permanent={'FOOD':1,'GOLD':1},
      dummies={'PASSAGE':{'PRODUCTION':2,'CULTURE':1},'EXCHANGE':{'SCIENCE':1}},
      cities=['White Mile','Brine Gate','Nahir Crossing','Last Well','Saltpan','The Ledger','Amber Caravan','Dune Rest','Broker Reach','Saffron Post','Glass Oasis','Dry Harbor','Blue Account','Tamarisk','Long Shadow','Three Cisterns','White Horizon','Spice Arch','High Market','Final Toll'],
      spies=['Measure','Weight','Seal','Balance','Invoice','Tally','Grain','Bond','Mint','Token']),
]

def identifiers(s):
    c=s['code']; return (f'CIVILIZATION_CWC3_{c}',f'LEADER_CWC3_{c}',f'TRAIT_CWC3_{c}',f'UNIT_CWC3_{c}',f'BUILDING_CWC3_{c}',f'PROMOTION_CWC3_{c}',f'TXT_KEY_CWC3_{c}_')

def main():
    db=schema_database()
    for s in SPECS:
        c=s['code']; civ,leader,trait,unit,building,promo,p=identifiers(s)
        folder=Path(os.environ.get('CWC3_SQL_ROOT',ROOT))/s['folder']/'SQL'; folder.mkdir(parents=True,exist_ok=True)
        def write(kind,sql):
            (folder/f'{c}_{kind}.sql').write_text('-- Generated by tools/generate_archived.py.\n'+sql,encoding='utf-8',newline='\n')
        sql=''
        options={'LOST':['EVENTS_RED_COMBAT','EVENTS_RED_COMBAT_RESULT','EVENTS_RED_COMBAT_ENDED'],
                 'SALT':['EVENTS_TRADE_ROUTES','EVENTS_TRADE_ROUTE_PLUNDERED','EVENTS_UNIT_PREKILL']}.get(c,[])
        for option in options: sql+=f"UPDATE CustomModOptions SET Value=1 WHERE Name='{option}';\n"
        for n,color in enumerate(s['colors']):
            sql+=f"INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES ('COLOR_CWC3_{c}_{n}',{','.join(map(str,color))},1);\n"
        sql+=f"INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES ('PLAYERCOLOR_CWC3_{c}','COLOR_CWC3_{c}_0','COLOR_CWC3_{c}_1','COLOR_PLAYER_WHITE_TEXT');\n"
        sql+=f"INSERT INTO Traits(Type,Description,ShortDescription) VALUES ('{trait}','{p}TRAIT_HELP','{p}TRAIT');\n"
        sql+=clone('Civilizations','CIVILIZATION_AMERICA',civ,dict(Description=p+'CIV',ShortDescription=p+'SHORT',Adjective=p+'ADJECTIVE',Civilopedia=p+'CIV_PEDIA',CivilopediaTag=p+'CIV5',Strategy=p+'STRATEGY',DefaultPlayerColor=f'PLAYERCOLOR_CWC3_{c}',Playable=1,AIPlayable=0,PackageID=None,DawnOfManQuote=p+'DAWN',DawnOfManAudio='',IconAtlas=f'CWC3_{c}_CIV_ATLAS',AlphaIconAtlas=f'CWC3_{c}_ALPHA_ATLAS',PortraitIndex=0,DawnOfManImage=f'CWC3_{c}_Dawn.dds',MapImage=f'CWC3_{c}_Map.dds'))
        sql+=clone('Leaders','LEADER_WASHINGTON',leader,dict(Description=p+'LEADER',Civilopedia=p+'LEADER_PEDIA',CivilopediaTag=p+'LEADERPAGE',PackageID=None,Boldness=3,WarmongerHate=7,Meanness=2,Loyalty=8,Forgiveness=6,DoFWillingness=7,IconAtlas=f'CWC3_{c}_LEADER_ATLAS',PortraitIndex=0,ArtDefineTag=f'CWC3_{c}_LeaderScene.xml'))
        for table in ['Civilization_FreeBuildingClasses','Civilization_FreeTechs','Civilization_FreeUnits']:
            sql+=f"CREATE TEMP TABLE CWC3_ArchivedStart AS SELECT * FROM {table} WHERE CivilizationType='CIVILIZATION_AMERICA';\nUPDATE CWC3_ArchivedStart SET CivilizationType='{civ}';\nINSERT INTO {table} SELECT * FROM CWC3_ArchivedStart;\nDROP TABLE CWC3_ArchivedStart;\n"
        sql+=f"INSERT INTO Civilization_Leaders VALUES ('{civ}','{leader}');\nINSERT INTO Leader_Traits VALUES ('{leader}','{trait}');\n"
        sql+=f"INSERT INTO Civilization_UnitClassOverrides VALUES ('{civ}','UNITCLASS_{s['parent_unit']}','{unit}');\nINSERT INTO Civilization_BuildingClassOverrides VALUES ('{civ}','BUILDINGCLASS_{s['parent_building']}','{building}');\n"
        for table,column in [('Leader_Flavors','Flavor'),('Leader_MajorCivApproachBiases','Bias'),('Leader_MinorCivApproachBiases','Bias')]:
            sql+=f"CREATE TEMP TABLE CWC3_ArchivedLeader AS SELECT * FROM {table} WHERE LeaderType='LEADER_WASHINGTON';\nUPDATE CWC3_ArchivedLeader SET LeaderType='{leader}';\nINSERT INTO {table} SELECT * FROM CWC3_ArchivedLeader;\nDROP TABLE CWC3_ArchivedLeader;\n"
        for table,names,label in [('Civilization_CityNames',s['cities'],'CITY'),('Civilization_SpyNames',s['spies'],'SPY')]:
            for i in range(1,len(names)+1): sql+=f"INSERT INTO {table} VALUES ('{civ}','{p}{label}_{i}');\n"
        write('Civilization',sql)
        sql=clone('Units','UNIT_'+s['parent_unit'],unit,dict(Description=p+'UNIT',Civilopedia=p+'UNIT_PEDIA',Help=p+'UNIT_HELP',Strategy=p+'UNIT_STRATEGY',IconAtlas=f'CWC3_{c}_UNIT_ATLAS',PortraitIndex=0,UnitFlagAtlas=f'CWC3_{c}_FLAG_ATLAS',UnitFlagIconOffset=0))
        sql+=companions(db,'Unit_','UnitType','UNIT_'+s['parent_unit'],unit)
        fields={'Type':promo,'Description':p+'PROMOTION','Help':p+'PROMOTION_HELP','CannotBeChosen':1,'LostWithUpgrade':0,'PortraitIndex':0,'IconAtlas':f'CWC3_{c}_UNIT_ATLAS','PediaType':'PEDIA_ATTRIBUTES','PediaEntry':p+'PROMOTION',**s['promotion']}
        sql+=f"INSERT INTO UnitPromotions({','.join(fields)}) VALUES ({','.join(map(literal,fields.values()))});\nINSERT INTO Unit_FreePromotions VALUES ('{unit}','{promo}');\n"
        if c=='SALT':
            sql+=f"-- Unlike UnitPromotions_Terrains, TerrainModifiers applies even on feature tiles.\nINSERT INTO UnitPromotions_TerrainModifiers(PromotionType,TerrainType,Attack,Defense) VALUES ('{promo}','TERRAIN_DESERT',15,15);\n"
        write('Units',sql)
        sql=clone('Buildings','BUILDING_'+s['parent_building'],building,dict(Description=p+'BUILDING',Civilopedia=p+'BUILDING_PEDIA',Help=p+'BUILDING_HELP',Strategy=p+'BUILDING_STRATEGY',IconAtlas=f'CWC3_{c}_BUILDING_ATLAS',PortraitIndex=0))
        sql+=companions(db,'Building_','BuildingType','BUILDING_'+s['parent_building'],building)
        for kind,amount in s['permanent'].items():
            # Add once even if several inherited yield records exist.
            sql+=f"UPDATE Building_YieldChanges SET Yield=Yield+{amount} WHERE rowid=(SELECT MIN(rowid) FROM Building_YieldChanges WHERE BuildingType='{building}' AND YieldType='YIELD_{kind}');\nINSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT '{building}','YIELD_{kind}',{amount} WHERE NOT EXISTS (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='{building}' AND YieldType='YIELD_{kind}');\n"
        for suffix,yields in s['dummies'].items():
            b=f'BUILDING_CWC3_{c}_{suffix}'; cls=f'BUILDINGCLASS_CWC3_{c}_{suffix}'
            sql+=f"INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('{cls}','{b}','{p}DUMMY');\nINSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GoldMaintenance,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex) VALUES ('{b}','{cls}','{p}DUMMY','{p}DUMMY_HELP',-1,-1,0,-1,1,1,1,0,0,'CIV_COLOR_ATLAS',0);\n"
            for kind,amount in yields.items(): sql+=f"INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('{b}','YIELD_{kind}',{amount});\n"
        write('Buildings',sql)
        text={'CIV':s['name'],'SHORT':s['name'],'ADJECTIVE':s['adjective'],'LEADER':s['leader'],
              'TRAIT':s['ua'],'TRAIT_HELP':s['ua_help'],'CIV_PEDIA':s['pedia'],'STRATEGY':s['strategy'],
              'LEADER_PEDIA':s['pedia'],'DAWN':s['leader']+', guide '+s['name']+'. '+s['strategy'],
              'UNIT':s['unit'],'UNIT_HELP':'Replaces the active CP '+s['parent_unit'].replace('_',' ').title()+'. '+s['unit_help'],
              'UNIT_PEDIA':s['pedia']+' '+s['unit_help'],'UNIT_STRATEGY':s['unit_help']+' Preserves all other active CP unit properties and companions.',
              'BUILDING':s['building'],'BUILDING_HELP':'Replaces the active CP '+s['parent_building'].title()+'. '+s['building_help'],
              'BUILDING_PEDIA':s['pedia']+' '+s['building_help'],'BUILDING_STRATEGY':s['strategy'],
              'PROMOTION':s['unit'],'PROMOTION_HELP':s['unit_help'],'DUMMY':'Internal '+s['name']+' yields','DUMMY_HELP':'Invisible recurring city yield controller. Cannot be constructed or purchased.',
              'GREETING_1':{'LOST':'Please take a number. We may already have what you seek.','SCARECROW':'Mind the seedlings, traveler. Every field has its watcher.','MAKURIA':'Welcome to Dongola. May these walls shelter a lasting friendship.','SALT':'Welcome. Every safe road begins with an honest agreement.'}[c],
              'WAR_1':'Our people will defend what they have built.','DEFEAT_1':'Remember our people and what they made.','FALLBACK_1':'Your words have been heard. Let us consider the agreement.'}
        for label,names in [('CITY',s['cities']),('SPY',s['spies'])]:
            for i,name in enumerate(names,1): text[f'{label}_{i}']=name
        text.update(CIV5_HEADING_1=s['name'],CIV5_TEXT_1=s['pedia'],CIV5_HEADING_2=s['ua'],CIV5_TEXT_2=s['ua_help'],LEADERPAGE_NAME=s['leader'],LEADERPAGE_SUBTITLE=s['name'],LEADERPAGE_LIVED='Medieval Nubia' if c=='MAKURIA' else 'Fictional leader',LEADERPAGE_HEADING_1='Leadership',LEADERPAGE_TEXT_1=s['pedia'])
        sql='INSERT INTO Language_en_US(Tag,Text) VALUES\n'+',\n'.join(' ('+literal(p+k)+','+literal(v)+')' for k,v in text.items())+';\n'
        for response,tag in [('RESPONSE_FIRST_GREETING','GREETING'),('RESPONSE_DECLAREWAR','WAR'),('RESPONSE_DEFEATED','DEFEAT')]: sql+=f"INSERT INTO Diplomacy_Responses VALUES ('{leader}','{response}','{p}{tag}_%',1);\n"
        sql+=f"INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) SELECT DISTINCT '{leader}',N.ResponseType,'{p}FALLBACK_%',1 FROM Diplomacy_Responses N WHERE N.LeaderType='LEADER_WASHINGTON' AND NOT EXISTS (SELECT 1 FROM Diplomacy_Responses C WHERE C.LeaderType='{leader}' AND C.ResponseType=N.ResponseType);\n"
        write('Text',sql)
    db.close()
    print('Generated four archived civilizations with active CP151 clones and original art bindings')

if __name__=='__main__': main()
