extends MechanicLevel
## HiddenObjectHunt mechanic: find every Hotspot in the picture.
## Level scenes set the texture/size on SceneImage and add Hotspot nodes under
## SceneImage/Hotspots. Give CompareImage a texture to make it a spot-the-
## difference level: both pictures show side by side (same size) and a tap
## on either one counts.

## Extra forgiveness around each hotspot for small fingers.
@export var touch_padding: float = 24.0
## Seconds without a find before a hint pulses over a hidden item. 0 = off.
@export var hint_delay: float = 20.0
@export var marker_color: Color = Color(0.95, 0.3, 0.2)
@export var hint_color: Color = Color(1, 0.85, 0.1)

@onready var scene_image: TextureRect = $Layout/PlayArea/Pictures/SceneImage
@onready var compare_image: TextureRect = $Layout/PlayArea/Pictures/CompareImage
@onready var hotspots_root: Control = $Layout/PlayArea/Pictures/SceneImage/Hotspots
@onready var targets_bar: Container = $Layout/PlayArea/TargetsBar

var _hotspots: Array[Hotspot] = []
var _found: Array[Hotspot] = []
## category -> {"total": int, "found": int, "label": Label, "icon": Texture2D}
var _categories: Dictionary = {}
var _hint_timer: Timer


func _ready() -> void:
	super()
	compare_image.visible = compare_image.texture != null
	compare_image.custom_minimum_size = scene_image.custom_minimum_size

	for child in hotspots_root.get_children():
		if child is Hotspot:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_hotspots.append(child)
	if _hotspots.is_empty():
		push_warning("%s: no Hotspot nodes under SceneImage/Hotspots" % name)
		return

	_build_targets_bar()
	scene_image.gui_input.connect(_on_picture_input.bind(scene_image))
	compare_image.gui_input.connect(_on_picture_input.bind(compare_image))

	if hint_delay > 0.0:
		_hint_timer = Timer.new()
		_hint_timer.wait_time = hint_delay
		_hint_timer.timeout.connect(_show_hint)
		add_child(_hint_timer)
		_hint_timer.start()


func _build_targets_bar() -> void:
	for spot in _hotspots:
		if not _categories.has(spot.category):
			_categories[spot.category] = {"total": 0, "found": 0, "label": null, "icon": spot.icon}
		_categories[spot.category]["total"] += 1

	for category in _categories:
		var entry: Dictionary = _categories[category]
		var row := HBoxContainer.new()
		row.name = category.to_pascal_case() + "Row"
		row.add_theme_constant_override("separation", 16)
		if entry["icon"]:
			var icon := TextureRect.new()
			icon.texture = entry["icon"]
			icon.custom_minimum_size = Vector2(80, 80)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(icon)
		else:
			row.add_child(_make_label(category, 40))
		var count_label := _make_label("", 48)
		row.add_child(count_label)
		entry["label"] = count_label
		targets_bar.add_child(row)
		_update_category(category)


func _on_picture_input(event: InputEvent, picture: TextureRect) -> void:
	if is_finished:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	# Both pictures are the same size, so local coords map straight onto the hotspots.
	var spot := hotspot_at(event.position)
	if spot:
		find_hotspot(spot)
	else:
		_show_miss(picture, event.position)


## Unfound hotspot at `point` (in picture coords), or null. When hotspots
## overlap, the smallest one actually under the point wins (the more specific
## target); otherwise the closest one within touch_padding.
func hotspot_at(point: Vector2) -> Hotspot:
	var inside: Hotspot = null
	var inside_area := INF
	var near: Hotspot = null
	var near_distance := INF
	for spot in _hotspots:
		if _found.has(spot):
			continue
		var rect := Rect2(spot.position, spot.size)
		if rect.has_point(point):
			if rect.get_area() < inside_area:
				inside = spot
				inside_area = rect.get_area()
		elif rect.grow(touch_padding).has_point(point):
			var distance := rect.get_center().distance_to(point)
			if distance < near_distance:
				near = spot
				near_distance = distance
	return inside if inside else near


func find_hotspot(spot: Hotspot) -> void:
	if _found.has(spot):
		return
	_found.append(spot)
	var rect := Rect2(spot.position, spot.size)
	_add_marker(scene_image, rect)
	if compare_image.visible:
		_add_marker(compare_image, rect)
	_categories[spot.category]["found"] += 1
	_update_category(spot.category)
	if _hint_timer:
		_hint_timer.start()

	if _found.size() == _hotspots.size():
		if _hint_timer:
			_hint_timer.stop()
		finish_level()
	else:
		play_sound(correct_sound)


func _update_category(category: String) -> void:
	var entry: Dictionary = _categories[category]
	var label: Label = entry["label"]
	label.text = "%d / %d" % [entry["found"], entry["total"]]
	if entry["found"] == entry["total"]:
		label.add_theme_color_override("font_color", SUCCESS_COLOR)
		bounce(label)


func _add_marker(picture: Control, rect: Rect2) -> void:
	var marker := _make_ring(rect.grow(10), marker_color, 8)
	picture.add_child(marker)
	marker.scale = Vector2(1.4, 1.4)
	create_tween().tween_property(marker, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_miss(picture: Control, point: Vector2) -> void:
	var ripple := _make_ring(Rect2(point - Vector2(30, 30), Vector2(60, 60)), Color(1, 1, 1, 0.8), 5)
	picture.add_child(ripple)
	var tween := create_tween().set_parallel()
	tween.tween_property(ripple, "scale", Vector2(1.6, 1.6), 0.4)
	tween.tween_property(ripple, "modulate:a", 0.0, 0.4)
	tween.chain().tween_callback(ripple.queue_free)
	# Misses cost stars but get a soft tap, not the "wrong" sound: random
	# exploring taps are normal here.
	record_mistake()
	play_sound(tap_sound)


func _show_hint() -> void:
	for spot in _hotspots:
		if _found.has(spot):
			continue
		var ring := _make_ring(Rect2(spot.position, spot.size).grow(16), hint_color, 8)
		ring.modulate.a = 0.0
		scene_image.add_child(ring)
		var tween := create_tween()
		for i in 2:
			tween.tween_property(ring, "modulate:a", 1.0, 0.35)
			tween.tween_property(ring, "modulate:a", 0.0, 0.35)
		tween.tween_callback(ring.queue_free)
		return


func _make_ring(rect: Rect2, color: Color, width: int) -> Panel:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = color
	style.set_border_width_all(width)
	style.set_corner_radius_all(int(min(rect.size.x, rect.size.y) / 2.0))
	style.anti_aliasing = true
	var ring := Panel.new()
	ring.add_theme_stylebox_override("panel", style)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.position = rect.position
	ring.size = rect.size
	ring.pivot_offset = rect.size / 2.0
	return ring


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.35))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label
