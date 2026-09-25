extends Node
## Global singleton: background music that keeps playing across scene
## changes, plus the saved music on/off setting.

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_MUSIC_PATH := "res://Assets/Audio/Music/HappyTune.wav"
const MUSIC_VOLUME_DB := -10.0
const DUCKED_VOLUME_DB := -24.0
const TAP_SOUND: AudioStream = preload("res://Assets/Audio/SFX/Tap.wav")

signal music_toggled(enabled: bool)

var music_enabled := true
var _player: AudioStreamPlayer
## For menu sounds that must survive a scene change (e.g. tapping a card
## that immediately opens another screen).
var _ui_player: AudioStreamPlayer
var _duck_tween: Tween


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "Music"
	_player.volume_db = MUSIC_VOLUME_DB
	# WAVs don't loop by default; restart when the track ends.
	_player.finished.connect(_player.play)
	add_child(_player)
	_ui_player = AudioStreamPlayer.new()
	_ui_player.name = "UiSfx"
	add_child(_ui_player)
	_load_settings()
	play(load(DEFAULT_MUSIC_PATH))


## Switches track (no-op if it's already the current one).
func play(stream: AudioStream) -> void:
	if _player.stream == stream and _player.playing:
		return
	_player.stream = stream
	if music_enabled:
		_player.play()


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if enabled and not _player.playing:
		_player.play()
	elif not enabled:
		_player.stop()
	_save_settings()
	music_toggled.emit(enabled)


func play_ui_sound(stream: AudioStream = TAP_SOUND) -> void:
	_ui_player.stream = stream
	_ui_player.play()


## Temporarily lowers the music, e.g. under a fanfare.
func duck(seconds: float) -> void:
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(_player, "volume_db", DUCKED_VOLUME_DB, 0.2)
	_duck_tween.tween_interval(seconds)
	_duck_tween.tween_property(_player, "volume_db", MUSIC_VOLUME_DB, 0.8)


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", "music_enabled", music_enabled)
	config.save(SETTINGS_PATH)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		music_enabled = config.get_value("audio", "music_enabled", true)
