extends MechanicLevel
## MazeDrag mechanic: drag the player through a grid maze to the goal.
## The maze is typed into `layout`: '#' wall, '.' path, 'S' start, 'E' goal.
## The player follows the finger one cell at a time and can't cross walls,
## however fast the finger moves. A trail shows the way walked so far.

@export var layout: PackedStringArray = PackedStringArray([
	"#######",
	"#S...E#",
	"#######",
])
## The maze is scaled to fit inside this, keeping cells square.
@export var board_max_size: Vector2 = Vector2(1500, 740)
@export var player_texture: Texture2D
@export var goal_texture: Texture2D
@export var wall_color: Color = Color(0.25, 0.6, 0.3)
@export var path_color: Color = Color(0.96, 0.9, 0.75)
@export var trail_color: Color = Color(0.95, 0.5, 0.2, 0.55)

@onready var board: Control = $Layout/Board

var _cols := 0
var _rows := 0
var _cell := 0.0
var _walls := {}
var _start := Vector2i(-1, -1)
var _goal := Vector2i(-1, -1)
var _player_cell := Vector2i.ZERO
var _player: TextureRect
var _trail: Line2D
## Cells walked, start first; stepping back onto the previous one undoes a step.
var _trail_cells: Array[Vector2i] = []
var _dragging := false


func _ready() -> void:
	super()
	_parse_layout()
	if _start.x < 0 or _goal.x < 0:
		push_warning("%s: layout needs one 'S' and one 'E'" % name)
		return
	_build_board()
	board.gui_input.connect(_on_board_input)


func _parse_layout() -> void:
	_rows = layout.size()
	for y in _rows:
		var row := layout[y]
		_cols = max(_cols, row.length())
		for x in row.length():
			var cell := Vector2i(x, y)
			match row[x]:
				"#":
					_walls[cell] = true
				"S":
					_start = cell
				"E":
					_goal = cell


func _build_board() -> void:
	_cell = floorf(min(board_max_size.x / _cols, board_max_size.y / _rows))
	board.custom_minimum_size = Vector2(_cols, _rows) * _cell

	var floor_rect := ColorRect.new()
	floor_rect.name = "Floor"
	floor_rect.color = path_color
	floor_rect.size = board.custom_minimum_size
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(floor_rect)

	var wall_style := StyleBoxFlat.new()
	wall_style.bg_color = wall_color
	wall_style.set_corner_radius_all(int(_cell * 0.25))
	wall_style.anti_aliasing = true
	for cell in _walls:
		var wall := Panel.new()
		wall.add_theme_stylebox_override("panel", wall_style)
		wall.position = Vector2(cell) * _cell
		wall.size = Vector2(_cell, _cell)
		wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
		board.add_child(wall)

	_trail = Line2D.new()
	_trail.name = "Trail"
	_trail.width = _cell * 0.3
	_trail.default_color = trail_color
	_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	board.add_child(_trail)

	board.add_child(_make_sprite("Goal", goal_texture, _goal))
	_player = _make_sprite("Player", player_texture, _start)
	board.add_child(_player)
	_player_cell = _start
	_trail_cells = [_start]
	_trail.add_point(_cell_center(_start))


func _make_sprite(sprite_name: String, texture: Texture2D, cell: Vector2i) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.size = Vector2(_cell, _cell) * 0.9
	sprite.pivot_offset = sprite.size / 2.0
	sprite.position = _sprite_position(cell)
	return sprite


func _on_board_input(event: InputEvent) -> void:
	if is_finished:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Only start when the finger lands on (or right next to) the player.
			var offset := cell_at(event.position) - _player_cell
			_dragging = absi(offset.x) <= 1 and absi(offset.y) <= 1
			if not _dragging:
				bounce(_player)
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		follow_to(cell_at(event.position))


func cell_at(point: Vector2) -> Vector2i:
	return Vector2i((point / _cell).floor())


func is_open(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _cols and cell.y < _rows and not _walls.has(cell)


## Walks the player toward `target` one open cell at a time, trying the
## longer axis first, and stops at a wall.
func follow_to(target: Vector2i) -> void:
	for guard in _cols * _rows:
		if target == _player_cell or is_finished:
			return
		var delta := target - _player_cell
		var along_x := Vector2i(signi(delta.x), 0)
		var along_y := Vector2i(0, signi(delta.y))
		var steps := [along_x, along_y] if absi(delta.x) >= absi(delta.y) else [along_y, along_x]
		var moved := false
		for step in steps:
			if step != Vector2i.ZERO and is_open(_player_cell + step):
				_step(step)
				moved = true
				break
		if not moved:
			return


func _step(step: Vector2i) -> void:
	var next := _player_cell + step
	if _trail_cells.size() >= 2 and next == _trail_cells[-2]:
		_trail_cells.pop_back()
		_trail.remove_point(_trail.get_point_count() - 1)
	else:
		_trail_cells.append(next)
		_trail.add_point(_cell_center(next))
	_player_cell = next
	if step.x != 0:
		_player.flip_h = step.x < 0
	create_tween().tween_property(_player, "position", _sprite_position(next), 0.06)
	if next == _goal:
		_dragging = false
		bounce(_player)
		finish_level()


func _cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * _cell


func _sprite_position(cell: Vector2i) -> Vector2:
	return _cell_center(cell) - Vector2(_cell, _cell) * 0.45
