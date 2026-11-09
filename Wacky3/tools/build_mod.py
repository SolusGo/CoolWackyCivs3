"""Regenerate the one pack manifest and optionally create an installable folder ZIP."""
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib, argparse, zipfile
ROOT=Path(__file__).resolve().parents[1]
NAME='Cool Wacky Civs 3 (v 1).modinfo'
MOD_ID='70d794f7-4fb2-4196-9709-8193f8ee36a9'
ORDER=['Shared/SQL/CWC3_Options.sql']+['TheMinistryOfAlmost/SQL/Ministry_'+kind+'.sql' for kind in ['Civilization','Units','Buildings','Text','Art']]
ORDER += ['TheHollowChoir/SQL/Choir_'+kind+'.sql' for kind in ['Civilization','Units','Buildings','Text']]
ORDER += ['TheSeventeenthSummer/SQL/Summer_'+kind+'.sql' for kind in ['Civilization','Units','Buildings','Text']]
ORDER += ['ThePerpetualTimetable/SQL/Timetable_'+kind+'.sql' for kind in ['Civilization','Units','Buildings','Text','Art']]
ORDER += ['TheCandlekeepersCovenant/SQL/Covenant_'+kind+'.sql' for kind in ['Civilization','Units','Buildings','Text','Art']]
ORDER += ['ThePaleontologicalDirectorate/SQL/PALEO_'+kind+'.sql' for kind in ['Civilization','Units','Buildings','Text','Art']]
ENTRY='TheMinistryOfAlmost/Lua/CWC3_Almost.xml'
ENTRIES=[(ENTRY,'Always the Challenger','Ministry owner-turn snapshots and Second Wind defensive veterans.'),
         ('TheHollowChoir/Lua/CWC3_Choir.xml','Songs Beneath Stone','Hollow Choir terrain yields and capture cleanup.'),
         ('TheSeventeenthSummer/Lua/CWC3_Summer.xml','The Great Emergence','Save-backed Summer cycle, brood veterans and Nursery yields.'),
         ('ThePerpetualTimetable/Lua/CWC3_Timetable.xml','The Grand Schedule','Ordinary Capital connections and continuous owned railway city yields.'),
         ('TheCandlekeepersCovenant/Lua/CWC3_Covenant.xml','The Names We Carry','Save-backed permanent city destruction ledger, memory yields and Eternal Vigil.'),
         ('ThePaleontologicalDirectorate/Lua/PALEO_Gameplay.xml','The Earth Remembers','Library/University class yields and save-backed successful excavation rewards.')]

def files():
    return sorted(p for p in ROOT.rglob('*') if p.is_file() and
                  p.relative_to(ROOT).parts[0] not in ['tools','dist'] and 'Sources' not in p.relative_to(ROOT).parts
                  and p.name!=NAME and p.suffix in ['.sql','.lua','.xml','.dds','.md','.json'])

def build(package=False):
    root=ET.Element('Mod',id=MOD_ID,version='1'); props=ET.SubElement(root,'Properties')
    values={'Name':'Cool Wacky Civs 3','Teaser':"The Ministry of Almost, The Hollow Choir, The Seventeenth Summer, The Perpetual Timetable, The Candlekeeper's Covenant and The Paleontological Directorate.",
      'Description':'Independent human-only civilization pack for BNW + Community Patch v151. Science, Culture, defensive recovery and railway infrastructure.',
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
        imported=path.suffix in ['.dds','.lua'] or path.name in ['CWC3_LeaderScene.xml','CWC3_Timetable_LeaderScene.xml','CWC3_Covenant_LeaderScene.xml','PALEO_LeaderScene.xml']
        ET.SubElement(entries,'File',{'md5':hashlib.md5(path.read_bytes()).hexdigest().upper(),'import':'1' if imported else '0'}).text=path.relative_to(ROOT).as_posix()
    actions=ET.SubElement(ET.SubElement(root,'Actions'),'OnModActivated')
    for path in ORDER: ET.SubElement(actions,'UpdateDatabase').text=path
    points=ET.SubElement(root,'EntryPoints')
    for path,name,description in ENTRIES:
        entry=ET.SubElement(points,'EntryPoint',type='InGameUIAddin',file=path)
        ET.SubElement(entry,'Name').text=name
        ET.SubElement(entry,'Description').text=description
    ET.indent(root,space='  ')
    (ROOT/NAME).write_bytes(ET.tostring(root,encoding='utf-8',xml_declaration=True))
    if package:
        dest=ROOT/'dist/Cool Wacky Civs 3 (v 1).zip'; dest.parent.mkdir(exist_ok=True)
        with zipfile.ZipFile(dest,'w',zipfile.ZIP_DEFLATED) as out:
            for p in files()+[ROOT/NAME]: out.write(p,'Cool Wacky Civs 3 (v 1)/'+p.relative_to(ROOT).as_posix())
        print(dest)
    print(f'Manifest: {len(files())} files, {len(ORDER)} database actions, {len(ENTRIES)} gameplay contexts')
if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__); parser.add_argument('--package',action='store_true')
    build(parser.parse_args().package)
