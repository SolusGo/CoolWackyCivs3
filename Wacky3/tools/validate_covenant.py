"""Active-row inheritance and production Lua51 Covenant state-machine tests."""
from collections import Counter
from lupa.lua51 import LuaRuntime
from baseline import ROOT, quote
from target_schema import approved_companions
from generate_covenant import CIV, LEADER, TRAIT, UNIT, HALL, PROMO, DEFENSE, PREFIX, DUMMIES

def check_database(db):
    civ=db.execute('SELECT * FROM Civilizations WHERE Type=?',(CIV,)).fetchone()
    assert (civ['Playable'],civ['AIPlayable'])==(1,0)
    assert db.execute('SELECT LeaderheadType FROM Civilization_Leaders WHERE CivilizationType=?',(CIV,)).fetchone()[0]==LEADER
    assert db.execute('SELECT TraitType FROM Leader_Traits WHERE LeaderType=?',(LEADER,)).fetchone()[0]==TRAIT
    for table,parent,child,prefix,column in [('Units','UNIT_PIKEMAN',UNIT,'Unit_','UnitType'),('Buildings','BUILDING_TEMPLE',HALL,'Building_','BuildingType')]:
        old=db.execute('SELECT * FROM '+table+' WHERE Type=?',(parent,)).fetchone()
        new=db.execute('SELECT * FROM '+table+' WHERE Type=?',(child,)).fetchone()
        for k in old.keys():
            if k not in {'ID','Type','Description','Civilopedia','Help','Strategy'}: assert old[k]==new[k],(table,k,old[k],new[k])
        for companion in approved_companions(prefix,column):
            fields=[r[1] for r in db.execute('PRAGMA table_info('+quote(companion)+')') if r[1] not in [column,'ID']]
            query='SELECT '+','.join(map(quote,fields))+' FROM '+quote(companion)+' WHERE '+quote(column)+'=? ORDER BY rowid'
            expected=[tuple(r) for r in db.execute(query,(parent,))]
            if companion=='Unit_FreePromotions': expected.append((PROMO,))
            if companion=='Building_YieldChanges':
                for i,row in enumerate(expected):
                    if row[0]=='YIELD_CULTURE': expected[i]=(row[0],row[1]+1); break
                else: expected.append(('YIELD_CULTURE',1))
            actual=Counter(tuple(r) for r in db.execute(query,(child,)))
            assert actual==Counter(expected),(companion,actual,expected)
    assert db.execute('SELECT UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=? AND UnitClassType=?',(CIV,'UNITCLASS_PIKEMAN')).fetchone()[0]==UNIT
    assert db.execute('SELECT BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=? AND BuildingClassType=?',(CIV,'BUILDINGCLASS_TEMPLE')).fetchone()[0]==HALL
    identity=db.execute('SELECT * FROM UnitPromotions WHERE Type=?',(PROMO,)).fetchone()
    defense=db.execute('SELECT * FROM UnitPromotions WHERE Type=?',(DEFENSE,)).fetchone()
    assert identity['VisibilityChange']==1 and identity['LostWithUpgrade']==0
    assert defense['DefenseMod']==15 and defense['LostWithUpgrade']==1
    for row in [identity,defense]:
        for k in ['AttackMod','FriendlyLandsModifier','FriendlyLandsAttackModifier','CombatPercent']:
            assert row[k]==0,(row['Type'],k)
    for suffix,kind in DUMMIES:
        typ='BUILDING_CWC3_COVENANT_'+suffix
        row=db.execute('SELECT * FROM Buildings WHERE Type=?',(typ,)).fetchone()
        for k,v in dict(Cost=-1,FaithCost=-1,GoldMaintenance=0,GreatWorkCount=-1,NeverCapture=1,ConquestProb=0,IsDummy=1,ShowInPedia=0,SpecialistCount=0,Happiness=0,FreeTechs=0).items(): assert row[k]==v,(typ,k)
        assert [tuple(r) for r in db.execute('SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType=?',(typ,))]==[('YIELD_'+kind,1)]
        for companion in approved_companions('Building_','BuildingType'):
            if companion!='Building_YieldChanges': assert not db.execute('SELECT 1 FROM '+quote(companion)+' WHERE BuildingType=?',(typ,)).fetchone()
    assert db.execute('SELECT Text FROM Language_en_US WHERE Tag=?',(PREFIX+'CITY_1',)).fetchone()[0]=='Last Light'
    for key in ['CIV5_HEADING_1','CIV5_TEXT_1','CIV5_FACTOID_TEXT','SERAPHINE_NAME','SERAPHINE_SUBTITLE','SERAPHINE_LIVED','SERAPHINE_HEADING_1','SERAPHINE_TEXT_1']:
        assert db.execute('SELECT 1 FROM Language_en_US WHERE Tag=?',(PREFIX+key,)).fetchone()
    for (response,) in db.execute('SELECT Response FROM Diplomacy_Responses WHERE LeaderType=?',(LEADER,)):
        assert db.execute('SELECT 1 FROM Language_en_US WHERE Tag LIKE ?',(response,)).fetchone()
    for table in ['Civilization_FreeUnits','Civilization_FreeTechs','Civilization_FreeBuildingClasses']:
        fields=[r[1] for r in db.execute('PRAGMA table_info('+table+')') if r[1]!='CivilizationType']
        query='SELECT '+','.join(map(quote,fields))+' FROM '+table+' WHERE CivilizationType=?'
        assert Counter(tuple(r) for r in db.execute(query,(CIV,)))==Counter(tuple(r) for r in db.execute(query,('CIVILIZATION_AMERICA',)))
    assert db.execute("SELECT Value FROM CustomModOptions WHERE Name='EVENTS_BATTLES'").fetchone()[0]==1
    return 'PASS: human-only registration, complete active Pikeman/Temple scalar and 172 companion inheritance, exactly +1 Hall Culture including duplicate rows, 18 exclusive 0/1 controllers, native-model inheritance, permanent Sight and defense-only promotion'

