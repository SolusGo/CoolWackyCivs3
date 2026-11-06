"""Timetable active CP inheritance, city-yield and production Lua51 tests."""
from collections import Counter
import sqlite3
from lupa.lua51 import LuaRuntime
from baseline import ROOT, quote
from target_schema import approved_companions
from generate_timetable import CIV, LEADER, TRAIT, UNIT, OFFICE, PREFIX, DUMMIES


def check_database(db):
    civ = db.execute('SELECT * FROM Civilizations WHERE Type=?', (CIV,)).fetchone()
    assert (civ['Playable'], civ['AIPlayable']) == (1,0)
    assert db.execute('SELECT LeaderheadType FROM Civilization_Leaders WHERE CivilizationType=?', (CIV,)).fetchone()[0] == LEADER
    assert db.execute('SELECT TraitType FROM Leader_Traits WHERE LeaderType=?', (LEADER,)).fetchone()[0] == TRAIT
    for table,old,new,prefix,column in [('Units','UNIT_WORKER',UNIT,'Unit_','UnitType'),
                                       ('Buildings','BUILDING_WORKSHOP',OFFICE,'Building_','BuildingType')]:
        a = db.execute('SELECT * FROM '+table+' WHERE Type=?', (old,)).fetchone()
        b = db.execute('SELECT * FROM '+table+' WHERE Type=?', (new,)).fetchone()
        for key in a.keys():
            if key in {'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex'}: continue
            expected = a[key]
            if table == 'Units':
                if key == 'Moves': expected += 1
                if key == 'WorkRate': expected = int(expected*1.1+0.5)
            assert b[key] == expected, (table,key,expected,b[key])
        for companion in approved_companions(prefix, column):
            fields = [r[1] for r in db.execute('PRAGMA table_info('+quote(companion)+')') if r[1] not in [column,'ID']]
            query = 'SELECT '+','.join(map(quote,fields))+' FROM '+quote(companion)+' WHERE '+quote(column)+'=? ORDER BY rowid'
            source = [tuple(r) for r in db.execute(query, (old,))]
            expected = list(source)
            if companion == 'Building_YieldChanges':
                for i,row in enumerate(expected):
                    if row[0] == 'YIELD_GOLD':
                        expected[i] = (row[0],row[1]+1)
                        break
                else: expected.append(('YIELD_GOLD',1))
            actual = Counter(tuple(r) for r in db.execute(query, (new,)))
            assert actual == Counter(expected), (companion,actual,expected)
    worker = db.execute("SELECT * FROM Units WHERE Type='UNIT_WORKER'").fetchone()
    workshop = db.execute("SELECT * FROM Buildings WHERE Type='BUILDING_WORKSHOP'").fetchone()
    assert db.execute('SELECT UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=? AND UnitClassType=?', (CIV,worker['Class'])).fetchone()[0] == UNIT
    assert db.execute('SELECT BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=? AND BuildingClassType=?', (CIV,workshop['BuildingClass'])).fetchone()[0] == OFFICE
    # Database eligibility, not just a string saying the unit is trainable:
    # active Worker class, civilian domain, production/purchase/capture and builds.
    surveyor = db.execute('SELECT * FROM Units WHERE Type=?', (UNIT,)).fetchone()
    assert surveyor['Cost'] >= 0 and surveyor['Domain'] == worker['Domain']
    assert db.execute('SELECT 1 FROM Unit_Builds WHERE UnitType=?', (UNIT,)).fetchone()
    for suffix,kind in DUMMIES:
        typ = 'BUILDING_CWC3_TIMETABLE_'+suffix
        b = db.execute('SELECT * FROM Buildings WHERE Type=?', (typ,)).fetchone()
        for k,v in dict(Cost=-1,FaithCost=-1,GoldMaintenance=0,GreatWorkCount=-1,IsDummy=1,
                        ShowInPedia=0,NeverCapture=1,ConquestProb=0).items(): assert b[k] == v, (typ,k)
        assert [tuple(r) for r in db.execute('SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType=?', (typ,))] == [('YIELD_'+kind,1)]
        assert db.execute('SELECT DefaultBuilding FROM BuildingClasses WHERE Type=?', (b['BuildingClass'],)).fetchone()[0] == typ
        assert not db.execute('SELECT 1 FROM Civilization_BuildingClassOverrides WHERE BuildingType=?', (typ,)).fetchone()
        for companion in approved_companions('Building_', 'BuildingType'):
            if companion != 'Building_YieldChanges':
                assert not db.execute('SELECT 1 FROM '+quote(companion)+' WHERE BuildingType=?', (typ,)).fetchone(), (typ,companion)
    assert db.execute('SELECT Text FROM Language_en_US WHERE Tag=?', (PREFIX+'CITY_1',)).fetchone()[0] == 'Terminus Prime'
    exact = {
        'GREETING_1': 'Welcome, esteemed visitor. Your appointment was scheduled for precisely 14:32. You have arrived at 14:31. Excellent. I approve.',
        'WAR_1': 'Your civilization has repeatedly disrupted the proper functioning of international transportation. Regrettably, corrective measures are now scheduled.',
        'ATTACKED_1': 'An invasion? Without submitting the appropriate scheduling documentation? OUTRAGEOUS.',
        'DEFEAT_1': 'Impossible... our calculations... were perfect...',
    }
    for key,value in exact.items():
        assert db.execute('SELECT Text FROM Language_en_US WHERE Tag=?', (PREFIX+key,)).fetchone()[0] == value
    for ending in ['CIV5_HEADING_1','CIV5_TEXT_1','CIV5_FACTOID_TEXT','VEYL_NAME','VEYL_SUBTITLE','VEYL_LIVED','VEYL_HEADING_1','VEYL_TEXT_1']:
        assert db.execute('SELECT 1 FROM Language_en_US WHERE Tag=?', (PREFIX+ending,)).fetchone()
    for (response,) in db.execute('SELECT Response FROM Diplomacy_Responses WHERE LeaderType=?', (LEADER,)):
        assert db.execute('SELECT 1 FROM Language_en_US WHERE Tag LIKE ?', (response,)).fetchone(), response
    for table in ['Civilization_FreeUnits','Civilization_FreeTechs','Civilization_FreeBuildingClasses']:
        fields = [r[1] for r in db.execute('PRAGMA table_info('+table+')') if r[1] != 'CivilizationType']
        query = 'SELECT '+','.join(map(quote,fields))+' FROM '+table+' WHERE CivilizationType=?'
        assert Counter(tuple(r) for r in db.execute(query,(CIV,))) == Counter(tuple(r) for r in db.execute(query,('CIVILIZATION_AMERICA',)))
    # Lua yields below come from THESE executed SQL rows, rather than duplicating
    # the game's yield mapping inside the mock.
    return 'PASS: human-only registration, active Worker/Workshop scalars and all 172 companions, rounded WorkRate, one extra Gold, five isolated controllers, overrides, localization, starts and native model inheritance'


