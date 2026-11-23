"""Compile original art sheets into Civilization V portraits and presentation scenes."""
import json

from PIL import Image, ImageDraw, ImageFilter, ImageOps

from build_art import ROOT, SIZES, dds, leader_cell
from build_daily_art import framed
from build_daily_expansion_art import PALETTES

RESAMPLE = Image.Resampling.LANCZOS
OUTPUT = ROOT / 'Shared/SQL/CWC3_OriginalPresentation.sql'
DAILY = json.loads((ROOT / 'tools/daily_expansion.json').read_text(encoding='utf-8'))
CUSTOM = [
    ('TheHollowChoir', 'CIVILIZATION_CWC3_HOLLOW_CHOIR', 'CWC3_CHOIR', (42, 19, 70)),
    ('TheSeventeenthSummer', 'CIVILIZATION_CWC3_SEVENTEENTH_SUMMER', 'CWC3_SUMMER', (60, 44, 16)),
]
ROSTER = CUSTOM + [
    (entry['folder'], f"CIVILIZATION_CWC3_D{entry['id']:03}",
     f"CWC3_D{entry['id']:03}", tuple(bytes.fromhex(PALETTES[entry['id']-21])))
    for entry in DAILY
]
KEEPERS = ('TheCandlekeepersCovenant', 'CIVILIZATION_CWC3_COVENANT', 'CWC3_COVENANT', (28,29,58))
ATLAS_COUNT = (3*len(ROSTER) + 2*len(CUSTOM) + 2)*len(SIZES)
SCENE_COUNT = len(ROSTER)*3


def split_sheet(path, objects_only=False):
    with Image.open(path) as source:
        image = source.convert('RGBA')
    left, top = image.width // 2, image.height // 2
    boxes = [(0, 0, left, image.height), (left, 0, image.width, image.height)] if objects_only else [
        (0, 0, left, top), (left, 0, image.width, top),
        (0, top, left, image.height), (left, top, image.width, image.height)]
    # Inset a few pixels so filtering cannot sample an adjacent painting.
    return [image.crop((x+3,y+3,xx-3,yy-3)) for x,y,xx,yy in boxes]


def emblem(prefix):
    image = Image.new('RGBA', (256, 256))
    draw = ImageDraw.Draw(image)
    if prefix == 'CWC3_CHOIR':
        for x, peak, point in [(65, 68, 104), (111, 24, 128), (159, 53, 178)]:
            draw.polygon([(x, 191), (x, peak + 28), (point, peak),
                          (x + 31, peak + 32), (x + 31, 191)], fill='white')
        draw.rounded_rectangle((52, 198, 206, 219), radius=8, fill='white')
    else:
        draw.ellipse((94, 32, 160, 210), fill='white')
        draw.polygon([(110, 90), (45, 63), (37, 112), (69, 176), (113, 150)], fill='white')
        draw.polygon([(145, 90), (210, 63), (218, 112), (185, 176), (141, 150)], fill='white')
    return image


def badge(master, size, leader=False):
    if leader:
        return leader_cell(master, size)
    edge = round(size * .94)
    canvas = Image.new('RGBA', (size, size))
    canvas.paste(master.resize((edge, edge), RESAMPLE), ((size - edge) // 2,) * 2)
    return canvas


def landscape_portrait(image, background):
    size = (1600, 1200)
    # Extend the capital painting behind the full head-and-shoulders crop.
    canvas = ImageOps.fit(background, size, RESAMPLE).filter(ImageFilter.GaussianBlur(45))
    canvas = Image.blend(canvas, Image.new('RGBA', size, (15, 15, 22, 255)), .48)
    portrait = ImageOps.fit(image, (1200, 1200), RESAMPLE)
    alpha = Image.new('L', portrait.size, 255)
    for x in range(100):
        value = round(255 * x / 99)
        draw = ImageDraw.Draw(alpha)
        draw.line((x, 0, x, 1199), fill=value)
        draw.line((1199 - x, 0, 1199 - x, 1199), fill=value)
    portrait.putalpha(alpha)
    canvas.alpha_composite(portrait, (200, 0))
    return canvas


def scene(image, path):
    image.convert('RGBA').save(path, pixel_format='DXT5')


def compile_civ(folder, civ, prefix, background, objects_only=False):
    art = ROOT / folder / 'Art'
    parts = split_sheet(art / 'Sources/Presentation.png', objects_only)
    if objects_only:
        unit, building = parts
        images = {}
    else:
        lead, unit, building, city = parts
        images = {'LEADER': framed(lead, background)}
    images.update(UNIT=framed(unit, background), BUILDING=framed(building, background))
    is_new_emblem = folder in {record[0] for record in CUSTOM}
    if is_new_emblem:
        glyph = emblem(prefix)
        images['CIV'] = framed(glyph, background, 110)
        images['ALPHA'] = glyph
    rows = []
    for kind, master in images.items():
        for size in SIZES:
            filename = f'{prefix}_{kind}_{size}.dds'
            tile = master.resize((size, size), RESAMPLE) if kind == 'ALPHA' else badge(master, size, kind == 'LEADER')
            dds(tile, art / filename)
            rows.append(f"('{prefix}_{kind}_ATLAS',{size},'{filename}',1,1)")

    statements = [
        'INSERT INTO IconTextureAtlases(Atlas,IconSize,Filename,IconsPerRow,IconsPerColumn) VALUES\n' + ',\n'.join(rows) + ';',
        f"UPDATE Units SET IconAtlas='{prefix}_UNIT_ATLAS',PortraitIndex=0,UnitFlagAtlas='{prefix}_ALPHA_ATLAS',UnitFlagIconOffset=0 "
        f"WHERE Type IN (SELECT UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType='{civ}');",
        f"UPDATE Buildings SET IconAtlas='{prefix}_BUILDING_ATLAS',PortraitIndex=0 "
        f"WHERE Type IN (SELECT BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType='{civ}');",
    ]
    if not objects_only:
        dawn, map_name = f'{prefix}_Dawn.dds', f'{prefix}_Map.dds'
        diplomacy, scene_name = f'{prefix}_Diplomacy.dds', f'{prefix}_LeaderScene.xml'
        scene(landscape_portrait(lead, city), art / diplomacy)
        scene(ImageOps.fit(city, (1024,768), RESAMPLE), art / dawn)
        scene(ImageOps.fit(city, (360,412), RESAMPLE), art / map_name)
        (art / scene_name).write_text(f'<LeaderScene FallbackImage="{diplomacy}" />\n', encoding='utf-8', newline='\n')
        civ_values = f"MapImage='{map_name}',DawnOfManImage='{dawn}'"
        if is_new_emblem:
            civ_values += f",IconAtlas='{prefix}_CIV_ATLAS',AlphaIconAtlas='{prefix}_ALPHA_ATLAS',PortraitIndex=0"
        statements.extend([
            f"UPDATE Civilizations SET {civ_values} WHERE Type='{civ}';",
            f"UPDATE Leaders SET IconAtlas='{prefix}_LEADER_ATLAS',PortraitIndex=0,ArtDefineTag='{scene_name}' "
            f"WHERE Type IN (SELECT LeaderheadType FROM Civilization_Leaders WHERE CivilizationType='{civ}');",
        ])
    return '\n'.join(statements)


def main():
    blocks = [compile_civ(*record) for record in ROSTER]
    blocks.append(compile_civ(*KEEPERS, objects_only=True))
    OUTPUT.write_text('-- Generated by tools/build_original_presentation.py. Presentation fields only.\n'
                      + '\n\n'.join(blocks) + '\n', encoding='utf-8', newline='\n')


if __name__ == '__main__':
    main()