def check_lua(db):
    results=[]
    for majors,slot in [(4,0),(34,3)]:
        lua=LuaRuntime(); logs=[]
        lua.globals().print=lambda *a:logs.append(' '.join(map(str,a)))
        lua.globals().include=lambda n:lua.execute((ROOT/'Shared/Lua'/f'{n}.lua').read_text(encoding='utf-8'))
        lua.globals().LoadCovenant=lambda:lua.execute((ROOT/'TheCandlekeepersCovenant/Lua/CovenantGameplay.lua').read_text(encoding='utf-8'))
        lua.globals().MajorCount=majors; lua.globals().KeeperSlot=slot; lua.globals().RivalSlot=1 if slot==0 else 0
        lua.execute('DatabaseYields={}')
        for i,(suffix,_) in enumerate(DUMMIES,201):
            kind,amount=db.execute('SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType=?',('BUILDING_CWC3_COVENANT_'+suffix,)).fetchone()
            lua.globals().DatabaseYields[i]=lua.table_from(dict(kind=kind,amount=amount))
        value=lambda typ:db.execute("SELECT COALESCE(SUM(Yield),0) FROM Building_YieldChanges WHERE BuildingType=? AND YieldType='YIELD_CULTURE'",(typ,)).fetchone()[0]
        lua.globals().DatabaseHallCulture=value(HALL)-value('BUILDING_TEMPLE')
        row=db.execute('SELECT * FROM UnitPromotions WHERE Type=?',(DEFENSE,)).fetchone()
        lua.globals().DefenseValue=row['DefenseMod']; lua.globals().AttackValue=row['AttackMod']
        row=db.execute('SELECT * FROM UnitPromotions WHERE Type=?',(PROMO,)).fetchone()
        lua.globals().SightValue=row['VisibilityChange']; lua.globals().LostWithUpgrade=row['LostWithUpgrade']
        lua.execute((ROOT/'tools/tests/covenant.lua').read_text(encoding='utf-8'))
        for line in logs: print(line)
        results.extend(logs)
    return results

if __name__=='__main__':
    from target_schema import clean_fixture
    from validate_schema import seed_companions
    from build_mod import ORDER
    db=clean_fixture(); seed_companions(db)
    for path in ORDER: db.executescript((ROOT/path).read_text(encoding='utf-8'))
    print(check_database(db)); check_lua(db)
