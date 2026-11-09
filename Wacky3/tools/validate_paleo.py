"""PALEO active inheritance, meaningful Lua51 lifecycle/reward and DDS checks."""
from collections import Counter
import re
import struct
from xml.etree import ElementTree as ET
from PIL import Image
from lupa.lua51 import LuaRuntime
from baseline import ROOT, quote
from target_schema import approved_companions
from generate_paleo import CIV, LEADER, TRAIT, UNIT, MUSEUM, PROMO, PREFIX, DUMMIES


def check_database(db):
    civ = db.execute('SELECT * FROM Civilizations WHERE Type=?',(CIV,)).fetchone()
    assert (civ['Playable'],civ['AIPlayable']) == (1,0)
    assert db.execute('SELECT LeaderheadType FROM Civilization_Leaders WHERE CivilizationType=?',(CIV,)).fetchone()[0] == LEADER
    assert db.execute('SELECT TraitType FROM Leader_Traits WHERE LeaderType=?',(LEADER,)).fetchone()[0] == TRAIT
    scalar_changes = {'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex'}
    for table,parent,child,prefix,column in [('Units','UNIT_ARCHAEOLOGIST',UNIT,'Unit_','UnitType'),('Buildings','BUILDING_MUSEUM',MUSEUM,'Building_','BuildingType')]:
        old = db.execute('SELECT * FROM '+table+' WHERE Type=?',(parent,)).fetchone()
        new = db.execute('SELECT * FROM '+table+' WHERE Type=?',(child,)).fetchone()
        for key in old.keys():
            if key in scalar_changes or (table=='Units' and key in ['Moves','UnitFlagAtlas','UnitFlagIconOffset']): continue
            assert old[key] == new[key],(table,key,old[key],new[key])
        if table=='Units':
            assert new['Moves'] == old['Moves']+1
            assert new['BaseSightRange'] == old['BaseSightRange']
            assert new['UnitFlagAtlas'] == 'PALEO_FLAG_ATLAS' and new['UnitFlagIconOffset'] == 0
        for companion in approved_companions(prefix,column):
            fields = [r[1] for r in db.execute('PRAGMA table_info('+quote(companion)+')') if r[1] not in [column,'ID']]
            query = 'SELECT '+','.join(map(quote,fields))+' FROM '+quote(companion)+' WHERE '+quote(column)+'=? ORDER BY rowid'
            expected = [tuple(r) for r in db.execute(query,(parent,))]
            if companion=='Unit_FreePromotions': expected.append((PROMO,))
            if companion=='Building_YieldChanges':
                for kind,amount in [('SCIENCE',2),('CULTURE',1)]:
                    for i,row in enumerate(expected):
                        if row[0]=='YIELD_'+kind: expected[i]=(row[0],row[1]+amount); break
                    else: expected.append(('YIELD_'+kind,amount))
            actual = Counter(tuple(r) for r in db.execute(query,(child,)))
            assert actual == Counter(expected),(companion,actual,expected)
    assert db.execute('SELECT UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=? AND UnitClassType=?',(CIV,'UNITCLASS_ARCHAEOLOGIST')).fetchone()[0] == UNIT
    assert db.execute('SELECT BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=? AND BuildingClassType=?',(CIV,'BUILDINGCLASS_MUSEUM')).fetchone()[0] == MUSEUM
    assert db.execute("SELECT 1 FROM Unit_Builds WHERE UnitType=? AND BuildType='BUILD_ARCHAEOLOGY_DIG'",(UNIT,)).fetchone()
    assert db.execute('SELECT DefaultUnitAI FROM Units WHERE Type=?',(UNIT,)).fetchone()[0]=='UNITAI_ARCHAEOLOGIST'
    dig = db.execute("SELECT * FROM Builds WHERE Type='BUILD_ARCHAEOLOGY_DIG'").fetchone()
    assert dig['Kill']==0 and dig['ImprovementType']=='IMPROVEMENT_ARCHAEOLOGICAL_DIG'
    improvement = db.execute("SELECT * FROM Improvements WHERE Type='IMPROVEMENT_ARCHAEOLOGICAL_DIG'").fetchone()
    assert improvement['PromptWhenComplete']==1 and improvement['Permanent']==0 and improvement['CreatedByGreatPerson']==0
    resources = {r[0] for r in db.execute("SELECT ResourceType FROM Improvement_ResourceTypes WHERE ImprovementType='IMPROVEMENT_ARCHAEOLOGICAL_DIG'")}
    assert {'RESOURCE_ARTIFACTS','RESOURCE_HIDDEN_ARTIFACTS'} <= resources
    promotion = db.execute('SELECT * FROM UnitPromotions WHERE Type=?',(PROMO,)).fetchone()
    assert promotion['VisibilityChange']==1 and promotion['CannotBeChosen']==1
    for key in ['AttackMod','DefenseMod','FriendlyLandsModifier','CombatPercent','MovesChange']:
        assert promotion[key]==0,(key,promotion[key])
    for suffix,kind in DUMMIES:
        typ = 'BUILDING_PALEO_'+suffix
        dummy = db.execute('SELECT * FROM Buildings WHERE Type=?',(typ,)).fetchone()
        for key,value in dict(Cost=-1,FaithCost=-1,GoldMaintenance=0,GreatWorkCount=-1,NeverCapture=1,ConquestProb=0,IsDummy=1,ShowInPedia=0,SpecialistCount=0,Happiness=0,FreeTechs=0,FoodKept=0,FreeGreatPeople=0).items():
            assert dummy[key]==value,(typ,key,dummy[key])
        assert [tuple(r) for r in db.execute('SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType=?',(typ,))] == [('YIELD_'+kind,1)]
        for companion in approved_companions('Building_','BuildingType'):
            if companion!='Building_YieldChanges': assert not db.execute('SELECT 1 FROM '+quote(companion)+' WHERE BuildingType=?',(typ,)).fetchone()
    assert db.execute("SELECT Value FROM CustomModOptions WHERE Name='EVENTS_PLOT'").fetchone()[0]==1
    keys = {r[0] for r in db.execute("SELECT Tag FROM Language_en_US WHERE Tag LIKE 'TXT_KEY_PALEO_%'")}
    for path in (ROOT/'ThePaleontologicalDirectorate/SQL').glob('*.sql'):
        for key in re.findall(r"'(TXT_KEY_PALEO_[A-Z0-9_]+)'",path.read_text(encoding='utf-8')):
            if key not in [PREFIX+'CIV5',PREFIX+'OTHMAR']: assert key in keys,('Missing localization',key)
    for key in ['CIV5_HEADING_1','CIV5_TEXT_1','OTHMAR_NAME','OTHMAR_SUBTITLE','OTHMAR_LIVED','OTHMAR_HEADING_1','OTHMAR_TEXT_1']:
        assert PREFIX+key in keys
    assert db.execute('SELECT Text FROM Language_en_US WHERE Tag=?',(PREFIX+'CITY_1',)).fetchone()[0]=='Stratum Prime'
    for (response,) in db.execute('SELECT Response FROM Diplomacy_Responses WHERE LeaderType=?',(LEADER,)):
        assert db.execute('SELECT 1 FROM Language_en_US WHERE Tag LIKE ?',(response,)).fetchone()
    for table in ['Civilization_FreeUnits','Civilization_FreeTechs','Civilization_FreeBuildingClasses']:
        fields = [r[1] for r in db.execute('PRAGMA table_info('+table+')') if r[1]!='CivilizationType']
        query = 'SELECT '+','.join(map(quote,fields))+' FROM '+table+' WHERE CivilizationType=?'
        assert Counter(tuple(r) for r in db.execute(query,(CIV,)))==Counter(tuple(r) for r in db.execute(query,('CIVILIZATION_AMERICA',)))
    for table in ['Civilizations','Leaders','Traits','Units','Buildings','BuildingClasses','UnitPromotions']:
        assert not db.execute('SELECT Type FROM '+quote(table)+" WHERE Type LIKE '%PALEO_%' GROUP BY Type HAVING COUNT(*)<>1").fetchone()
    assert not db.execute("SELECT name FROM sqlite_temp_master WHERE name LIKE 'PALEO_%'").fetchone()
    return 'PASS: human-only registration, all active Archaeologist/Museum scalar and 172 companion definitions, +1 move/sight, exactly +2 Science/+1 Culture including duplicate inherited yields, bounded dummies, localization and overrides'


