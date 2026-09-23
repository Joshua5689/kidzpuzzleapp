extends Node
## Global singleton: level registry, unlocked levels and saved progress.

const SAVE_PATH := "user://progress.cfg"
const MAIN_MENU_SCENE := "res://Scenes/UI/MainMenu.tscn"
const LEVEL_SELECT_SCENE := "res://Scenes/UI/LevelSelect.tscn"

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
]

## Keep true while levels are still being built so every level is reachable.
## Set to false before handing the app to kids.
const UNLOCK_ALL_LEVELS := true

signal level_completed(level_number: int)

## Highest level the player may start (1-based).
var highest_unlocked: int = 1
var completed_levels: Array[int] = []


func _ready() -> void:
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
	return UNLOCK_ALL_LEVELS or level_number <= highest_unlocked


func is_completed(level_number: int) -> bool:
	return completed_levels.has(level_number)


func complete_level(level_number: int) -> void:
	if not completed_levels.has(level_number):
		completed_levels.append(level_number)
	highest_unlocked = max(highest_unlocked, min(level_number + 1, LEVELS.size()))
	_save_progress()
	level_completed.emit(level_number)


func go_to_level(level_number: int) -> void:
	if not level_exists(level_number):
		push_warning("Level %d has no scene yet" % level_number)
		go_to_level_select()
		return
	get_tree().change_scene_to_file(LEVELS[level_number - 1]["scene"])


## Goes to the next level that has a scene, or back to LevelSelect if none.
func go_to_next_level(current_level: int) -> void:
	for n in range(current_level + 1, LEVELS.size() + 1):
		if level_exists(n):
			go_to_level(n)
			return
	go_to_level_select()


func go_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func go_to_level_select() -> void:
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)


func reset_progress() -> void:
	highest_unlocked = 1
	completed_levels.clear()
	_save_progress()


func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "highest_unlocked", highest_unlocked)
	config.set_value("progress", "completed_levels", completed_levels)
	config.save(SAVE_PATH)


func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	highest_unlocked = config.get_value("progress", "highest_unlocked", 1)
	completed_levels.assign(config.get_value("progress", "completed_levels", []))
