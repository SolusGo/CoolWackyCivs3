"""Audit dimensions, native UI sampling and DDS payloads for all packaged textures."""
from collections import Counter
from hashlib import md5
from io import BytesIO
import json
from pathlib import Path
import re
import struct
from xml.etree import ElementTree as ET

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MAP_SIZE = (360, 412)
DIPLOMACY_SIZE = (1600, 1200)
WIDESCREEN_DAWNS = set()
AUXILIARY = {}
ATLAS_ROW = re.compile(
    r"'[A-Za-z0-9_]+'\s*,\s*(\d+)\s*,\s*'([A-Za-z0-9_.-]+\.dds)'\s*,\s*(\d+)\s*,\s*(\d+)",
    re.I,
)
PAIR = re.compile(r"(\d+)\s*,\s*(\d+)")


def pair(value):
    match = PAIR.fullmatch(value or '')
    return tuple(map(int, match.groups())) if match else None


def dds_size(data):
    assert data[:4] == b'DDS ' and len(data) >= 128, 'Missing DDS header'
    height, width = struct.unpack_from('<II', data, 12)
    levels = struct.unpack_from('<I', data, 28)[0] or 1
    assert width and height and 1 <= levels <= max(width, height).bit_length(), 'Invalid size or mip count'
    fourcc = data[84:88]
    block = {b'DXT1':8, b'DXT3':16, b'DXT5':16}.get(fourcc)
    bytes_per_pixel = struct.unpack_from('<I', data, 88)[0] // 8
    assert block or (fourcc == bytes(4) and bytes_per_pixel in (3, 4)), ('Unexpected DDS format', fourcc)
    expected = 128
    for level in range(levels):
        w, h = max(1, width >> level), max(1, height >> level)
        expected += ((w+3)//4)*((h+3)//4)*block if block else w*h*bytes_per_pixel
    assert len(data) == expected, ('Incorrect DDS payload length', expected, len(data))
    with Image.open(BytesIO(data)) as image:
        image.load()
        assert image.size == (width, height)
    return width, height


def audit(root=ROOT):
    manifest, = root.glob('*.modinfo')
    files = ET.parse(manifest).findall('Files/File')
    paths = [root / entry.text for entry in files]
    textures = {}
    for entry, path in zip(files, paths):
        if path.suffix.lower() != '.dds':
            continue
        key = path.name.lower()
        assert key not in textures, ('Conflicting VFS texture name', path)
        assert entry.get('import') == '1', ('Texture missing VFS import', path)
        data = path.read_bytes()
        try:
            assert md5(data).hexdigest().upper() == entry.get('md5', '').upper(), 'Manifest MD5 differs'
            textures[key] = dds_size(data)
        except (AssertionError, OSError) as error:
            raise AssertionError(f'{path.relative_to(root)}: {error}') from error

    covered = set()
    counts = Counter()

    def require(name, size, role):
        assert textures.get(name) == size, (role, name, 'expected', size, 'found', textures.get(name))
        covered.add(name)
        counts[role] += 1

    for path in paths:
        if path.suffix == '.sql':
            source = path.read_text(encoding='utf-8-sig')
            for statement in re.findall(r'INSERT\s+(?:OR\s+\w+\s+)?INTO\s+IconTextureAtlases\b.*?;', source, re.I | re.S):
                for size, name, columns, rows in ATLAS_ROW.findall(statement):
                    require(name.lower(), (int(size)*int(columns), int(size)*int(rows)), 'atlas declaration')
        if path.suffix == '.xml':
            for node in ET.parse(path).iter():
                fallback = node.get('FallbackImage', '').lower()
                if fallback in textures:
                    require(fallback, DIPLOMACY_SIZE, 'diplomacy scene')
                name = node.get('Texture', '').lower()
                if name not in textures:
                    continue
                size = pair(node.get('Size'))
                offset = pair(node.get('TextureOffset'))
                if size and offset is not None:
                    assert all(o+s <= t for o,s,t in zip(offset, size, textures[name])), (path, name, size, offset)
                    covered.add(name)
                    counts['UI atlas regions'] += 1
                elif size:
                    require(name, size, 'UI texture use')

    for name in textures:
        if name.endswith('map.dds'):
            require(name, MAP_SIZE, 'setup map')
        elif name.endswith('dawn.dds') or name == 'lastlight.dds':
            require(name, (1024, 768) if name not in WIDESCREEN_DAWNS else (1600, 900), 'loading scene')

    inventory = root / 'docs/UIRefreshInventory.json'
    if inventory.is_file():
        for record in json.loads(inventory.read_text(encoding='utf-8')):
            for name, size in record['textures'].items():
                require(name.lower(), tuple(size), 'themed UI texture')
    for name, size in AUXILIARY.items():
        require(name.lower(), size, 'additional UI texture')

    assert covered == textures.keys(), ('Missing dimension contracts', sorted(textures.keys()-covered))
    details = ', '.join(f'{count} {role}' for role, count in sorted(counts.items()))
    print(f'PASS {len(textures)} packaged DDS textures with verified dimensions, VFS and payloads ({details})')


if __name__ == '__main__':
    audit()
