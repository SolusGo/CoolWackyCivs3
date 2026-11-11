"""Extra data-only fixture and pinned trade source; no target schema changes."""
import argparse
import hashlib
import json
import urllib.request
from xml.etree import ElementTree as ET
from baseline import ROOT, quote
from target_schema import installations, LAYERS, row_values

PIN=ROOT/'tools/archived_sources.json'
PARENTS={'UnitType':{'UNIT_COMPOSITE_BOWMAN','UNIT_HORSEMAN'},
         'BuildingType':{'BUILDING_CARAVANSARY','BUILDING_WALLS','BUILDING_UNIVERSITY'},
         'ImprovementType':{'IMPROVEMENT_FARM'}}

def add_samples(db):
    assets,_=installations()
    pins=json.loads(PIN.read_text())['native_data']
    samples={}
    types=set.union(*PARENTS.values())
    for layer in LAYERS:
        rows={}
        for path in sorted((assets/layer).rglob('*.xml')):
            used=False
            for data in ET.parse(path).getroot():
                if data.tag=='Table': continue
                for row in data.findall('Row'):
                    values=row_values(row)
                    key=next((k for k,v in PARENTS.items() if values.get(k) in v),None)
                    if key or values.get('Type') in types:
                        group=values.get(key) if key else values['Type']
                        rows.setdefault((data.tag,group),[]).append(values); used=True
            if used:
                name=path.relative_to(assets).as_posix()
                assert hashlib.sha256(path.read_bytes()).hexdigest()==pins[name],('Changed archived fixture',name)
        samples.update(rows)
    for (table,_),rows in samples.items():
        columns={r[1] for r in db.execute('PRAGMA table_info('+quote(table)+')')}
        assert columns,table
        for row in rows:
            values={k:(int(v.lower()=='true') if v.lower() in ['true','false'] else v) for k,v in row.items() if k in columns and k!='ID'}
            db.execute('INSERT INTO '+quote(table)+'('+','.join(map(quote,values))+') VALUES ('+','.join('?' for _ in values)+')',tuple(values.values()))
    audio=assets/'Sounds/XML/UnitGameplay.xml'
    assert hashlib.sha256(audio.read_bytes()).hexdigest()==pins['Sounds/XML/UnitGameplay.xml']
    for row in ET.parse(audio).getroot().findall('UnitGameplay2DScripts/Row'):
        values=row_values(row)
        if values.get('UnitType') in PARENTS['UnitType']:
            db.execute('INSERT INTO UnitGameplay2DScripts('+','.join(map(quote,values))+') VALUES ('+','.join('?' for _ in values)+')',tuple(values.values()))

