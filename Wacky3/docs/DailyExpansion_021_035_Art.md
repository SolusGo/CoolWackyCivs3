# Daily Surprise art

The fifteen expansion emblems are original geometric glyphs built with Pillow. They share the gold rim of the earlier pack. Their monochrome counterparts serve as civilization alpha icons and unit flags. Motifs include a Ryukyuan-inspired roofline and wave, the Muisca lake and gold ring, and a cloud-forest ridge above Chachapoya-inspired terraces. These decorative motifs are modern design interpretations.

Run `python tools/build_daily_expansion_art.py` from Wacky3 to recompile the original emblems and alpha icons. It retains two RGBA source PNGs per expansion civilization and exports 270 DDS files across the nine established atlas sizes.

All fifteen civs now ship original leader, unit and building portraits, static diplomacy backgrounds, Dawn illustrations and setup maps. The Hollow Choir and Seventeenth Summer also have original emblems and flags, and the Candlekeepers' Vigil Keeper and Hall of Remembrance have original portraits. Unit and building world models still use the inherited game models.

Run `python tools/build_original_presentation.py` to compile the new artwork from each civilization's `Art/Sources/Presentation.png`, then `python tools/build_mod.py --package`. The [retained prompts](../tools/original_presentation_prompts.json) record the built-in imagegen inputs. Portraits use the nine native atlas sizes and gold rims. The leader art is 96 × 96 within its 128-pixel selection slot. Static diplomacy is 1600 × 1200, Dawn is 1024 × 768 and setup maps are 360 × 412. The validation scripts check active database references, atlas dimensions, portrait bounds and DDS payloads.
