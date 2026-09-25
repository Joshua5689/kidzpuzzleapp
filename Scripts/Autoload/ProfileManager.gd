extends Node
## Global singleton: the player profiles on this device (name, gender, age,
## avatar) and which one is playing. Everything is stored locally in
## user://profiles.cfg and never leaves the device. Each profile's progress
## lives in its own file (see progress_path()), loaded by GameManager.

const PROFILES_PATH := "user://profiles.cfg"
## Pre-profile save file; adopted by the first profile created.
const LEGACY_PROGRESS_PATH := "user://progress.cfg"
const MAX_PROFILES := 6
const MAX_NAME_LENGTH := 12
const MIN_AGE := 2
const MAX_AGE := 6

## Avatar id -> picture shown on the profile card.
const AVATARS := {
	"frog": "res://Assets/Images/Avatars/Frog.svg",
	"duck": "res://Assets/Images/Avatars/Duck.svg",
	"bee": "res://Assets/Images/Avatars/Bee.svg",
	"owl": "res://Assets/Images/Avatars/Owl.svg",
	"dog": "res://Assets/Images/Avatars/Dog.svg",
	"fish": "res://Assets/Images/Avatars/Fish.svg",
}
const GENDERS := ["boy", "girl", "unspecified"]

signal profile_changed

## Each profile: {"id": String, "name": String, "gender": String, "age": int, "avatar": String}
var profiles: Array[Dictionary] = []
var current_id := ""
## Set before opening ProfileEdit: "" creates a new profile, an id edits one.
var editing_id := ""


func _ready() -> void:
	_load()


func has_current() -> bool:
	return get_profile(current_id) != {}


func current() -> Dictionary:
	return get_profile(current_id)


func get_profile(id: String) -> Dictionary:
	for profile in profiles:
		if profile["id"] == id:
			return profile
	return {}


func can_add() -> bool:
	return profiles.size() < MAX_PROFILES


func avatar_texture(avatar_id: String) -> Texture2D:
	return load(AVATARS.get(avatar_id, AVATARS["frog"]))


## Returns the new profile's id.
func create_profile(profile_name: String, gender: String, age: int, avatar: String) -> String:
	var id := "p%d" % Time.get_unix_time_from_system()
	while get_profile(id) != {}:
		id += "x"
	var is_first := profiles.is_empty()
	profiles.append(_clean({"id": id, "name": profile_name, "gender": gender, "age": age, "avatar": avatar}))
	if is_first and FileAccess.file_exists(LEGACY_PROGRESS_PATH):
		DirAccess.rename_absolute(LEGACY_PROGRESS_PATH, progress_path(id))
	_save()
	return id


func update_profile(id: String, profile_name: String, gender: String, age: int, avatar: String) -> void:
	for i in profiles.size():
		if profiles[i]["id"] == id:
			profiles[i] = _clean({"id": id, "name": profile_name, "gender": gender, "age": age, "avatar": avatar})
	_save()
	if id == current_id:
		profile_changed.emit()


func delete_profile(id: String) -> void:
	profiles = profiles.filter(func(p): return p["id"] != id)
	DirAccess.remove_absolute(progress_path(id))
	if current_id == id:
		current_id = ""
		profile_changed.emit()
	_save()


func select(id: String) -> void:
	if get_profile(id) == {}:
		return
	current_id = id
	_save()
	profile_changed.emit()


func progress_path(id: String) -> String:
	return "user://progress_%s.cfg" % id


func _clean(profile: Dictionary) -> Dictionary:
	profile["name"] = String(profile["name"]).strip_edges().left(MAX_NAME_LENGTH)
	profile["age"] = clampi(int(profile["age"]), MIN_AGE, MAX_AGE)
	if not GENDERS.has(profile["gender"]):
		profile["gender"] = "unspecified"
	if not AVATARS.has(profile["avatar"]):
		profile["avatar"] = "frog"
	return profile


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("profiles", "list", profiles)
	config.set_value("profiles", "current", current_id)
	config.save(PROFILES_PATH)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(PROFILES_PATH) != OK:
		return
	profiles.assign(config.get_value("profiles", "list", []))
	current_id = config.get_value("profiles", "current", "")
