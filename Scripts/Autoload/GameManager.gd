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
]

## Keep true while levels are still being built so every level is reachable.
## Set to false before handing the app to kids.
const UNLOCK_ALL_LEVELS := true

signal level_completed(level_number: int, stars: int)

## Highest level the player may start (1-based).
var highest_unlocked: int = 1
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
	return UNLOCK_ALL_LEVELS or level_number <= highest_unlocked


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
	highest_unlocked = max(highest_unlocked, min(level_number + 1, LEVELS.size()))
	_save_progress()
	level_completed.emit(level_number, stars)
	return not was_all_done and all_levels_completed()


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


func go_to_celebration() -> void:
	get_tree().change_scene_to_file(CELEBRATION_SCENE)


func go_to_profile_select() -> void:
	get_tree().change_scene_to_file(PROFILE_SELECT_SCENE)


## Opens the profile form; pass "" to create a new profile.
func go_to_profile_edit(profile_id: String) -> void:
	ProfileManager.editing_id = profile_id
	get_tree().change_scene_to_file(PROFILE_EDIT_SCENE)


func reset_progress() -> void:
	highest_unlocked = 1
	completed_levels.clear()
	best_stars.clear()
	_save_progress()


func _save_progress() -> void:
	if not ProfileManager.has_current():
		return
	var config := ConfigFile.new()
	config.set_value("progress", "highest_unlocked", highest_unlocked)
	config.set_value("progress", "completed_levels", completed_levels)
	config.set_value("progress", "best_stars", best_stars)
	config.save(ProfileManager.progress_path(ProfileManager.current_id))


func _load_progress() -> void:
	highest_unlocked = 1
	completed_levels.clear()
	best_stars = {}
	if not ProfileManager.has_current():
		return
	var config := ConfigFile.new()
	if config.load(ProfileManager.progress_path(ProfileManager.current_id)) != OK:
		return
	highest_unlocked = config.get_value("progress", "highest_unlocked", 1)
	completed_levels.assign(config.get_value("progress", "completed_levels", []))
	best_stars = config.get_value("progress", "best_stars", {})
