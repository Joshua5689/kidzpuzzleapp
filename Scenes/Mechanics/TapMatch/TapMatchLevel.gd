extends MechanicLevel
## TapMatch mechanic: the child taps every correct item among the ones shown.
##
## Single round: add TextureButtons under Layout/ItemsContainer and pick the
## correct ones in `correct_items`.
## Several rounds: add TapRound nodes under Layout/Rounds instead (each with
## its own buttons, prompt, correct items and optional clue pictures). They are
## played in order and ItemsContainer is ignored.

## Buttons under ItemsContainer that count as correct. All must be tapped.
@export var correct_items: Array[NodePath] = []
## Shown after each round except the last.
@export var round_correct_text: String = "Great!"
@export var round_delay: float = 0.9
@export var clue_size: float = 150.0

@onready var items_container: Container = $Layout/ItemsContainer
@onready var rounds_root: Container = $Layout/Rounds
@onready var clue_row: HBoxContainer = $Layout/ClueRow

var _rounds: Array[TapRound] = []
var _round := 0
var _current_buttons: Array[BaseButton] = []
var _correct_buttons: Array[BaseButton] = []
var _found: Array[BaseButton] = []
var _answer_slot: TextureRect


func _ready() -> void:
	super()
	for child in rounds_root.get_children():
		if child is TapRound:
			_rounds.append(child)
			child.visible = false
			_connect_buttons(child)
	clue_row.visible = false
	if _rounds.is_empty():
		_connect_buttons(items_container)
		_set_round_items(items_container, correct_items, self)
	else:
		items_container.visible = false
		_start_round(0)


func _connect_buttons(container: Node) -> void:
	for child in container.get_children():
		if child is BaseButton:
			child.pressed.connect(_on_item_pressed.bind(child))


## Makes `container`'s buttons the active ones; `paths` are relative to `base`.
func _set_round_items(container: Node, paths: Array[NodePath], base: Node) -> void:
	_current_buttons.clear()
	for child in container.get_children():
		if child is BaseButton:
			_current_buttons.append(child)
	_correct_buttons.clear()
	_found.clear()
	for path in paths:
		var button := base.get_node_or_null(path) as BaseButton
		if button == null:
			push_warning("%s: correct item '%s' is not a button" % [name, path])
			continue
		_correct_buttons.append(button)
	if _correct_buttons.is_empty():
		push_warning("%s: a round has no correct items and can't be finished" % name)


func _start_round(index: int) -> void:
	if _round < _rounds.size():
		_rounds[_round].visible = false
	_round = index
	var tap_round := _rounds[index]
	tap_round.visible = true
	clear_feedback()
	if tap_round.prompt != "":
		prompt_label.text = tap_round.prompt
	_build_clue_row(tap_round.clues)
	_set_round_items(tap_round, tap_round.correct_items, tap_round)


func _build_clue_row(clues: Array[Texture2D]) -> void:
	for child in clue_row.get_children():
		clue_row.remove_child(child)
		child.queue_free()
	_answer_slot = null
	clue_row.visible = not clues.is_empty()
	if clues.is_empty():
		return
	for texture in clues:
		clue_row.add_child(_make_clue(texture))
	# The "?" box the right answer drops into.
	var slot := PanelContainer.new()
	slot.name = "AnswerSlot"
	slot.custom_minimum_size = Vector2(clue_size, clue_size)
	slot.add_theme_stylebox_override("panel", UiStyle.rounded(Color(1, 1, 1, 0.7), 24, UiStyle.MUTED_COLOR, 5))
	var mark := Label.new()
	mark.text = "?"
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.add_theme_font_size_override("font_size", 96)
	mark.add_theme_color_override("font_color", UiStyle.MUTED_COLOR)
	slot.add_child(mark)
	_answer_slot = _make_clue(null)
	_answer_slot.visible = false
	slot.add_child(_answer_slot)
	clue_row.add_child(slot)


func _make_clue(texture: Texture2D) -> TextureRect:
	var clue := TextureRect.new()
	clue.texture = texture
	clue.custom_minimum_size = Vector2(clue_size, clue_size)
	clue.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	clue.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return clue


func _on_item_pressed(button: BaseButton) -> void:
	if is_finished or _found.has(button) or not _current_buttons.has(button):
		return
	if not _correct_buttons.has(button):
		shake(button)
		show_try_again()
		return

	_found.append(button)
	button.disabled = true
	bounce(button)
	if _answer_slot and button is TextureButton:
		_answer_slot.texture = button.texture_normal
		_answer_slot.visible = true
		_answer_slot.get_parent().get_child(0).visible = false
		bounce(_answer_slot)
	if _found.size() < _correct_buttons.size():
		play_sound(correct_sound)
		clear_feedback()
		return

	for other in _current_buttons:
		other.disabled = true
	if _rounds.is_empty() or _round == _rounds.size() - 1:
		finish_level()
		return
	show_feedback(round_correct_text)
	play_sound(correct_sound)
	# A tween (not a timer) so the callback dies with the scene if Back is pressed.
	var tween := create_tween()
	tween.tween_interval(round_delay)
	tween.tween_callback(_start_round.bind(_round + 1))
