extends Control
## One page per world (GameManager.WORLD_SIZE levels): a button per level with
## its best stars, the world's star total, and — for a locked world — how many
## stars are still needed to open it. When a world is finished but the next
## one is still locked, levels without 3 stars wobble to say "play me again".

const STAR_TEXTURE: Texture2D = preload("res://Assets/Images/UI/Star.svg")
const LOCK_TEXTURE: Texture2D = preload("res://Assets/Images/UI/Lock.svg")
const MISSED_STAR_COLOR := Color(0.3, 0.3, 0.35, 0.35)
## Spoken versions of the page messages (fixed wording, so one recording each).
const LOCKED_LINE := "This world is locked. Win more stars to open it!"
const WOBBLY_LINE := "Play the wobbly games again to win more stars!"

## Remembered while the app runs, so coming back from a level keeps the page
## (but only for the same player: a new player starts where they are).
static var _page := -1
static var _page_player := ""

@onready var title_label: Label = $Layout/TitleLabel
@onready var page_label: Label = $Layout/WorldRow/PageLabel
@onready var stars_label: Label = $Layout/WorldRow/StarsLabel
@onready var levels_grid: GridContainer = $Layout/LevelsGrid
@onready var locked_label: Label = $Layout/LockedLabel
@onready var back_button: Button = $BackButton
@onready var prev_page_button: Button = $PrevPageButton
@onready var next_page_button: Button = $NextPageButton


func _ready() -> void:
	back_button.pressed.connect(GameManager.go_to_main_menu)
	UiStyle.style_button(prev_page_button, UiStyle.MUTED_COLOR, 64)
	UiStyle.style_button(next_page_button, UiStyle.MUTED_COLOR, 64)
	prev_page_button.pressed.connect(func(): show_page(_page - 1))
	next_page_button.pressed.connect(func(): show_page(_page + 1))
	if _page < 0 or _page_player != ProfileManager.current_id:
		_page = GameManager.world_of(_first_playable_unfinished_level())
		_page_player = ProfileManager.current_id
	show_page(_page)


func show_page(page: int) -> void:
	_page = clampi(page, 0, GameManager.world_count() - 1)
	for child in levels_grid.get_children():
		levels_grid.remove_child(child)
		child.queue_free()
	var first := _page * GameManager.WORLD_SIZE + 1
	var last := mini(first + GameManager.WORLD_SIZE - 1, GameManager.level_count())
	for n in range(first, last + 1):
		levels_grid.add_child(_make_level_button(n))

	page_label.text = "World %d · Levels %d - %d  " % [_page + 1, first, last]
	stars_label.text = "%d / %d" % [GameManager.world_stars(_page), (last - first + 1) * 3]
	if not GameManager.is_world_open(_page):
		locked_label.text = "Win %d more stars in World %d to open World %d!" % [
			GameManager.STARS_TO_OPEN_NEXT_WORLD - GameManager.world_stars(_page - 1), _page, _page + 1]
		Voice.say(LOCKED_LINE)
	elif needs_more_stars(_page):
		Voice.say(WOBBLY_LINE)
		locked_label.text = "Play the wobbly games again to win %d more stars and open World %d!" % [
			GameManager.STARS_TO_OPEN_NEXT_WORLD - GameManager.world_stars(_page), _page + 2]
		for n in range(first, last + 1):
			if GameManager.stars_for(n) < 3:
				_wobble(levels_grid.get_node("Level%02dButton" % n))
	else:
		locked_label.text = ""
	prev_page_button.visible = _page > 0
	next_page_button.visible = _page < GameManager.world_count() - 1


## True when every level of an open world is done but there aren't enough
## stars yet to open the next world.
func needs_more_stars(world: int) -> bool:
	if world + 1 >= GameManager.world_count() or GameManager.is_world_open(world + 1):
		return false
	var first := world * GameManager.WORLD_SIZE + 1
	for n in range(first, mini(first + GameManager.WORLD_SIZE, GameManager.level_count() + 1)):
		if not GameManager.is_completed(n):
			return false
	return true


## Gentle side-to-side rock, repeating, with a pause so it reads as a nudge.
func _wobble(button: Control) -> void:
	button.set_meta("wobble", true)
	button.resized.connect(func(): button.pivot_offset = button.size / 2.0)
	var tween := button.create_tween().set_loops()
	tween.tween_interval(0.6)
	for angle in [-0.06, 0.06, -0.04, 0.04, 0.0]:
		tween.tween_property(button, "rotation", angle, 0.09)


## The first unlocked level not finished yet, so the screen opens where the
## child left off.
func _first_playable_unfinished_level() -> int:
	var best := 1
	for n in range(1, GameManager.level_count() + 1):
		if GameManager.is_unlocked(n):
			best = n
			if not GameManager.is_completed(n):
				return n
	return best


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
		# Number on top, padlock underneath (the button's own icon slot).
		button.text = str(level_number)
		button.disabled = true
		button.icon = LOCK_TEXTURE
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_BOTTOM
		button.add_theme_constant_override("icon_max_width", 90)
		button.add_theme_color_override("icon_disabled_color", Color.WHITE)
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
