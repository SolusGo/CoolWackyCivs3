"""Derive the BNW + standalone CP151 schema from pinned installed declarations.

Caches are never schema authorities. --pin records source hashes after an explicit
source audit; normal generators/checks fail if those sources or inventory change.
The clean fixture has native XML sample rows, not a recreated CP gameplay cache.
"""
import argparse
import hashlib
import json
import os
import re
import sqlite3
from functools import lru_cache
from pathlib import Path
from xml.etree import ElementTree as ET
from baseline import ROOT, USER, CP_ID, quote

PIN = ROOT/'tools/cp151_schema_sources.json'
LAYERS = ['Gameplay/XML', 'DLC/Expansion/Gameplay/XML', 'DLC/Expansion2/Gameplay/XML']


def installations():
    cp = Path(os.environ.get('CWC3_CP_DIR', USER/'MODS/(1) Community Patch'))
    game = os.environ.get('CWC3_GAME_DIR')
    if not game:
        steam = Path(os.environ.get('ProgramFiles(x86)', 'C:/Program Files (x86)'))/'Steam'
        libraries = [steam]
        vdf = steam/'steamapps/libraryfolders.vdf'
        if vdf.exists():
            libraries += [Path(p.replace('\\\\', '\\')) for p in re.findall(r'"path"\s*"([^"]+)"', vdf.read_text())]
        candidates = [p/"steamapps/common/Sid Meier's Civilization V" for p in libraries]
        game = next((p for p in candidates if (p/'Assets/DLC/Expansion2').is_dir()), None)
    assert game, 'Set CWC3_GAME_DIR to the installed BNW game directory'
    return Path(game)/'Assets', cp


def uncomment(text):
    # Preserve quoted comment markers, including SQL strings containing '--'.
    return re.sub(r"'(?:''|[^'])*'|\"(?:\"\"|[^\"])*\"|--[^\n]*|/\*.*?\*/",
                  lambda m: ' ' if m[0].startswith(('--','/*')) else m[0], text, flags=re.S)


def statements(text):
    pending = ''
    for piece in uncomment(text).split(';'):
        pending += piece+';'
        if sqlite3.complete_statement(pending):
            if pending.strip(' ;\r\n\t'): yield pending.strip()
            pending = ''
    assert not pending.strip(' ;\r\n\t'), 'Incomplete source SQL'


def literal(value):
    if value.upper() == 'NULL': return 'NULL'
    if value.lower() in ['true','false']: return '1' if value.lower()=='true' else '0'
    return "'"+value.replace("'", "''")+"'"


def create_table(db, table):
    columns = []
    for col in table:
        assert col.tag == 'Column', ('Unhandled XML schema element', col.tag)
        value = quote(col.get('name'))+' '+col.get('type','text')
        if col.get('primarykey') == 'true':
            value += ' PRIMARY KEY'
            if col.get('autoincrement') == 'true': value += ' AUTOINCREMENT'
        if col.get('notnull') == 'true': value += ' NOT NULL'
        if col.get('unique') == 'true': value += ' UNIQUE'
        if col.get('default') is not None: value += ' DEFAULT '+literal(col.get('default'))
        if col.get('reference'): value += ' REFERENCES '+col.get('reference')
        columns.append(value)
    db.execute('CREATE TABLE '+quote(table.get('name'))+'('+','.join(columns)+')')


def companion_tables(db, prefix, column):
    """Call only with the source-derived target schema, never an arbitrary cache."""
    result = []
    for (name,) in db.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name").fetchall():
        if not (name.startswith(prefix) or (prefix=='Unit_' and name=='UnitGameplay2DScripts')): continue
        columns = [r[1] for r in db.execute('PRAGMA table_info('+quote(name)+')')]
        if column in columns: result.append(name)
    return result


def row_values(row):
    return {**row.attrib, **{c.tag: c.text or '' for c in row}}


