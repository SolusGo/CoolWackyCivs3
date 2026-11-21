"""Review expansion contracts against the same pinned CP151 source set."""
from baseline import ROOT


def check_source():
    refs = ROOT/'tools/reference'

    def code(name):
        return (refs/name).read_text(encoding='utf-8-sig')

    def body(source, signature):
        start = source.index(signature)
        return source[start:source.index('\n}', start)+2]

    def ordered(source, *fragments):
        cursor = 0
        for fragment in fragments:
            cursor = source.index(fragment, cursor) + len(fragment)

    city = code('CvCity.cpp')
    city_turn = body(city, 'void CvCity::doTurn(')
    assert city_turn.index('doProduction(') < city_turn.index('DoTestResourceDemanded()')
    day_change = body(city, 'void CvCity::ChangeWeLoveTheKingDayCounter(')
    assert day_change.index('m_iWeLoveTheKingDayCounter += iChange') < day_change.index('GAMEEVENT_CityBeginsWLTKD')
    day = body(city, 'void CvCity::DoTestResourceDemanded(')
    assert day.index('ChangeWeLoveTheKingDayCounter(-1)') < day.index('GAMEEVENT_CityEndsWLTKD')
    players = code('CvPlayer.cpp')
    owner_turn = body(players, 'void CvPlayer::doTurnPostDiplomacy(')
    assert owner_turn.index('pLoopCity->doTurn()') < owner_turn.index('GetTreasury()->DoGold()') < owner_turn.index('doResearch()')
    assert 'pLoopUnit->restoreFullMoves()' in body(players, 'void CvPlayer::DoUnitReset(')
    assert 'setMoves( maxMoves() )' in body(code('CvUnit.cpp'), 'void CvUnit::restoreFullMoves(')
    assert 'lGetMoves' in code('CvLuaUnit.cpp') and 'lSetMoves' in code('CvLuaUnit.cpp')
    reveals = body(code('CvPlot.cpp'), 'bool CvPlot::setRevealed(')
    assert 'bNewValue && bRevealed' in reveals
    assert 'eFromTeam' in reveals and '(pUnit ? pUnit->getOwner() : NO_PLAYER)' in reveals
    assert '(pUnit ? pUnit->GetID() : -1)' in reveals
    assert 'pLoopUnit->CanGarrison()' in body(code('CvPlot.cpp'), 'CvUnit* CvPlot::getBestGarrison(')
    assert 'GetNumUnits' in code('CvLuaPlot.cpp')
    promotion = code('CvPromotionClasses.cpp')
    assert 'UnitPromotions_Features' in promotion and 'm_pbFeatureDoubleMove[iFeatureID] = bDoubleMove' in promotion
    assert 'featureDefenseModifier(pInPlot->getFeatureType())' in code('CvUnit.cpp')
    # No settlement-stage debt interception: both paths credit their final
    # current yield before completion hooks, which report the result afterward.
    production = body(city, 'void CvCity::doProduction(')
    ordered(production, 'getYieldRateTimes100(YIELD_PRODUCTION) + getTotalOverflowProductionTimes100()',
            'setOverflowProduction(0)', 'setFeatureProduction(0)', 'popOrder(0, !isProductionProcess(), true)')
    assert 'changeOverflowProductionTimes100(getYieldRateTimes100(YIELD_PRODUCTION))' in production
    assert 'GAMEEVENTINVOKE' not in production and 'CallHook' not in production
    orders = body(city, 'void CvCity::popOrder(')
    for item in ('eTrainUnit','eConstructBuilding','eCreateProject'):
        assert 'produce('+item in orders
    research = body(players, 'void CvPlayer::doResearch(')
    ordered(research, 'getOverflowResearchTimes100()', 'setOverflowResearch(0)',
            'GetScienceTimes100() + iOverflowResearch', 'ChangeResearchProgressTimes100')
    assert 'GAMEEVENTINVOKE' not in research and 'CallHook' not in research
    ordered(owner_turn, 'pLoopCity->doTurn()', 'GetTreasury()->DoGold()', 'doResearch()', '"PlayerDoTurn"')
    tech = body(code('CvTechClasses.cpp'), 'void CvTeamTechs::SetResearchProgressTimes100(')
    ordered(tech, 'if (iOverflow >= 0)', 'changeOverflowResearchTimes100', 'setHasTech')
    assert 'pLoopCity->getYieldRateTimes100(YIELD_SCIENCE' in body(players,'int CvPlayer::GetScienceFromCitiesTimes100(')
    assert 'changeYieldRateModifier(eYield, (pBuildingInfo->GetYieldModifier(eYield) * iChange))' in city
    assert 'iBaseYield * getBaseYieldRateModifier' in body(city,'int CvCity::getYieldRateTimes100(YieldTypes eYield')

    unit = code('CvUnit.cpp')
    combat = code('CvUnitCombat.cpp')
    resolve = body(combat,'void CvUnitCombat::ResolveCombat(')
    ordered(resolve, '"MustAbortAttack"', '"CombatResult"', 'ResolveRangedUnitVsCombat', '"CombatEnded"')
    air = body(combat,'void CvUnitCombat::GenerateAirCombatInfo(')
    ordered(air, 'setDamageInflicted(BATTLE_UNIT_INTERCEPTOR, iInterceptionDamage)', 'if (iInterceptionDamage > 0)',
            'setFinalDamage(BATTLE_UNIT_ATTACKER, 0)', 'return;')
    sweep = body(combat,'void CvUnitCombat::GenerateAirSweepCombatInfo(')
    ordered(sweep, 'if(pkDefender->getDomainType() != DOMAIN_AIR)',
            'setDamageInflicted(BATTLE_UNIT_DEFENDER, iInterceptionDamage)')
    ranged = body(combat,'void CvUnitCombat::ResolveRangedUnitVsCombat(')
    assert 'DoAdjacentPlotDamage' in ranged and 'DoExtraPlotDamage' in ranged
    splash = body(unit,'int CvUnit::DoAdjacentPlotDamage(')
    assert 'pEnemyUnit->changeDamage(iValue, getOwner()' in splash
    assert 'getDamage() >= GetMaxHitPoints()' in body(unit,'bool CvUnit::IsDead()')
    ordered(body(unit,'int CvUnit::setDamage('),'m_iDamage =','if(IsDead())','kill(true, ePlayer)')
    ordered(body(unit,'void CvUnit::kill('),'GAMEEVENT_UnitPrekill', 'startDelayedDeath()')
    assert '"GameCoreUpdateEnd"' in code('CvGame.cpp')
    ordered(body(unit,'void CvUnit::convert('),'setMoves(pUnit->getMoves())','GAMEEVENT_UnitConverted','pUnit->kill')
    ordered(body(unit,'void CvUnit::move('), 'embark(pOldPlot)', 'setXY(', 'changeMoves(-iMoveCost)')
    assert 'GD_INT_GET(EMBARKED_UNIT_MOVEMENT)' in unit
    ordered(body(players,'void CvPlayer::setTurnActive('),'GAMEEVENT_PlayerDoneTurn','DoUnitReset()')
    team = code('CvTeam.cpp')
    ordered(body(team,'void CvTeam::SetAllowsOpenBordersToTeam('),
            'm_abOpenBorders[eIndex] = bNewValue','verifyUnitValidPlot','setDirty(Score_DIRTY_BIT')
    plot = code('CvPlot.cpp')
    ordered(body(plot,'void CvPlot::setFeatureType('),'m_eFeatureType = eNewValue','GAMEEVENT_TileFeatureChanged')
    ordered(body(plot,'void CvPlot::setOwner('),'setOwningCity(eNewValue, iAcquiringCityID)',
            'GAMEEVENT_TileOwnershipChanged','changeAdjacentSight(getTeam()')
    return ('PASS: pinned CP151 settlement and completion, science modifier, reveal source, '
            'air interception and scoped ranged damage, post-calculation combat, '
            'movement stores and callbacks, garrison and terrain change contracts')
