"""Real SQLite/Lua51/source/texture/package checks; never claims in-game passes."""
import argparse, hashlib, json, os, re, struct, zipfile
from collections import Counter
from pathlib import Path
from xml.etree import ElementTree as ET
from PIL import Image
from lupa.lua51 import LuaRuntime
from baseline import ROOT, database, quote, EVIDENCE
from build_mod import NAME, MOD_ID, ORDER, ENTRY, ENTRIES, files
from audit_cp import audit
from validate_hollow_choir import check_database as check_choir_database, check_lua as check_choir_lua
from validate_seventeenth_summer import check_database as check_summer_database, check_lua as check_summer_lua
from validate_timetable import check_database as check_timetable_database, check_lua as check_timetable_lua, check_rounding
from validate_covenant import check_database as check_covenant_database, check_lua as check_covenant_lua
from validate_paleo import check_database as check_paleo_database, check_lua as check_paleo_lua, check_art as check_paleo_art
from paleo_fixture import source_checks as paleo_source_checks
from target_schema import clean_fixture, approved_companions, verified
from validate_schema import check_regeneration, seed_companions
from validate_archived import check_database as check_archived_database, check_lua as check_archived_lua, mutate_baselines
from archived_fixture import source_checks as archived_source_checks
from validate_daily_art import check_art as check_daily_art

