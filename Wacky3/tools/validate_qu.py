"""Qu-specific database, Lua, artwork and pinned CP151 contracts."""
from collections import Counter
from hashlib import sha256
import json
from xml.etree import ElementTree as ET

from lupa.lua51 import LuaRuntime
from PIL import Image

from baseline import ROOT, quote
from build_qu_art import ART, SCENES
from generate_qu import BUILDING, CASTES, CIV, LEADER, PREFIX, PROMOTION, UNIT
from target_schema import approved_companions

EXTRA_SOURCES = {
    'QuCvGameCoreStructs.cpp': ('CvGameCoreDLL_Expansion2/CvGameCoreStructs.cpp',
                               'f9db846e35c2983ca71db5d8634c69eac5b01329de6205f606c2f9eba491b0b3'),
    'QuCvDatabaseUtility.cpp': ('CvGameCoreDLL_Expansion2/CvDatabaseUtility.cpp',
                                'b8c6a24149675e05b76f1e5615d998119668107505594750190f875557659ac3'),
    'QuDiploCorner.lua': ('(1)%20Community%20Patch/LUA/DiploCorner.lua',
                          '8c434e52d449b34ebb3b45c1df22156259594caaec41dfed3c30cc7fe17b8f29'),
}


def check_source():
    ref = ROOT / 'tools/reference'
    for filename, (_, digest) in EXTRA_SOURCES.items():
        assert sha256((ref / filename).read_bytes()).hexdigest() == digest, filename

    def source(name):
        return (ref / name).read_text(encoding='utf-8-sig')

    def ordered(body, *fragments):
        start = 0
        for fragment in fragments:
            start = body.index(fragment, start) + len(fragment)

    def body(name, signature):
        content = source(name)
        start = content.index(signature)
        return content[start:content.index('\n}', start)]

    structs = body('QuCvGameCoreStructs.cpp', 'void CvCombatInfo::setUnit(')
    assert 'BATTLE_JOINED(unit, unitType, false)' in structs
    for name in ('GenerateMeleeCombatInfo(CvUnit&', 'GenerateRangedCombatInfo(CvUnit&', 'GenerateAirCombatInfo(CvUnit&'):
        generate = body('CvUnitCombat.cpp', 'void CvUnitCombat::' + name)
        ordered(generate, 'BATTLE_STARTED(', 'setUnit(BATTLE_UNIT_ATTACKER, &kAttacker)',
                'setUnit(BATTLE_UNIT_DEFENDER, pkDefender)')
        for strength in ('GetMaxDefenseStrength', 'GetRangeCombatDamage'):
            if strength in generate:
                assert generate.index('setUnit(BATTLE_UNIT_DEFENDER, pkDefender)') < generate.index(strength)
    attack = body('CvUnit.cpp', 'int CvUnit::GetMaxAttackStrength(')
    ordered(attack, 'pDefender->getDamage() + iAssumeExtraOtherDamage > 0', 'attackWoundedModifier()')
    assert 'getDefenseModifier(bQuickAndDirty)' in body('CvUnit.cpp', 'int CvUnit::GetMaxDefenseStrength(')
    ordered(body('CvUnit.cpp', 'int CvUnit::setDamage('), 'if(IsDead())', 'kill(true, ePlayer)',
            'DoUnitKilledCombat(NULL, getOwner(), getUnitType())')
    assert '!IsCombatUnit() && !IsCanAttackRanged() && !canNuke()' in body('CvUnit.cpp', 'bool CvUnit::IsCivilianUnit(')
    for method in ('IsCombatUnit', 'IsCanAttackRanged', 'CanNuke'):
        assert f'Method({method});' in source('CvLuaUnit.cpp')
    ordered(body('CvPlayer.cpp', 'void CvPlayer::DoUnitKilledCombat('),
            'Push(GetID())', 'Push(eKilledPlayer)', 'Push(eUnitType)', '"UnitKilledInCombat"')
    ordered(body('CvPlayer.cpp', 'CvCity* CvPlayer::acquireCity('),
            'args->Push(eOldOwner)', 'args->Push(iCityX)', 'args->Push(iCityY)',
            'args->Push(GetID())', 'args->Push(bConquest)', '"CityCaptureComplete"')
    assert 'GAMEEVENT_TeamSetEra, GetID(), GetCurrentEra()' in source('CvTeam.cpp')
    assert '"SetPopulation"' in body('CvCity.cpp', 'void CvCity::setPopulation(')
    assert 'SetYields(m_piYieldModifier, "Building_YieldModifiers"' in source('CvBuildingClasses.cpp')
    assert 'const int value = pResults->GetInt(1);\n\t\tpArray[idx] = value;' in source('QuCvDatabaseUtility.cpp')
    assert 'changeYieldRateModifier(eYield, (pBuildingInfo->GetYieldModifier(eYield) * iChange))' in source('CvCity.cpp')
    ordered(body('CvCity.cpp', 'int CvCity::getYieldRateTimes100('),
            'iBaseYield * getBaseYieldRateModifier', 'iModifiedYield /= 100',
            'GetPostModifierYieldRateTimes100', 'getGrowthMods(')
    assert 'iYield -= iFoodConsumption' in body('CvCity.cpp', 'int CvCity::GetPostModifierYieldRateTimes100(')
    assert 'LuaEvents.AdditionalInformationDropdownGatherEntries(additionalEntries)' in source('QuDiploCorner.lua')
    return 'PASS: CP151 attribution, pre-damage roles and defense, ownership, signed fixed-point yields, era/population hooks and add-in menu'


