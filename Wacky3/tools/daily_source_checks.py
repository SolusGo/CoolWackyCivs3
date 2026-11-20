"""Review expansion contracts against the same pinned CP151 source set."""
from baseline import ROOT


def check_source():
    refs = ROOT/'tools/reference'

    def code(name):
        return (refs/name).read_text(encoding='utf-8-sig')

    def body(source, signature):
        start = source.index(signature)
        return source[start:source.index('\n}', start)+2]

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
    return ('PASS: pinned CP151 city and treasury/research order, WLTKD transitions, '
            'movement store, reveal source, garrison and Marsh feature contracts')
