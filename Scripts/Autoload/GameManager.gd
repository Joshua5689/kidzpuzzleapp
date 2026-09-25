extends Node
## Global singleton: level registry, and the current player's unlocked
## levels, stars and saved progress (one save file per ProfileManager profile).

const MAIN_MENU_SCENE := "res://Scenes/UI/MainMenu.tscn"
const PROFILE_SELECT_SCENE := "res://Scenes/UI/ProfileSelect.tscn"
const PROFILE_EDIT_SCENE := "res://Scenes/UI/ProfileEdit.tscn"
const LEVEL_SELECT_SCENE := "res://Scenes/UI/LevelSelect.tscn"
const CELEBRATION_SCENE := "res://Scenes/UI/Celebration.tscn"

## Single source of truth for level order. LevelSelect builds its buttons from
## this list and the Next button uses it, so register every new level here.
## Levels whose scene file doesn't exist yet show as "coming soon".
const LEVELS: Array[Dictionary] = [
	{"title": "Puzzle", "scene": "res://Scenes/Levels/Level01_Puzzle.tscn"},
	{"title": "Count", "scene": "res://Scenes/Levels/Level02_CountNumbers.tscn"},
	{"title": "Colours", "scene": "res://Scenes/Levels/Level03_FindColours.tscn"},
	{"title": "Fruit", "scene": "res://Scenes/Levels/Level04_FindFruit.tscn"},
	{"title": "Colour In", "scene": "res://Scenes/Levels/Level05_ColourObject.tscn"},
	{"title": "Dog Maze", "scene": "res://Scenes/Levels/Level06_DogMaze.tscn"},
	{"title": "Differences", "scene": "res://Scenes/Levels/Level07_SpotDifferences.tscn"},
	{"title": "Bike Shapes", "scene": "res://Scenes/Levels/Level08_BikeShapes.tscn"},
	{"title": "Trace", "scene": "res://Scenes/Levels/Level09_TraceNumber.tscn"},
	{"title": "Pond", "scene": "res://Scenes/Levels/Level10_FindFrogsFish.tscn"},
	{"title": "Ducks", "scene": "res://Scenes/Levels/Level11_CountDucks.tscn"},
	{"title": "Farm", "scene": "res://Scenes/Levels/Level12_FarmPuzzle.tscn"},
	{"title": "Odd One", "scene": "res://Scenes/Levels/Level13_OddOneOut.tscn"},
	{"title": "Pairs", "scene": "res://Scenes/Levels/Level14_MemoryPairs.tscn"},
	{"title": "Butterfly", "scene": "res://Scenes/Levels/Level15_ColourButterfly.tscn"},
	{"title": "Bee Maze", "scene": "res://Scenes/Levels/Level16_BeeMaze.tscn"},
	{"title": "Sorting", "scene": "res://Scenes/Levels/Level17_SortToys.tscn"},
	{"title": "Park", "scene": "res://Scenes/Levels/Level18_ParkDifferences.tscn"},
	{"title": "Letters", "scene": "res://Scenes/Levels/Level19_TraceLetters.tscn"},
	{"title": "Night Sky", "scene": "res://Scenes/Levels/Level20_NightSky.tscn"},
	{"title": "Shadows", "scene": "res://Scenes/Levels/Level21_ShadowMatch.tscn"},
	{"title": "Patterns", "scene": "res://Scenes/Levels/Level22_WhatComesNext.tscn"},
	{"title": "Big Memory", "scene": "res://Scenes/Levels/Level23_BigMemory.tscn"},
	{"title": "Trace 4 5 6", "scene": "res://Scenes/Levels/Level24_TraceNumbers456.tscn"},
	{"title": "Adding", "scene": "res://Scenes/Levels/Level25_AddApples.tscn"},
	{"title": "Big & Small", "scene": "res://Scenes/Levels/Level26_BigAndSmall.tscn"},
	{"title": "Colours", "scene": "res://Scenes/Levels/Level27_SortColours.tscn"},
	{"title": "Bee Race", "scene": "res://Scenes/Levels/Level28_BeeRace.tscn"},
	{"title": "Beach", "scene": "res://Scenes/Levels/Level29_BeachDifferences.tscn"},
	{"title": "Party", "scene": "res://Scenes/Levels/Level30_FrogParty.tscn"},
]

## Levels are grouped into worlds of WORLD_SIZE. Inside an open world levels
## unlock one after another; the next world opens once the player has at
## least STARS_TO_OPEN_NEXT_WORLD stars from the world before it.
const WORLD_SIZE := 10
const STARS_TO_OPEN_NEXT_WORLD := 25