RESULTS={}
def sql_checks(mutate=True, clean=False):
    db=clean_fixture() if clean else database()
    if clean:
        EVIDENCE.clear()
        EVIDENCE.update(database='source-derived clean BNW + CP151 schema fixture',
            mode='pinned native declarations; native XML sample rows; NOT a native final CP gameplay cache',
            source_tables=db.execute("SELECT COUNT(*) FROM sqlite_master WHERE type='table'").fetchone()[0],
            source_civilizations=db.execute('SELECT COUNT(*) FROM Civilizations').fetchone()[0])
        EVIDENCE['synthetic_companion_records']=seed_companions(db)
    # Deliberately modify the active source definitions in memory. Generated SQL
    # must inherit these, proving it doesn't replace CP values with vanilla ones.
    if mutate:
        mutate_baselines(db)
        db.execute("UPDATE Units SET Combat=Combat+3,Cost=Cost+7,Moves=Moves+1 WHERE Type='UNIT_SPEARMAN'")
        db.execute("UPDATE Buildings SET Cost=Cost+13,GoldMaintenance=GoldMaintenance+2 WHERE Type='BUILDING_LIBRARY'")
        db.execute("INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES('BUILDING_LIBRARY','YIELD_CULTURE',2)")
        db.execute("UPDATE Units SET Combat=Combat+4,Cost=Cost+9,Moves=Moves+1 WHERE Type='UNIT_SWORDSMAN'")
        db.execute("UPDATE Buildings SET Cost=Cost+17,GoldMaintenance=GoldMaintenance+1,SpecialistCount=SpecialistCount+1 WHERE Type='BUILDING_AMPHITHEATER'")
        db.execute("UPDATE Building_YieldChanges SET Yield=Yield+2 WHERE BuildingType='BUILDING_AMPHITHEATER' AND YieldType='YIELD_CULTURE'")
        db.execute("UPDATE Buildings SET Cost=Cost+19,GoldMaintenance=GoldMaintenance+2 WHERE Type='BUILDING_GRANARY'")
        db.execute("INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES('BUILDING_GRANARY','YIELD_FAITH',3)")
        db.execute("UPDATE Units SET Moves=Moves+2,Cost=Cost+11,WorkRate=85 WHERE Type='UNIT_WORKER'")
        db.execute("UPDATE Buildings SET Cost=Cost+23,GoldMaintenance=GoldMaintenance+3,SpecialistCount=SpecialistCount+1 WHERE Type='BUILDING_WORKSHOP'")
        # Two inherited Gold rows exercise the exactly-one-additional-Gold path.
        db.execute("INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES('BUILDING_WORKSHOP','YIELD_GOLD',3)")
        db.execute("INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES('BUILDING_WORKSHOP','YIELD_GOLD',2)")
        db.execute("UPDATE Units SET Combat=Combat+6,Cost=Cost+27,Moves=Moves+1 WHERE Type='UNIT_PIKEMAN'")
        db.execute("UPDATE Buildings SET Cost=Cost+29,GoldMaintenance=GoldMaintenance+3,SpecialistCount=SpecialistCount+1 WHERE Type='BUILDING_TEMPLE'")
        db.execute("INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES('BUILDING_TEMPLE','YIELD_CULTURE',2)")
        db.execute("INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES('BUILDING_TEMPLE','YIELD_CULTURE',4)")
        db.execute("UPDATE Units SET Moves=Moves+3,Cost=Cost+23,BaseSightRange=BaseSightRange+2 WHERE Type='UNIT_ARCHAEOLOGIST'")
        db.execute("UPDATE Buildings SET Cost=Cost+29,GoldMaintenance=GoldMaintenance+2,GreatWorkCount=GreatWorkCount+1,SpecialistCount=SpecialistCount+1 WHERE Type='BUILDING_MUSEUM'")
        db.execute("INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES('BUILDING_MUSEUM','YIELD_SCIENCE',4),('BUILDING_MUSEUM','YIELD_SCIENCE',3),('BUILDING_MUSEUM','YIELD_CULTURE',2)")
    baseline={t:[tuple(r) for r in db.execute('SELECT * FROM '+quote(t))] for t in ['Civilizations','Units','Buildings','Traits','UnitPromotions']}
    native_companions={}
    for prefix,column,parent in [('Unit_','UnitType','UNIT_WORKER'),('Building_','BuildingType','BUILDING_WORKSHOP'),('Unit_','UnitType','UNIT_PIKEMAN'),('Building_','BuildingType','BUILDING_TEMPLE'),('Unit_','UnitType','UNIT_SPEARMAN'),('Unit_','UnitType','UNIT_COMPOSITE_BOWMAN'),('Unit_','UnitType','UNIT_HORSEMAN'),('Building_','BuildingType','BUILDING_CARAVANSARY'),('Building_','BuildingType','BUILDING_LIBRARY'),('Building_','BuildingType','BUILDING_GRANARY')]:
        for table in approved_companions(prefix,column):
            native_companions[(table,column,parent)]=[tuple(r) for r in db.execute('SELECT * FROM '+quote(table)+' WHERE '+quote(column)+'=?',(parent,))]
    for path in ORDER: db.executescript((ROOT/path).read_text(encoding='utf-8'))
    for (table,column,parent),rows in native_companions.items():
        assert [tuple(r) for r in db.execute('SELECT * FROM '+quote(table)+' WHERE '+quote(column)+'=?',(parent,))]==rows,('Native companion changed',table,parent)
    civ=db.execute("SELECT * FROM Civilizations WHERE Type='CIVILIZATION_CWC3_ALMOST'").fetchone()
    assert (civ['Playable'],civ['AIPlayable'])==(1,0)
    for table,old,new,allowed in [
      ('Units','UNIT_SPEARMAN','UNIT_CWC3_SECOND_WIND_GUARD',{'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex','Moves'}),
      ('Buildings','BUILDING_LIBRARY','BUILDING_CWC3_RUNNER_UP_ACADEMY',{'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex'})]:
        a=db.execute('SELECT * FROM '+table+' WHERE Type=?',(old,)).fetchone()
        b=db.execute('SELECT * FROM '+table+' WHERE Type=?',(new,)).fetchone()
        for key in a.keys():
            if key not in allowed: assert a[key]==b[key],(table,key,a[key],b[key])
        if table=='Units': assert b['Moves']==a['Moves']+1
        prefix,column=('Unit_','UnitType') if table=='Units' else ('Building_','BuildingType')
        for companion in approved_companions(prefix, column):
            cols=[r[1] for r in db.execute('PRAGMA table_info('+quote(companion)+')')]
            if column not in cols: continue
            fields=[c for c in cols if c not in [column,'ID']]
            query='SELECT '+','.join(map(quote,fields))+' FROM '+quote(companion)+' WHERE '+quote(column)+'=?'
            original=Counter(tuple(r) for r in db.execute(query,(old,)))
            unique=Counter(tuple(r) for r in db.execute(query,(new,)))
            if companion=='Unit_FreePromotions':
                unique.subtract({('PROMOTION_CWC3_SECOND_WIND',):1}); unique=+unique
            if companion=='Building_YieldChanges':
                expected=Counter((r[0],r[1]+1) if r[0]=='YIELD_CULTURE' else r for r in original.elements())
                if not any(r[0]=='YIELD_CULTURE' for r in original): expected[('YIELD_CULTURE',1)]+=1
                assert unique==expected,(companion,unique,expected)
            else: assert original==unique,(companion,original-unique,unique-original)
    for table,rows in baseline.items():
        existing=[tuple(r) for r in db.execute('SELECT * FROM '+quote(table)) if not any(p in str(r['Type']) for p in ['CWC3_','BUILDING_SUMMER_','PROMOTION_SUMMER_','PALEO_'])]
        assert existing==rows,('changed native rows',table)
    for table in ['Civilizations','Leaders','Traits','Units','Buildings','UnitPromotions']:
        assert not db.execute('SELECT Type FROM '+quote(table)+" WHERE Type LIKE '%CWC3_%' GROUP BY Type HAVING COUNT(*)<>1").fetchone(),('duplicate identifier',table)
    for suffix,kind in [('SCIENCE_1','SCIENCE'),('SCIENCE_2','SCIENCE'),('CULTURE','CULTURE'),('ACADEMY_PRODUCTION','PRODUCTION')]:
        typ='BUILDING_CWC3_ALMOST_'+suffix
        row=db.execute('SELECT * FROM Buildings WHERE Type=?',(typ,)).fetchone()
        assert all(row[k]==v for k,v in {'Cost':-1,'FaithCost':-1,'IsDummy':1,'ShowInPedia':0,'NeverCapture':1,'ConquestProb':0}.items())
        assert [tuple(r) for r in db.execute('SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType=?',(typ,))]==[('YIELD_'+kind,1)]
    promotion=db.execute("SELECT * FROM UnitPromotions WHERE Type='PROMOTION_CWC3_HOME_DEFENSE'").fetchone()
    assert promotion['DefenseMod']==15 and promotion['AttackMod']==0 and promotion['FriendlyLandsModifier']==0
    assert db.execute("SELECT LostWithUpgrade FROM UnitPromotions WHERE Type='PROMOTION_CWC3_SECOND_WIND'").fetchone()[0]==0
    assert db.execute("SELECT UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=? AND UnitClassType='UNITCLASS_SPEARMAN'",(civ['Type'],)).fetchone()[0]=='UNIT_CWC3_SECOND_WIND_GUARD'
    assert db.execute("SELECT BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=? AND BuildingClassType='BUILDINGCLASS_LIBRARY'",(civ['Type'],)).fetchone()[0]=='BUILDING_CWC3_RUNNER_UP_ACADEMY'
    assert db.execute("SELECT Count FROM Civilization_FreeUnits WHERE CivilizationType=? AND UnitClassType='UNITCLASS_SETTLER'",(civ['Type'],)).fetchone()[0]==1
    keys={r[0] for r in db.execute("SELECT Tag FROM Language_en_US WHERE Tag LIKE 'TXT_KEY_CWC3_%'")}
    for key in ['CIV5_HEADING_1','CIV5_TEXT_1','PENULTIMATE_NAME','PENULTIMATE_SUBTITLE','PENULTIMATE_LIVED','PENULTIMATE_HEADING_1','PENULTIMATE_TEXT_1']:
        assert 'TXT_KEY_CWC3_'+key in keys,('missing dynamic Civilopedia key',key)
    for path in [ROOT/p for p in ORDER]:
        for key in re.findall(r"'(TXT_KEY_CWC3_[A-Z0-9_]+)'",path.read_text()):
            if key in ['TXT_KEY_CWC3_CIV5','TXT_KEY_CWC3_PENULTIMATE','TXT_KEY_CWC3_CHOIR_CIV5','TXT_KEY_CWC3_CHOIR_FIRST_NOTE','TXT_KEY_CWC3_SUMMER_CIV5','TXT_KEY_CWC3_SUMMER_IXA','TXT_KEY_CWC3_TIMETABLE_CIV5','TXT_KEY_CWC3_TIMETABLE_VEYL','TXT_KEY_CWC3_COVENANT_CIV5','TXT_KEY_CWC3_COVENANT_SERAPHINE'] or any(key=='TXT_KEY_CWC3_'+c+'_'+suffix for c in ['LOST','SCARECROW','MAKURIA','SALT'] for suffix in ['CIV5','LEADERPAGE']): continue # Pedia category prefixes
            assert key in keys,('missing localization',key)
    for row in db.execute("SELECT Response FROM Diplomacy_Responses WHERE LeaderType='LEADER_CWC3_PENULTIMATE' AND Response LIKE 'TXT_KEY_CWC3_%'"):
        assert db.execute('SELECT 1 FROM Language_en_US WHERE Tag LIKE ?',(row[0],)).fetchone(),row[0]
    assert db.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
    RESULTS['database_evidence']=dict(EVIDENCE)
    RESULTS['inherited_selection_sound']=dict(db.execute("SELECT * FROM UnitGameplay2DScripts WHERE UnitType='UNIT_CWC3_SECOND_WIND_GUARD'").fetchone())
    assert not db.execute("SELECT name FROM sqlite_temp_master WHERE name LIKE 'CWC3_%'").fetchone(),'temporary clones must be dropped'
    RESULTS['database']='PASS: SQLite execution, pristine and mutated baseline stats/Culture, complete Spearman/Library inheritance, native rows unchanged, bounded dummies, overrides, localization and selection sounds'
    RESULTS['hollow_choir_database']=check_choir_database(db)
    RESULTS['seventeenth_summer_database']=check_summer_database(db)
    RESULTS['timetable_database']=check_timetable_database(db)
    RESULTS['timetable_rounding']=check_rounding(db)
    RESULTS['covenant_database']=check_covenant_database(db)
    RESULTS['paleo_database']=check_paleo_database(db)
    RESULTS['archived_database']=check_archived_database(db)
    return db

