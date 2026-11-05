"""Verify pinned CP151 source evidence. --fetch downloads the ignored references."""
import argparse, hashlib, json, urllib.request, re
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def audit(fetch=False):
    from target_schema import verified
    schema_evidence=verified()[2]
    manifest=json.loads((ROOT/'tools/cp151_sources.json').read_text())
    ref=ROOT/'tools/reference'; ref.mkdir(exist_ok=True)
    source={}
    for name,entry in manifest['files'].items():
        path=ref/name
        if fetch: path.write_bytes(urllib.request.urlopen(entry['url'], timeout=45).read())
        assert path.is_file(), f'Missing {path}; run tools/audit_cp.py --fetch'
        assert hashlib.sha256(path.read_bytes()).hexdigest()==entry['sha256'], f'Source hash mismatch: {name}'
        source[name]=path.read_text(encoding='utf-8-sig')
    checks={
      'DLL identifies as v151':'MOD_DLL_VERSION_NUMBER ((uint) 151)' in source['CustomMods.h'],
      'Team:IsHasTech is registered':'Method(IsHasTech)' in source['CvLuaTeam.cpp'],
      'Team:IsHasTech uses researched state':'GetTeamTechs()->HasTech(eTech)' in source['CvLuaTeam.cpp'],
      'City:SetNumRealBuilding is registered':'Method(SetNumRealBuilding)' in source['CvLuaCity.cpp'],
      'Player ScriptData read/write registered':all('Method('+m+')' in source['CvLuaPlayer.cpp'] for m in ['GetScriptData','SetScriptData']),
      'DefenseMod is read from promotions':'GetInt("DefenseMod")' in source['CvPromotionClasses.cpp'],
      'Defense strength uses defense-only modifier':'iModifier += getDefenseModifier(bQuickAndDirty);' in source['CvUnit.cpp'],
      'Tile ownership callback occurs after ownership assignment':source['CvPlot.cpp'].index('m_eOwner = eNewValue;',source['CvPlot.cpp'].index('void CvPlot::setOwner(')) < source['CvPlot.cpp'].index('GAMEEVENTINVOKE_HOOK(GAMEEVENT_TileOwnershipChanged'),
      'Upgrade conversion preserves non-lost promotions':'(!bIsUpgrade || !pkPromotionInfo->IsLostWithUpgrade())' in source['CvUnit.cpp'],
    }
    def body(filename, signature):
        text=source[filename]; start=text.index(signature)
        return text[start:text.index('\n}',start)+2]
    def binding(filename, names):
        return all(re.search(r'\bMethod\(\s*'+name+r'\s*\)',source[filename]) for name in names)
    checks['Free dummy cleanup bindings']=binding('CvLuaCity.cpp',['GetNumFreeBuilding','SetNumFreeBuilding'])
    checks['Explicit construction reward suppression']='const bool bNoBonus = luaL_optbool(L, 4, true)' in body('CvLuaCity.cpp','int CvLuaCity::lSetNumRealBuilding(')
    checks['Diagnostic player stores exposed']=binding('CvLuaPlayer.cpp',['GetCurrentResearch','GetResearchProgressTimes100','GetJONSCultureEverGeneratedTimes100'])
    checks['Diagnostic city stores exposed']=binding('CvLuaCity.cpp',['GetID','GetX','GetY','GetProductionTimes100','GetProductionUnit','GetProductionBuilding','GetProductionProject'])
    checks['Game turn and active player exposed']=binding('CvLuaGame.cpp',['GetGameTurn','GetActivePlayer'])
    checks['Summer game speed and owner APIs']=binding('CvLuaGame.cpp',['GetGameSpeedType']) and binding('CvLuaPlayer.cpp',['IsHuman','AddNotification'])
    checks['Summer unit reconciliation APIs']=binding('CvLuaUnit.cpp',['GetUnitType','GetID','IsHasPromotion','SetHasPromotion'])
    attack=body('CvUnit.cpp','int CvUnit::GetMaxAttackStrength(')
    generic=body('CvUnit.cpp','int CvUnit::GetGenericMeleeStrengthModifier(')
    checks['Summer CombatPercent promotion source']='GetInt("CombatPercent")' in source['CvPromotionClasses.cpp'] and 'changeExtraCombatPercent(thisPromotion.GetCombatPercent() * iChange)' in source['CvUnit.cpp']
    checks['Summer generic melee combat includes CombatPercent']='int iModifier = getExtraCombatPercent() + GetStrategicResourceCombatPenalty();' in generic
    checks['Summer attack uses generic melee modifier']='GetGenericMeleeStrengthModifier(pDefender, pToPlot, true' in attack
    checks['Melee attack excludes generic defense modifier']='getDefenseModifier(' not in attack
    checks['Choir native promotion fields']=all('GetInt("'+field+'")' in source['CvPromotionClasses.cpp'] for field in ['VisibilityChange','HillsDefense'])
    checks['Choir attack excludes hill defense']='hillsDefenseModifier(' not in attack
    defense=body('CvUnit.cpp','int CvUnit::GetMaxDefenseStrength(')
    checks['Summer defense uses generic melee modifier']='GetGenericMeleeStrengthModifier(pAttacker, pInPlot, false' in defense
    checks['Choir melee hill defense conditional']=bool(re.search(r'if\(pInPlot->isHills\(\)\)\s*iModifier \+= hillsDefenseModifier\(\)',defense))
    checks['Choir terrain Lua bindings']=binding('CvLuaPlot.cpp',['IsHills','IsMountain','GetOwner','GetX','GetY','GetPlotCity'])
    ranged=body('CvUnit.cpp','int CvUnit::GetMaxRangedCombatStrength(')
    checks['Summer ranged CombatPercent precedes attack-defense branches']='int iModifier = getExtraCombatPercent() + GetStrategicResourceCombatPenalty();' in ranged
    checks['Ranged generic defense only in non-attacking branch']=bool(re.search(r'else\s*\{\s*// Regular defense modifier\s*iModifier \+= getDefenseModifier',ranged))
    defending_branch=re.search(r'else\s*\{\s*// City Defense',ranged)
    hill_branch=re.search(r'if \(pMyPlot->isHills\(\)\)\s*iModifier \+= hillsDefenseModifier\(\)',ranged)
    checks['Choir ranged hill defense conditional']=bool(defending_branch and hill_branch and defending_branch.start() < hill_branch.start())
    upgrade=body('CvUnit.cpp','CvUnit* CvUnit::DoUpgradeTo(')
    checks['UnitUpgraded precedes normal conversion']=upgrade.index('GAMEEVENTINVOKE_HOOK(GAMEEVENT_UnitUpgraded') < upgrade.index('pNewUnit->convert(this, true, false)')
    convert=body('CvUnit.cpp','void CvUnit::convert(')
    checks['UnitConverted follows all promotion transfer']=convert.index('setHasPromotion(ePromotion, bGivePromotion)') < convert.index('GAMEEVENTINVOKE_HOOK(GAMEEVENT_UnitConverted')
    checks['UnitConverted exact argument order']='GAMEEVENT_UnitConverted, pUnit->getOwner(),getOwner(), pUnit->GetID(), GetID(), bIsUpgrade' in convert
    checks['Summer conversion repair precedes old unit death']=convert.index('GAMEEVENTINVOKE_HOOK(GAMEEVENT_UnitConverted') < convert.index('pUnit->kill(true, NO_PLAYER)')
    checks['Summer gifts use the same post-transfer conversion']='pGiftUnit->convert(this, false, true)' in body('CvUnit.cpp','void CvUnit::gift(')
    checks['Summer Sight is native unit base plus promotion visibility']='m_pUnitInfo->GetBaseSightRange() + m_iExtraVisibilityRange' in source['CvUnit.cpp'] and 'changeExtraVisibilityRange(thisPromotion.GetVisibilityChange() * iChange)' in source['CvUnit.cpp']
    checks['UnitUpgraded exact argument order']='GAMEEVENT_UnitUpgraded, getOwner(), GetID(), pNewUnit->GetID(), false' in upgrade
    checks['UnitCreated exact argument order']='GAMEEVENT_UnitCreated, getOwner(), GetID(), getUnitType(), getX(), getY()' in source['CvUnit.cpp']
    init=body('CvUnit.cpp','void CvUnit::initWithNameOffset(')
    checks['UnitCreated follows initial free promotions']=init.index('setHasPromotion(') < init.index('GAMEEVENTINVOKE_HOOK(GAMEEVENT_UnitCreated')
    checks['UnitSetXY argument order']=bool(re.search(r'args->Push\(getOwner\(\)\);\s*args->Push\(GetID\(\)\);\s*args->Push\(getX\(\)\);\s*args->Push\(getY\(\)\);\s*bool bResult = false;\s*LuaSupport::CallHook\(pkScriptSystem, "UnitSetXY"',source['CvUnit.cpp']))
    checks['TileOwnershipChanged exact argument order']='GAMEEVENT_TileOwnershipChanged, getX(), getY(), getOwner(), eOldOwner' in source['CvPlot.cpp']
    acquisition=body('CvPlayer.cpp','CvCity* CvPlayer::acquireCity(')
    checks['All city acquisition modes share completion callback']='"CityCaptureComplete"' in acquisition and 'bool bGift' in acquisition and 'args->Push(bConquest)' in acquisition
    checks['Completion follows building copy and ownership changes']=acquisition.index('SetNumRealBuildingTimed') < acquisition.index('ownedPlots[i]->setOwner') < acquisition.index('"CityCaptureComplete"')
    checks['PlayerLiberated exact argument order']='GAMEEVENT_PlayerLiberated, GetID(), ePlayer, pNewCity->GetID()' in source['CvPlayer.cpp']
    checks['CityConstructed purchase flag contract']='GameEvents.CityConstructed.Add(function(iPlayer, iCity, iBuilding, bGold, bFaith)' in source['CustomMods.h']
    founded=body('CvPlayer.cpp','void CvPlayer::foundCity(')
    checks['PlayerCityFounded coordinate contract']=bool(re.search(r'args->Push\(GetID\(\)\);\s*args->Push\(pCity->getX\(\)\);\s*args->Push\(pCity->getY\(\)\);\s*bool bResult = false;\s*LuaSupport::CallHook\(pkScriptSystem, "PlayerCityFounded"',founded))
    sold=body('CvDllNetMessageHandler.cpp','void CvDllNetMessageHandler::ResponseSellBuilding(')
    checks['CitySoldBuilding follows sale']=sold.index('DoSellBuilding') < sold.index('GAMEEVENT_CitySoldBuilding, ePlayer, iCityID, eBuilding')
    player=source['CvPlayer.cpp']; post=player[player.index('void CvPlayer::doTurnPostDiplomacy()'):]
    checks['PlayerDoTurn is after city yields and research']=post.index('pLoopCity->doTurn();') < post.index('doResearch();') < post.index('"PlayerDoTurn"')
    game=source['CvGame.cpp']; turn=game[game.index('void CvGame::doTurn()'):]
    checks['NewGameTurn precedes sequential player activation']=turn.index('PublishNewGameTurn') < turn.index('setTurnActive(true)')
    active=body('CvPlayer.cpp','void CvPlayer::setTurnActive(')
    checks['TURN_START published before owner doTurn']=active.index('PublishPlayerTurnStatus(DLLUIClass::TURN_START') < active.index('\n\t\t\t\t\t\tdoTurn();')
    update=body('CvGame.cpp','void CvGame::update()')
    checks['GameCoreUpdateBegin is per update rather than per owner']='"GameCoreUpdateBegin"' in update and 'getNumGameTurnActive() == 0' in update
    assert all(checks.values()),checks
    return {'commit':manifest['commit'], 'source_files_verified':len(source),
            'schema_source_files_verified':len(schema_evidence['sources']),
            'approved_schema_companions':len(schema_evidence['companions']), 'checks':checks,
            'ui_dispatch_synchrony':'NOT established by DLL source; manual in-game acceptance required',
            'ai_processing_human_boundary':'NOT established; diagnostic-only, never updates snapshots',
            'supported_boundary':'NewGameTurn for actual Ministry owner only when first living sequential player',
            'other_hooks_reviewed':'PlayerDoTurn and ActivePlayerTurnStart are post-economy; GameCoreUpdateBegin is per update and cannot identify each owner boundary without polling/approximating'}

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__); parser.add_argument('--fetch',action='store_true')
    print(json.dumps(audit(parser.parse_args().fetch),indent=2))
