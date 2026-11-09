"""Additional hash-pinned data samples and CP151 archaeology/research evidence.

No schema changes, no fabricated final CP gameplay data. --fetch refreshes ignored
DLL reference files using the exact audited commit and checks their hashes.
"""
import argparse
import hashlib
import json
import re
import urllib.request
from xml.etree import ElementTree as ET
from baseline import ROOT, quote
from target_schema import installations, LAYERS, row_values

PIN = ROOT/'tools/paleo_sources.json'
PARENTS = {'UnitType':'UNIT_ARCHAEOLOGIST','BuildingType':'BUILDING_MUSEUM',
           'BuildType':'BUILD_ARCHAEOLOGY_DIG','ImprovementType':'IMPROVEMENT_ARCHAEOLOGICAL_DIG'}
TYPES = set(PARENTS.values()) | {'UNITCLASS_ARCHAEOLOGIST','BUILDINGCLASS_MUSEUM'}


def add_samples(db):
    assets, _ = installations()
    pins = json.loads(PIN.read_text(encoding='utf-8'))['native_data']
    samples = {}
    for layer in LAYERS:
        layer_rows = {}
        for path in sorted((assets/layer).rglob('*.xml')):
            used = False
            for data in ET.parse(path).getroot():
                if data.tag == 'Table': continue
                for row in data.findall('Row'):
                    values = row_values(row)
                    key = next((k for k,v in PARENTS.items() if values.get(k)==v),None)
                    if key or values.get('Type') in TYPES:
                        group = values.get(key) if key else values['Type']
                        layer_rows.setdefault((data.tag,group),[]).append(values); used = True
            if used:
                name = path.relative_to(assets).as_posix()
                assert hashlib.sha256(path.read_bytes()).hexdigest()==pins[name], ('Changed PALEO native fixture',name)
        samples.update(layer_rows)
    for (table,_),rows in samples.items():
        columns = {r[1] for r in db.execute('PRAGMA table_info('+quote(table)+')')}
        assert columns, ('Sample table absent from CP151 inventory',table)
        for row in rows:
            values = {k:(int(v.lower()=='true') if v.lower() in ['true','false'] else v) for k,v in row.items() if k in columns and k!='ID'}
            db.execute('INSERT INTO '+quote(table)+'('+','.join(map(quote,values))+') VALUES ('+','.join('?' for _ in values)+')',tuple(values.values()))
    audio = assets/'Sounds/XML/UnitGameplay.xml'
    assert hashlib.sha256(audio.read_bytes()).hexdigest()==pins['Sounds/XML/UnitGameplay.xml']
    for row in ET.parse(audio).getroot().findall('UnitGameplay2DScripts/Row'):
        values = row_values(row)
        if values.get('UnitType')==PARENTS['UnitType']:
            db.execute('INSERT INTO UnitGameplay2DScripts('+','.join(map(quote,values))+') VALUES ('+','.join('?' for _ in values)+')',tuple(values.values()))


