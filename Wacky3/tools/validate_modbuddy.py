"""Check native project wiring and optional actual SDK output against the manifest."""
import argparse
import hashlib
from pathlib import Path
from xml.etree import ElementTree as ET
from build_mod import ROOT, NAME, files, ORDER, ENTRIES
from modbuddy import PROJECT_ID, PROJECT_NAME, NS, BOOLEAN_KEYS

N={'m':NS}


def normalized_path(text):
    return text.replace('\\','/')


def normalized_value(name, text):
    if name in BOOLEAN_KEYS or name=='ImportIntoVFS':
        return '1' if text.lower() in ('1','true') else '0'
    return text


def validate_project():
    manifest=ET.parse(ROOT/NAME).getroot()
    project_path=ROOT/(PROJECT_NAME+'.civ5proj')
    project=ET.parse(project_path).getroot()
    properties=project.find('m:PropertyGroup',N)
    for prop in manifest.find('Properties'):
        assert normalized_value(prop.tag,properties.findtext('m:'+prop.tag,namespaces=N))==prop.text,prop.tag
    assert properties.findtext('m:Guid',namespaces=N)==manifest.get('id')
    assert properties.findtext('m:ModVersion',namespaces=N)==manifest.get('version')
    assert properties.findtext('m:ProjectGuid',namespaces=N)=='{'+PROJECT_ID.upper()+'}'
    assert properties.findtext('m:SafeName',namespaces=N)=='Cool Wacky Civs 3'
    assert project.find('m:Import',N).get('Project')=='$(MSBuildExtensionsPath)\\Firaxis\\ModBuddy\\Civ5Mod.targets'

    expected={entry.text:entry.get('import') for entry in manifest.findall('Files/File')}
    assert set(expected)=={path.relative_to(ROOT).as_posix() for path in files()}
    actual={}
    for item in project.findall('m:ItemGroup/m:Content',N):
        path=normalized_path(item.get('Include'))
        assert path not in actual,('duplicate project file',path)
        assert (ROOT/path).is_file(),('missing file',path)
        actual[path]=normalized_value('ImportIntoVFS',item.findtext('m:ImportIntoVFS',namespaces=N))
    assert actual==expected,'Project inventory or VFS flags differ from the manifest'
    actions=[]
    for action in properties.findall('m:ModActions/m:Action',N):
        assert action.findtext('m:Set',namespaces=N)=='OnModActivated'
        assert action.findtext('m:Type',namespaces=N)=='UpdateDatabase'
        actions.append(normalized_path(action.findtext('m:FileName',namespaces=N)))
    assert actions==ORDER==[item.text for item in manifest.findall('Actions/OnModActivated/UpdateDatabase')]
    entries=[]
    for content in properties.findall('m:ModContent/m:Content',N):
        assert content.findtext('m:Type',namespaces=N)=='InGameUIAddin'
        entries.append(tuple(content.findtext('m:'+key,namespaces=N) for key in ['FileName','Name','Description']))
    assert entries==ENTRIES
    for section,property_name in [('Dependencies','ModDependencies'),('References','ModReferences'),('Blocks','ModBlockers')]:
        expected_associations=[(item.tag,item.get('title'),item.get('id'),item.get('minversion'),item.get('maxversion')) for item in manifest.find(section)]
        actual_associations=[tuple(item.findtext('m:'+key,namespaces=N) for key in ['Type','Name','Id','MinVersion','MaxVersion'])
                             for item in properties.findall('m:'+property_name+'/m:Association',N)]
        assert actual_associations==expected_associations,property_name
    solution=(ROOT.parent/(PROJECT_NAME+'.civ5sln')).read_text(encoding='utf-8')
    assert f'"Wacky3\\{PROJECT_NAME}.civ5proj", "{{{PROJECT_ID.upper()}}}"' in solution
    for config in ['Default','Deploy Only','Package Only']:
        assert f'{{{PROJECT_ID.upper()}}}.{config}|x86.Build.0 = {config}|x86' in solution
    return f'PASS: ModBuddy solution/project, {len(actual)} files, {len(actions)} ordered SQL actions, {len(entries)} entry points, exact dependencies and VFS flags'


def validate_built_manifest(path):
    source=ET.parse(ROOT/NAME).getroot()
    built=ET.parse(path).getroot()
    assert built.get('id').lower()==source.get('id') and built.get('version')==source.get('version')
    for prop in source.find('Properties'):
        assert normalized_value(prop.tag,built.findtext('Properties/'+prop.tag))==prop.text,prop.tag
    expected={entry.text:entry for entry in source.findall('Files/File')}
    entries=built.findall('Files/File')
    assert len(entries)==len(expected)
    assert {normalized_path(entry.text) for entry in entries}==set(expected)
    for entry in entries:
        name=normalized_path(entry.text)
        assert entry.get('import')==expected[name].get('import'),('VFS flag',name)
        output=path.parent/name
        assert output.read_bytes()==(ROOT/name).read_bytes(),('SDK file differs',name)
        checksum=hashlib.md5(output.read_bytes()).hexdigest().upper()
        assert entry.get('md5').upper()==checksum==expected[name].get('md5'),('checksum',name)
    assert [normalized_path(entry.text) for entry in built.findall('Actions/OnModActivated/UpdateDatabase')]==ORDER
    assert [(normalized_path(entry.get('file')),entry.get('type'),entry.findtext('Name'),entry.findtext('Description'))
            for entry in built.findall('EntryPoints/EntryPoint')]==[(file,'InGameUIAddin',name,description) for file,name,description in ENTRIES]
    for section in ['Dependencies','References','Blocks']:
        def associations(root):
            # Firaxis omits the DLC display title; IDs/version bounds are retained.
            return [(item.tag,item.get('id').lower(),item.get('minversion'),item.get('maxversion'),
                     item.get('title') if item.tag=='Mod' else None) for item in root.find(section)]
        assert associations(built)==associations(source),section
    return f'PASS: actual SDK manifest and all {len(entries)} output files match the Python inventory and source bytes'


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--built-manifest',type=Path)
    args=parser.parse_args()
    print(validate_project())
    if args.built_manifest:
        print(validate_built_manifest(args.built_manifest))
