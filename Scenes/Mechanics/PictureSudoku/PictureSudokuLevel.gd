extends MechanicLevel
## PictureSudoku mechanic: a 4x4 (or other square) grid where every picture
## appears once per row, column and box. `solution` holds one string per row
## of symbol letters (A = first texture in `symbols`, B = second, ...).
## `puzzle` is the same with "." for the squares the child fills. The child
## picks a picture from the palette, then taps an empty square; a wrong
## picture shakes and doesn't stay.

@export var symbols: Array[Texture2D] = []
@export var solution: PackedStringArray = PackedStringArray(["ABCD", "CDAB", "BADC", "DCBA"])
@export var puzzle: PackedStringArray = PackedStringArray(["A.C.", ".D.B", "B.D.", ".C.A"])
@export var cell_size: float = 150.0
## Width/height of the shaded boxes (2 for a 4x4 grid).
@export var box_size: int = 2

@onready var grid: GridContainer = $Layout/PlayArea/Grid
@onready var palette_bar: VBoxContainer = $Layout/PlayArea/Palette

const BOX_COLOURS := [Color(1, 0.96, 0.82), Color(0.86, 0.93, 1)]

var _cells: Array[TextureButton] = []
var _picks: Array[TextureButton] = []
var _selected := 0
var _empty := 0


func _ready() -> void:
	super()
	var n := solution.size()
	if n == 0 or symbols.size() < n or puzzle.size() != n:
		push_warning("%s: solution/puzzle/symbols don't match" % name)
		return
	grid.columns = n
	for row in n:
		for col in n:
			grid.add_child(_make_cell(row, col))
	for i in n:
		var pick := TextureButton.new()
		pick.name = "Pick%s" % char(65 + i)
		pick.texture_normal = symbols[i]
		pick.ignore_texture_size = true
		pick.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		pick.custom_minimum_size = Vector2(cell_size, cell_size) * 0.85
		pick.pressed.connect(_select.bind(i))
		palette_bar.add_child(pick)
		_picks.append(pick)
	_select(0)


func _make_cell(row: int, col: int) -> TextureButton:
	var cell := TextureButton.new()
	cell.name = "Cell%d%d" % [row, col]
	cell.custom_minimum_size = Vector2(cell_size, cell_size)
	cell.ignore_texture_size = true
	cell.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	var box := (floori(float(row) / box_size) + floori(float(col) / box_size)) % 2
	var back := Panel.new()
	back.show_behind_parent = true
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.add_theme_stylebox_override("panel", UiStyle.rounded(BOX_COLOURS[box], 16, UiStyle.MUTED_COLOR, 3))
	cell.add_child(back)
	var given := puzzle[row][col]
	cell.set_meta("answer", solution[row].unicode_at(col) - 65)
	if given != ".":
		cell.texture_normal = symbols[given.unicode_at(0) - 65]
		cell.disabled = true
	else:
		_empty += 1
		cell.pressed.connect(_on_cell_pressed.bind(cell))
	_cells.append(cell)
	return cell


func _select(index: int) -> void:
	_selected = index
	for i in _picks.size():
		var chosen := i == index
		_picks[i].modulate = Color.WHITE if chosen else Color(1, 1, 1, 0.45)
		_picks[i].pivot_offset = _picks[i].custom_minimum_size / 2.0
		_picks[i].scale = Vector2(1.12, 1.12) if chosen else Vector2.ONE
	if is_node_ready():
		play_sound(tap_sound)


func _on_cell_pressed(cell: TextureButton) -> void:
	if is_finished or cell.texture_normal != null:
		return
	place(cell, _selected)


## Puts picture `symbol` in `cell` if it's right there.
func place(cell: TextureButton, symbol: int) -> void:
	if symbol != cell.get_meta("answer"):
		cell.texture_normal = symbols[symbol]
		shake(cell)
		show_try_again()
		var tween := create_tween()
		tween.tween_interval(0.35)
		tween.tween_callback(func(): cell.texture_normal = null)
		return
	cell.texture_normal = symbols[symbol]
	cell.disabled = true
	bounce(cell)
	clear_feedback()
	_empty -= 1
	if _empty == 0:
		finish_level()
	else:
		play_sound(correct_sound)


## For tests: the empty cells and their answers.
func empty_cells() -> Array[TextureButton]:
	var out: Array[TextureButton] = []
	for c in _cells:
		if c.texture_normal == null:
			out.append(c)
	return out