def source_checks(fetch=False):
    pins = json.loads(PIN.read_text(encoding='utf-8'))
    refs = ROOT/'tools/reference'
    for name, entry in pins['dll'].items():
        path = refs/name
        if fetch: path.write_bytes(urllib.request.urlopen(entry['url'],timeout=45).read())
        assert path.exists(), f'Missing {path}; run python tools/paleo_fixture.py --fetch'
        assert hashlib.sha256(path.read_bytes()).hexdigest()==entry['sha256'], ('Changed CP151 source',name)
    # Existing core audit verifies these source files before this additional audit.
    from audit_cp import audit
    audit()
    text = {name:(refs/name).read_text(encoding='utf-8-sig') for name in
            ['CvUnit.cpp','CvPlot.cpp','CvCultureClasses.cpp','CvLuaTeamTech.cpp','CvTechClasses.cpp','CvLuaPlayer.cpp','CvPlayer.cpp','CustomMods.h','CvBuildingClasses.cpp','CvDllNetMessageHandler.cpp','CvLuaCity.cpp','CvLuaUnit.cpp','CvLuaPlot.cpp','CvLuaTeam.cpp','CvLuaGame.cpp']}
    def body(file, signature):
        source=text[file]; start=source.index(signature)
        return source[start:source.index('\n}',start)+2]
    build=body('CvUnit.cpp','bool CvUnit::build(')
    progress=body('CvPlot.cpp','bool CvPlot::changeBuildProgress(')
    assert 'bFinished = pPlot->changeBuildProgress(eBuild, iWorkRateWithMoves, getOwner(), NewBuild)' in build
    assert build.index('if(bFinished)') < build.index('GAMEEVENTINVOKE_HOOK(GAMEEVENT_PlayerBuilt') < build.index('else // we are not done doing this')
    assert 'GAMEEVENT_PlayerBuilt, getOwner(), GetID(), getX(), getY(), eBuild' in build
    assert progress.index('if(getBuildProgress(eBuild) >= getBuildTime(eBuild, ePlayer))') < progress.index('AddDigCompletePlot(this)') < progress.index('bFinished = true') < progress.index('"BuildFinished"')
    assert 'GetArchaeologicalRecord().m_eArtifactType != NO_GREAT_WORK_ARTIFACT_CLASS' in progress
    assert 'if (kPlayer.isHuman(ISHUMAN_AI_TOURISM))' in progress
    choice=body('CvCultureClasses.cpp','void CvPlayerCulture::DoArchaeologyChoice(')
    assert all(s in choice for s in ['case ARCHAEOLOGY_LANDMARK:','case ARCHAEOLOGY_ARTIFACT_PLAYER1:','case ARCHAEOLOGY_ARTIFACT_PLAYER2:','pUnit->kill(true)'])
    archaeologist=body('CvCultureClasses.cpp','CvUnit *CvPlayerCulture::GetNextDigCompleteArchaeologist(')
    assert 'AI_getUnitAIType() == UNITAI_ARCHAEOLOGIST' in archaeologist and 'getUnitType()' not in archaeologist
    assert 'Method(ChangeResearchProgress)' in text['CvLuaTeamTech.cpp']
    research=body('CvTechClasses.cpp','void CvTeamTechs::SetResearchProgressTimes100(')
    assert 'changeOverflowResearchTimes100((int)iOverflow)' in research and 'm_pTeam->setHasTech(eIndex, true, ePlayer, true, true)' in research
    assert 'BasicLuaMethod(L, &CvTeamTechs::ChangeResearchProgress)' in text['CvLuaTeamTech.cpp']
    assert 'Method(ChangeOverflowResearch)' in text['CvLuaPlayer.cpp']
    assert 'changeOverflowResearchTimes100(iChange * 100)' in body('CvPlayer.cpp','void CvPlayer::changeOverflowResearch(')
    assert 'visitor(player.m_iOverflowResearch)' in text['CvPlayer.cpp']
    assert 'visitor(player.m_strScriptData)' in text['CvPlayer.cpp']
    for filename, methods in {
        'CvLuaCity.cpp':['GetOwner','GetNumRealBuilding','SetNumRealBuilding','GetNumFreeBuilding','SetNumFreeBuilding','GetX','GetY'],
        'CvLuaUnit.cpp':['GetOwner','GetUnitType','GetX','GetY'],
        'CvLuaPlot.cpp':['GetImprovementType','GetArchaeologyArtifactType','GetPlotCity'],
        'CvLuaPlayer.cpp':['IsAlive','IsHuman','GetCivilizationType','GetCityByID','GetUnitByID','GetScriptData','SetScriptData','GetCurrentResearch','GetTeam','GetOverflowResearchTimes100','ChangeOverflowResearch'],
        'CvLuaTeam.cpp':['GetTeamTechs'], 'CvLuaGame.cpp':['GetGameSpeedType'],
    }.items():
        for method in methods:
            assert re.search(r'\bMethod\(\s*'+method+r'\s*\)',text[filename]),(filename,method)
    sale=body('CvDllNetMessageHandler.cpp','void CvDllNetMessageHandler::ResponseSellBuilding(')
    assert sale.index('DoSellBuilding(eBuilding)') < sale.index('GAMEEVENTINVOKE_HOOK(GAMEEVENT_CitySoldBuilding')
    assert 'SetNumRealBuilding(eIndex, 0)' in body('CvBuildingClasses.cpp','void CvCityBuildings::DoSellBuilding(')
    assert 'if(!buildingEntry->IsDummy())' in text['CvBuildingClasses.cpp']
    return 'PASS: pinned CP151 successful build branch, exact finishing-unit event, human archaeology queue/choice lifetime, native research completion and serialized overflow'


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__); parser.add_argument('--fetch',action='store_true')
    print(source_checks(parser.parse_args().fetch))
