"""Summer active-row inheritance and production-controller Lua 5.1 regressions."""
from collections import Counter
from lupa.lua51 import LuaRuntime
from baseline import ROOT, quote
from target_schema import approved_companions
from generate_seventeenth_summer import CIV, LEADER, UNIT, NURSERY, LINEAGE, AWAKENED, PREFIX, DUMMIES
from generate_summer_ui import generated


def check_database(db):
    civ = db.execute('SELECT * FROM Civilizations WHERE Type=?',(CIV,)).fetchone()
    assert (civ['Playable'],civ['AIPlayable']) == (1,0)
    assert db.execute('SELECT LeaderheadType FROM Civilization_Leaders WHERE CivilizationType=?',(CIV,)).fetchone()[0] == LEADER
    for table,old,new,prefix,column in [('Units','UNIT_SPEARMAN',UNIT,'Unit_','UnitType'),
                                       ('Buildings','BUILDING_GRANARY',NURSERY,'Building_','BuildingType')]:
        a=db.execute('SELECT * FROM '+table+' WHERE Type=?',(old,)).fetchone()
        b=db.execute('SELECT * FROM '+table+' WHERE Type=?',(new,)).fetchone()
        for key in a.keys():
            if key in {'ID','Type','Description','Civilopedia','Help','Strategy'}: continue
            expected = a[key]+1 if table=='Units' and key=='BaseSightRange' else a[key]
            assert b[key] == expected, (table,key,a[key],b[key])
        for companion in approved_companions(prefix,column):
            cols=[r[1] for r in db.execute('PRAGMA table_info('+quote(companion)+')') if r[1] not in [column,'ID']]
            query='SELECT '+','.join(map(quote,cols))+' FROM '+quote(companion)+' WHERE '+quote(column)+'=?'
            original=Counter(tuple(r) for r in db.execute(query,(old,)))
            unique=Counter(tuple(r) for r in db.execute(query,(new,)))
            if companion=='Unit_FreePromotions':
                assert unique[(LINEAGE,)]==1
                unique.subtract({(LINEAGE,):1}); unique=+unique
            if companion=='Building_YieldChanges':
                expected=Counter((r[0],r[1]+1) if r[0]=='YIELD_FAITH' else r for r in original.elements())
                if not any(r[0]=='YIELD_FAITH' for r in original): expected[('YIELD_FAITH',1)]+=1
                assert unique==expected,(companion,unique,expected)
            else: assert unique==original,(companion,original-unique,unique-original)
    for suffix,kind,amount in DUMMIES:
        typ='BUILDING_SUMMER_'+suffix
        b=db.execute('SELECT * FROM Buildings WHERE Type=?',(typ,)).fetchone()
        for k,v in dict(Cost=-1,FaithCost=-1,GoldMaintenance=0,GreatWorkCount=-1,IsDummy=1,ShowInPedia=0,NeverCapture=1,ConquestProb=0).items():
            assert b[k]==v,(typ,k)
        assert [tuple(r) for r in db.execute('SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType=?',(typ,))]==[('YIELD_'+kind,amount)]
    for typ,expected in [(LINEAGE,dict(CannotBeChosen=1,LostWithUpgrade=0,ShowInUnitPanel=0,IsVisibleAboveFlag=0,CombatPercent=0)),
                         (AWAKENED,dict(CannotBeChosen=1,LostWithUpgrade=1,LostOnGifting=1,CombatPercent=20,AttackMod=0,DefenseMod=0))]:
        row=db.execute('SELECT * FROM UnitPromotions WHERE Type=?',(typ,)).fetchone()
        for k,v in expected.items(): assert row[k]==v,(typ,k)
    assert [r[0] for r in db.execute('SELECT UnitType FROM Unit_FreePromotions WHERE PromotionType=?',(LINEAGE,))]==[UNIT]
    assert db.execute('SELECT UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=? AND UnitClassType=?',(CIV,'UNITCLASS_SPEARMAN')).fetchone()[0]==UNIT
    assert db.execute('SELECT BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=? AND BuildingClassType=?',(CIV,'BUILDINGCLASS_GRANARY')).fetchone()[0]==NURSERY
    assert db.execute('SELECT Text FROM Language_en_US WHERE Tag=?',(PREFIX+'CITY_1',)).fetchone()[0]=='First Emergence'
    assert {tuple(r) for r in db.execute('SELECT * FROM CWC3_SummerCycles')} == {
        ('GAMESPEED_QUICK',9,3),('GAMESPEED_STANDARD',13,4),('GAMESPEED_EPIC',20,6),('GAMESPEED_MARATHON',39,12)}
    for ending in ['CIV5_HEADING_1','CIV5_TEXT_1','CIV5_FACTOID_TEXT','IXA_NAME','IXA_SUBTITLE','IXA_LIVED','IXA_HEADING_1','IXA_TEXT_1']:
        assert db.execute('SELECT 1 FROM Language_en_US WHERE Tag=?',(PREFIX+ending,)).fetchone()
    for (response,) in db.execute('SELECT Response FROM Diplomacy_Responses WHERE LeaderType=?',(LEADER,)):
        assert db.execute('SELECT 1 FROM Language_en_US WHERE Tag LIKE ?',(response,)).fetchone(),response
    for table in ['Civilization_FreeUnits','Civilization_FreeTechs','Civilization_FreeBuildingClasses']:
        cols=[r[1] for r in db.execute('PRAGMA table_info('+table+')') if r[1]!='CivilizationType']
        query='SELECT '+','.join(map(quote,cols))+' FROM '+table+' WHERE CivilizationType=?'
        assert Counter(tuple(r) for r in db.execute(query,(CIV,)))==Counter(tuple(r) for r in db.execute(query,('CIVILIZATION_AMERICA',)))
    return 'PASS: human-only registration, active Spearman/Granary scalars and all companions, Sight/Faith deltas, four controllers, promotions, overrides, starts and localization'


