extends Control
## "Who's playing?" — one big card per profile plus a New player card.
## This is the first screen when the app starts.

const CARD_SIZE := Vector2(320, 340)

@onready var title_label: Label = $Layout/TitleLabel
@onready var cards_grid: GridContainer = $Layout/CardsGrid


func _ready() -> void:
	var profiles := ProfileManager.profiles
	title_label.text = "Who's playing?" if not profiles.is_empty() else "Hello! Let's make your player"
	for profile in profiles:
		cards_grid.add_child(_make_profile_card(profile))
	if ProfileManager.can_add():
		cards_grid.add_child(_make_new_card())
	cards_grid.columns = clampi(cards_grid.get_child_count(), 1, 4)


func _make_profile_card(profile: Dictionary) -> Control:
	var column := VBoxContainer.new()
	column.name = "Card_%s" % profile["id"]
	column.add_theme_constant_override("separation", 12)

	var card := _make_card_button(UiStyle.CARD_COLOR)
	card.pressed.connect(_on_profile_pressed.bind(profile["id"]))
	var content := _card_content(card)
	var avatar := TextureRect.new()
	avatar.texture = ProfileManager.avatar_texture(profile["avatar"])
	avatar.custom_minimum_size = Vector2(200, 200)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(avatar)
	content.add_child(_card_label(profile["name"], 52))
	column.add_child(card)

	var edit := Button.new()
	edit.name = "EditButton"
	edit.text = "Edit"
	edit.custom_minimum_size = Vector2(0, 76)
	UiStyle.style_button(edit, UiStyle.MUTED_COLOR, 36)
	edit.pressed.connect(GameManager.go_to_profile_edit.bind(profile["id"]))
	column.add_child(edit)
	return column


func _make_new_card() -> Control:
	var column := VBoxContainer.new()
	column.name = "NewPlayerCard"
	var card := _make_card_button(UiStyle.NEW_CARD_COLOR)
	card.pressed.connect(GameManager.go_to_profile_edit.bind(""))
	var content := _card_content(card)
	content.add_child(_card_label("+", 150))
	content.add_child(_card_label("New player", 44))
	column.add_child(card)
	return column


func _make_card_button(color: Color) -> Button:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	UiStyle.style_button(card, color, 40, 40)
	return card


func _card_content(card: Button) -> VBoxContainer:
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(content)
	return content


func _card_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", UiStyle.TEXT_COLOR)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _on_profile_pressed(profile_id: String) -> void:
	MusicPlayer.play_ui_sound()
	ProfileManager.select(profile_id)
	GameManager.go_to_main_menu()
