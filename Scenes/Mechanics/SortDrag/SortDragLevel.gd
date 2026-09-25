extends MechanicLevel
## SortDrag mechanic: drag every SortItem into the SortBin with the same
## category. Level scenes place SortBin nodes under PlayArea/Bins and
## SortItem nodes under PlayArea/Items (free positions inside PlayArea).
## A right drop tucks the item into the bin; a wrong drop sends it back.

## How small an item gets once it's inside its bin.
@export var sorted_scale: float = 0.45
## Shadow-match style: the item snaps onto the centre of its bin at full size
## (use one bin per item, e.g. an animal and its shadow).
@export var snap_to_bin: bool = false

@onready var play_area: Control = $Layout/PlayArea
@onready var bins_root: Control = $Layout/PlayArea/Bins
@onready var items_root: Control = $Layout/PlayArea/Items

var _bins: Array[SortBin] = []
var _items: Array[SortItem] = []
var _sorted: Array[SortItem] = []
var _dragging: SortItem = null
var _grab_offset := Vector2.ZERO
## item -> where it started, so wrong drops can go home.
var _home := {}
## bin -> how many items it holds (to lay them out in rows).
var _bin_counts := {}


func _ready() -> void:
	super()
	for child in bins_root.get_children():
		if child is SortBin:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_bins.append(child)
			_bin_counts[child] = 0
	for child in items_root.get_children():
		if child is SortItem:
			child.mouse_filter = Control.MOUSE_FILTER_STOP
			child.gui_input.connect(_on_item_input.bind(child))
			_items.append(child)
			_home[child] = child.position
			if not _bins.any(func(b): return b.category == child.category):
				push_warning("%s: item %s has no bin for category '%s'" % [name, child.name, child.category])
	if _items.is_empty():
		push_warning("%s: no SortItem nodes under PlayArea/Items" % name)


func _on_item_input(event: InputEvent, item: SortItem) -> void:
	if is_finished or _sorted.has(item):
		return
	if not event is InputEventMouse:
		return
	# Event position is item-local; convert to Items-container space.
	var point: Vector2 = item.get_transform() * event.position
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _dragging == null:
			_dragging = item
			_grab_offset = point - item.position
			item.move_to_front()
			item.pivot_offset = item.size / 2.0
			item.scale = Vector2(1.1, 1.1)
			play_sound(tap_sound)
		elif not event.pressed and _dragging == item:
			_dragging = null
			item.scale = Vector2.ONE
			_drop(item)
	elif event is InputEventMouseMotion and _dragging == item:
		item.position = point - _grab_offset


func _drop(item: SortItem) -> void:
	var bin := bin_at(item.get_global_rect().get_center())
	if bin == null:
		_send_home(item)
	elif bin.category == item.category:
		sort_into(item, bin)
	else:
		show_try_again()
		shake(bin)
		_send_home(item)


## The bin under a point in global coordinates, or null.
func bin_at(global_point: Vector2) -> SortBin:
	for bin in _bins:
		if bin.get_global_rect().grow(20).has_point(global_point):
			return bin
	return null


## Shrinks the item into the next free spot inside the bin (or, with
## snap_to_bin, places it exactly over the bin).
func sort_into(item: SortItem, bin: SortBin) -> void:
	_sorted.append(item)
	if snap_to_bin:
		item.pivot_offset = item.size / 2.0
		item.scale = Vector2.ONE
		var centre := bin.global_position + bin.size / 2.0 - item.size / 2.0 - items_root.global_position
		create_tween().tween_property(item, "position", centre, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		bounce(item)
		clear_feedback()
		if _sorted.size() == _items.size():
			finish_level()
		else:
			play_sound(correct_sound)
		return
	var slot: int = _bin_counts[bin]
	_bin_counts[bin] = slot + 1
	var small := item.size * sorted_scale
	var per_row := maxi(1, int(bin.size.x * 0.8 / small.x))
	var spot := Vector2(slot % per_row, floori(float(slot) / per_row)) * small * 0.9
	var target_global := bin.global_position + Vector2(bin.size.x * 0.1, bin.size.y * 0.2) + spot
	var target := target_global - items_root.global_position

	item.pivot_offset = Vector2.ZERO
	var tween := create_tween().set_parallel()
	tween.tween_property(item, "position", target, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(item, "scale", Vector2(sorted_scale, sorted_scale), 0.25)
	bounce(bin)
	clear_feedback()
	if _sorted.size() == _items.size():
		finish_level()
	else:
		play_sound(correct_sound)


func _send_home(item: SortItem) -> void:
	create_tween().tween_property(item, "position", _home[item], 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
