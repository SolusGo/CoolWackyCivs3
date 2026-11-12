"""Archive integration, exact active inheritance and production Lua51 mocks."""
from collections import Counter
import re
from lupa.lua51 import LuaRuntime
from baseline import ROOT,quote
from target_schema import approved_companions
from generate_archived import SPECS,identifiers

def mutate_baselines(db):
    for unit in ['UNIT_COMPOSITE_BOWMAN','UNIT_HORSEMAN']:
        db.execute('UPDATE Units SET Combat=Combat+9,RangedCombat=RangedCombat+4,Cost=Cost+17,Moves=Moves+1,BaseSightRange=BaseSightRange+2 WHERE Type=?',(unit,))
    db.execute("UPDATE Buildings SET Cost=Cost+21,GoldMaintenance=GoldMaintenance+2,SpecialistCount=SpecialistCount+1 WHERE Type='BUILDING_CARAVANSARY'")
    # Exact permanent deltas, including duplicate inherited records, for every UB.
    for building,kind in [('BUILDING_GRANARY','CULTURE'),('BUILDING_TEMPLE','SCIENCE'),('BUILDING_CARAVANSARY','FOOD'),('BUILDING_CARAVANSARY','GOLD')]:
        db.execute('INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES (?,?,3),(?,?,5)',(building,'YIELD_'+kind,building,'YIELD_'+kind))

def check_database(db):
    from generate_paleo import CIV as PALEO
    civs=['CIVILIZATION_CWC3_ALMOST','CIVILIZATION_CWC3_HOLLOW_CHOIR','CIVILIZATION_CWC3_SEVENTEENTH_SUMMER','CIVILIZATION_CWC3_PERPETUAL_TIMETABLE','CIVILIZATION_CWC3_COVENANT',PALEO]
    # Existing Summer identifier is deliberately read from its generator.
    from generate_seventeenth_summer import CIV as SUMMER
    civs[2]=SUMMER
    for s in SPECS:
        c=s['code']; civ,leader,trait,unit,building,promo,p=identifiers(s); civs.append(civ)
        for option in {'LOST':['EVENTS_RED_COMBAT','EVENTS_RED_COMBAT_RESULT','EVENTS_RED_COMBAT_ENDED'],
                       'SALT':['EVENTS_TRADE_ROUTES','EVENTS_TRADE_ROUTE_PLUNDERED','EVENTS_UNIT_PREKILL']}.get(c,[]):
            assert db.execute('SELECT Value FROM CustomModOptions WHERE Name=?',(option,)).fetchone()[0]==1,option
        row=db.execute('SELECT * FROM Civilizations WHERE Type=?',(civ,)).fetchone()
        assert row and (row['Playable'],row['AIPlayable'])==(1,0),c
        assert db.execute('SELECT LeaderheadType FROM Civilization_Leaders WHERE CivilizationType=?',(civ,)).fetchone()[0]==leader
        assert db.execute('SELECT TraitType FROM Leader_Traits WHERE LeaderType=?',(leader,)).fetchone()[0]==trait
        assert db.execute('SELECT UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=? AND UnitClassType=?',(civ,'UNITCLASS_'+s['parent_unit'])).fetchone()[0]==unit
        assert db.execute('SELECT BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=? AND BuildingClassType=?',(civ,'BUILDINGCLASS_'+s['parent_building'])).fetchone()[0]==building
        metadata={'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex'}
        for table,parent,child,prefix,column in [('Units','UNIT_'+s['parent_unit'],unit,'Unit_','UnitType'),('Buildings','BUILDING_'+s['parent_building'],building,'Building_','BuildingType')]:
            old=db.execute('SELECT * FROM '+table+' WHERE Type=?',(parent,)).fetchone(); new=db.execute('SELECT * FROM '+table+' WHERE Type=?',(child,)).fetchone()
            assert old and new,(c,table)
            for key in old.keys():
                if key not in metadata and not (table=='Units' and key in ['UnitFlagAtlas','UnitFlagIconOffset']):
                    assert old[key]==new[key],(c,table,key,old[key],new[key])
            for companion in approved_companions(prefix,column):
                fields=[r[1] for r in db.execute('PRAGMA table_info('+quote(companion)+')') if r[1] not in [column,'ID']]
                query='SELECT '+','.join(map(quote,fields))+' FROM '+quote(companion)+' WHERE '+quote(column)+'=? ORDER BY rowid'
                expected=[tuple(r) for r in db.execute(query,(parent,))]
                if companion=='Unit_FreePromotions': expected.append((promo,))
                if companion=='Building_YieldChanges':
                    for kind,amount in s['permanent'].items():
                        for i,row in enumerate(expected):
                            if row[0]=='YIELD_'+kind: expected[i]=(row[0],row[1]+amount); break
                        else: expected.append(('YIELD_'+kind,amount))
                assert Counter(tuple(r) for r in db.execute(query,(child,)))==Counter(expected),(c,companion)
        row=db.execute('SELECT * FROM UnitPromotions WHERE Type=?',(promo,)).fetchone()
        assert row['LostWithUpgrade']==0 and row['CannotBeChosen']==1
        for key in ['VisibilityChange','BarbarianCombatBonus','FriendlyLandsModifier','DefenseMod','AttackMod','CombatPercent','FriendlyLandsAttackModifier','MovesChange']:
            assert row[key]==s['promotion'].get(key,0),(c,key)
        terrain=list(db.execute('SELECT TerrainType,Attack,Defense FROM UnitPromotions_TerrainModifiers WHERE PromotionType=?',(promo,)))
        assert [tuple(r) for r in terrain]==([('TERRAIN_DESERT',15,15)] if c=='SALT' else [])
        for suffix,yields in s['dummies'].items():
            b='BUILDING_CWC3_'+c+'_'+suffix
            row=db.execute('SELECT * FROM Buildings WHERE Type=?',(b,)).fetchone()
            for key,value in dict(Cost=-1,FaithCost=-1,GoldMaintenance=0,GreatWorkCount=-1,IsDummy=1,ShowInPedia=0,NeverCapture=1,ConquestProb=0).items(): assert row[key]==value,(b,key)
            assert dict(db.execute('SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType=?',(b,)))=={'YIELD_'+k:v for k,v in yields.items()}
            for companion in approved_companions('Building_','BuildingType'):
                if companion!='Building_YieldChanges': assert not db.execute('SELECT 1 FROM '+quote(companion)+' WHERE BuildingType=?',(b,)).fetchone(),(b,companion)
        for table in ['Civilization_FreeUnits','Civilization_FreeTechs','Civilization_FreeBuildingClasses']:
            fields=[r[1] for r in db.execute('PRAGMA table_info('+table+')') if r[1]!='CivilizationType']
            query='SELECT '+','.join(map(quote,fields))+' FROM '+table+' WHERE CivilizationType=?'
            assert Counter(tuple(r) for r in db.execute(query,(civ,)))==Counter(tuple(r) for r in db.execute(query,('CIVILIZATION_AMERICA',)))
        keys={r[0] for r in db.execute('SELECT Tag FROM Language_en_US WHERE Tag LIKE ?',(p+'%',))}
        for path in (ROOT/s['folder']/'SQL').glob('*.sql'):
            for key in re.findall(r"'(TXT_KEY_CWC3_[A-Z0-9_]+)'",path.read_text(encoding='utf-8')):
                if key not in [p+'CIV5',p+'LEADERPAGE']: assert key in keys,(c,'Missing text',key)
        for key in ['CIV5_HEADING_1','CIV5_TEXT_1','LEADERPAGE_NAME','LEADERPAGE_SUBTITLE','LEADERPAGE_LIVED','LEADERPAGE_HEADING_1','LEADERPAGE_TEXT_1']: assert p+key in keys
        assert db.execute('SELECT Text FROM Language_en_US WHERE Tag=?',(p+'CITY_1',)).fetchone()[0]==s['capital']
        for response, in db.execute('SELECT Response FROM Diplomacy_Responses WHERE LeaderType=?',(leader,)):
            assert db.execute('SELECT 1 FROM Language_en_US WHERE Tag LIKE ?',(response,)).fetchone()
        for table,child,kind in [('Civilizations',civ,'CIV'),('Leaders',leader,'LEADER'),('Units',unit,'UNIT'),('Buildings',building,'BUILDING')]:
            assert tuple(db.execute('SELECT IconAtlas,PortraitIndex FROM '+table+' WHERE Type=?',(child,)).fetchone())==(f'CWC3_{c}_{kind}_ATLAS',0)
        assert tuple(db.execute('SELECT UnitFlagAtlas,UnitFlagIconOffset FROM Units WHERE Type=?',(unit,)).fetchone())==(f'CWC3_{c}_FLAG_ATLAS',0)
        assert tuple(db.execute('SELECT IconAtlas,PortraitIndex FROM UnitPromotions WHERE Type=?',(promo,)).fetchone())==(f'CWC3_{c}_UNIT_ATLAS',0)
    assert len(civs)==10 and len(set(civs))==10
    for civ in civs:
        assert tuple(db.execute('SELECT Playable,AIPlayable FROM Civilizations WHERE Type=?',(civ,)).fetchone())==(1,0),civ
    for table in ['Civilizations','Leaders','Traits','Units','Buildings','BuildingClasses','UnitPromotions','Language_en_US']:
        key='Tag' if table=='Language_en_US' else 'Type'
        assert not db.execute('SELECT '+key+' FROM '+table+' GROUP BY '+key+' HAVING COUNT(*)>1').fetchone(),table
    return 'PASS: ten human-only civilizations; four active parent gameplay scalar/172 companion clones; mutated and duplicate yields; unique promotions; exact controllers; original portrait/flag/scene bindings; localization and starting grants'

