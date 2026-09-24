extends Control
## Builds one button per level from GameManager.LEVELS, with the best stars
## earned on each.

const STAR_TEXTURE: Texture2D = preload("res://Assets/Images/UI/Star.svg")
const MISSED_STAR_COLOR := Color(0.3, 0.3, 0.35, 0.35)

@onready var levels_grid: GridContainer = $Layout/LevelsGrid
@onready var back_button: Button = $BackButton


func _ready() -> void:
	back_button.pressed.connect(GameManager.go_to_main_menu)
	for n in range(1, GameManager.level_count() + 1):
		levels_grid.add_child(_make_level_button(n))


func _make_level_button(level_number: int) -> Button:
	var button := Button.new()
	button.name = "Level%02dButton" % level_number
	button.custom_minimum_size = Vector2(260, 230)
	button.add_theme_font_size_override("font_size", 40)
	button.pressed.connect(GameManager.go_to_level.bind(level_number))

	if not GameManager.level_exists(level_number):
		button.text = "%d\nComing soon" % level_number
		button.disabled = true
	elif not GameManager.is_unlocked(level_number):
		button.text = "%d\nLocked" % level_number
		button.disabled = true
	else:
		# Leave room at the bottom for the stars row.
		button.text = "%d\n%s\n" % [level_number, GameManager.level_title(level_number)]
		if GameManager.is_completed(level_number):
			button.add_child(_make_stars_row(GameManager.stars_for(level_number)))
	return button


func _make_stars_row(stars: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Stars"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	row.offset_top = -62
	row.offset_bottom = -14
	row.offset_left = -80
	row.offset_right = 80
	for i in 3:
		var star := TextureRect.new()
		star.texture = STAR_TEXTURE
		star.custom_minimum_size = Vector2(46, 46)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if i >= stars:
			star.modulate = MISSED_STAR_COLOR
		row.add_child(star)
	return row