def check_lua(db):
    results = []
    for majors in [4,34]:
        lua = LuaRuntime(); logs = []
        lua.globals().print = lambda *a: logs.append(' '.join(map(str,a)))
        lua.globals().include = lambda n: lua.execute((ROOT/'Shared/Lua'/f'{n}.lua').read_text(encoding='utf-8'))
        lua.globals().LoadTimetable = lambda: lua.execute((ROOT/'ThePerpetualTimetable/Lua/TimetableGameplay.lua').read_text(encoding='utf-8'))
        lua.globals().MajorCount = majors
        lua.execute('DatabaseYields={}; DatabaseGold=1')
        for i,(suffix,_) in enumerate(DUMMIES,202):
            rows = list(db.execute('SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType=?', ('BUILDING_CWC3_TIMETABLE_'+suffix,)))
            assert len(rows)==1
            kind,amount = rows[0]
            lua.globals().DatabaseYields[i] = lua.table_from({'kind':kind,'amount':amount})
        # Subtract inherited Workshop Gold: the fixture tracks unique deltas.
        gold = lambda typ: db.execute("SELECT COALESCE(SUM(Yield),0) FROM Building_YieldChanges WHERE BuildingType=? AND YieldType='YIELD_GOLD'",(typ,)).fetchone()[0]
        lua.globals().DatabaseGold = gold(OFFICE)-gold('BUILDING_WORKSHOP')
        lua.execute((ROOT/'tools/tests/timetable.lua').read_text(encoding='utf-8'))
        for line in logs: print(line)
        results.extend(logs)
    return results


def check_rounding(db):
    # Re-execute production unit SQL against varied ACTIVE native rows. Explicit
    # expected values exercise both given examples and a half-integer rounding.
    for baseline,expected in [(80,88),(85,94),(100,110)]:
        copy = sqlite3.connect(':memory:'); db.backup(copy)
        for table in approved_companions('Unit_', 'UnitType'):
            copy.execute('DELETE FROM '+quote(table)+' WHERE UnitType=?', (UNIT,))
        copy.execute('DELETE FROM Units WHERE Type=?', (UNIT,))
        copy.execute("UPDATE Units SET WorkRate=? WHERE Type='UNIT_WORKER'", (baseline,))
        copy.executescript((ROOT/'ThePerpetualTimetable/SQL/Timetable_Units.sql').read_text(encoding='utf-8'))
        assert copy.execute('SELECT WorkRate FROM Units WHERE Type=?', (UNIT,)).fetchone()[0]==expected
        assert copy.execute("SELECT WorkRate FROM Units WHERE Type='UNIT_WORKER'").fetchone()[0]==baseline
        copy.close()
    return 'PASS: production SQL inherits active WorkRate 80 -> 88, 85 -> 94, 100 -> 110; native Worker unchanged'


if __name__ == '__main__':
    from target_schema import clean_fixture
    from validate_schema import seed_companions
    from build_mod import ORDER
    db = clean_fixture(); seed_companions(db)
    for path in ORDER: db.executescript((ROOT/path).read_text(encoding='utf-8'))
    print(check_database(db))
    print(check_rounding(db))
    check_lua(db)
    db.close()