def check_lua(db):
    results=[]
    for slots,speed in [(slots,speed) for speed in ['QUICK','STANDARD','EPIC','MARATHON'] for slots in [4,34]]:
        lua=LuaRuntime(); logs=[]
        lua.globals().print=lambda *args:logs.append(' '.join(map(str,args)))
        lua.globals().include=lambda name:lua.execute((ROOT/'Shared/Lua'/f'{name}.lua').read_text(encoding='utf-8'))
        lua.globals().LoadArchive=lambda code:lua.execute((ROOT/next(s['folder'] for s in SPECS if s['code']==code)/'Lua'/f'{code}_Gameplay.lua').read_text(encoding='utf-8'))
        types={}
        for table in ['Civilizations','Units','Buildings','Improvements','UnitPromotions']:
            types.update({r['Type']:r['ID'] for r in db.execute('SELECT Type,ID FROM '+table)})
        types['BUILDING_MOCK_WALLS']=30000
        lua.globals().GameInfoTypes=lua.table_from(types)
        rows=[lua.table_from(dict(r)) for r in db.execute('SELECT ID,BuildingClass FROM Buildings')]
        rows.append(lua.table_from({'ID':30000,'BuildingClass':'BUILDINGCLASS_WALLS'}))
        lua.globals().BuildingRows=lua.table_from(rows)
        lua.globals().SlotCount=slots
        lua.globals().SpeedName='GAMESPEED_'+speed
        lua.execute((ROOT/'tools/tests/archived.lua').read_text(encoding='utf-8'))
        results.extend(logs)
    return results
