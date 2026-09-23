extends Control

@onready var play_button: Button = $Layout/PlayButton


func _ready() -> void:
	play_button.pressed.connect(GameManager.go_to_level_select)
