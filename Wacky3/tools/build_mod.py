"""Regenerate the one pack manifest and optionally create an installable folder ZIP."""
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib, argparse, zipfile
ROOT=Path(__file__).resolve().parents[1]
NAME='Cool Wacky Civs 3 (v 1).modinfo'
MOD_ID='70d794f7-4fb2-4196-9709-8193f8ee36a9'
ORDER=['Shared/SQL/CWC3_Options.sql']+['TheMinistryOfAlmost/SQL/Ministry_'+kind+'.sql' for kind in ['Civilization','Units','Buildings','Text','Art']]
ENTRY='TheMinistryOfAlmost/Lua/CWC3_Almost.xml'

def files():
    return sorted(p for p in ROOT.rglob('*') if p.is_file() and
                  p.relative_to(ROOT).parts[0] not in ['tools','dist'] and 'Sources' not in p.relative_to(ROOT).parts
                  and p.name!=NAME and p.suffix in ['.sql','.lua','.xml','.dds','.md','.json'])

def build(package=False):
    root=ET.Element('Mod',id=MOD_ID,version='1'); props=ET.SubElement(root,'Properties')
    values={'Name':'Cool Wacky Civs 3','Teaser':'The Ministry of Almost: second place inspires another attempt.',
      'Description':'Independent human-only civilization pack for BNW + Community Patch v151. Science, Culture and defensive recovery without permanent stacking.',
      'Authors':'SolusGo','Homepage':'https://github.com/SolusGo/CoolWackyCivs3','AffectsSavedGames':'1',
      'MinCompatibleSaveVersion':'1','SupportsSinglePlayer':'1','SupportsMultiplayer':'0','SupportsHotSeat':'0','SupportsMac':'0',
      'ReloadAudioSystem':'0','ReloadLandmarkSystem':'0','ReloadStrategicViewSystem':'0','ReloadUnitSystem':'0'}
    for k,v in values.items(): ET.SubElement(props,k).text=v
    deps=ET.SubElement(root,'Dependencies')
    ET.SubElement(deps,'Dlc',id='6DA07636-4123-4018-B643-6575B4EC336B',minversion='0',maxversion='999',title='Expansion - Brave New World')
    ET.SubElement(deps,'Mod',id='d1b6328c-ff44-4b0d-aad7-c657f83610cd',minversion='151',maxversion='151',title='(1) Community Patch')
    ET.SubElement(root,'References'); ET.SubElement(root,'Blocks')
    entries=ET.SubElement(root,'Files')
    for path in files():
        imported=path.suffix in ['.dds','.lua'] or path.name=='CWC3_LeaderScene.xml'
        ET.SubElement(entries,'File',{'md5':hashlib.md5(path.read_bytes()).hexdigest().upper(),'import':'1' if imported else '0'}).text=path.relative_to(ROOT).as_posix()
    actions=ET.SubElement(ET.SubElement(root,'Actions'),'OnModActivated')
    for path in ORDER: ET.SubElement(actions,'UpdateDatabase').text=path
    entry=ET.SubElement(ET.SubElement(root,'EntryPoints'),'EntryPoint',type='InGameUIAddin',file=ENTRY)
    ET.SubElement(entry,'Name').text='Always the Challenger'
    ET.SubElement(entry,'Description').text='Ministry owner-turn snapshots and Second Wind defensive veterans.'
    ET.indent(root,space='  ')
    (ROOT/NAME).write_bytes(ET.tostring(root,encoding='utf-8',xml_declaration=True))
    if package:
        dest=ROOT/'dist/Cool Wacky Civs 3 (v 1).zip'; dest.parent.mkdir(exist_ok=True)
        with zipfile.ZipFile(dest,'w',zipfile.ZIP_DEFLATED) as out:
            for p in files()+[ROOT/NAME]: out.write(p,'Cool Wacky Civs 3 (v 1)/'+p.relative_to(ROOT).as_posix())
        print(dest)
    print(f'Manifest: {len(files())} files, {len(ORDER)} database actions, one gameplay context')
if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__); parser.add_argument('--package',action='store_true')
    build(parser.parse_args().package)
