"""Complete companion inventory, clean-schema SQL and regeneration regressions."""
import contextlib
import io
import os
import re
import runpy
import sqlite3
import tempfile
from pathlib import Path
from baseline import ROOT, quote
from target_schema import approved_companions, clean_fixture, verified


def seed_companions(db):
    """Exercise even normally-empty CP tables with nonzero test-only records."""
    count=0
    for prefix,column,parents in [('Building_','BuildingType',['BUILDING_LIBRARY','BUILDING_AMPHITHEATER','BUILDING_GRANARY','BUILDING_WORKSHOP','BUILDING_TEMPLE']),
                                   ('Unit_','UnitType',['UNIT_SPEARMAN','UNIT_SWORDSMAN','UNIT_WORKER','UNIT_PIKEMAN'])]:
        for table in approved_companions(prefix,column):
            columns=list(db.execute('PRAGMA table_info('+quote(table)+')'))
            for parent in parents:
                if db.execute('SELECT 1 FROM '+quote(table)+' WHERE '+quote(column)+'=?',(parent,)).fetchone(): continue
                values={}
                for c in columns:
                    name,typ,required,default,pk=c[1:]
                    if name=='ID': continue
                    if name==column: values[name]=parent
                    elif 'INT' in typ.upper() or typ.upper() in ['BOOLEAN','BOOL']: values[name]=7
                    elif required and default is None: values[name]='CWC3_SCHEMA_TEST_'+name
                db.execute('INSERT INTO '+quote(table)+'('+','.join(map(quote,values))+') VALUES ('+','.join('?' for _ in values)+')',tuple(values.values()))
                count+=1
    return count


def audit_generated_inventory():
    inventories={prefix:set(approved_companions(prefix,col)) for prefix,col in [('Building_','BuildingType'),('Unit_','UnitType')]}
    for civ,stem in [('TheHollowChoir','Choir'),('TheMinistryOfAlmost','Ministry'),('TheSeventeenthSummer','Summer'),('ThePerpetualTimetable','Timetable'),('TheCandlekeepersCovenant','Covenant')]:
        for kind,prefix in [('Buildings','Building_'),('Units','Unit_')]:
            sql=(ROOT/civ/'SQL'/f'{stem}_{kind}.sql').read_text()
            referenced=set(re.findall(r'Companion AS SELECT \* FROM "([^"]+)"',sql))
            assert referenced==inventories[prefix],(civ,kind,'missing',inventories[prefix]-referenced,'extra',referenced-inventories[prefix])
    return {prefix:len(tables) for prefix,tables in inventories.items()}


def check_regeneration():
    inventory=audit_generated_inventory()
    previous={key:os.environ.get(key) for key in ['CWC3_DATABASE','CWC3_SQL_ROOT']}
    results=[]
    try:
        with tempfile.TemporaryDirectory(prefix='cwc3-schema-') as temp:
            temp=Path(temp)
            baseline=clean_fixture()
            for unsupported in ['Building_JFD_District','Building_ConstructionAudio']:
                assert not baseline.execute('SELECT 1 FROM sqlite_master WHERE name=?',(unsupported,)).fetchone()
                # A negative control proves this fixture would catch the old bug.
                try:
                    baseline.execute('SELECT * FROM '+quote(unsupported))
                except sqlite3.OperationalError as error:
                    assert 'no such table' in str(error)
                else: raise AssertionError('Missing-table negative control failed')
            cache=temp/'baseline.db'
            disk=sqlite3.connect(cache); baseline.backup(disk); disk.close()
            baseline.close()
            for contaminated in [False,True]:
                if contaminated:
                    disk=sqlite3.connect(cache)
                    disk.executescript("""CREATE TABLE Building_JFD_District(BuildingType TEXT, DistrictType TEXT);
                    INSERT INTO Building_JFD_District VALUES('BUILDING_LIBRARY','DISTRICT_TEST');
                    INSERT INTO Building_JFD_District VALUES('BUILDING_AMPHITHEATER','DISTRICT_TEST');
                    CREATE TABLE Unit_ThirdPartySchemaRegression(UnitType TEXT, Bonus INTEGER);
                    INSERT INTO Unit_ThirdPartySchemaRegression VALUES('UNIT_SWORDSMAN',99);""")
                    disk.close()
                output=temp/('contaminated' if contaminated else 'clean')
                os.environ.update(CWC3_DATABASE=str(cache),CWC3_SQL_ROOT=str(output))
                for script in ['generate_sql.py','generate_hollow_choir.py','generate_seventeenth_summer.py','generate_timetable.py','generate_covenant.py']:
                    with contextlib.redirect_stdout(io.StringIO()): runpy.run_path(str(ROOT/'tools'/script),run_name='__main__')
                paths=list(output.rglob('*.sql'))
                assert len(paths)==19, 'Every generator output must be compared'
                for generated in paths:
                    relative=generated.relative_to(output)
                    assert generated.read_bytes()==(ROOT/relative).read_bytes(),('Nondeterministic or contaminated regeneration',relative)
                    assert 'Building_JFD_District' not in generated.read_text()
                    assert 'Unit_ThirdPartySchemaRegression' not in generated.read_text()
                results.append({'input':'artificial third-party building/unit tables' if contaminated else 'clean source-derived schema',
                                'result':'PASS: all nineteen SQL outputs byte-identical to checked-in output'})
    finally:
        for key,value in previous.items():
            if value is None: os.environ.pop(key,None)
            else: os.environ[key]=value
    evidence=verified()[2]
    return {'result':'PASS','pinned_source_files':len(evidence['sources']), 'approved_companions':inventory,
            'removed_unsupported':['Building_ConstructionAudio','Building_JFD_District'],
            'regeneration':results,
            'fixture_limit':'Clean target schema with native XML samples and synthetic companion sentinels; not native final CP gameplay data or in-game acceptance'}
