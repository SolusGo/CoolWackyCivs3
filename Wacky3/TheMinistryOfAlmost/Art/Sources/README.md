# Original artwork sources and prompts

The five illustrated PNGs were generated with the **built-in imagegen tool** for this project on 2 November 2026. They are original fictional artwork, retained at native resolution as editable raster masters. The underlying generator is stochastic; rebuilding textures from these retained masters is deterministic. No API key, image service, Wacky2 asset or remote runtime dependency is needed to rebuild DDS files.

`tools/build_art.py` compiles all sources, derives the circular leader portrait, creates the original white II alpha glyph programmatically, writes legacy uncompressed BGRA/RGBA8888 DDS textures, and generates `ArtReview.png`. All icon sizes (256, 128, 80, 64, 48, 45, 32, 24, 16) have complete mip chains down to 1×1. The 1024×768 Dawn, 1600×1200 static leader and 360×412 capital-detail map panel have one mip level, appropriate for fixed UI illustrations. Transparent source alpha is preserved in colored icons. No custom unit model or animated diplomacy model is provided; the native Spearman model/flag and static leader scene are deliberate choices.

Final generation prompts:

## Leader.png

Use case: stylized-concept. Asset: finished Civilization V fictional leader portrait, landscape 4:3 framing. Acting Chancellor Penultimate, dignified middle-aged woman with dark graying hair seated at a formal desk in an elaborate silver ceremonial uniform with navy sash and restrained gold trim, serious capable expression. Hundreds of silver medals carefully displayed in cabinets throughout grand classical government office; enormous oil portrait of the first Chancellor behind her. Painterly realistic historical strategy game diplomacy presentation, warm window light, deep navy shadows, silver, muted gold, beautiful materials and detailed professional finish. No UI, no captions or watermark.

## Dawn.png

Use case: stylized-concept. Finished historical strategy game Dawn of Man illustration, landscape 4:3. The grand capital Runner-Up of The Ministry of Almost: monumental neoclassical administrative palace and broad civic plaza, elegant silver banners with a bold Roman numeral II and deep navy borders, muted gold details, paired silver laurels and understated runner-up trophies around a central second-place podium monument. Citizens small for scale. Dawn light, sweeping classical Civilization V painterly presentation, atmospheric perspective, professional environmental concept art, rich navy silver muted gold white palette. No modern vehicles, no text except II, no interface, no watermark. Compose full frame for 1024x768 delivery.

## Emblem.png

Transparent background enabled. Use case: logo-brand. One finished circular civilization icon on transparent background. A bold bright silver medal engraved with very clear Roman numeral II, encircled by a refined muted gold circular Civilization V style rim, deep navy enamel inset and crisp white highlights. Strictly frontal symmetric centered medallion, simple legible silhouette at 32px, polished sculptural metal, sophisticated historical strategy game emblem. Circle occupies 90 percent of square canvas, fully transparent exterior, no drop shadow beyond circle, no text except II, no watermark.

## Unit.png

Transparent background enabled. Use case: stylized-concept. Single finished circular Civilization V style unit portrait icon on transparent background. Second Wind Guard, ancient professional spearman in silver helmet and polished silver cuirass over navy tunic, upright spear and large deep navy shield with silver Roman numeral II, determined resilient stance, three-quarter upper body. Refined muted gold circular rim, atmospheric blue backdrop INSIDE circular portrait only. Dramatic painterly historical strategy game illustration, readable strong silhouette at 64px, cohesive navy silver muted gold colors, no words, no watermark, transparent outside rim.

## Academy.png

Transparent background enabled. Use case: stylized-concept. One finished circular Civilization V style building icon, transparent outside circular muted gold rim. Runner-Up Academy: beautiful neoclassical library with silver dome, white stone columns, deep navy banners bearing a clear silver Roman numeral II, silver laurel motif over doorway, warm scholarly light from windows. Three-quarter architectural perspective, strong simple composition legible at 64px, painterly historical strategy game aesthetic, navy silver white muted gold cohesive palette. Full building fits comfortably INSIDE circle against deep blue sky. No interface, no words except II, no watermark.
