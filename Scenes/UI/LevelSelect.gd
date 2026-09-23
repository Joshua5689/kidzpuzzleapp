extends Control
## Builds one button per level from GameManager.LEVELS.

@onready var levels_grid: GridContainer = $Layout/LevelsGrid
@onready var back_button: Button = $BackButton


func _ready() -> void:
	back_button.pressed.connect(GameManager.go_to_main_menu)
	for n in range(1, GameManager.level_count() + 1):
		levels_grid.add_child(_make_level_button(n))


func _make_level_button(level_number: int) -> Button:
	var button := Button.new()
	button.name = "Level%02dButton" % level_number
	button.custom_minimum_size = Vector2(260, 200)
	button.add_theme_font_size_override("font_size", 40)
	var label := "%d\n%s" % [level_number, GameManager.level_title(level_number)]
	if GameManager.is_completed(level_number):
		label += " ★"
	if not GameManager.level_exists(level_number):
		label = "%d\nComing soon" % level_number
		button.disabled = true
	elif not GameManager.is_unlocked(level_number):
		label = "%d\n🔒" % level_number
		button.disabled = true
	button.text = label
	button.pressed.connect(GameManager.go_to_level.bind(level_number))
	return button
