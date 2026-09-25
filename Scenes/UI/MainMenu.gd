extends Control

@onready var avatar: TextureRect = $Layout/PlayerRow/Avatar
@onready var greeting_label: Label = $Layout/PlayerRow/GreetingLabel
@onready var play_button: Button = $Layout/PlayButton
@onready var music_button: Button = $MusicButton
@onready var change_player_button: Button = $ChangePlayerButton


func _ready() -> void:
	if not ProfileManager.has_current():
		# Nobody chosen yet (first launch or profile deleted): ask who's playing.
		GameManager.go_to_profile_select.call_deferred()
		return
	var profile := ProfileManager.current()
	avatar.texture = ProfileManager.avatar_texture(profile["avatar"])
	greeting_label.text = "Hi, %s!" % profile["name"]

	UiStyle.style_button(play_button, UiStyle.GO_COLOR, 72, 40)
	UiStyle.style_button(music_button, UiStyle.MUTED_COLOR, 40)
	UiStyle.style_button(change_player_button, UiStyle.MUTED_COLOR, 40)
	play_button.pressed.connect(GameManager.go_to_level_select)
	change_player_button.pressed.connect(GameManager.go_to_profile_select)
	music_button.pressed.connect(func(): MusicPlayer.set_music_enabled(not MusicPlayer.music_enabled))
	MusicPlayer.music_toggled.connect(_update_music_button)
	_update_music_button(MusicPlayer.music_enabled)


func _update_music_button(enabled: bool) -> void:
	music_button.text = "Music: On" if enabled else "Music: Off"