def derive():
    assets, cp = installations()
    sources, definitions, samples = {}, {}, {}
    parents = {'UnitType': {'UNIT_SPEARMAN','UNIT_SWORDSMAN'},
               'BuildingType': {'BUILDING_LIBRARY','BUILDING_AMPHITHEATER','BUILDING_GRANARY'},
               'CivilizationType': {'CIVILIZATION_AMERICA'}, 'LeaderType': {'LEADER_WASHINGTON'}}
    types = set().union(*parents.values(), {'CIVILIZATION_VENICE'})
    catalogs = {'Flavors','MajorCivApproachTypes','MinorCivApproachTypes','IconTextureAtlases'}
    def record(path, origin):
        name = path.relative_to(assets if origin=='bnw' else cp).as_posix()
        sources[origin+':'+name] = hashlib.sha256(path.read_bytes()).hexdigest()
    # Later expansion declarations supersede earlier definitions of the same table.
    # Sample data is restricted to native rows used by Wacky3 and their companions.
    for layer in LAYERS:
        layer_rows = {}
        for path in sorted((assets/layer).rglob('*.xml')):
            root = ET.parse(path).getroot()
            used = False
            for table in root.findall('Table'):
                if table.get('name'):
                    definitions[table.get('name')] = table; used = True
            for data in root:
                if data.tag=='Table': continue
                for row in data.findall('Row'):
                    values = row_values(row)
                    key = next((k for k, allowed in parents.items() if values.get(k) in allowed), None)
                    if data.tag in catalogs or values.get('Type') in types or key:
                        group = values.get(key) if key else values.get('Type', data.tag)
                        layer_rows.setdefault((data.tag, group), []).append(values); used = True
            if used: record(path,'bnw')
        samples.update(layer_rows)
    db = sqlite3.connect(':memory:')
    for name, table in sorted(definitions.items()): create_table(db, table)
    # Native selection sounds have their own schema outside Gameplay/XML.
    audio = assets/'Sounds/XML/UnitGameplay.xml'
    record(audio,'bnw')
    audio_root = ET.parse(audio).getroot()
    for table in audio_root.findall('Table'): create_table(db,table)
    for row in audio_root.findall('UnitGameplay2DScripts/Row'):
        values=row_values(row)
        if values.get('UnitType') in parents['UnitType']:
            samples[('UnitGameplay2DScripts',values['UnitType'])]=[values]
    localization = assets/'SQL/Civ5LocalizationDatabaseSchema.sql'
    record(localization,'bnw')
    for statement in statements(localization.read_text(encoding='utf-8-sig')):
        if re.match(r'CREATE TABLE Language_en_US\b', statement, re.I): db.execute(statement)
    manifests = list(cp.glob('*.modinfo'))
    manifest = next(p for p in manifests if ET.parse(p).getroot().get('id')==CP_ID)
    root = ET.parse(manifest).getroot()
    assert root.get('version')=='151', 'CP151 package required'
    record(manifest,'cp151')
    record(cp/'Database Changes/NewCustomModOptions.xml','cp151')
    declared = {e.text.replace('\\','/'): e.get('md5') for e in root.findall('Files/File')}
    actions = [e.text.replace('\\','/') for e in root.findall('Actions/OnModActivated/UpdateDatabase')]
    # Apply ALL schema declarations in actual activation order, including table
    # replacement/rename and indexes/triggers. DML is deliberately not replayed:
    # this is a schema fixture, not a replacement for native CP data loading.
    for name in actions:
        path = cp/name
        # Installed CP151 manifest typo: the matching .sql contains localization
        # UPDATEs only. Do not repair the external package or invent its .xml.
        if name == 'Database Changes/Text/en_US/CoreGameOptionTextChanges.xml' and not path.exists():
            continue
        content = path.read_text(encoding='utf-8-sig')
        if path.suffix=='.xml':
            tables = ET.fromstring(re.sub(r'<!--.*?-->', '', content, flags=re.S)).findall('Table')
            ddl = []
        else:
            tables = []
            ddl = [s for s in statements(content) if re.match(r'(CREATE|ALTER|DROP)\s',s,re.I)] if re.search(r'\b(CREATE|ALTER|DROP)\s',content,re.I) else []
        if not tables and not ddl: continue
        assert hashlib.md5(path.read_bytes()).hexdigest().upper()==declared[name].upper(), ('Modified CP package source',name)
        record(path,'cp151')
        for table in tables: create_table(db,table)
        for statement in ddl: db.execute(statement)
    assert not db.execute("SELECT name FROM sqlite_temp_master").fetchone(), 'CP schema temporary table leak'
    inventory = {}
    for prefix, column in [('Building_','BuildingType'),('Unit_','UnitType')]:
        for table in companion_tables(db,prefix,column):
            inventory[table] = [dict(zip(['name','type','notnull','default','pk'], r[1:])) for r in db.execute('PRAGMA table_info('+quote(table)+')')]
    db.commit()
    return db, samples, {'sources':dict(sorted(sources.items())), 'companions':dict(sorted(inventory.items())),
                         'basis':'Installed BNW XML + standalone CP151 manifest-ordered XML/SQL DDL; no cache schema',
                         'cp_source_commit':json.loads((ROOT/'tools/cp151_sources.json').read_text())['commit']}


