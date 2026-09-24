extends MechanicLevel
## CountSelect mechanic: each round shows N copies of `item_texture` and the
## child taps the matching number. Tapping an item numbers it (1, 2, 3...) so
## they can count by touch. Wrong answers grey out, so every round is winnable.

@export var item_texture: Texture2D
## How many items to show in each round, in order.
@export var rounds: Array[int] = [3, 5, 2]
## Answer buttons per round, including the correct one.
@export_range(2, 5) var answer_choices: int = 3
## Wrong answers are picked from 1..max_number.
@export_range(2, 20) var max_number: int = 10
@export var item_size: float = 150.0
@export var tap_items_to_count: bool = true
## Shown after each correct round except the last; %d is the answer.
@export var round_correct_text: String = "Yes, %d!"
## Pause before the next round starts.
@export var round_delay: float = 0.9

@onready var items_container: Container = $Layout/ItemsContainer
@onready var answers_container: Container = $Layout/AnswersContainer
@onready var round_label: Label = $RoundLabel

var _round := 0
var _tap_count := 0


func _ready() -> void:
	super()
	if item_texture == null:
		push_warning("%s: no item_texture set" % name)
	if rounds.is_empty():
		push_warning("%s: no rounds set, level can't be finished" % name)
		return
	for count in rounds:
		if count < 1 or count > max_number:
			push_warning("%s: round count %d is outside 1..%d" % [name, count, max_number])
	_start_round(0)


func current_answer() -> int:
	return rounds[_round]


func _start_round(index: int) -> void:
	_round = index
	_tap_count = 0
	clear_feedback()
	round_label.text = "%d / %d" % [index + 1, rounds.size()]
	_clear(items_container)
	_clear(answers_container)

	for n in current_answer():
		var item := TextureButton.new()
		item.name = "Item%02d" % (n + 1)
		item.texture_normal = item_texture
		item.ignore_texture_size = true
		item.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		item.custom_minimum_size = Vector2(item_size, item_size)
		item.pressed.connect(_on_item_tapped.bind(item))
		items_container.add_child(item)
		item.modulate.a = 0.0
		create_tween().tween_property(item, "modulate:a", 1.0, 0.25).set_delay(n * 0.08)

	for value in _make_choices(current_answer()):
		var button := Button.new()
		button.name = "Answer%d" % value
		button.text = str(value)
		button.custom_minimum_size = Vector2(180, 160)
		button.add_theme_font_size_override("font_size", 80)
		button.pressed.connect(_on_answer_pressed.bind(value, button))
		answers_container.add_child(button)


## The correct answer plus distinct random wrong ones, sorted ascending.
func _make_choices(correct: int) -> Array[int]:
	var pool: Array[int] = []
	for n in range(1, max_number + 1):
		if n != correct:
			pool.append(n)
	pool.shuffle()
	var choices: Array[int] = [correct]
	choices.append_array(pool.slice(0, answer_choices - 1))
	choices.sort()
	return choices


func _on_item_tapped(item: TextureButton) -> void:
	if not tap_items_to_count or is_finished or item.has_meta("counted"):
		return
	_tap_count += 1
	item.set_meta("counted", true)
	item.self_modulate = Color(1, 1, 1, 0.45)
	var label := Label.new()
	label.text = str(_tap_count)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0.2, 0.2, 0.35))
	label.add_theme_constant_override("outline_size", 14)
	item.add_child(label)
	bounce(item)
	play_sound(tap_sound)


func _on_answer_pressed(value: int, button: Button) -> void:
	if is_finished:
		return
	if value != current_answer():
		button.disabled = true
		shake(button)
		show_try_again()
		return

	for child in answers_container.get_children():
		if child != button:
			child.disabled = true
	_mark_correct(button)
	if _round == rounds.size() - 1:
		finish_level()
		return
	show_feedback(round_correct_text % value if "%d" in round_correct_text else round_correct_text)
	play_sound(correct_sound)
	# A tween (not a timer) so the callback dies with the scene if Back is pressed.
	var tween := create_tween()
	tween.tween_interval(round_delay)
	tween.tween_callback(_start_round.bind(_round + 1))


## Keeps the right answer lit up in green so the child sees what they got.
func _mark_correct(button: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = SUCCESS_COLOR
	style.set_corner_radius_all(12)
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bounce(button)


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
