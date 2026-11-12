# SALT original art

Older merchant matriarch; knowing smile, white eyebrow streak, low turquoise wrap and coral robe.

Six new original illustrations are retained in `Sources`: leader, emblem, unit, Building, Dawn and capital. Built-in image_gen produced each asset from its own prompt. Exact prompts/settings are in [Sources/Prompts.json](Sources/Prompts.json); no API key or image service is needed for rebuilding the retained files.

`python tools/build_daily_art.py --civ SALT` (from Wacky3) compiles 57 DDS assets: six nine-size atlases for civilization, leader, unique unit, unique building, civilization alpha and unit flag; plus a 1600×1200 static diplomacy scene, separate 1024×768 Dawn scene and 360×412 capital illustration. Gold-rimmed portraits match the pack, while palette, face/silhouette and symbols differ between civilizations. Original code-native monochrome glyphs stay legible at small map sizes. Native CP unit/building world models and audio remain inherited.

All files use legacy BGRA8888 DDS; icons have full mip chains and transparent corners. LeaderScene XML is imported into VFS. The art SQL registers only original atlas resources. PNG sources and review sheets are development assets excluded from the installable mod resources. The capital panel is an illustration, not a claim of a surveyed map.

[Art direction, historical references and acceptance](../../docs/ArchivedArtReport.md). `validate_daily_art.py` checks wiring, dimensions, alpha, glyphs, unique source hashes, exact prompts and byte-identical recompilation. Static QA does not certify native Civ V rendering; in-game art/UI acceptance remains outstanding. Gameplay/save formats are unchanged by this visual update.
