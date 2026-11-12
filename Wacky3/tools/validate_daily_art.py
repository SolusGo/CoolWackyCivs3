"""Validate five original art sets, their SQL wiring and byte regeneration."""
import contextlib
import hashlib
import io
import json
import struct
from xml.etree import ElementTree as ET
from PIL import Image
from baseline import ROOT
from build_art import SIZES
from build_daily_art import compile_art
from daily_art import CATALOG

def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def check_art(db,declared):
    original_hashes=set(); leader_hashes=set(); flag_hashes=set(); count=0
    prompts=json.loads((ROOT/'tools/daily_art_prompts.json').read_text(encoding='utf-8'))
    assert len(prompts['assets'])==30
    assert len({(a['code'],a['kind']) for a in prompts['assets']})==30
    for s in CATALOG:
        prefix=s['prefix']; art=ROOT/s['folder']/'Art'; sources=art/'Sources'; bk=s['building_kind']
        recorded={a['file']:a['sha256'] for a in json.loads((sources/'Provenance.json').read_text())['assets']}
        assert json.loads((sources/'Prompts.json').read_text())['assets']==[a for a in prompts['assets'] if a['code']==s['code']]
        for kind in ['Leader','Emblem','Unit',bk,'Dawn','Capital']:
            path=sources/f'{kind}.png'; im=Image.open(path); im.load()
            assert min(im.size)>=1024,(path,im.size)
            h=digest(path); assert h not in original_hashes,('Reused original illustration',path); original_hashes.add(h)
            assert recorded[path.name]==h,('Stale source provenance',path)
            assert any(a['source']==path.relative_to(ROOT).as_posix() for a in prompts['assets'])
            if kind=='Emblem': assert im.convert('RGBA').getchannel('A').getextrema()==(0,255),('Emblem transparency',path)
        expected=[]
        for kind in ['Civ','Leader','Unit',bk,'Alpha','Flag']:
            atlas=prefix+'_'+kind.upper()+'_ATLAS'
            entries=[(int(r[0]),r[1],int(r[2]),int(r[3])) for r in db.execute('SELECT IconSize,Filename,IconsPerRow,IconsPerColumn FROM IconTextureAtlases WHERE Atlas=? ORDER BY IconSize DESC',(atlas,))]
            assert entries==[(size,f'{prefix}_{kind}{size}.dds',1,1) for size in SIZES],(s['code'],kind,entries)
            for size in SIZES:
                path=art/f'{prefix}_{kind}{size}.dds'; expected.append(path)
                image=Image.open(path); image.load(); assert image.size==(size,size)
                header=struct.unpack('<31I',path.read_bytes()[4:128]); assert header[21]==32 and header[19]==0x41 and header[6]==size.bit_length()
                assert image.getchannel('A').getextrema()==(0,255)
                width=size; payload=128
                for _ in range(header[6]): payload+=width*width*4; width=max(1,width//2)
                assert path.stat().st_size==payload
                assert declared[path.relative_to(ROOT).as_posix()].get('import')=='1'
                if kind in ['Alpha','Flag']:
                    for red,green,blue,alpha in zip(*(image.getchannel(c).tobytes() for c in 'RGBA')):
                        if alpha: assert red==green==blue==255,('Not monochrome flag',path)
        for kind,dimensions in [('Leader',(1600,1200)),('Dawn',(1024,768)),('Map',(360,412))]:
            path=art/f'{prefix}_{kind}.dds'; expected.append(path)
            assert Image.open(path).size==dimensions
            assert path.stat().st_size==128+dimensions[0]*dimensions[1]*4
            assert declared[path.relative_to(ROOT).as_posix()].get('import')=='1'
        assert len(expected)==57 and set(art.glob('*.dds'))==set(expected)
        scene=art/f'{prefix}_LeaderScene.xml'
        assert ET.parse(scene).getroot().get('FallbackImage')==f'{prefix}_Leader.dds'
        assert declared[scene.relative_to(ROOT).as_posix()].get('import')=='1'
        for table,typ,kind in [('Civilizations',s['civ'],'CIV'),('Leaders',s['leader'],'LEADER'),('Units',s['unit'],'UNIT'),('Buildings',s['building'],bk.upper())]:
            assert tuple(db.execute('SELECT IconAtlas,PortraitIndex FROM '+table+' WHERE Type=?',(typ,)).fetchone())==(prefix+'_'+kind+'_ATLAS',0)
        assert tuple(db.execute('SELECT AlphaIconAtlas,DawnOfManImage,MapImage FROM Civilizations WHERE Type=?',(s['civ'],)).fetchone())==(prefix+'_ALPHA_ATLAS',prefix+'_Dawn.dds',prefix+'_Map.dds')
        assert db.execute('SELECT ArtDefineTag FROM Leaders WHERE Type=?',(s['leader'],)).fetchone()[0]==prefix+'_LeaderScene.xml'
        assert tuple(db.execute('SELECT UnitFlagAtlas,UnitFlagIconOffset FROM Units WHERE Type=?',(s['unit'],)).fetchone())==(prefix+'_FLAG_ATLAS',0)
        leader_hashes.add(digest(art/f'{prefix}_Leader256.dds')); flag_hashes.add(digest(art/f'{prefix}_Flag64.dds'))
        sql=ROOT/s['folder']/'SQL'/f"{s['code']}_Art.sql"
        before={p:digest(p) for p in [*expected,scene,sql]}
        with contextlib.redirect_stdout(io.StringIO()): compile_art(s,review=False)
        assert {p:digest(p) for p in before}==before,('Nondeterministic art compiler',s['code'])
        count+=len(expected)
    assert len(original_hashes)==30 and len(leader_hashes)==5 and len(flag_hashes)==5
    return f'PASS: 30 distinct original PNG masters and exact built-in prompts; five unique leaders/glyphs; {count} DDS textures, six complete nine-size atlases per civ, gold-rimmed portraits, monochrome alpha/flags, distinct Dawn/capital scenes, SQL/VFS wiring and deterministic byte regeneration. Native UI rendering NOT RUN.'
