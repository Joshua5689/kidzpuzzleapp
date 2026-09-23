extends MechanicLevel
## DragRearrange mechanic: `image` is cut into rows x columns tiles and
## shuffled. The child drags a tile onto another slot to swap them until the
## picture is whole. Level scenes only need to set `image` and the grid size.

@export var image: Texture2D
@export_range(1, 6) var rows: int = 2
@export_range(1, 6) var columns: int = 3
## On-screen width of the whole puzzle; height follows the image aspect.
@export var board_width: float = 960.0
## Space between tiles while unsolved, so the pieces read as separate.
@export var tile_gap: float = 6.0
## Tiles in their correct slot can't be moved (less frustrating for kids).
@export var lock_correct_tiles: bool = true
@export var show_preview: bool = true

@onready var board: Control = $Layout/PlayArea/Board
@onready var preview_image: TextureRect = $Layout/PlayArea/PreviewImage

var _tile_size := Vector2.ZERO
## _tiles[i] is the tile whose correct slot is i.
var _tiles: Array[TextureRect] = []
## _slot_of[i] is the slot tile i currently sits in.
var _slot_of: Array[int] = []
var _dragging: TextureRect = null
var _grab_offset := Vector2.ZERO


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
	_tile_size = board_size / Vector2(columns, rows)
	_build_tiles(image_size / Vector2(columns, rows))
	_shuffle()


func _build_tiles(region_size: Vector2) -> void:
	for i in rows * columns:
		var atlas := AtlasTexture.new()
		atlas.atlas = image
		atlas.region = Rect2(_slot_coords(i) * region_size, region_size)
		var tile := TextureRect.new()
		tile.name = "Tile%02d" % i
		tile.texture = atlas
		tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tile.stretch_mode = TextureRect.STRETCH_SCALE
		tile.mouse_filter = Control.MOUSE_FILTER_STOP
		tile.size = _tile_size - Vector2(tile_gap, tile_gap)
		tile.gui_input.connect(_on_tile_gui_input.bind(tile))
		board.add_child(tile)
		_tiles.append(tile)
		_slot_of.append(i)


## Random order with no tile already in its correct slot.
func _shuffle() -> void:
	var count := _tiles.size()
	if count < 2:
		return
	var order: Array[int] = []
	order.assign(range(count))
	var has_fixed_point := true
	while has_fixed_point:
		order.shuffle()
		has_fixed_point = false
		for i in count:
			if order[i] == i:
				has_fixed_point = true
				break
	for i in count:
		_slot_of[i] = order[i]
		_tiles[i].position = _slot_position(order[i])


func _on_tile_gui_input(event: InputEvent, tile: TextureRect) -> void:
	if is_finished:
		return
	if not event is InputEventMouse:
		return
	# Event position is tile-local; convert to board space.
	var point: Vector2 = tile.get_transform() * event.position
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _dragging == null:
			_start_drag(tile, point)
		elif not event.pressed and _dragging == tile:
			_end_drag(tile)
	elif event is InputEventMouseMotion and _dragging == tile:
		tile.position = point - _grab_offset


func _start_drag(tile: TextureRect, point: Vector2) -> void:
	var index := _tiles.find(tile)
	if lock_correct_tiles and _slot_of[index] == index:
		bounce(tile)
		return
	_dragging = tile
	_grab_offset = point - tile.position
	tile.move_to_front()
	tile.modulate = Color(1, 1, 1, 0.85)


func _end_drag(tile: TextureRect) -> void:
	_dragging = null
	tile.modulate = Color.WHITE
	var target := _slot_at(tile.position + tile.size / 2.0)
	move_tile_to_slot(_tiles.find(tile), target)


## Moves tile `index` into `target_slot`, swapping with whatever is there.
## A target of -1, the tile's own slot or a locked slot sends it back.
func move_tile_to_slot(index: int, target_slot: int) -> void:
	var from_slot := _slot_of[index]
	var other := _slot_of.find(target_slot)
	var target_locked := lock_correct_tiles and other == target_slot
	if target_slot == -1 or target_slot == from_slot or target_locked:
		_snap(index)
		return

	_slot_of[index] = target_slot
	_slot_of[other] = from_slot
	_snap(index)
	_snap(other)

	var placed_right := false
	for i in [index, other]:
		if _slot_of[i] == i:
			placed_right = true
			bounce(_tiles[i])
	if is_solved():
		_on_solved()
	elif placed_right:
		play_sound(correct_sound)


func is_solved() -> bool:
	for i in _slot_of.size():
		if _slot_of[i] != i:
			return false
	return true


func _on_solved() -> void:
	# Close the gaps so the finished picture looks whole, after the snap ends.
	var tween := create_tween().set_parallel()
	for i in _tiles.size():
		tween.tween_property(_tiles[i], "position", _slot_coords(i) * _tile_size, 0.3).set_delay(0.2)
		tween.tween_property(_tiles[i], "size", _tile_size, 0.3).set_delay(0.2)
	finish_level()


func _snap(index: int) -> void:
	var tween := create_tween()
	tween.tween_property(_tiles[index], "position", _slot_position(_slot_of[index]), 0.15) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


@warning_ignore("integer_division")
func _slot_coords(slot: int) -> Vector2:
	return Vector2(slot % columns, slot / columns)


func _slot_position(slot: int) -> Vector2:
	return _slot_coords(slot) * _tile_size + Vector2(tile_gap, tile_gap) / 2.0


## Slot under a point in board space, or -1 if outside the board.
func _slot_at(point: Vector2) -> int:
	if not Rect2(Vector2.ZERO, board.custom_minimum_size).has_point(point):
		return -1
	var coords := (point / _tile_size).floor()
	return int(coords.y) * columns + int(coords.x)