@lru_cache(maxsize=1)
def verified():
    db, samples, evidence = derive()
    expected = json.loads(PIN.read_text(encoding='utf-8'))
    assert evidence == expected, 'Target schema/source hash changed; audit before updating tools/target_schema.py --pin'
    return db, samples, evidence


def schema_database():
    target, _, _ = verified()
    copy = sqlite3.connect(':memory:'); target.backup(copy)
    copy.row_factory = sqlite3.Row
    return copy


def approved_companions(prefix, column):
    target, _, _ = verified()
    return companion_tables(target, prefix, column)


def clean_fixture():
    db = schema_database()
    _, samples, _ = verified()
    # Native XML sample rows are test inputs, not a claim to reproduce final CP
    # data values. All parent scalars still clone the ACTIVE game row at mod load.
    for (table, _), rows in samples.items():
        columns = {r[1] for r in db.execute('PRAGMA table_info('+quote(table)+')')}
        if not columns: continue
        for row in rows:
            values = {k:(int(v.lower()=='true') if v.lower() in ['true','false'] else v)
                      for k,v in row.items() if k in columns and k!='ID'}
            # No columns or tables are invented to accommodate data samples.
            db.execute('INSERT INTO '+quote(table)+'('+','.join(map(quote,values))+') VALUES ('+','.join('?' for _ in values)+')',tuple(values.values()))
    # Data-only extension, independently hashed; never changes the schema pin or
    # the authoritative companion inventory used by any SQL generator.
    from timetable_fixture import add_samples
    add_samples(db)
    add_samples(db, {'UnitType':'UNIT_PIKEMAN', 'BuildingType':'BUILDING_TEMPLE'})
    from paleo_fixture import add_samples as add_paleo_samples
    add_paleo_samples(db)
    _, cp = installations()
    for row in ET.parse(cp/'Database Changes/NewCustomModOptions.xml').iter('Row'):
        if row.get('Name'):
            values = row_values(row)
            db.execute('INSERT INTO CustomModOptions('+','.join(map(quote,values))+') VALUES ('+','.join('?' for _ in values)+')',tuple(values.values()))
    db.commit()
    return db


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pin',action='store_true',help='Record deliberately audited installed sources/inventory')
    args=parser.parse_args()
    if args.pin:
        db, _, evidence = derive()
        PIN.write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf-8',newline='\n')
    else:
        db=clean_fixture(); evidence=verified()[2]
    print(f"Verified schema: {len(evidence['sources'])} source hashes; {len(evidence['companions'])} unit/building companion tables")