def lua_checks(db):
    syntax=LuaRuntime().eval('function(s,n) local f,e=loadstring(s,n); assert(f,e) end')
    paths=list(ROOT.rglob('*.lua'))
    for path in paths: syntax(path.read_text(encoding='utf-8'),str(path))
    suites=[]
    for test in ['ministry_assertions.lua','ministry_hardening.lua']:
        lua=LuaRuntime(); logs=[]
        lua.globals().print=lambda *args:logs.append(' '.join(map(str,args)))
        def include(name): lua.execute((ROOT/'Shared/Lua'/f'{name}.lua').read_text(encoding='utf-8'))
        lua.globals().include=include
        lua.globals().LoadGameplay=lambda:lua.execute((ROOT/'TheMinistryOfAlmost/Lua/Ministry_Gameplay.lua').read_text(encoding='utf-8'))
        lua.execute((ROOT/'tools/tests/ministry_mock.lua').read_text())
        lua.execute((ROOT/'tools/tests'/test).read_text())
        summaries=[line for line in logs if line.startswith('PASS ')]
        for line in summaries: print(line)
        suites.append({'file':test,'result':summaries,'diagnostic_lines_observed':sum(s.startswith('CWC3_ALMOST_DIAG') for s in logs)})
    RESULTS['lua_mock_suites']=suites
    RESULTS['hollow_choir_lua']=check_choir_lua()
    RESULTS['seventeenth_summer_lua']=check_summer_lua()
    RESULTS['timetable_lua']=check_timetable_lua(db)
    RESULTS['covenant_lua']=check_covenant_lua(db)
    RESULTS['paleo_lua']=check_paleo_lua(db)
    RESULTS['archived_lua']=check_archived_lua(db)
    RESULTS['lua']=f'PASS: {len(paths)} files parse under Lua 5.1; production gameplay in isolated 25/34-slot mock suites (not in-game timing verification)'

