"""Generate native ModBuddy files from the pack's existing manifest."""
from pathlib import Path
from xml.etree import ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
PROJECT_ID='8d8f6fc0-e6d8-4b4a-ac36-7dedede8675d'
PROJECT_NAME='CoolWackyCivs3'
NS='http://schemas.microsoft.com/developer/msbuild/2003'
BOOLEAN_KEYS={'AffectsSavedGames','SupportsSinglePlayer','SupportsMultiplayer',
              'SupportsHotSeat','SupportsMac','ReloadAudioSystem',
              'ReloadLandmarkSystem','ReloadStrategicViewSystem','ReloadUnitSystem'}


def write_project(manifest):
    """Keep the inventory, VFS flags and ordered actions identical to Python builds."""
    ET.register_namespace('', NS)
    def tag(name): return '{'+NS+'}'+name
    def value(parent, name, text, **attributes):
        node=ET.SubElement(parent, tag(name), attributes)
        node.text=text
        return node
    project=ET.Element(tag('Project'), DefaultTargets='Deploy', ToolsVersion='4.0')
    group=ET.SubElement(project, tag('PropertyGroup'))
    for prop in manifest.find('Properties'):
        text=('true' if prop.text=='1' else 'false') if prop.tag in BOOLEAN_KEYS else prop.text
        value(group, prop.tag, text)
    for name,text in {
        'Guid':manifest.get('id'), 'ProjectGuid':'{'+PROJECT_ID.upper()+'}',
        'ModVersion':manifest.get('version'), 'SafeName':'Cool Wacky Civs 3',
        'AssemblyName':PROJECT_NAME, 'RootNamespace':PROJECT_NAME, 'Stability':'Alpha',
    }.items(): value(group, name, text)
    value(group, 'Civ5UserPath', "$(USERPROFILE)\\Documents\\My Games\\Sid Meier's Civilization 5",
          Condition=" '$(Civ5UserPath)' == '' ")
    value(group, 'Configuration', 'Default', Condition=" '$(Configuration)' == '' ")
    actions=ET.SubElement(group, tag('ModActions'))
    for path in manifest.findall('Actions/OnModActivated/UpdateDatabase'):
        action=ET.SubElement(actions, tag('Action'))
        for name,text in [('Set','OnModActivated'),('Type','UpdateDatabase'),('FileName',path.text)]:
            value(action, name, text)
    content=ET.SubElement(group, tag('ModContent'))
    for entry in manifest.findall('EntryPoints/EntryPoint'):
        item=ET.SubElement(content, tag('Content'))
        for name,text in [('Type',entry.get('type')),('Name',entry.findtext('Name')),
                          ('Description',entry.findtext('Description')),('FileName',entry.get('file'))]:
            value(item, name, text)
    for section,property_name in [('Dependencies','ModDependencies'),('References','ModReferences'),('Blocks','ModBlockers')]:
        associations=ET.SubElement(group, tag(property_name))
        for dependency in manifest.find(section):
            association=ET.SubElement(associations, tag('Association'))
            for name,text in [('Type',dependency.tag),('Name',dependency.get('title')),
                              ('Id',dependency.get('id')),('MinVersion',dependency.get('minversion')),
                              ('MaxVersion',dependency.get('maxversion'))]:
                value(association, name, text)
    for configuration in ['Default','Deploy Only','Package Only']:
        settings=ET.SubElement(project, tag('PropertyGroup'),
                              Condition=f" '$(Configuration)' == '{configuration}' ")
        value(settings, 'OutputPath', '.')
    items=ET.SubElement(project, tag('ItemGroup'))
    directories=set()
    for entry in manifest.findall('Files/File'):
        item=ET.SubElement(items, tag('Content'), Include=entry.text)
        value(item, 'ImportIntoVFS', 'True' if entry.get('import')=='1' else 'False')
        directories.update(parent for parent in Path(entry.text).parents if parent!=Path('.'))
    folders=ET.SubElement(project, tag('ItemGroup'))
    for directory in sorted(directories):
        ET.SubElement(folders, tag('Folder'), Include=str(directory).replace('/','\\')+'\\')
    ET.SubElement(project, tag('Import'),
                  Project='$(MSBuildExtensionsPath)\\Firaxis\\ModBuddy\\Civ5Mod.targets')
    ET.indent(project, space='  ')
    (ROOT/(PROJECT_NAME+'.civ5proj')).write_bytes(
        ET.tostring(project, encoding='utf-8', xml_declaration=True))

    guid='{'+PROJECT_ID.upper()+'}'
    lines=[
        'Microsoft Visual Studio Solution File, Format Version 11.00',
        '# ModBuddy Solution File, Format Version 11.00',
        f'Project("{{F5FC21B5-7CC2-458A-ABBA-992F515BBA20}}") = "{PROJECT_NAME}", "Wacky3\\{PROJECT_NAME}.civ5proj", "{guid}"',
        'EndProject', 'Global',
        '\tGlobalSection(SolutionConfigurationPlatforms) = preSolution',
    ]
    configurations=['Default','Deploy Only','Package Only']
    lines.extend(f'\t\t{config}|x86 = {config}|x86' for config in configurations)
    lines.extend(['\tEndGlobalSection','\tGlobalSection(ProjectConfigurationPlatforms) = postSolution'])
    for config in configurations:
        lines.extend([f'\t\t{guid}.{config}|x86.ActiveCfg = {config}|x86',
                      f'\t\t{guid}.{config}|x86.Build.0 = {config}|x86'])
    lines.extend(['\tEndGlobalSection','\tGlobalSection(SolutionProperties) = preSolution',
                  '\t\tHideSolutionNode = FALSE','\tEndGlobalSection','EndGlobal',''])
    (ROOT.parent/(PROJECT_NAME+'.civ5sln')).write_bytes('\n'.join(lines).encode('utf-8'))
