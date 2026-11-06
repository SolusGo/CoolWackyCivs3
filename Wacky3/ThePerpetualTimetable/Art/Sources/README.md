# Timetable artwork sources

Five original PNG masters were created with the built-in imagegen tool on 6 November 2026: `Emblem.png`, `Leader.png`, `Dawn.png`, `Unit.png`, `Office.png`. Exact prompts and generation mode are retained in `GenerationPrompts.json`. The emblem, unit and Office use genuine generated transparency outside their circular gold rims. The leader is a static scene, not an animated model. No temporary portrait assets are used.

Run `python tools/build_timetable_art.py` from Wacky3 to reproduce 45 one-cell icon DDS files (256, 128, 80, 64, 48, 45, 32, 24, 16), three illustration DDS files, the static leader scene XML and `Timetable_Art.sql`. It reuses the pack's DDS writer: legacy uncompressed BGRA/RGBA8888, standard header, full icon mip chains, transparent icon edges. PortraitIndex is zero in every one-cell atlas. `Alpha.png` is an original deterministic wheel/clock glyph; `ArtReview.png` is the compiled review sheet. `Sources` files are deliberately excluded from the install manifest/ZIP.

The Dawn image is 1024×768, leader background 1600×1200 and map illustration 360×412. All consuming filenames/atlas names are unique within the pack. Unit 3D model/animations/flag and Office world model remain inherited native Worker/Workshop assets. Civ city style uses native America references. Actual game presentation still needs native acceptance.
