extends Node
## Global singleton: the spoken voice. Every line is a pre-generated OGG in
## res://Assets/Audio/Voice/, named by slug(text) (made by
## Tools/Voice/gen_voice.py), so the voice is the same on every tablet and
## needs no internet or device speech engine. To use a real recording for a
## line, drop an .ogg with the same name over the generated one.
## Text without a file is skipped quietly and listed in missing_lines.

const VOICE_DIR := "res://Assets/Audio/Voice/"
const SETTINGS_PATH := "user://settings.cfg"
const VOLUME_DB := 0.0

signal voice_toggled(enabled: bool)

var voice_enabled := true
## text -> true for lines that had no file (checked by tests).
var missing_lines := {}
var _player: AudioStreamPlayer
## The line playing now is a prompt; "soft" lines (feedback) won't cut it off.
var _important := false


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "VoicePlayer"
	_player.volume_db = VOLUME_DB
	add_child(_player)
	_load_settings()


## Speaks `text`. Important lines (prompts, questions) interrupt anything;
## soft lines (feedback like "Great!") are skipped while a prompt is playing.
func say(text: String, important := true) -> void:
	if not voice_enabled or text.strip_edges().is_empty():
		return
	if not important and _important and _player.playing:
		return
	var stream := stream_for(text)
	if stream == null:
		missing_lines[text] = true
		return
	_player.stream = stream
	_player.play()
	_important = important
	MusicPlayer.duck(stream.get_length())


## Says `text` after `delay` seconds; the tween belongs to `owner_node`,
## so nothing is said if that screen has gone by then.
func say_later(owner_node: Node, text: String, delay: float, important := true) -> void:
	var tween := owner_node.create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(say.bind(text, important))


func stop() -> void:
	_player.stop()


func is_speaking() -> bool:
	return _player.playing


func has_line(text: String) -> bool:
	return ResourceLoader.exists(path_for(text))


func stream_for(text: String) -> AudioStream:
	var path := path_for(text)
	if not ResourceLoader.exists(path):
		return null
	return load(path)


func path_for(text: String) -> String:
	return VOICE_DIR + slug(text) + ".ogg"


## File name for a line: lower case, runs of anything but a-z / 0-9 become
## "_", trimmed, at most 60 characters. Must match slug() in gen_voice.py.
static func slug(text: String) -> String:
	var out := ""
	var gap := false
	for c in text.to_lower():
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			if gap and not out.is_empty():
				out += "_"
			out += c
			gap = false
		else:
			gap = true
	return out.left(60)


func set_voice_enabled(enabled: bool) -> void:
	voice_enabled = enabled
	if not enabled:
		stop()
	_save_settings()
	voice_toggled.emit(enabled)


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", "voice_enabled", voice_enabled)
	config.save(SETTINGS_PATH)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		voice_enabled = config.get_value("audio", "voice_enabled", true)
