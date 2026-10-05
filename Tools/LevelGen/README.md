# Level and art generators

Python scripts that draw the placeholder SVG art and write the level scenes
for each world. Run from this folder, e.g. `python gen_levels_41_50.py`.
They overwrite the files they generate, so hand edits to those level scenes
or SVGs are lost if a generator is re-run.

- `art.py` - shared drawing helpers (animals, toys, svg/place/write)
- `gen_animals.py` - Animals/, Toys/, Avatars/ SVGs
- `gen_tapmatch_art.py` - balloons, fruit, Levels 3-4
- `gen_levels_11_20.py` - World 2. NOTE: written before timers existed;
  re-running it drops the `time_limit` lines that were added to levels
  11-20 afterwards, so re-add them (see CLAUDE.md level table) or edit
  those scenes by hand instead.
- `gen_levels_21_30.py`, `gen_levels_31_40.py`, `gen_levels_41_50.py`
- `gen_mechanics_41_50.py` - base scenes for SlidePuzzle, SequenceMemory,
  ConnectDots, PictureSudoku

Older one-off generators for levels 1-10 were not kept.
