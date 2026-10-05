# Level and art generators

Python scripts that draw the placeholder SVG art and write the level scenes
for each world. Run from this folder, e.g. `python gen_levels_31_40.py`.
They overwrite the files they generate, so hand edits to those level scenes
or SVGs will be lost if a generator is re-run.

- `art.py` - shared drawing helpers (animals, toys, svg/place/write)
- `gen_animals.py` - Animals/, Toys/, Avatars/ SVGs
- `gen_tapmatch_art.py` - balloons, fruit, Levels 3-4
- `gen_levels_11_20.py`, `gen_levels_21_30.py`, `gen_levels_31_40.py`

Older one-off generators for levels 1-10 were not kept.
