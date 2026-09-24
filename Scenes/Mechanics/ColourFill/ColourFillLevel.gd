extends MechanicLevel
## ColourFill mechanic: pick a colour from the palette, tap a region to fill it.
## Level scenes draw regions as Polygon2D children of Canvas/Regions (the
## polygon editor works well for this) and put the outline art on
## Canvas/LineArt, which sits on top. The level is done once every region has
## been coloured; the child can keep recolouring afterwards.

@export var palette: PackedColorArray = PackedColorArray([
	Color("e63946"), Color("ff9f1c"), Color("ffd23f"), Color("43b649"),
	Color("3a86ff"), Color("7b3fa0"), Color("ff6fb5"), Color("7a4e2d"),
])
## Colour regions start as, and don't count as "coloured".
@export var blank_color: Color = Color.WHITE
@export var swatch_size: float = 110.0

@onready var canvas: Control = $Layout/Canvas
@onready var regions_root: Node2D = $Layout/Canvas/Regions
@onready var palette_bar: Container = $Layout/PaletteBar

var _regions: Array[Polygon2D] = []
var _coloured: Array[Polygon2D] = []
var _selected_color: Color
var _swatches: Array[Button] = []


func _ready() -> void:
	super()
	for child in regions_root.get_children():
		if child is Polygon2D:
			child.color = blank_color
			_regions.append(child)
	if _regions.is_empty():
		push_warning("%s: no Polygon2D regions under Canvas/Regions" % name)
	if palette.is_empty():
		push_warning("%s: empty palette" % name)
		return
	_build_palette()
	_select(0)
	canvas.gui_input.connect(_on_canvas_input)


func _build_palette() -> void:
	for i in palette.size():
		var swatch := Button.new()
		swatch.name = "Swatch%d" % i
		swatch.custom_minimum_size = Vector2(swatch_size, swatch_size)
		swatch.pressed.connect(_select.bind(i))
		palette_bar.add_child(swatch)
		_swatches.append(swatch)
		_style_swatch(i, false)


func _select(index: int) -> void:
	for i in _swatches.size():
		_style_swatch(i, i == index)
	_selected_color = palette[index]
	bounce(_swatches[index])


func _style_swatch(index: int, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = palette[index]
	style.set_corner_radius_all(int(swatch_size / 2.0))
	style.anti_aliasing = true
	style.set_border_width_all(10 if selected else 4)
	style.border_color = Color(0.2, 0.2, 0.35) if selected else Color.WHITE
	for state in ["normal", "hover", "pressed", "focus"]:
		_swatches[index].add_theme_stylebox_override(state, style)


func _on_canvas_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var region := region_at(event.position)
		if region:
			fill_region(region, _selected_color)


## Top-most region under `point` (canvas coords), or null.
func region_at(point: Vector2) -> Polygon2D:
	for i in range(_regions.size() - 1, -1, -1):
		var region := _regions[i]
		var local := (regions_root.transform * region.transform).affine_inverse() * point
		if Geometry2D.is_point_in_polygon(local, region.polygon):
			return region
	return null


func fill_region(region: Polygon2D, color: Color) -> void:
	create_tween().tween_property(region, "color", color, 0.2)
	play_sound(correct_sound)
	if not _coloured.has(region):
		_coloured.append(region)
		if _coloured.size() == _regions.size():
			finish_level()