def check_lua():
    results=[]
    for speed,dormant,emerged in [('QUICK',9,3),('STANDARD',13,4),('EPIC',20,6),('MARATHON',39,12)]:
        lua=LuaRuntime(); logs=[]
        lua.globals().print=lambda *a:logs.append(' '.join(map(str,a)))
        lua.globals().include=lambda n:lua.execute((ROOT/'Shared/Lua'/f'{n}.lua').read_text(encoding='utf-8'))
        lua.globals().LoadSummer=lambda:lua.execute((ROOT/'TheSeventeenthSummer/Lua/SummerGameplay.lua').read_text(encoding='utf-8'))
        lua.globals().Speed=speed; lua.globals().Dormant=dormant; lua.globals().Emerged=emerged
        lua.execute((ROOT/'tools/tests/seventeenth_summer.lua').read_text(encoding='utf-8'))
        for line in logs: print(line)
        results.extend(logs)
    for name,expected in generated().items():
        actual=(ROOT/'TheSeventeenthSummer/UI'/name).read_text(encoding='utf-8')
        assert actual==expected,('Only the pinned ancestry filter may differ from CP151 UI',name)
        # Run the actual promotion-rendering function independently of native UI.
        start=actual.index('function UpdateUnitPromotions(')
        end=actual.index('\nend',start)+4
        code=actual[start:end]
        if name=='UnitPanel.lua': code=code.replace('g_EarnedPromotionIM','MockManager')
        lua=LuaRuntime()
        lua.execute("""
        local promotions={{ID=1,Type='PROMOTION_SUMMER_BROOD_LINEAGE'}, {ID=2,Type='PROMOTION_SUMMER_AWAKENED'}}
        GameInfo={UnitPromotions=function() local i=0; return function() i=i+1; return promotions[i] end end}
        Icons={}; IconHookup=function(index,size,atlas,control) Icons[#Icons+1]=control end
        Locale={ConvertTextKey=function() return '' end}
        MockManager={ResetInstances=function() end,GetInstance=function() return {UnitPromotionImage={SetToolTipString=function() end}} end}
        Controls={}
        for i=1,3 do
          local c={hidden=true}; function c:SetHide(v) self.hidden=v end; function c:IsHidden() return self.hidden end
          Controls['UnitPromotion'..i]=c
        end
        MockUnit={IsHasPromotion=function() return true end,IsTrade=function() return false end}
        """)
        lua.execute(code)
        lua.execute('UpdateUnitPromotions(MockUnit); assert(#Icons==1,"lineage hidden, Awakened visible")')
    results.append('PASS: pinned CP151 panels hide lineage and retain the visible Awakened icon')
    return results