def check_lua(db):
    results = []
    value = lambda typ,kind: db.execute('SELECT COALESCE(SUM(Yield),0) FROM Building_YieldChanges WHERE BuildingType=? AND YieldType=?',(typ,'YIELD_'+kind)).fetchone()[0]
    for speed,expected in [('QUICK',17),('STANDARD',25),('EPIC',38),('MARATHON',75)]:
        for slot in [0,3]:
            lua = LuaRuntime(); logs = []
            lua.globals().print = lambda *args: logs.append(' '.join(map(str,args)))
            lua.globals().include = lambda name: lua.execute((ROOT/'Shared/Lua'/f'{name}.lua').read_text(encoding='utf-8'))
            lua.globals().LoadPaleo = lambda: lua.execute((ROOT/'ThePaleontologicalDirectorate/Lua/PALEO_Gameplay.lua').read_text(encoding='utf-8'))
            lua.globals().PaleoSlot = slot; lua.globals().SpeedName = 'GAMESPEED_'+speed; lua.globals().ExpectedReward = expected
            lua.globals().MuseumScience = value(MUSEUM,'SCIENCE')-value('BUILDING_MUSEUM','SCIENCE')
            lua.globals().MuseumCulture = value(MUSEUM,'CULTURE')-value('BUILDING_MUSEUM','CULTURE')
            lua.execute((ROOT/'tools/tests/paleo.lua').read_text(encoding='utf-8'))
            for line in logs: print(line)
            results.extend(logs)
    return results