def package_checks(db):
    root=ET.parse(ROOT/NAME).getroot()
    assert len(list(ROOT.glob('*.modinfo')))==1
    assert root.get('id')==MOD_ID and root.get('version')=='1'
    for key,value in {'MinCompatibleSaveVersion':'1','AffectsSavedGames':'1','SupportsSinglePlayer':'1','SupportsMultiplayer':'0','SupportsHotSeat':'0'}.items():
        assert root.findtext('Properties/'+key)==value,key
    deps=list(root.find('Dependencies'))
    assert [(d.tag,d.get('id').lower(),d.get('minversion'),d.get('maxversion')) for d in deps]==[
      ('Dlc','6da07636-4123-4018-b643-6575b4ec336b','0','999'),('Mod','d1b6328c-ff44-4b0d-aad7-c657f83610cd','151','151')]
    declared={e.text:e for e in root.findall('Files/File')}
    assert len(declared)==len(root.findall('Files/File')),'duplicate manifest path'
    assert set(declared)=={p.relative_to(ROOT).as_posix() for p in files()}
    assert [e.text for e in root.findall('Actions/OnModActivated/UpdateDatabase')]==ORDER
    assert [e.get('file') for e in root.findall('EntryPoints/EntryPoint')]==[entry[0] for entry in ENTRIES]
    context=ET.parse(ROOT/ENTRY).getroot()
    assert context.find('Script').get('file')=='Ministry_Gameplay.lua'
    assert ET.parse(ROOT/ENTRIES[1][0]).getroot().find('Script').get('file')=='HollowChoirGameplay.lua'
    assert ET.parse(ROOT/ENTRIES[2][0]).getroot().find('Script').get('file')=='SummerGameplay.lua'
    assert ET.parse(ROOT/ENTRIES[3][0]).getroot().find('Script').get('file')=='TimetableGameplay.lua'
    assert ET.parse(ROOT/ENTRIES[4][0]).getroot().find('Script').get('file')=='CovenantGameplay.lua'
    assert ET.parse(ROOT/ENTRIES[5][0]).getroot().find('Script').get('file')=='PALEO_Gameplay.lua'
    assert len(ENTRIES)==10 and len(set(e[0] for e in ENTRIES))==10
    assert len(ORDER)==len(set(ORDER))==49
    for entry,_,_ in ENTRIES[6:]:
        assert ET.parse(ROOT/entry).getroot().find('Script').get('file')==Path(entry).stem+'.lua'
    imported=[]
    for name,entry in declared.items():
        path=ROOT/name
        assert hashlib.md5(path.read_bytes()).hexdigest().upper()==entry.get('md5'),name
        if path.suffix in ['.lua','.xml','.sql','.md']:
            assert b'\r' not in path.read_bytes(),('noncanonical line endings would invalidate Git checkout checksums',name)
        if entry.get('import')=='1': imported.append(path.name.casefold())
        if path.suffix=='.xml': ET.parse(path)
        if path.suffix=='.sql': assert entry.get('import')=='0'
        if path.suffix in ['.lua','.dds']: assert entry.get('import')=='1'
        if path.suffix in ['.sql','.lua','.xml']:
            assert 'CWC2_' not in path.read_text(encoding='utf-8'),'unwanted runtime dependency on previous pack'
    assert len(imported)==len(set(imported)),'VFS basename collision'
    art=ROOT/'TheMinistryOfAlmost/Art'
    textures=[]
    for atlas,size,name,cols,rows in db.execute("SELECT Atlas,IconSize,Filename,IconsPerRow,IconsPerColumn FROM IconTextureAtlases WHERE Atlas LIKE 'CWC3_%'"):
        matches=[p for p in files() if p.name==name]
        assert len(matches)==1,('missing/ambiguous atlas',name)
        path=matches[0]; assert path.is_file(),name
        im=Image.open(path); im.load(); assert im.size==(size*int(cols),size*int(rows))
        header=struct.unpack('<31I',path.read_bytes()[4:128]); assert header[21]==32 and header[19]==0x41
        assert header[6]==size.bit_length(),('mip count',name,header[6])
        expected=128; w,h=im.size
        for _ in range(header[6]): expected+=w*h*4; w=max(1,w//2); h=max(1,h//2)
        assert path.stat().st_size==expected,('DDS payload',name)
        assert im.getchannel('A').getextrema()[0]==0,('missing transparency',name)
        textures.append(name)
    assert len(textures)==333
    for name,dimensions in [('CWC3_Dawn.dds',(1024,768)),('CWC3_Leader.dds',(1600,1200)),('CWC3_Map.dds',(360,412))]:
        assert Image.open(art/name).size==dimensions
    assert ET.parse(art/'CWC3_LeaderScene.xml').getroot().get('FallbackImage')=='CWC3_Leader.dds'
    timetable_art=ROOT/'ThePerpetualTimetable/Art'
    for kind,dimensions in [('Dawn',(1024,768)),('Leader',(1600,1200)),('Map',(360,412))]:
        assert Image.open(timetable_art/f'CWC3_Timetable_{kind}.dds').size==dimensions
    assert ET.parse(timetable_art/'CWC3_Timetable_LeaderScene.xml').getroot().get('FallbackImage')=='CWC3_Timetable_Leader.dds'
    assert declared['ThePerpetualTimetable/Art/CWC3_Timetable_LeaderScene.xml'].get('import')=='1'
    covenant_art=ROOT/'TheCandlekeepersCovenant/Art'
    for kind,dimensions in [('Dawn',(1024,768)),('Leader',(1600,1200)),('Map',(360,412))]:
        assert Image.open(covenant_art/f'CWC3_Covenant_{kind}.dds').size==dimensions
    assert ET.parse(covenant_art/'CWC3_Covenant_LeaderScene.xml').getroot().get('FallbackImage')=='CWC3_Covenant_Leader.dds'
    assert declared['TheCandlekeepersCovenant/Art/CWC3_Covenant_LeaderScene.xml'].get('import')=='1'
    RESULTS['paleo_art']=check_paleo_art(db,declared)
    RESULTS['daily_art']=check_daily_art(db,declared)
    for table,typ in [('Civilizations','CIVILIZATION_CWC3_COVENANT'),('Leaders','LEADER_CWC3_COVENANT_SERAPHINE')]:
        row=db.execute('SELECT IconAtlas,PortraitIndex FROM '+table+' WHERE Type=?',(typ,)).fetchone()
        assert db.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND IconSize=256 AND IconsPerRow*IconsPerColumn>?',tuple(row)).fetchone()
    for table,typ in [('Civilizations','CIVILIZATION_CWC3_ALMOST'),('Leaders','LEADER_CWC3_PENULTIMATE'),('Units','UNIT_CWC3_SECOND_WIND_GUARD'),('Buildings','BUILDING_CWC3_RUNNER_UP_ACADEMY')]:
        row=db.execute('SELECT IconAtlas,PortraitIndex FROM '+table+' WHERE Type=?',(typ,)).fetchone()
        assert db.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND IconSize=256 AND IconsPerRow*IconsPerColumn>?',tuple(row)).fetchone()
    for table,typ in [('Civilizations','CIVILIZATION_CWC3_PERPETUAL_TIMETABLE'),('Leaders','LEADER_CWC3_VEYL'),('Units','UNIT_CWC3_LINE_SURVEYOR'),('Buildings','BUILDING_CWC3_DISPATCH_OFFICE')]:
        row=db.execute('SELECT IconAtlas,PortraitIndex FROM '+table+' WHERE Type=?',(typ,)).fetchone()
        assert db.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND IconSize=256 AND IconsPerRow*IconsPerColumn>?',tuple(row)).fetchone()
    package=ROOT/'dist/Cool Wacky Civs 3 (v 1).zip'
    if package.exists():
        with zipfile.ZipFile(package) as archive:
            expected={'Cool Wacky Civs 3 (v 1)/'+name:ROOT/name for name in [*declared,NAME]}
            assert len(archive.namelist())==len(expected) and set(archive.namelist())==set(expected)
            for name,path in expected.items(): assert archive.read(name)==path.read_bytes(),('Stale package file',name)
        RESULTS['distributable']='PASS: every ZIP entry matches the current manifest/source bytes'
    else: RESULTS['distributable']='NOT BUILT; run tools/build_mod.py --package'
    texture_count=sum(p.suffix=='.dds' for p in files())
    assert texture_count==411
    RESULTS['package']=f'PASS: {len(declared)} manifest files + checksums, correct dependencies/order/context/VFS paths, {texture_count} DDS textures, alpha and full icon mip chains'

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--compare-database',type=Path,action='append',default=[],help='Also execute SQL against an existing cache without overlaying a CP-schema snapshot')
    args=parser.parse_args()
    RESULTS['source_audit']=audit()
    RESULTS['paleo_source_audit']=paleo_source_checks()
    RESULTS['archived_source_audit']=archived_source_checks()
    RESULTS['schema_audit']=check_regeneration()
    db=sql_checks(clean=True)
    runs=[{'evidence':dict(EVIDENCE),'fixture':'mutated stats and pre-existing Culture','result':'PASS'}]
    pristine=sql_checks(mutate=False, clean=True); pristine.close()
    runs.append({'evidence':dict(EVIDENCE),'fixture':'unaltered source definitions','result':'PASS'})
    for mutate in [False,True]:
        comparison=sql_checks(mutate); comparison.close()
        runs.append({'evidence':dict(EVIDENCE),'fixture':'mutated source definitions' if mutate else 'unaltered source definitions','result':'PASS'})
    previous=os.environ.get('CWC3_DATABASE')
    try:
        for path in args.compare_database:
            os.environ['CWC3_DATABASE']=str(path)
            for mutate in [False,True]:
                comparison=sql_checks(mutate); comparison.close()
                runs.append({'evidence':dict(EVIDENCE),'fixture':'mutated stats and pre-existing Culture' if mutate else 'unaltered source definitions','result':'PASS'})
    finally:
        if previous is None: os.environ.pop('CWC3_DATABASE',None)
        else: os.environ['CWC3_DATABASE']=previous
    RESULTS['database_runs']=runs
    RESULTS['database_evidence']=runs[0]['evidence']
    lua_checks(db); package_checks(db); db.close()
    RESULTS['in_game']='NOT RUN. Native yield settlement, combat previews, engine save persistence, archaeology choice dispatch and art/UI presentation require docs/ArchivedDailyTesting.md and the existing civilization acceptance guides. The new archive controllers, Covenant, Summer and Timetable use explicit post-economy next-payout reconciliation; Ministry UI dispatch synchrony remains unverified. Existing saves have NOT been acceptance-tested with this roster; start a new game.'
    # Report stays outside the manifest to avoid a checksum self-reference.
    out=ROOT/'tools/Validation.json'; out.write_text(json.dumps(RESULTS,indent=2)+'\n',encoding='utf-8',newline='\n')
    for k,v in RESULTS.items():
        if k in ['database_evidence','inherited_selection_sound','lua_mock_suites']: continue
        if k=='database_runs': print('database_runs: '+str(len(v))+' SQLite baselines passed'); continue
        print(k+': '+(str(v) if k!='source_audit' else 'PASS pinned source hashes and API/timing assertions'))
if __name__=='__main__': main()
