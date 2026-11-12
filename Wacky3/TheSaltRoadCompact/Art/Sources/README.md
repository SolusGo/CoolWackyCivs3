# SALT retained art masters

Older merchant matriarch; knowing smile, white eyebrow streak, low turquoise wrap and coral robe.

Built-in image_gen generated six independent PNG masters: `Leader.png`, `Emblem.png`, `Unit.png`, `Building.png`, `Dawn.png` and `Capital.png`. Exact final prompts and transparent-background settings are in [Prompts.json](Prompts.json). Source hashes and provenance are in `Provenance.json`. The emblem was requested with genuine transparency. No stock artwork was copied.

`Alpha.png`, `ArtReview.png` and `CompiledHashes.json` are deterministic compiler outputs. Rebuild with `python tools/build_daily_art.py --civ SALT` from Wacky3. The compiler handles only engine preparation: crop, circular rim, size conversion, code-native glyphs, mip chains and legacy DDS encoding. Visual content was created by image_gen. See [the full art guide](../README.md).
