extends Control

@onready var play_button: Button = $Layout/PlayButton
@onready var music_button: Button = $MusicButton


func _ready() -> void:
	play_button.pressed.connect(GameManager.go_to_level_select)
	music_button.pressed.connect(func(): MusicPlayer.set_music_enabled(not MusicPlayer.music_enabled))
	MusicPlayer.music_toggled.connect(_update_music_button)
	_update_music_button(MusicPlayer.music_enabled)


func _update_music_button(enabled: bool) -> void:
	music_button.text = "Music: On" if enabled else "Music: Off"
