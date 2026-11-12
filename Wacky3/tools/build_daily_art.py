"""Compile 30 retained original masters to five complete, deterministic DDS sets.

Illustrations come from built-in image_gen. This compiler performs engine asset
preparation only: portrait crop/rim, sizes, alpha glyphs, mip chains and DDS layout.
"""
import argparse
import hashlib
import json
import math
from PIL import Image, ImageDraw, ImageOps
from baseline import ROOT
from build_art import dds, SIZES
from daily_art import CATALOG

def alpha_glyph(code):
    """Original code-native solid flag marks, designed for 16–64px readability."""
    image=Image.new('RGBA',(1024,1024)); d=ImageDraw.Draw(image)
    if code=='LOST':
        d.polygon([(260,220),(650,220),(820,390),(820,770),(260,770)],fill='white')
        d.ellipse((540,285,625,370),fill=(0,0,0,0))
        d.ellipse((380,395,590,605),fill=(0,0,0,0))
        d.polygon([(450,560),(520,560),(560,690),(410,690)],fill=(0,0,0,0))
    elif code=='SCARECROW':
        d.polygon([(330,350),(694,350),(750,680),(274,680)],fill='white')
        d.rounded_rectangle((440,220,584,360),radius=45,fill='white')
        d.ellipse((460,695,564,800),fill='white')
        d.line((210,170,210,790),fill='white',width=30)
        d.line((814,170,814,790),fill='white',width=30)
        for y in [230,370,510,650]:
            d.ellipse((110,y-85,210,y+25),fill='white'); d.ellipse((210,y-85,310,y+25),fill='white')
            d.ellipse((714,y-85,814,y+25),fill='white'); d.ellipse((814,y-85,914,y+25),fill='white')
    elif code=='MAKURIA':
        d.rectangle((445,155,579,550),fill='white'); d.rectangle((320,280,704,410),fill='white')
        d.rectangle((235,660,789,830),fill='white')
        for x in [235,425,615]: d.rectangle((x,575,x+174,700),fill='white')
        d.rounded_rectangle((450,715,574,860),radius=50,fill=(0,0,0,0))
    elif code=='SALT':
        d.rectangle((480,190,544,800),fill='white'); d.ellipse((450,140,574,264),fill='white')
        d.line((235,330,789,330),fill='white',width=55)
        for x in [260,764]:
            d.line((x,330,x-115,590),fill='white',width=27); d.line((x,330,x+115,590),fill='white',width=27)
            d.pieslice((x-130,460,x+130,720),0,180,fill='white')
        d.polygon([(340,800),(684,800),(760,865),(264,865)],fill='white')
    else:
        points=[]
        for i in range(401):
            angle=i/400*math.pi*4.8; radius=32+350*i/400
            points.append((512+math.cos(angle)*radius,512+math.sin(angle)*radius))
        d.line(points,fill='white',width=66,joint='curve')
        for i in range(215,401,17):
            angle=i/400*math.pi*4.8; radius=32+350*i/400
            d.line([(512+math.cos(angle)*radius,512+math.sin(angle)*radius),
                    (512+math.cos(angle+.08)*(radius-85),512+math.sin(angle+.08)*(radius-85))],fill='white',width=25)
    return image

