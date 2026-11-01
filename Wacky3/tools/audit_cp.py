"""Verify pinned CP151 source evidence. --fetch downloads the ignored references."""
import argparse, hashlib, json, urllib.request
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def audit(fetch=False):
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
    player=source['CvPlayer.cpp']; post=player[player.index('void CvPlayer::doTurnPostDiplomacy()'):]
    checks['PlayerDoTurn is after city yields and research']=post.index('pLoopCity->doTurn();') < post.index('doResearch();') < post.index('"PlayerDoTurn"')
    game=source['CvGame.cpp']; turn=game[game.index('void CvGame::doTurn()'):]
    checks['NewGameTurn precedes sequential player activation']=turn.index('PublishNewGameTurn') < turn.index('setTurnActive(true)')
    assert all(checks.values()),checks
    return {'commit':manifest['commit'], 'source_files_verified':len(source), 'checks':checks,
            'ui_dispatch_synchrony':'NOT established by DLL source; manual in-game acceptance required'}

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__); parser.add_argument('--fetch',action='store_true')
    print(json.dumps(audit(parser.parse_args().fetch),indent=2))
