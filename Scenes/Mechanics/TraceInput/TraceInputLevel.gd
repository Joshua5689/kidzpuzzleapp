extends MechanicLevel
## TraceInput mechanic: trace each shape (e.g. a number) along its guide path.
## Level scenes add one Node2D per round under Board/Guides, each holding one
## or more Line2D strokes in the order they should be traced (point order =
## direction). A pulsing dot shows where to start; ink follows the finger
## only while it stays near the path, and never skips far ahead.

## How far (px) the finger may stray from the path and still count.
@export var tolerance: float = 55.0
@export var guide_width: float = 70.0
@export var ink_width: float = 48.0
@export var guide_color: Color = Color(0.82, 0.86, 0.92)
## Ink colour per round, cycling.
@export var ink_colors: PackedColorArray = PackedColorArray([
	Color("3a86ff"), Color("e63946"), Color("43b649"), Color("ff9f1c"), Color("7b3fa0"),
])
@export var start_dot_color: Color = Color("43b649")
## Shown after each shape except the last.
@export var round_correct_text: String = "Great!"
@export var round_delay: float = 1.0
## Spacing of the points the path is resampled into; smaller = smoother ink.
@export var sample_spacing: float = 8.0

@onready var board: Control = $Layout/Board
@onready var guides_root: Node2D = $Layout/Board/Guides
@onready var round_label: Label = $RoundLabel

var _shapes: Array[Node2D] = []
var _round := 0
## Current shape's strokes, resampled into board coordinates.
var _strokes: Array[PackedVector2Array] = []
var _stroke := 0
var _progress := 0
var _ink: Line2D
var _inks: Array[Line2D] = []
var _start_dot: Panel
var _tracing := false
var _between_rounds := false


func _ready() -> void:
	super()
	for child in guides_root.get_children():
		if child is Node2D and child.get_children().any(func(c): return c is Line2D):
			child.visible = false
			_shapes.append(child)
	if _shapes.is_empty():
		push_warning("%s: no shapes (Node2D with Line2D strokes) under Board/Guides" % name)
		return
	_start_dot = _make_start_dot()
	board.add_child(_start_dot)
	var pulse := _start_dot.create_tween().set_loops()
	pulse.tween_property(_start_dot, "scale", Vector2(1.25, 1.25), 0.45)
	pulse.tween_property(_start_dot, "scale", Vector2.ONE, 0.45)
	board.gui_input.connect(_on_board_input)
	_start_round(0)


func _start_round(index: int) -> void:
	if _round < _shapes.size():
		_shapes[_round].visible = false
	for ink in _inks:
		ink.queue_free()
	_inks.clear()

	_round = index
	_between_rounds = false
	clear_feedback()
	round_label.text = "%d / %d" % [index + 1, _shapes.size()]

	var shape := _shapes[index]
	shape.visible = true
	_strokes.clear()
	for child in shape.get_children():
		var line := child as Line2D
		if line:
			_style_guide(line)
			var to_board := guides_root.transform * shape.transform * line.transform
			_strokes.append(_resample(to_board * line.points))
	_begin_stroke(0)


func _begin_stroke(index: int) -> void:
	_stroke = index
	_progress = 0
	_ink = Line2D.new()
	_ink.width = ink_width
	_ink.default_color = ink_colors[_round % ink_colors.size()]
	_ink.joint_mode = Line2D.LINE_JOINT_ROUND
	_ink.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_ink.end_cap_mode = Line2D.LINE_CAP_ROUND
	_ink.add_point(_strokes[index][0])
	board.add_child(_ink)
	_inks.append(_ink)
	_start_dot.move_to_front()
	_start_dot.visible = true
	_move_dot()


func _on_board_input(event: InputEvent) -> void:
	if is_finished or _between_rounds:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Must start where the ink left off (the pulsing dot).
			_tracing = event.position.distance_to(_strokes[_stroke][_progress]) <= tolerance
		else:
			_tracing = false
	elif event is InputEventMouseMotion and _tracing:
		trace_to(event.position)


## Advances the ink to the furthest nearby path point the finger is close to.
## Looking only a short way ahead stops shortcuts where a path loops back.
func trace_to(point: Vector2) -> void:
	var samples := _strokes[_stroke]
	var lookahead := int(ceil(tolerance * 2.0 / sample_spacing))
	var last := mini(samples.size() - 1, _progress + lookahead)
	var best := _progress
	for i in range(_progress + 1, last + 1):
		if samples[i].distance_to(point) <= tolerance:
			best = i
	if best == _progress:
		return
	for i in range(_progress + 1, best + 1):
		_ink.add_point(samples[i])
	_progress = best
	_move_dot()
	if _progress >= samples.size() - 1:
		_finish_stroke()


func _finish_stroke() -> void:
	_tracing = false
	if _stroke + 1 < _strokes.size():
		play_sound(correct_sound)
		_begin_stroke(_stroke + 1)
		return
	_start_dot.visible = false
	for ink in _inks:
		bounce_line(ink)
	if _round == _shapes.size() - 1:
		finish_level()
		return
	_between_rounds = true
	show_feedback(round_correct_text)
	play_sound(correct_sound)
	# A tween (not a timer) so the callback dies with the scene if Back is pressed.
	var tween := create_tween()
	tween.tween_interval(round_delay)
	tween.tween_callback(_start_round.bind(_round + 1))


## Brief thicken-and-settle on a finished stroke.
func bounce_line(line: Line2D) -> void:
	var tween := create_tween()
	tween.tween_property(line, "width", ink_width * 1.25, 0.12)
	tween.tween_property(line, "width", ink_width, 0.18)


func _style_guide(line: Line2D) -> void:
	line.width = guide_width
	line.default_color = guide_color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND


## Evenly spaced points along a polyline, always ending on its last point.
func _resample(points: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	if points.is_empty():
		return out
	out.append(points[0])
	var carry := 0.0
	for i in range(1, points.size()):
		var a := points[i - 1]
		var b := points[i]
		var length := a.distance_to(b)
		var d := sample_spacing - carry
		while d <= length:
			out.append(a.lerp(b, d / length))
			d += sample_spacing
		carry = length - (d - sample_spacing)
	if out[-1] != points[-1]:
		out.append(points[-1])
	return out


func _make_start_dot() -> Panel:
	var style := StyleBoxFlat.new()
	style.bg_color = start_dot_color
	style.border_color = Color.WHITE
	style.set_border_width_all(6)
	style.set_corner_radius_all(40)
	style.anti_aliasing = true
	var dot := Panel.new()
	dot.name = "StartDot"
	dot.add_theme_stylebox_override("panel", style)
	dot.size = Vector2(60, 60)
	dot.pivot_offset = dot.size / 2.0
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return dot


func _move_dot() -> void:
	_start_dot.position = _strokes[_stroke][_progress] - _start_dot.size / 2.0
