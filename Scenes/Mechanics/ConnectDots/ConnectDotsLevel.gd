extends MechanicLevel
## ConnectDots mechanic: numbered dots on the board; tap them in order and a
## line joins them. When the last dot is joined the shape closes and the
## round's picture fades in over it. Rounds come from `shapes` (one dot list
## each, in board coordinates) with a matching picture in `reveals`.

@export var shapes: Array[PackedVector2Array] = []
@export var reveals: Array[Texture2D] = []
## Where each round's picture is drawn (board coordinates); one per round.
@export var reveal_rects: Array[Rect2] = []
@export var board_size: Vector2 = Vector2(1100, 760)
@export var dot_radius: float = 34.0
@export var line_color: Color = Color("3a86ff")
@export var round_correct_text: String = "Great!"

@onready var board: Control = $Layout/Board
@onready var round_label: Label = $RoundLabel

var _round := 0
var _next := 0
var _dots: Array[Panel] = []
var _line: Line2D
var _reveal: TextureRect
var _hint: Tween


func _ready() -> void:
	super()
	board.custom_minimum_size = board_size
	if shapes.is_empty():
		push_warning("%s: no shapes" % name)
		return
	_start_round(0)


func _start_round(index: int) -> void:
	_round = index
	_next = 0
	round_label.text = "%d / %d" % [index + 1, shapes.size()]
	clear_feedback()
	if _hint:
		_hint.kill()
	for child in board.get_children():
		board.remove_child(child)
		child.queue_free()
	_dots.clear()

	if index < reveals.size() and reveals[index]:
		_reveal = TextureRect.new()
		_reveal.texture = reveals[index]
		_reveal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_reveal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var rect: Rect2 = reveal_rects[index] if index < reveal_rects.size() else Rect2(Vector2.ZERO, board_size)
		_reveal.position = rect.position
		_reveal.size = rect.size
		_reveal.modulate.a = 0.0
		_reveal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		board.add_child(_reveal)
	else:
		_reveal = null

	_line = Line2D.new()
	_line.width = 12.0
	_line.default_color = line_color
	_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	board.add_child(_line)

	var points: PackedVector2Array = shapes[index]
	for i in points.size():
		var dot := _make_dot(i + 1, points[i])
		dot.gui_input.connect(_on_dot_input.bind(i))
		board.add_child(dot)
		_dots.append(dot)
	_pulse_next()


func _make_dot(number: int, at: Vector2) -> Panel:
	var dot := Panel.new()
	dot.name = "Dot%d" % number
	dot.size = Vector2(dot_radius, dot_radius) * 2.0
	dot.position = at - dot.size / 2.0
	dot.pivot_offset = dot.size / 2.0
	dot.add_theme_stylebox_override("panel", UiStyle.rounded(Color.WHITE, int(dot_radius), UiStyle.MUTED_COLOR, 5))
	var label := Label.new()
	label.text = str(number)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", UiStyle.TEXT_COLOR)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.add_child(label)
	return dot


func _on_dot_input(event: InputEvent, index: int) -> void:
	if is_finished or not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	tap_dot(index)


func tap_dot(index: int) -> void:
	if index != _next:
		if index >= _next:
			record_mistake()
			shake(_dots[index])
		return
	var dot := _dots[index]
	dot.add_theme_stylebox_override("panel", UiStyle.rounded(UiStyle.GO_COLOR, int(dot_radius), UiStyle.GO_COLOR.darkened(0.3), 5))
	dot.get_child(0).add_theme_color_override("font_color", Color.WHITE)
	bounce(dot)
	_line.add_point(dot.position + dot.size / 2.0)
	play_sound(tap_sound)
	_next += 1
	if _next < _dots.size():
		_pulse_next()
		return
	# Close the shape and show the picture.
	_line.add_point(_dots[0].position + _dots[0].size / 2.0)
	if _hint:
		_hint.kill()
	if _reveal:
		var tween := create_tween()
		tween.tween_interval(0.2)
		tween.tween_property(_reveal, "modulate:a", 1.0, 0.6)
		for d in _dots:
			tween.parallel().tween_property(d, "modulate:a", 0.0, 0.6)
	if _round == shapes.size() - 1:
		finish_level()
		return
	show_feedback(round_correct_text)
	play_sound(correct_sound)
	var next := create_tween()
	next.tween_interval(2.0)
	next.tween_callback(_start_round.bind(_round + 1))


## Gently pulses the dot to tap next (a hint for younger players).
func _pulse_next() -> void:
	if _hint:
		_hint.kill()
	for dot in _dots:
		dot.scale = Vector2.ONE
	var dot := _dots[_next]
	_hint = create_tween().set_loops()
	_hint.tween_property(dot, "scale", Vector2(1.18, 1.18), 0.45)
	_hint.tween_property(dot, "scale", Vector2.ONE, 0.45)
