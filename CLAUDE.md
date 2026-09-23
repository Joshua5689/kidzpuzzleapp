# Kids Puzzle App

Godot 4.x, GDScript. Offline puzzle game for kids on Android tablets, 10 levels.
Sideloaded for now, packaged for Play Store once validated with real kids.

## Architecture

The app is NOT 10 unique builds. It is a small set of reusable mechanic scenes
under `Scenes/Mechanics/`, each one instanced multiple times under
`Scenes/Levels/` with different artwork and exported config values.

Every mechanic script extends `MechanicLevel` (`Scripts/MechanicLevel.gd`),
which owns what all mechanics share: level_number, prompt, feedback text,
sounds, Back/Next buttons and `finish_level()`. Mechanic scenes must keep the
node paths it expects (Layout/PromptLabel, Layout/FeedbackLabel,
Layout/NextButton, BackButton, SfxPlayer).

Never duplicate mechanic logic into a level specific script. If a level needs
new behaviour, extend the shared mechanic script instead so every level using
that mechanic benefits.

## Level to mechanic mapping

| Level | Game | Mechanic used |
|---|---|---|
| 1 | Puzzle, arrange the image | DragRearrange |
| 2 | Count the numbers | CountSelect |
| 3 | Find the colours | TapMatch |
| 4 | Find the fruit | TapMatch |
| 5 | Colour the object | ColourFill |
| 6 | Help the dog find the bone | MazeDrag |
| 7 | Spot the differences | HiddenObjectHunt |
| 8 | Find the shapes in the bike | HiddenObjectHunt |
| 9 | Trace the number | TraceInput |
| 10 | Find the frogs, fish, gift box | HiddenObjectHunt |

## Folder structure

- `Scenes/Mechanics/<Mechanic>/` : one reusable base scene + script per mechanic
- `Scenes/Levels/` : one scene per level, each an instance of a mechanic scene
  with swapped assets and exported values
- `Scenes/UI/` : MainMenu, LevelSelect
- `Scripts/Autoload/GameManager.gd` : global singleton tracking unlocked
  levels and progress across scenes
- `Assets/Images/<category>/`, `Assets/Audio/SFX|Music/`

## Naming conventions

- Scene and script files: PascalCase, matching names (TapMatchLevel.tscn /
  TapMatchLevel.gd)
- Level scenes: `LevelNN_ShortName.tscn`, zero padded number
  (Level03_FindColours.tscn) so they sort correctly in the file browser
- Node names inside scenes: PascalCase and descriptive (ItemsContainer,
  FeedbackLabel, NextButton), never Node2, Button3, etc.
- Mechanic scripts expose their per level config through `@export` vars,
  never hardcoded values, so one script drives every level using that
  mechanic

## Adding a new level

1. Scene > New Inherited Scene, pick the mechanic scene from `Scenes/Mechanics/`
   (inherit, don't duplicate, so fixes to the base scene reach every level)
2. Save into `Scenes/Levels/` as `LevelNN_ShortName.tscn`
3. Add/swap artwork on the TextureButtons/TextureRects
4. Set exported variables on the root node in the Inspector (e.g. level_number,
   prompt_text, correct_items)
5. Make sure the level's path is in `LEVELS` in `Scripts/Autoload/GameManager.gd`.
   LevelSelect builds its buttons from that list and the Next button follows it.
   Levels whose scene file doesn't exist yet show as "Coming soon".

### HiddenObjectHunt levels

Set the picture on `SceneImage` (texture + custom_minimum_size = the size it
should display at), then add `Hotspot` nodes (Add Child Node > Hotspot) under
`SceneImage/Hotspots`, drawn over each thing to find. Set each hotspot's
`category` and `icon`; hotspots sharing a category are counted together in the
checklist. For spot-the-difference, also set a texture on `CompareImage`
(same size); hotspots are placed on the left picture only.

## Progress / unlocking

`GameManager.UNLOCK_ALL_LEVELS` is `true` during development. Set it to `false`
before testing with kids so levels unlock in order. Progress is saved to
`user://progress.cfg`.

## Running and testing

- Run current scene in editor: F6
- Run project from CLI: `godot --path . --scene Scenes/Levels/Level03_FindColours.tscn`
- Headless check for script errors: `godot --headless --check-only --path .`
- Godot is not on PATH. Console build: `C:\Users\joshu\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`