def fetch_sources():
    from urllib.request import urlretrieve

    commit = json.loads((ROOT / 'tools/cp151_sources.json').read_text(encoding='utf-8'))['commit']
    ref = ROOT / 'tools/reference'
    ref.mkdir(exist_ok=True)
    for filename, (source, digest) in EXTRA_SOURCES.items():
        temporary = ref / (filename + '.download')
        urlretrieve(f'https://raw.githubusercontent.com/LoneGazebo/Community-Patch-DLL/{commit}/{source}', temporary)
        assert sha256(temporary.read_bytes()).hexdigest() == digest, source
        temporary.replace(ref / filename)


def check_database(db):
    def row(table, code):
        result = db.execute(f'SELECT * FROM {table} WHERE Type=?', (code,)).fetchone()
        assert result is not None, (table, code)
        return result

    civ = row('Civilizations', CIV)
    assert (civ['Playable'], civ['AIPlayable']) == (1, 0)
    assert row('Leaders', LEADER)['ArtDefineTag'] == 'CWC3_Qu_LeaderScene.xml'
    assert db.execute('SELECT LeaderheadType FROM Civilization_Leaders WHERE CivilizationType=?', (CIV,)).fetchone()[0] == LEADER
    assert db.execute('SELECT Text FROM Language_en_US WHERE Tag=?', (PREFIX+'CITY_1',)).fetchone()[0] == 'Genesis Spire'
    for table, prefix, column, parent, unique, override, class_col in (
        ('Units','Unit_','UnitType','UNIT_RIFLEMAN',UNIT,'UnitClass','Class'),
        ('Buildings','Building_','BuildingType','BUILDING_WORKSHOP',BUILDING,'BuildingClass','BuildingClass'),
    ):
        native, actual = row(table, parent), row(table, unique)
        allowed = {'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex',
                   'UnitFlagAtlas','UnitFlagIconOffset'}
        assert all(native[key] == actual[key] for key in native.keys() if key not in allowed), unique
        assigned = db.execute(f'SELECT {column} FROM Civilization_{override}Overrides '
                              f'WHERE CivilizationType=? AND {override}Type=?', (CIV, native[class_col])).fetchone()
        assert assigned[0] == unique
        for companion in approved_companions(prefix, column):
            cols = [r[1] for r in db.execute(f'PRAGMA table_info({quote(companion)})')
                    if r[1] not in (column, 'ID')]
            fields = ','.join(map(quote, cols))
            query = f'SELECT {fields} FROM {quote(companion)} WHERE {quote(column)}=?'
            inherited = Counter(tuple(r) for r in db.execute(query, (parent,)))
            if companion == 'Unit_FreePromotions':
                inherited[(PROMOTION,)] += 1
            assert inherited == Counter(tuple(r) for r in db.execute(query, (unique,))), companion
    assert db.execute('SELECT UnitClassType FROM Unit_ClassUpgrades WHERE UnitType=?', (UNIT,)).fetchone()
    permanent = row('UnitPromotions', PROMOTION)
    scoped = row('UnitPromotions', 'PROMOTION_CWC3_QU_BIOLOGICAL_DEFENSE')
    assert (permanent['AttackWoundedMod'], permanent['LostWithUpgrade'], permanent['DefenseMod']) == (15,0,0)
    assert (scoped['AttackWoundedMod'], scoped['LostWithUpgrade'], scoped['DefenseMod']) == (0,1,15)
    for suffix in (*CASTES, 'FOUNDRY_1', 'FOUNDRY_2'):
        name = 'BUILDING_CWC3_QU_' + suffix
        dummy = row('Buildings', name)
        for col, val in dict(Cost=-1, FaithCost=-1, GoldMaintenance=0, NeverCapture=1,
                             ConquestProb=0, IsDummy=1, ShowInPedia=0, GreatWorkCount=-1).items():
            assert dummy[col] == val, (suffix,col)
        mods = dict(db.execute('SELECT YieldType,Yield FROM Building_YieldModifiers WHERE BuildingType=?', (name,)))
        base = dict(db.execute('SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType=?', (name,)))
        if suffix in CASTES:
            assert mods == {'YIELD_'+key: value for key, value in CASTES[suffix].items()}
            assert not base
        else:
            assert not mods and base == {'YIELD_SCIENCE': int(suffix[-1])}
    return 'PASS: active Rifleman/Workshop clones, upgrade path, promotion roles, signed local modifiers and hidden Foundry tiers'


