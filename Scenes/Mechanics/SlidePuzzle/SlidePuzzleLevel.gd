extends MechanicLevel
## SlidePuzzle mechanic: `image` is cut into size x size tiles with the
## bottom-right one missing. Tapping a tile next to the gap slides it in.
## The shuffle is made of legal moves from the solved state, so it is always
## solvable. Taps on tiles that can't move count as (gentle) mistakes.

@export var image: Texture2D
@export_range(2, 5) var grid_size: int = 3
## Random legal moves used to shuffle. More = harder.
@export var shuffle_moves: int = 60
@export var board_width: float = 660.0
@export var tile_gap: float = 6.0
@export var show_preview: bool = true

@onready var board: Control = $Layout/PlayArea/Board
@onready var preview_image: TextureRect = $Layout/PlayArea/PreviewImage

var _tile_size := Vector2.ZERO
## _cell_of[i] = grid cell (index) where tile i currently is. The last tile is
## the gap and is hidden until the puzzle is solved.
var _cell_of: Array[int] = []
var _tiles: Array[TextureRect] = []
var _gap := 0


func _ready() -> void:
	super()
	if image == null:
		push_warning("%s: no image set" % name)
		return
	preview_image.texture = image
	preview_image.visible = show_preview
	var image_size := image.get_size()
	var board_size := Vector2(board_width, board_width * image_size.y / image_size.x)
	board.custom_minimum_size = board_size
	_tile_size = board_size / grid_size
	var region := image_size / grid_size
	var count := grid_size * grid_size
	for i in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = image
		atlas.region = Rect2(_coords(i) * region, region)
		var tile := TextureRect.new()
		tile.name = "Tile%02d" % i
		tile.texture = atlas
		tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tile.stretch_mode = TextureRect.STRETCH_SCALE
		tile.size = _tile_size - Vector2(tile_gap, tile_gap)
		tile.mouse_filter = Control.MOUSE_FILTER_STOP
		tile.gui_input.connect(_on_tile_input.bind(i))
		board.add_child(tile)
		_tiles.append(tile)
		_cell_of.append(i)
	_gap = count - 1
	_tiles[_gap].visible = false
	_shuffle()


func _coords(cell: int) -> Vector2:
	return Vector2(cell % grid_size, floori(float(cell) / grid_size))


func _cell_position(cell: int) -> Vector2:
	return _coords(cell) * _tile_size + Vector2(tile_gap, tile_gap) / 2.0


func _neighbours(cell: int) -> Array[int]:
	var out: Array[int] = []
	var c := _coords(cell)
	for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		var n: Vector2 = c + d
		if n.x >= 0 and n.y >= 0 and n.x < grid_size and n.y < grid_size:
			out.append(int(n.y) * grid_size + int(n.x))
	return out


## Legal random moves from solved, never undoing the previous move.
func _shuffle() -> void:
	var previous := -1
	for i in shuffle_moves:
		var options := _neighbours(_cell_of[_gap]).filter(func(c): return c != previous)
		var cell: int = options.pick_random()
		previous = _cell_of[_gap]
		_swap_with_gap(_cell_of.find(cell))
	if is_solved():
		_swap_with_gap(_cell_of.find(_neighbours(_cell_of[_gap])[0]))
	for i in _tiles.size():
		_tiles[i].position = _cell_position(_cell_of[i])


func _swap_with_gap(tile: int) -> void:
	var cell := _cell_of[tile]
	_cell_of[tile] = _cell_of[_gap]
	_cell_of[_gap] = cell


func _on_tile_input(event: InputEvent, tile: int) -> void:
	if is_finished or not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	slide(tile)


## Slides `tile` into the gap if it is next to it.
func slide(tile: int) -> void:
	if tile == _gap or not _neighbours(_cell_of[_gap]).has(_cell_of[tile]):
		record_mistake()
		shake(_tiles[tile])
		return
	_swap_with_gap(tile)
	create_tween().tween_property(_tiles[tile], "position", _cell_position(_cell_of[tile]), 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	play_sound(tap_sound)
	if is_solved():
		_on_solved()


func is_solved() -> bool:
	for i in _cell_of.size():
		if _cell_of[i] != i:
			return false
	return true


func _on_solved() -> void:
	# Bring in the missing corner and close the gaps so the picture looks whole.
	var last := _tiles[_gap]
	last.position = _cell_position(_gap)
	last.modulate.a = 0.0
	last.visible = true
	var tween := create_tween().set_parallel()
	tween.tween_property(last, "modulate:a", 1.0, 0.3)
	for i in _tiles.size():
		tween.tween_property(_tiles[i], "position", _coords(i) * _tile_size, 0.3).set_delay(0.15)
		tween.tween_property(_tiles[i], "size", _tile_size, 0.3).set_delay(0.15)
	finish_level()
