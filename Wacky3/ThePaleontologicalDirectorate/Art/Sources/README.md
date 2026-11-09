# Directorate art masters

The built-in `image_gen.imagegen` tool generated `Leader.png`, `Emblem.png`, `Unit.png` and `Museum.png` for this civilization. The exact final prompt set and transparent-background setting are in [Prompts.json](Prompts.json). No external stock image or paid API/CLI dependency is used.

From `Wacky3`, `python tools/build_paleo_art.py` deterministically crops/resizes the retained masters, makes circular portraits and the code-native monochrome ammonite glyph, and writes all 57 legacy BGRA8888 DDS assets. `Alpha.png` and `ArtReview.png` are compiler outputs. Atlas icons have full mip chains and transparency; the scene files are single-level 1600x1200, 1024x768 and 360x412 textures. PNG sources are excluded from the installable manifest, following pack conventions.

The civilization emblem, leader, expedition and Museum portraits, civilization alpha and unit flag are custom. In-world expedition and Museum models inherit native Archaeologist/Museum art. Diplomacy is a static illustrated scene without animation or voice; the fictional capital panel uses the Museum illustration. No required visual asset is unfinished.
