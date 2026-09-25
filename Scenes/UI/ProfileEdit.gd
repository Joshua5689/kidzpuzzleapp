extends Control
## Create / edit a player profile: name, picture, gender and age.
## ProfileManager.editing_id says which profile ("" = new one).

@onready var title_label: Label = $Layout/TitleLabel
@onready var name_edit: LineEdit = $Layout/Form/NameEdit
@onready var avatar_row: HBoxContainer = $Layout/Form/AvatarRow
@onready var gender_row: HBoxContainer = $Layout/Form/GenderRow
@onready var age_row: HBoxContainer = $Layout/Form/AgeRow
@onready var cancel_button: Button = $Layout/Buttons/CancelButton
@onready var delete_button: Button = $Layout/Buttons/DeleteButton
@onready var save_button: Button = $Layout/Buttons/SaveButton
@onready var confirm_delete: Control = $ConfirmDelete
@onready var confirm_label: Label = $ConfirmDelete/Card/Content/MessageLabel
@onready var confirm_yes: Button = $ConfirmDelete/Card/Content/Buttons/YesButton
@onready var confirm_no: Button = $ConfirmDelete/Card/Content/Buttons/NoButton

const GENDER_LABELS := {"boy": "Boy", "girl": "Girl", "unspecified": "Skip"}

var _editing: Dictionary = {}
var _avatar := "frog"
var _gender := "unspecified"
var _age := 0
var _avatar_buttons := {}


func _ready() -> void:
	_editing = ProfileManager.get_profile(ProfileManager.editing_id)
	title_label.text = "Edit player" if _editing else "New player"
	name_edit.max_length = ProfileManager.MAX_NAME_LENGTH
	name_edit.text_changed.connect(func(_t): _update_save_button())

	_build_avatar_choices()
	_build_choices(gender_row, GENDER_LABELS.keys(), func(value): return GENDER_LABELS[value], _on_gender_chosen)
	var ages := range(ProfileManager.MIN_AGE, ProfileManager.MAX_AGE + 1)
	_build_choices(age_row, ages, func(value): return str(value), _on_age_chosen)

	UiStyle.style_button(cancel_button, UiStyle.MUTED_COLOR, 48)
	UiStyle.style_button(delete_button, UiStyle.DANGER_COLOR, 48)
	UiStyle.style_button(save_button, UiStyle.GO_COLOR, 52)
	UiStyle.style_button(confirm_no, UiStyle.MUTED_COLOR, 48)
	UiStyle.style_button(confirm_yes, UiStyle.DANGER_COLOR, 48)
	cancel_button.pressed.connect(GameManager.go_to_profile_select)
	save_button.pressed.connect(_on_save_pressed)
	delete_button.visible = not _editing.is_empty()
	delete_button.pressed.connect(_on_delete_pressed)
	confirm_no.pressed.connect(func(): confirm_delete.visible = false)
	confirm_yes.pressed.connect(_on_delete_confirmed)
	confirm_delete.visible = false

	if _editing:
		name_edit.text = _editing["name"]
		_select_avatar(_editing["avatar"])
		_press_choice(gender_row, _editing["gender"])
		_gender = _editing["gender"]
		_press_choice(age_row, _editing["age"])
		_age = _editing["age"]
	else:
		_select_avatar(ProfileManager.AVATARS.keys()[ProfileManager.profiles.size() % ProfileManager.AVATARS.size()])
		_press_choice(gender_row, "unspecified")
	_update_save_button()


func _build_avatar_choices() -> void:
	for avatar_id in ProfileManager.AVATARS:
		var button := TextureButton.new()
		button.name = "Avatar_%s" % avatar_id
		button.texture_normal = ProfileManager.avatar_texture(avatar_id)
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.custom_minimum_size = Vector2(140, 140)
		button.pressed.connect(_select_avatar.bind(avatar_id))
		avatar_row.add_child(button)
		_avatar_buttons[avatar_id] = button


func _build_choices(row: HBoxContainer, values: Array, label_for: Callable, on_chosen: Callable) -> void:
	var group := ButtonGroup.new()
	for value in values:
		var button := Button.new()
		button.name = "Choice_%s" % value
		button.text = label_for.call(value)
		button.custom_minimum_size = Vector2(150, 110)
		UiStyle.style_choice(button, 48)
		button.button_group = group
		button.set_meta("value", value)
		button.pressed.connect(on_chosen.bind(value))
		row.add_child(button)


func _press_choice(row: HBoxContainer, value) -> void:
	for button in row.get_children():
		if button.get_meta("value") == value:
			button.button_pressed = true


func _select_avatar(avatar_id: String) -> void:
	_avatar = avatar_id
	for id in _avatar_buttons:
		var button: TextureButton = _avatar_buttons[id]
		var chosen: bool = id == avatar_id
		button.modulate = Color.WHITE if chosen else Color(1, 1, 1, 0.4)
		button.pivot_offset = button.custom_minimum_size / 2.0
		button.scale = Vector2(1.15, 1.15) if chosen else Vector2.ONE
	if is_node_ready():
		MusicPlayer.play_ui_sound()


func _on_gender_chosen(value: String) -> void:
	_gender = value


func _on_age_chosen(value: int) -> void:
	_age = value
	_update_save_button()


func _update_save_button() -> void:
	save_button.disabled = name_edit.text.strip_edges().is_empty() or _age == 0


func _on_save_pressed() -> void:
	var player_name := name_edit.text.strip_edges()
	if _editing:
		ProfileManager.update_profile(_editing["id"], player_name, _gender, _age, _avatar)
		GameManager.go_to_profile_select()
	else:
		var id := ProfileManager.create_profile(player_name, _gender, _age, _avatar)
		ProfileManager.select(id)
		GameManager.go_to_main_menu()


func _on_delete_pressed() -> void:
	confirm_label.text = "Delete %s?\nTheir stars will be lost." % _editing["name"]
	confirm_delete.visible = true


func _on_delete_confirmed() -> void:
	ProfileManager.delete_profile(_editing["id"])
	GameManager.go_to_profile_select()