def framed(image, background, padding=0):
    out=Image.new('RGBA',(1024,1024),(*background,255))
    if padding:
        image=ImageOps.contain(image,(1024-padding*2,1024-padding*2),Image.Resampling.LANCZOS).convert('RGBA')
        out.alpha_composite(image,((1024-image.width)//2,(1024-image.height)//2))
    else:
        image=ImageOps.fit(image,(1024,1024),Image.Resampling.LANCZOS).convert('RGBA')
        out.alpha_composite(image)
    mask=Image.new('L',out.size); ImageDraw.Draw(mask).ellipse((30,30,994,994),fill=255)
    out.putalpha(mask)
    d=ImageDraw.Draw(out); d.ellipse((30,30,994,994),outline=(219,175,77,255),width=18)
    d.ellipse((49,49,975,975),outline=(96,66,26,255),width=6)
    return out

def compile_art(s, review=True):
    art=ROOT/s['folder']/'Art'; sources=art/'Sources'; prefix=s['prefix']; bk=s['building_kind']
    names=['Leader','Emblem','Unit',bk,'Dawn','Capital']
    images={k:Image.open(sources/(k+'.png')).convert('RGBA') for k in names}
    leader=images['Leader']; w,h=leader.size
    crop=leader.crop(tuple(round(v*(w if i%2==0 else h)) for i,v in enumerate(s['portrait'])))
    alpha=alpha_glyph(s['code']); alpha.save(sources/'Alpha.png')
    masters={'Civ':framed(images['Emblem'],s['background'],110), 'Leader':framed(crop,s['background']),
             'Unit':framed(images['Unit'],s['background']),bk:framed(images[bk],s['background']),
             'Alpha':alpha,'Flag':alpha}
    declarations=[]
    for kind,master in masters.items():
        for size in SIZES:
            name=f'{prefix}_{kind}{size}.dds'
            dds(master.resize((size,size),Image.Resampling.LANCZOS),art/name)
            declarations.append(f" ('{prefix}_{kind.upper()}_ATLAS',{size},'{name}',1,1)")
    for kind,source,dimensions in [('Leader','Leader',(1600,1200)),('Dawn','Dawn',(1024,768)),('Map','Capital',(360,412))]:
        dds(ImageOps.fit(images[source],dimensions,Image.Resampling.LANCZOS),art/f'{prefix}_{kind}.dds',False)
    (art/f'{prefix}_LeaderScene.xml').write_text(f'<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="{prefix}_Leader.dds" />\n',encoding='utf-8',newline='\n')
    stem='PALEO' if s['code']=='PALEO' else s['code']
    (ROOT/s['folder']/'SQL'/f'{stem}_Art.sql').write_text('-- Generated by tools/build_daily_art.py.\nINSERT INTO IconTextureAtlases(Atlas,IconSize,Filename,IconsPerRow,IconsPerColumn) VALUES\n'+',\n'.join(declarations)+';\n',encoding='utf-8',newline='\n')
    if review:
        sheet=Image.new('RGB',(1536,1050),(18,23,30)); d=ImageDraw.Draw(sheet)
        for i,kind in enumerate(['Civ','Leader','Unit',bk,'Alpha','Flag']):
            icon=Image.open(art/f'{prefix}_{kind}256.dds'); sheet.paste(icon,(i*256,25),icon); d.text((i*256+12,6),kind,fill='white')
        for i,kind in enumerate(['Leader','Dawn','Map']):
            scene=Image.open(art/f'{prefix}_{kind}.dds'); scene.thumbnail((490,700)); sheet.paste(scene,(i*512+10,300))
        sheet.save(sources/'ArtReview.png')
    hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(art.glob('*.dds'))}
    (sources/'CompiledHashes.json').write_text(json.dumps(hashes,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(f"Compiled {s['code']}: 6 original illustration masters, 54 mipmapped atlas textures, 3 distinct scene textures")

def overview():
    sheet=Image.new('RGB',(1600,1680),(15,20,29)); d=ImageDraw.Draw(sheet)
    lineup=Image.new('RGB',(1600,340),(15,20,29)); labels=ImageDraw.Draw(lineup)
    names=['Chief Registrar Nobody','Old Man Thistle','Merkurios','First Broker Nahir','Director Emeritus Othmar']
    for row,s in enumerate(CATALOG):
        art=ROOT/s['folder']/'Art'; prefix=s['prefix']; y=row*336
        d.text((15,y+8),s['code']+' | '+s['identity'],fill='white')
        scene=Image.open(art/f'{prefix}_Leader.dds'); scene.thumbnail((420,300)); sheet.paste(scene,(10,y+30))
        face=Image.open(art/f'{prefix}_Leader256.dds'); lineup.paste(face,(row*320+32,18),face)
        labels.text((row*320+22,286),names[row],fill='white',font_size=18)
        for col,kind in enumerate(['Civ','Leader','Unit',s['building_kind'],'Alpha','Flag']):
            icon=Image.open(art/f'{prefix}_{kind}128.dds'); sheet.paste(icon,(450+col*185,y+78),icon)
            d.text((450+col*185,y+218),kind,fill='white')
    destination=ROOT/'docs/ArtReview'; destination.mkdir(exist_ok=True)
    sheet.save(destination/'ArchivedLeaders.png')
    lineup.save(destination/'LeaderLineup.png')

def main():
    parser=argparse.ArgumentParser(description=__doc__); parser.add_argument('--civ',choices=[s['code'] for s in CATALOG]); args=parser.parse_args()
    for s in CATALOG:
        if not args.civ or args.civ==s['code']: compile_art(s)
    if not args.civ: overview()

if __name__=='__main__': main()