def source_checks(fetch=False):
    from audit_cp import audit
    audit()
    ref=ROOT/'tools/reference'
    entry=json.loads(PIN.read_text())['trade_source']; path=ref/'CvTradeClasses.cpp'
    if fetch: path.write_bytes(urllib.request.urlopen(entry['url'],timeout=45).read())
    assert hashlib.sha256(path.read_bytes()).hexdigest()==entry['sha256'],'Trade source pin'
    text={n:(ref/n).read_text(encoding='utf-8-sig') for n in ['CvUnit.cpp','CvUnitCombat.cpp','CvTradeClasses.cpp','CvLuaPlayer.cpp','CvLuaUnit.cpp','CvLuaCity.cpp','CvLuaPlot.cpp','CvLuaTeam.cpp','CvLuaMap.cpp','CvPromotionClasses.cpp','CustomMods.h','CvPlot.cpp']}
    def body(file,signature):
        t=text[file]; start=t.index(signature); return t[start:t.index('\n}',start)+2]
    combat=body('CvUnitCombat.cpp','void CvUnitCombat::ResolveCombat(')
    assert combat.index('"CombatResult"')<combat.index('ResolveMeleeCombat(kInfo')<combat.index('"CombatEnded"')
    assert combat.index('if (bCanAttack && MOD_EVENTS_RED_COMBAT_RESULT)')<combat.index('"CombatResult"')
    args=['iAttackingPlayer','iAttackingUnit','attackerDamage','attackerFinalDamage','attackerMaxHP','iDefendingPlayer','iDefendingUnit','defenderDamage','defenderFinalDamage','defenderMaxHP','iInterceptingPlayer','iInterceptingUnit','interceptorDamage','plotX','plotY']
    for section in [combat[:combat.index('"CombatResult"')],combat[combat.index('// RED : CombatEnded'):]]:
        offsets=[section.index('args->Push('+a+')') for a in args]
        assert offsets==sorted(offsets),'Combat argument order'
    for method in ['IsCombatUnit','IsDead','GetGameTurnCreated','GetUnitType','GetOwner','GetX','GetY']:
        assert 'Method('+method+');' in text['CvLuaUnit.cpp']
    for method in ['GetOriginalOwner','GetGameTurnFounded','GetNumBuilding']:
        assert 'Method('+method+');' in text['CvLuaCity.cpp']
    for file,methods in {
        'CvLuaPlayer.cpp':['GetID','GetTeam','GetUnitByID','GetScriptData','SetScriptData','GetCivilizationType','IsAlive','IsHuman','GetTradeRoutes'],
        'CvLuaTeam.cpp':['IsAtWar'],
        'CvLuaMap.cpp':['GetPlot','PlotDirection','PlotDistance'],
        'CvLuaPlot.cpp':['GetPlotIndex','GetImprovementType','IsImprovementPillaged','GetOwner','GetPlotCity'],
    }.items():
        for method in methods: assert 'Method('+method+');' in text[file],(file,method)
    promotion=text['CvPromotionClasses.cpp']; unit=text['CvUnit.cpp']
    assert all('GetInt("'+f+'")' in promotion for f in ['BarbarianCombatBonus','FriendlyLandsModifier','DefenseMod','VisibilityChange'])
    generic=body('CvUnit.cpp','int CvUnit::GetGenericMeleeStrengthModifier(')
    assert 'if(pOtherUnit->isBarbarian())' in generic and 'iModifier += GetBarbarianCombatBonus();' in generic
    assert 'if(pBattlePlot->IsFriendlyTerritory(getOwner()))' in generic and 'iModifier += getFriendlyLandsModifier();' in generic
    attack=body('CvUnit.cpp','int CvUnit::GetMaxAttackStrength(')
    defense=body('CvUnit.cpp','int CvUnit::GetMaxDefenseStrength(')
    ranged=body('CvUnit.cpp','int CvUnit::GetMaxRangedCombatStrength(')
    assert 'getDefenseModifier(' not in attack
    assert 'getDefenseModifier(' in defense and '// Regular defense modifier\n\t\tiModifier += getDefenseModifier' in ranged
    assert 'GetTerrainModifierAttack(pToPlot->getTerrainType())' in attack
    assert 'GetTerrainModifierDefense(pInPlot->getTerrainType())' in defense
    assert 'GetTerrainModifierDefense(pMyPlot->getTerrainType())' in ranged
    assert '//UnitPromotions_TerrainModifiers' in promotion
    assert 'UnitPromotions_TerrainModifiers.Attack, UnitPromotions_TerrainModifiers.Defense' in promotion
    # No MOD_BALANCE_VP guard surrounds the terrain modifier application.
    for fragment in ['ChangeTerrainModifierAttack(((TerrainTypes)iI), (thisPromotion.GetTerrainModifierAttack(iI) * iChange))','ChangeTerrainModifierDefense(((TerrainTypes)iI), (thisPromotion.GetTerrainModifierDefense(iI) * iChange))']:
        assert fragment in unit
    routes=body('CvLuaPlayer.cpp','int CvLuaPlayer::lGetTradeRoutes(')
    for fragment in ['IsTradeRouteIndexEmpty(ui)','pConnection->m_eOriginOwner != pkPlayer->GetID()','"FromCity"','"FromID"','"Domain"','"ToCity"','"ToID"','"IsRecalled"','"CircuitsCompleted"','"CircuitsToComplete"']:
        assert fragment in routes
    make=body('CvUnit.cpp','bool CvUnit::makeTradeRoute(')
    assert make.index('CreateTradeRoute(')<make.index('kill(true)')
    trade=text['CvTradeClasses.cpp']
    end=trade.index('GAMEEVENT_PlayerTradeRouteCompleted,')
    assert trade.index('pTradeConnection->m_iCircuitsCompleted >= pTradeConnection->m_iCircuitsToComplete')<end
    assert end<trade.index('pTrade->ClearTradeRoute(ui);',end)
    plunder=trade.index('GAMEEVENT_PlayerPlunderedTradeRoute,')
    assert trade.rfind('ClearTradeRoute(iTradeConnectionIndex)',0,plunder)>trade.index('bool CvPlayerTrade::PlunderTradeRoute(')
    assert 'GAMEEVENT_TileImprovementChanged, getX(), getY(), getOwner(), getImprovementType(), getImprovementType(), IsImprovementPillaged()' in text['CvPlot.cpp']
    return 'PASS: pinned CP151 combat result/end order and 15 arguments; native promotion consumers; land-route origin/domain/circuit lifecycle; post-create Caravan prekill; total class counts and farm/pillage hooks. Native runtime acceptance NOT RUN.'

if __name__=='__main__':
    p=argparse.ArgumentParser(); p.add_argument('--fetch',action='store_true'); print(source_checks(p.parse_args().fetch))
