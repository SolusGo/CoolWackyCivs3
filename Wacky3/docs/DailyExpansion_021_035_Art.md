# Daily Surprise art

The fifteen expansion emblems are original geometric glyphs built with Pillow. They share the gold rim of the earlier pack. Their monochrome counterparts serve as civilization alpha icons and unit flags. Motifs include a Ryukyuan-inspired roofline and wave, the Muisca lake and gold ring, and a cloud-forest ridge above Chachapoya-inspired terraces. These decorative motifs are modern design interpretations.

Run `python tools/build_daily_expansion_art.py` from Wacky3 after regenerating the SQL. The compiler retains 30 RGBA PNGs in each civilization's `Art/Sources` directory and exports 270 BGRA DDS files at the nine established atlas sizes, with complete mip chains. The pack imports the DDS textures through VFS and retains Source PNGs in Git.

The existing native leader portraits, static diplomacy scenes, Dawn illustrations, map images and unit/building portraits remain temporary fallbacks. Unit world models are inherited. Original scene and portrait illustrations, along with native verification of the graphics, are outstanding.
