"""Resolve the active civilization presentation through the packaged database."""
from pathlib import Path
from xml.etree import ElementTree as ET

from build_mod import NAME, ORDER, ROOT
from target_schema import clean_fixture

PRESENTATION_FIELDS = {
    'Civilizations': {'IconAtlas','AlphaIconAtlas','PortraitIndex','MapImage','DawnOfManImage'},
    'Leaders': {'IconAtlas','PortraitIndex','ArtDefineTag'},
    'Units': {'IconAtlas','PortraitIndex','UnitFlagAtlas','UnitFlagIconOffset'},
    'Buildings': {'IconAtlas','PortraitIndex'},
}


def validate_presentation(db, declared):
    imported = {Path(path).name: ROOT/path for path, row in declared.items() if row.get('import')=='1'}

    def assert_portrait(atlas, index, owner):
        variants = db.execute('SELECT Filename,IconsPerRow,IconsPerColumn FROM IconTextureAtlases '
                              'WHERE Atlas=? AND IconSize=?', (atlas,128)).fetchall()
        assert len(variants)==1, (owner,atlas)
        image, cols, rows = variants[0]
        assert image in imported and 0 <= index < int(cols)*int(rows), (owner,atlas,index,image)

    civs = db.execute("SELECT * FROM Civilizations WHERE Type LIKE 'CIVILIZATION_CWC3_%' "
                      "OR Type='CIVILIZATION_PALEO_DIRECTORATE'").fetchall()
    assert len(civs)==26
    scenes = set()
    for civ in civs:
        name=civ['Type']
        assert_portrait(civ['IconAtlas'],civ['PortraitIndex'],name)
        for key in ['DawnOfManImage','MapImage']:
            assert civ[key] in imported, (name,key,civ[key])
        for table,link,field in [
            ('Leaders','Civilization_Leaders','LeaderheadType'),
            ('Units','Civilization_UnitClassOverrides','UnitType'),
            ('Buildings','Civilization_BuildingClassOverrides','BuildingType'),
        ]:
            objects=db.execute(f'SELECT a.* FROM {table} a JOIN {link} x ON a.Type=x.{field} '
                               'WHERE x.CivilizationType=?',(name,)).fetchall()
            assert objects, (name,table)
            for obj in objects:
                assert_portrait(obj['IconAtlas'],obj['PortraitIndex'],obj['Type'])
                if table=='Leaders':
                    scene=obj['ArtDefineTag']
                    assert scene in imported and scene not in scenes, (name,scene)
                    scenes.add(scene)
                    fallback=ET.parse(imported[scene]).getroot().get('FallbackImage')
                    assert fallback in imported, (scene,fallback)
    return f'PASS all {len(civs)} civilizations resolve to packaged emblems, leader/unique portraits, Dawn, map and diplomacy art'


def gameplay_rows(db):
    snapshots={}
    for table, excluded in PRESENTATION_FIELDS.items():
        columns=[r[1] for r in db.execute(f'PRAGMA table_info({table})') if r[1] not in excluded]
        select=','.join(f'"{col}"' for col in columns)
        snapshots[table]=[tuple(r) for r in db.execute(f'SELECT {select} FROM {table} ORDER BY Type')]
    return snapshots


if __name__=='__main__':
    assert ORDER[-1]=='Shared/SQL/CWC3_OriginalPresentation.sql'
    with clean_fixture() as db:
        for sql in ORDER[:-1]:
            db.executescript((ROOT/sql).read_text(encoding='utf-8'))
        before=gameplay_rows(db)
        db.executescript((ROOT/ORDER[-1]).read_text(encoding='utf-8'))
        assert before==gameplay_rows(db), 'Presentation patch changed gameplay or on-map models'
        manifest=ET.parse(ROOT/NAME)
        print(validate_presentation(db,{e.text:e for e in manifest.findall('Files/File')}))
        print('PASS all gameplay and model columns unchanged')
