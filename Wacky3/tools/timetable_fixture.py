"""Verified native Worker/Workshop sample data; does not repin the target schema.

The two expansion unit data files add Worker companion rows. Other selected
inputs are already in the existing 260-file pin. None is a CP balance cache.
"""
import hashlib
import json
from xml.etree import ElementTree as ET
from baseline import ROOT, quote
from target_schema import installations, LAYERS, row_values

EXTRA_DATA_HASHES = {
    'bnw:DLC/Expansion/Gameplay/XML/Units/CIV5Units_Expansion.xml':
        '87779b3f57b7b87395ed6be93992e56f3956fa1df8646aebd96e7c49573d3f27',
    'bnw:DLC/Expansion2/Gameplay/XML/Units/CIV5Units_Expansion2.xml':
        '4251334eea66007794a612390a87d177e7f8bd7f660c1d21e2b95ff3e2cd89c9',
}


def add_samples(db, parents=None):
    assets, _ = installations()
    pins = json.loads((ROOT/'tools/cp151_schema_sources.json').read_text())['sources']
    pins = {**pins, **EXTRA_DATA_HASHES}
    parents = parents or {'UnitType':'UNIT_WORKER', 'BuildingType':'BUILDING_WORKSHOP'}
    samples = {}
    for layer in LAYERS:
        layer_rows = {}
        for path in sorted((assets/layer).rglob('*.xml')):
            used = False
            for data in ET.parse(path).getroot():
                if data.tag == 'Table': continue
                for row in data.findall('Row'):
                    values = row_values(row)
                    key = next((k for k,v in parents.items() if values.get(k)==v), None)
                    if key or values.get('Type') in parents.values():
                        group = values.get(key) if key else values['Type']
                        layer_rows.setdefault((data.tag,group), []).append(values)
                        used = True
            if used:
                name = 'bnw:'+path.relative_to(assets).as_posix()
                assert name in pins and hashlib.sha256(path.read_bytes()).hexdigest()==pins[name], ('Unverified Timetable data fixture source',name)
        samples.update(layer_rows)
    for (table,_),rows in samples.items():
        columns = {r[1] for r in db.execute('PRAGMA table_info('+quote(table)+')')}
        assert columns, ('Sample table must exist in pinned schema',table)
        for row in rows:
            values = {k:(int(v.lower()=='true') if v.lower() in ['true','false'] else v)
                      for k,v in row.items() if k in columns and k!='ID'}
            db.execute('INSERT INTO '+quote(table)+'('+','.join(map(quote,values))+') VALUES ('+','.join('?' for _ in values)+')',tuple(values.values()))
    # Worker selection sounds live outside the gameplay data layers, already
    # hashed by the core schema workflow.
    audio = assets/'Sounds/XML/UnitGameplay.xml'
    assert hashlib.sha256(audio.read_bytes()).hexdigest()==pins['bnw:Sounds/XML/UnitGameplay.xml']
    for row in ET.parse(audio).getroot().findall('UnitGameplay2DScripts/Row'):
        values = row_values(row)
        if values.get('UnitType')==parents['UnitType']:
            db.execute('INSERT INTO UnitGameplay2DScripts('+','.join(map(quote,values))+') VALUES ('+','.join('?' for _ in values)+')',tuple(values.values()))
