"""Read a BNW database and overlay the installed CP151 schema in memory only."""
import os, re, sqlite3
from pathlib import Path
from xml.etree import ElementTree as ET

CP_ID = 'd1b6328c-ff44-4b0d-aad7-c657f83610cd'
ROOT = Path(__file__).resolve().parents[1]
USER = Path.home()/"Documents/My Games/Sid Meier's Civilization 5"
EVIDENCE = {}

def quote(name):
    return '"' + name.replace('"', '""') + '"'

def database():
    cache = Path(os.environ.get('CWC3_DATABASE', USER/'cache_backup/Civ5DebugDatabase.db')).resolve()
    cp = Path(os.environ.get('CWC3_CP_DIR', USER/'MODS/(1) Community Patch'))
    manifests = [ET.parse(p).getroot() for p in cp.glob('*.modinfo')]
    assert any(m.get('id') == CP_ID and m.get('version') == '151' for m in manifests), 'CP v151 required'
    source = sqlite3.connect(cache.as_uri()+'?mode=ro', uri=True)
    d = sqlite3.connect(':memory:'); source.backup(d); source.close()
    assert d.execute("SELECT 1 FROM Civilizations WHERE Type='CIVILIZATION_VENICE'").fetchone(), 'BNW required'
    assert not d.execute("SELECT 1 FROM Civilizations WHERE Type='CIVILIZATION_CWC3_ALMOST'").fetchone(), 'Use a baseline without Wacky3'
    active = 'IsDummy' in {r[1] for r in d.execute('PRAGMA table_info(Buildings)')}
    EVIDENCE.clear()
    reported=cache.relative_to(USER.resolve()).as_posix() if cache.is_relative_to(USER.resolve()) else str(cache)
    EVIDENCE.update(database=reported, installed_cp_version=151,
        mode='existing CP-schema snapshot (not certified CP-only)' if active else 'BNW snapshot with CP151 schema overlay (not active CP data)',
        source_tables=d.execute("SELECT COUNT(*) FROM sqlite_master WHERE type='table'").fetchone()[0],
        source_civilizations=d.execute('SELECT COUNT(*) FROM Civilizations').fetchone()[0])
    for table,typ,fields in [('Buildings','BUILDING_LIBRARY',['Cost','GoldMaintenance','PrereqTech','SpecialistType','SpecialistCount']),
                             ('Units','UNIT_SPEARMAN',['Combat','Moves','Cost','PrereqTech'])]:
        row=d.execute('SELECT '+','.join(fields)+' FROM '+table+' WHERE Type=?',(typ,)).fetchone()
        EVIDENCE[typ]=dict(zip(fields,row))
    # Do not silently overlay a captured active database: missing runtime tables
    # must fail the SQL test rather than being manufactured by the fixture.
    if active:
        d.execute('CREATE TABLE IF NOT EXISTS Language_en_US(Tag TEXT PRIMARY KEY, Text TEXT)')
        d.row_factory = sqlite3.Row
        return d
    # Vanilla caches need CP schema additions. Active CP caches are also accepted.
    for path in sorted((cp/'Database Changes').rglob('*.sql')):
        for statement in re.findall(r'ALTER\s+TABLE\s+[^;]+?\s+ADD\s+.*?;', path.read_text(encoding='utf-8-sig'), re.I|re.S):
            try: d.execute(statement)
            except sqlite3.OperationalError as exc:
                if 'duplicate column name' not in str(exc).lower(): raise
    for path in sorted((cp/'Database Changes').rglob('*.xml')):
        content = re.sub(r'<!--.*?-->', '', path.read_text(encoding='utf-8-sig'), flags=re.S)
        root = ET.fromstring(content)
        for table in root.findall('Table'):
            columns = []
            for col in table.findall('Column'):
                suffix = ''
                if col.get('default') is not None: suffix += " DEFAULT '"+col.get('default').replace("'", "''")+"'"
                if col.get('primarykey') == 'true':
                    suffix += ' PRIMARY KEY'
                    if col.get('autoincrement') == 'true': suffix += ' AUTOINCREMENT'
                columns.append(quote(col.get('name'))+' '+col.get('type', 'text')+suffix)
            if columns: d.execute('CREATE TABLE IF NOT EXISTS '+quote(table.get('name'))+'('+','.join(columns)+')')
    d.execute('CREATE TABLE IF NOT EXISTS CustomModOptions(Name TEXT, Value INTEGER, Class INTEGER, DbUpdates INTEGER)')
    for row in ET.parse(cp/'Database Changes/NewCustomModOptions.xml').iter('Row'):
        if row.get('Name'):
            d.execute('DELETE FROM CustomModOptions WHERE Name=?', (row.get('Name'),))
            d.execute('INSERT INTO CustomModOptions(Name,Value,Class,DbUpdates) VALUES(?,?,?,?)',
                      (row.get('Name'), int(row.get('Value',0)), int(row.get('Class',0)), int(row.get('DbUpdates',0))))
    d.execute('CREATE TABLE IF NOT EXISTS Language_en_US(Tag TEXT PRIMARY KEY, Text TEXT)')
    d.row_factory = sqlite3.Row
    return d
