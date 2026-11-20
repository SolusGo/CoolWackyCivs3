"""SQLite inheritance checks and Lua 5.1 gameplay fixtures for Daily #021–#035."""
from collections import Counter
import hashlib
from PIL import Image
from build_art import SIZES
import re

from lupa.lua51 import LuaRuntime
from baseline import ROOT, quote
from generate_daily_expansion import ROSTER, code
from target_schema import approved_companions, clean_fixture


def mutate_baselines(db):
    for parent in {spec['unit_parent'] for spec in ROSTER}:
        db.execute("UPDATE Units SET Combat=Combat+2,Cost=Cost+3,Moves=Moves+1 WHERE Type=?", ('UNIT_'+parent,))
    for parent in {spec['building_parent'] for spec in ROSTER}:
        db.execute("UPDATE Buildings SET Cost=Cost+7,GoldMaintenance=GoldMaintenance+1 WHERE Type=?", ('BUILDING_'+parent,))
    for parent,kind in {(spec['building_parent'],kind) for spec in ROSTER for kind in spec['yields']}:
        db.executemany('INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES (?,?,?)',
                       [('BUILDING_'+parent,'YIELD_'+kind,3), ('BUILDING_'+parent,'YIELD_'+kind,5)])


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
            identity = {'ID','Type','Description','Civilopedia','Help','Strategy','UnitFlagAtlas','UnitFlagIconOffset'}
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
        lineage = promotion+'_LINEAGE'
        expected_terrain = [(f'TERRAIN_{t}',a,0) for t,a in spec.get('terrain_attack', {}).items()]
        expected_terrain += [(f'TERRAIN_{t}',0,d) for t,d in spec.get('terrain_defense', {}).items()]
        assert Counter(tuple(r) for r in db.execute(
            'SELECT TerrainType,Attack,Defense FROM UnitPromotions_TerrainModifiers WHERE PromotionType=?', (lineage,)
        )) == Counter(expected_terrain), stem
        assert {r[0] for r in db.execute(
            'SELECT TerrainType FROM UnitPromotions_Terrains WHERE PromotionType=? AND DoubleMove=1', (lineage,)
        )} == {f'TERRAIN_{terrain}' for terrain in spec.get('terrain_move', [])}, stem
        assert Counter(tuple(r) for r in db.execute(
            'SELECT PromotionType,FeatureType,Defense,DoubleMove FROM UnitPromotions_Features WHERE PromotionType LIKE ?',
            (promotion+'_%',)
        )) == Counter((promotion+'_'+suffix,'FEATURE_'+feature,defense,move)
                      for suffix,feature,defense,move in spec.get('features', [])), stem
        for active in spec.get('free_promotions', []):
            row = db.execute('SELECT RangedDefenseMod,LostWithUpgrade FROM UnitPromotions WHERE Type=?',(active,)).fetchone()
            assert row and row[0] > 0 and row[1] == 0, active
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
    for speed in ('QUICK','STANDARD','EPIC','MARATHON'):
        for spec in ROSTER:
            if speed in ('QUICK','EPIC') and spec['id'] != 31:
                continue
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



def check_art(db, declared):
    originals = set()
    for spec in ROSTER:
        stem = 'CWC3_' + code(spec)
        civ = 'CIVILIZATION_' + stem
        art = ROOT/spec['folder']/'Art'
        assert tuple(db.execute('SELECT IconAtlas,AlphaIconAtlas,PortraitIndex FROM Civilizations WHERE Type=?',(civ,)).fetchone()) == (
            stem+'_CIV_ATLAS',stem+'_ALPHA_ATLAS',0)
        assert tuple(db.execute('SELECT UnitFlagAtlas,UnitFlagIconOffset FROM Units WHERE Type=?',('UNIT_'+stem,)).fetchone()) == (
            stem+'_ALPHA_ATLAS',0)
        for name in ('Emblem','Alpha'):
            source=art/'Sources'/f'{name}.png'
            with Image.open(source) as im:
                assert im.size==(1024,1024) and im.getchannel('A').getextrema()==(0,255), source
            digest=hashlib.sha256(source.read_bytes()).digest()
            assert digest not in originals, source
            originals.add(digest)
        for kind in ('CIV','ALPHA'):
            atlas=stem+'_'+kind+'_ATLAS'
            actual=[(int(size),name,int(columns),int(rows)) for size,name,columns,rows in db.execute(
                'SELECT IconSize,Filename,IconsPerRow,IconsPerColumn FROM IconTextureAtlases WHERE Atlas=? ORDER BY IconSize DESC',
                (atlas,))]
            assert actual==[(size,f'{stem}_{kind}_{size}.dds',1,1) for size in SIZES], atlas
            for _,name,_,_ in actual:
                assert declared[(art/name).relative_to(ROOT).as_posix()].get('import')=='1'
                if kind=='ALPHA':
                    with Image.open(art/name) as im:
                        low, high = im.getchannel('A').getextrema()
                        # At 16px, downsampling narrow strokes may leave only near-opaque pixels.
                        assert low == 0 and high >= 250, (name, low, high)
                        assert all(r==g==b==255 for r,g,b,a in im.getdata() if a), name
    return f'PASS {len(originals)} distinct emblem/alpha sources, {18*len(ROSTER)} DDS atlas registrations and VFS imports'


if __name__ == '__main__':
    from build_mod import ORDER
    with clean_fixture() as db:
        for path in ORDER:
            db.executescript((ROOT/path).read_text(encoding='utf-8'))
        print(check_database(db))
        for result in check_lua(db):
            print(result)