def check_lua():
    lua = LuaRuntime()
    source = ROOT / 'TheQu/Lua'
    def include(name):
        path = source / f'{name}.lua'
        if not path.exists():
            path = ROOT / 'Shared/Lua' / f'{name}.lua'
        lua.execute(path.read_text(encoding='utf-8'), name=str(path))
    lua.globals().include = include
    lua.execute((ROOT / 'tools/tests/qu.lua').read_text(encoding='utf-8'))
    return 'PASS: 3 speed/load/turn runs, native-event mocks, city lifecycle, Foundry thresholds, scoped defense and UI confirmation'


def check_art(db, declared):
    results = {}
    for name, size in SCENES.items():
        filename = f'CWC3_Qu_{name}.dds'
        assert Image.open(ART / filename).size == size
        assert declared[f'TheQu/Art/{filename}'].get('import') == '1'
    scene = 'CWC3_Qu_LeaderScene.xml'
    assert ET.parse(ART / scene).getroot().get('FallbackImage') == 'CWC3_Qu_Diplomacy.dds'
    assert declared[f'TheQu/Art/{scene}'].get('import') == '1'
    for kind in ('CIV','LEADER','UNIT','FOUNDRY','ALPHA','FLAG'):
        atlas = f'CWC3_QU_{kind}_ATLAS'
        sizes = {r[0] for r in db.execute('SELECT IconSize FROM IconTextureAtlases WHERE Atlas=?', (atlas,))}
        assert sizes == ({32} if kind == 'FLAG' else {16,24,32,45,48,64,80,128,256}), (atlas,sizes)
        results[kind] = len(sizes)
    return f'PASS: {sum(results.values())} atlas sizes, Dawn, map and static diplomacy'


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--fetch', action='store_true')
    if parser.parse_args().fetch:
        fetch_sources()
    print(check_source())
    print(check_lua())
