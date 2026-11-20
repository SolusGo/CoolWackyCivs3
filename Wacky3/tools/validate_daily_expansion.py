"""SQLite inheritance checks and Lua 5.1 gameplay fixtures for Daily #021–#035."""
from collections import Counter
import re

from lupa.lua51 import LuaRuntime
from baseline import ROOT, quote
from generate_daily_expansion import ROSTER, code
from target_schema import approved_companions, clean_fixture


def check_database(db):
    for spec in ROSTER:
        stem = 'CWC3_' + code(spec)
        civ, leader, trait, unit, building, promotion = [
            f'{kind}_{stem}' for kind in ('CIVILIZATION','LEADER','TRAIT','UNIT','BUILDING','PROMOTION')
        ]
        for option in spec.get('options', []):
            assert db.execute('SELECT Value FROM CustomModOptions WHERE Name=?', (option,)).fetchone()[0] == 1
        assert tuple(db.execute('SELECT Playable,AIPlayable FROM Civilizations WHERE Type=?',(civ,)).fetchone()) == (1,0)
        assert [r[0] for r in db.execute('SELECT LeaderheadType FROM Civilization_Leaders WHERE CivilizationType=?',(civ,))] == [leader]
        assert [r[0] for r in db.execute('SELECT TraitType FROM Leader_Traits WHERE LeaderType=?',(leader,))] == [trait]
        for table, field, parent, child in [
            ('Units','Class','UNIT_'+spec['unit_parent'],unit),
            ('Buildings','BuildingClass','BUILDING_'+spec['building_parent'],building),
        ]:
            original = db.execute(f'SELECT * FROM {table} WHERE Type=?',(parent,)).fetchone()
            replacement = db.execute(f'SELECT * FROM {table} WHERE Type=?',(child,)).fetchone()
            assert original and replacement, (stem, parent, child)
            identity = {'ID','Type','Description','Civilopedia','Help','Strategy'}
            changes = spec.get('building_fields', {}) if table == 'Buildings' else {
                col: original[col]+delta for col,delta in spec.get('unit_fields', {}).items()
            }
            for col in original.keys():
                if col not in identity:
                    assert replacement[col] == changes.get(col, original[col]), (stem, child, col)
            kind = 'Unit' if table == 'Units' else 'Building'
            overrides = db.execute(f'SELECT {kind}ClassType,{kind}Type FROM Civilization_{kind}ClassOverrides WHERE CivilizationType=?',(civ,))
            assert [tuple(row) for row in overrides] == [(original[field],child)]
            for companion in approved_companions(kind+'_',kind+'Type'):
                cols = [r[1] for r in db.execute(f'PRAGMA table_info({quote(companion)})') if r[1] not in ('ID',kind+'Type')]
                query = f'SELECT {",".join(map(quote,cols))} FROM {quote(companion)} WHERE {kind}Type=? ORDER BY rowid'
                expected = [tuple(r) for r in db.execute(query,(parent,))]
                if companion == 'Unit_FreePromotions':
                    free = [promotion+'_LINEAGE'] if 'promotion' in spec else []
                    free += [p for p in spec.get('free_promotions', []) if (p,) not in expected]
                    expected += [(p,) for p in free]
                if companion == 'Building_YieldChanges':
                    for yield_kind, amount in spec['yields'].items():
                        for i, (yield_type, value) in enumerate(expected):
                            if yield_type == 'YIELD_'+yield_kind:
                                expected[i] = (yield_type,value+amount)
                                break
                        else:
                            expected.append(('YIELD_'+yield_kind,amount))
                assert Counter(tuple(r) for r in db.execute(query,(child,))) == Counter(expected), (stem, companion)
        promotions = dict(spec.get('extra_promotions', {}))
        if 'promotion' in spec:
            promotions['LINEAGE'] = spec['promotion']
        for suffix, expected in promotions.items():
            row = db.execute('SELECT * FROM UnitPromotions WHERE Type=?',(promotion+'_'+suffix,)).fetchone()
            assert row['CannotBeChosen'] == 1
            for field in ('VisibilityChange','DefenseMod','AttackMod','CombatPercent','FriendlyLandsModifier','HillsDefense','MovesChange','LostWithUpgrade','IgnoreTerrainCost'):
                assert row[field] == expected.get(field, 0), (stem,suffix,field)
        for suffix, yields in spec['controllers'].items():
            dummy = building+'_'+suffix
            row = db.execute('SELECT * FROM Buildings WHERE Type=?',(dummy,)).fetchone()
            assert tuple(row[k] for k in ('IsDummy','Cost','FaithCost','NeverCapture','ConquestProb','ShowInPedia')) == (1,-1,-1,1,0,0)
            assert dict(db.execute('SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType=?',(dummy,))) == {
                'YIELD_'+kind: value for kind,value in yields.items()
            }
        prefix = 'TXT_KEY_'+stem+'_'
        keys = dict(db.execute('SELECT Tag,Text FROM Language_en_US WHERE Tag LIKE ?',(prefix+'%',)))
        assert keys[prefix+'CITY_1'] == spec['capital']
        assert keys[prefix+'CIV'] == spec['name'] and keys[prefix+'LEADER'] == spec['leader']
        for path in (ROOT/spec['folder']/'SQL').glob('*.sql'):
            for tag in re.findall(r"'(TXT_KEY_"+stem+r"_[A-Z0-9_]+)'", path.read_text(encoding='utf-8')):
                assert tag in keys or tag in (prefix+'LEADERPAGE',prefix+'CIV5'), (stem, tag)
    assert db.execute("SELECT COUNT(*) FROM Civilizations WHERE Type LIKE 'CIVILIZATION_CWC3_D0%'").fetchone()[0] == len(ROSTER)
    return f'PASS {len(ROSTER)} Daily identities, intended active scalar and all approved companion deltas, dummies and localization'