## Development switch: true opens every level regardless of the rules above.
const UNLOCK_ALL_LEVELS := false

## Session-only override for testing on a device (see LevelSelect: hold the
## title for 3 seconds). Never saved.
var unlock_all_this_session := false

signal level_completed(level_number: int, stars: int)

var completed_levels: Array[int] = []
## Best star score (1-3) per level number.
var best_stars: Dictionary = {}


func _ready() -> void:
	ProfileManager.profile_changed.connect(_load_progress)
	_load_progress()


func level_count() -> int:
	return LEVELS.size()


func level_title(level_number: int) -> String:
	return LEVELS[level_number - 1]["title"]


func level_exists(level_number: int) -> bool:
	if level_number < 1 or level_number > LEVELS.size():
		return false
	return ResourceLoader.exists(LEVELS[level_number - 1]["scene"])


func is_unlocked(level_number: int) -> bool:
	if UNLOCK_ALL_LEVELS or unlock_all_this_session:
		return true
	if not is_world_open(world_of(level_number)):
		return false
	var first_in_world := world_of(level_number) * WORLD_SIZE + 1
	return level_number == first_in_world or is_completed(level_number - 1)


## 0-based world index of a level.
func world_of(level_number: int) -> int:
	return floori(float(level_number - 1) / WORLD_SIZE)


func world_count() -> int:
	return ceili(float(LEVELS.size()) / WORLD_SIZE)


func world_stars(world: int) -> int:
	var total := 0
	for n in range(world * WORLD_SIZE + 1, mini((world + 1) * WORLD_SIZE, LEVELS.size()) + 1):
		total += stars_for(n)
	return total


func is_world_open(world: int) -> bool:
	if UNLOCK_ALL_LEVELS or unlock_all_this_session or world <= 0:
		return true
	return world_stars(world - 1) >= STARS_TO_OPEN_NEXT_WORLD and is_world_open(world - 1)


func is_completed(level_number: int) -> bool:
	return completed_levels.has(level_number)


func stars_for(level_number: int) -> int:
	return best_stars.get(level_number, 0)


func total_stars() -> int:
	var total := 0
	for stars in best_stars.values():
		total += stars
	return total


func all_levels_completed() -> bool:
	for n in range(1, LEVELS.size() + 1):
		if not completed_levels.has(n):
			return false
	return true


## Records a finished level. Returns true if this completion was the one that
## finished every level (so the celebration shows only once).
func complete_level(level_number: int, stars: int = 3) -> bool:
	var was_all_done := all_levels_completed()
	if not completed_levels.has(level_number):
		completed_levels.append(level_number)
	best_stars[level_number] = max(stars_for(level_number), stars)
	_save_progress()
	level_completed.emit(level_number, stars)
	return not was_all_done and all_levels_completed()


func go_to_level(level_number: int) -> void:
	if not level_exists(level_number):
		push_warning("Level %d has no scene yet" % level_number)
		go_to_level_select()
		return
	get_tree().change_scene_to_file(LEVELS[level_number - 1]["scene"])


## Goes to the next level if it exists and is unlocked, otherwise back to
## LevelSelect (which explains what's needed to open it).
func go_to_next_level(current_level: int) -> void:
	var next := current_level + 1
	if level_exists(next) and is_unlocked(next):
		go_to_level(next)
	else:
		go_to_level_select()


func go_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func go_to_level_select() -> void:
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)


func go_to_celebration() -> void:
	get_tree().change_scene_to_file(CELEBRATION_SCENE)


func go_to_profile_select() -> void:
	get_tree().change_scene_to_file(PROFILE_SELECT_SCENE)


## Opens the profile form; pass "" to create a new profile.
func go_to_profile_edit(profile_id: String) -> void:
	ProfileManager.editing_id = profile_id
	get_tree().change_scene_to_file(PROFILE_EDIT_SCENE)


func reset_progress() -> void:
	completed_levels.clear()
	best_stars.clear()
	_save_progress()


func _save_progress() -> void:
	if not ProfileManager.has_current():
		return
	var config := ConfigFile.new()
	config.set_value("progress", "completed_levels", completed_levels)
	config.set_value("progress", "best_stars", best_stars)
	config.save(ProfileManager.progress_path(ProfileManager.current_id))


func _load_progress() -> void:
	completed_levels.clear()
	best_stars = {}
	if not ProfileManager.has_current():
		return
	var config := ConfigFile.new()
	if config.load(ProfileManager.progress_path(ProfileManager.current_id)) != OK:
		return
	completed_levels.assign(config.get_value("progress", "completed_levels", []))
	best_stars = config.get_value("progress", "best_stars", {})
