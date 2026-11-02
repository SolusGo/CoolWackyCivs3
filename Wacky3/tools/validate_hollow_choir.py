"""Hollow Choir database inheritance and production-Lua behavioral checks."""
from collections import Counter
from lupa.lua51 import LuaRuntime
from baseline import ROOT, quote
from generate_hollow_choir import CIV, LEADER, UNIT, HALL, PROMO, PREFIX


def check_database(db):
    civ = db.execute('SELECT * FROM Civilizations WHERE Type=?', (CIV,)).fetchone()
    assert (civ['Playable'], civ['AIPlayable']) == (1, 0)
    assert tuple(db.execute('SELECT LeaderheadType FROM Civilization_Leaders WHERE CivilizationType=?', (CIV,)).fetchone()) == (LEADER,)
    assert db.execute('SELECT UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=? AND UnitClassType=?', (CIV, 'UNITCLASS_SWORDSMAN')).fetchone()[0] == UNIT
    assert db.execute('SELECT BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=? AND BuildingClassType=?', (CIV, 'BUILDINGCLASS_AMPHITHEATER')).fetchone()[0] == HALL
    excluded = {'ID','Type','Description','Civilopedia','Help','Strategy'}
    companions = 0
    for table, old, new, prefix, column in [('Units','UNIT_SWORDSMAN',UNIT,'Unit_','UnitType'),
                                            ('Buildings','BUILDING_AMPHITHEATER',HALL,'Building_','BuildingType')]:
        a = db.execute('SELECT * FROM '+table+' WHERE Type=?', (old,)).fetchone()
        b = db.execute('SELECT * FROM '+table+' WHERE Type=?', (new,)).fetchone()
        for key in a.keys():
            if key not in excluded: assert a[key] == b[key], (table, key, a[key], b[key])
        for (companion,) in db.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
            if not (companion.startswith(prefix) or (table=='Units' and companion=='UnitGameplay2DScripts')) or companion.endswith('_new'): continue
            cols = [r[1] for r in db.execute('PRAGMA table_info('+quote(companion)+')')]
            if column not in cols: continue
            fields = [c for c in cols if c not in [column,'ID']]
            query = 'SELECT '+','.join(map(quote, fields))+' FROM '+quote(companion)+' WHERE '+quote(column)+'=?'
            original = Counter(tuple(r) for r in db.execute(query, (old,)))
            unique = Counter(tuple(r) for r in db.execute(query, (new,)))
            if companion == 'Unit_FreePromotions':
                assert unique[ (PROMO,) ] == 1
                unique.subtract({(PROMO,): 1}); unique = +unique
            if companion == 'Building_YieldChanges':
                expected = Counter((r[0],r[1]+1) if r[0]=='YIELD_CULTURE' else r for r in original.elements())
                if not any(r[0]=='YIELD_CULTURE' for r in original): expected[('YIELD_CULTURE',1)] += 1
                assert unique == expected, (companion, unique, expected)
            else: assert unique == original, (companion, original-unique, unique-original)
            companions += 1
    promotion = db.execute('SELECT * FROM UnitPromotions WHERE Type=?', (PROMO,)).fetchone()
    for key,value in {'VisibilityChange':1,'HillsDefense':20,'HillsAttack':0,'DefenseMod':0,'AttackMod':0,
                      'CombatPercent':0,'CannotBeChosen':1,'LostWithUpgrade':0,'MovesChange':0,'CanCrossMountains':0}.items():
        assert promotion[key] == value, (key, promotion[key])
    assert not db.execute("SELECT 1 FROM Unit_FreePromotions WHERE PromotionType=? AND UnitType<>?", (PROMO,UNIT)).fetchone()
    for suffix,kind in [('HILL_PRODUCTION','PRODUCTION'),('MOUNTAIN_FAITH_1','FAITH'),('MOUNTAIN_FAITH_2','FAITH'),
                        ('RESONANCE_SCIENCE_1','SCIENCE'),('RESONANCE_SCIENCE_2','SCIENCE')]:
        typ = 'BUILDING_CWC3_CHOIR_'+suffix
        row = db.execute('SELECT * FROM Buildings WHERE Type=?', (typ,)).fetchone()
        for key,value in {'Cost':-1,'FaithCost':-1,'GoldMaintenance':0,'GreatWorkCount':-1,'IsDummy':1,'ShowInPedia':0,
                          'NeverCapture':1,'ConquestProb':0,'Happiness':0,'SpecialistCount':0,'PrereqTech':None}.items():
            assert row[key] == value, (typ,key,row[key])
        assert [tuple(r) for r in db.execute('SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType=?',(typ,))] == [('YIELD_'+kind,1)]
    for table in ['Civilization_FreeUnits','Civilization_FreeTechs','Civilization_FreeBuildingClasses']:
        cols = [r[1] for r in db.execute('PRAGMA table_info('+table+')') if r[1]!='CivilizationType']
        query = 'SELECT '+','.join(map(quote,cols))+' FROM '+table+' WHERE CivilizationType=?'
        assert Counter(tuple(r) for r in db.execute(query,(CIV,))) == Counter(tuple(r) for r in db.execute(query,('CIVILIZATION_AMERICA',)))
    assert db.execute('SELECT Text FROM Language_en_US WHERE Tag=?',(PREFIX+'CITY_1',)).fetchone()[0] == 'Resonance'
    for ending in ['CIV5_HEADING_1','CIV5_TEXT_1','CIV5_FACTOID_TEXT','FIRST_NOTE_NAME','FIRST_NOTE_SUBTITLE','FIRST_NOTE_LIVED','FIRST_NOTE_HEADING_1','FIRST_NOTE_TEXT_1']:
        assert db.execute('SELECT 1 FROM Language_en_US WHERE Tag=?',(PREFIX+ending,)).fetchone()
    for (response,) in db.execute('SELECT Response FROM Diplomacy_Responses WHERE LeaderType=?',(LEADER,)):
        assert db.execute('SELECT 1 FROM Language_en_US WHERE Tag LIKE ?',(response,)).fetchone(),response
    # All temporary native art references are exact inherited values, checked above.
    return f'PASS: human-only registration, exact Swordsman/Amphitheater scalars and {companions} companion tables, +1 Culture, five bounded yield definitions, native hill-defense promotion, localization and native art inheritance'


def check_lua():
    lua = LuaRuntime()
    logs = []
    lua.globals().print = lambda *args: logs.append(' '.join(map(str,args)))
    lua.globals().include = lambda name: lua.execute((ROOT/'Shared/Lua'/f'{name}.lua').read_text(encoding='utf-8'))
    lua.globals().LoadChoir = lambda: lua.execute((ROOT/'TheHollowChoir/Lua/HollowChoirGameplay.lua').read_text(encoding='utf-8'))
    lua.execute((ROOT/'tools/tests/hollow_choir.lua').read_text(encoding='utf-8'))
    for line in logs: print(line)
    return logs