def check_art(db,declared):
    art = ROOT/'ThePaleontologicalDirectorate/Art'; textures = []
    for atlas,size,name,cols,rows in db.execute("SELECT Atlas,IconSize,Filename,IconsPerRow,IconsPerColumn FROM IconTextureAtlases WHERE Atlas LIKE 'PALEO_%'"):
        path = art/name; image = Image.open(path); image.load()
        assert image.size == (size*int(cols),size*int(rows)),(name,image.size,size,cols,rows)
        header = struct.unpack('<31I',path.read_bytes()[4:128])
        assert header[21]==32 and header[19]==0x41 and header[6]==size.bit_length()
        expected = 128; width,height = image.size
        for _ in range(header[6]): expected+=width*height*4; width=max(1,width//2); height=max(1,height//2)
        assert path.stat().st_size==expected and image.getchannel('A').getextrema()[0]==0,name
        assert declared[path.relative_to(ROOT).as_posix()].get('import')=='1'
        textures.append(name)
    assert len(textures)==54
    for kind,dimensions in [('Dawn',(1024,768)),('Leader',(1600,1200)),('Map',(360,412))]:
        path=art/f'PALEO_{kind}.dds'; assert Image.open(path).size==dimensions
        assert path.stat().st_size==128+dimensions[0]*dimensions[1]*4
    assert ET.parse(art/'PALEO_LeaderScene.xml').getroot().get('FallbackImage')=='PALEO_Leader.dds'
    assert declared['ThePaleontologicalDirectorate/Art/PALEO_LeaderScene.xml'].get('import')=='1'
    for table,typ in [('Civilizations',CIV),('Leaders',LEADER),('Units',UNIT),('Buildings',MUSEUM)]:
        atlas,index = db.execute('SELECT IconAtlas,PortraitIndex FROM '+table+' WHERE Type=?',(typ,)).fetchone()
        assert db.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND IconSize=256 AND IconsPerRow*IconsPerColumn>?',(atlas,index)).fetchone()
    return 'PASS: 57 legacy DDS files, declared dimensions, BGRA8888 payloads, transparent atlas masks, full icon mips, custom unit flag and static leader scene'


if __name__=='__main__':
    from target_schema import clean_fixture
    from validate_schema import seed_companions
    from build_mod import ORDER
    from paleo_fixture import source_checks
    print(source_checks())
    db=clean_fixture(); seed_companions(db)
    for path in ORDER: db.executescript((ROOT/path).read_text(encoding='utf-8'))
    print(check_database(db)); check_lua(db)
