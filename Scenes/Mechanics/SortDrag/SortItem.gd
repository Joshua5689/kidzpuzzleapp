class_name SortItem
extends TextureRect
## A draggable thing in a SortDrag level; belongs in the SortBin with the same
## `category`. Place under PlayArea/Items where it should start.

@export var category: String = ""
## Optional big text drawn on the item (e.g. a letter tile for spelling).
@export var text: String = ""


func _ready() -> void:
	if text == "":
		return
	var label := Label.new()
	label.name = "Text"
	label.text = text
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", int(minf(size.x, size.y) * 0.62))
	label.add_theme_color_override("font_color", Color(0.25, 0.18, 0.1))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