def check_lua(db):
    types = {}
    for table in ['Civilizations','Units','Buildings','Improvements','UnitPromotions','Terrains','Features','Resources','GameSpeeds']:
        types.update(dict(db.execute(f'SELECT Type,ID FROM {table}')))
    # The clean schema fixture only seeds selected gameplay rows. Enums used by
    # the Lua tests only need stable distinct mock IDs when omitted.
    for i, name in enumerate((
        "TERRAIN_PLAINS", "TERRAIN_GRASS", "TERRAIN_TUNDRA", "TERRAIN_SNOW", "TERRAIN_DESERT",
        "FEATURE_MARSH", "IMPROVEMENT_MINE", "RESOURCE_GOLD", "RESOURCE_SILVER",
        "GAMESPEED_QUICK", "GAMESPEED_STANDARD", "GAMESPEED_EPIC", "GAMESPEED_MARATHON",
    ), 10000):
        types.setdefault(name, i)
    logs = []
    for speed in ('STANDARD','MARATHON'):
        for spec in ROSTER:
            lua = LuaRuntime()
            env = lua.globals()
            env.GameInfoTypes = lua.table_from(types)
            env.BuildingRows = lua.table_from([lua.table_from(dict(r)) for r in db.execute('SELECT ID,BuildingClass FROM Buildings')])
            env.LoadShared = lambda name: lua.execute((ROOT/'Shared/Lua'/f'{name}.lua').read_text(encoding='utf-8'))
            def load_civ(number):
                spec = next((s for s in ROSTER if s['id'] == number), None)
                if not spec:
                    return False
                path = ROOT/spec['folder']/'Lua'/f'{code(spec)}_Gameplay.lua'
                lua.execute(path.read_text(encoding='utf-8'))
                return True
            env.LoadDaily = load_civ
            env.Speed = speed
            env.DailyNumber = spec["id"]
            env.Controller = next(iter(spec["controllers"]))
            env.print = lambda line: logs.append(line)
            lua.execute((ROOT/'tools/tests/daily_expansion.lua').read_text(encoding='utf-8'))
    return logs


if __name__ == '__main__':
    from build_mod import ORDER
    with clean_fixture() as db:
        for path in ORDER:
            db.executescript((ROOT/path).read_text(encoding='utf-8'))
        print(check_database(db))
        for result in check_lua(db):
            print(result)
