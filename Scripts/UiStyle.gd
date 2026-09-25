class_name UiStyle
extends RefCounted
## Shared colours and big rounded button styles for menu screens.

const TEXT_COLOR := Color(0.2, 0.2, 0.35)
const CARD_COLOR := Color(1, 1, 1)
const NEW_CARD_COLOR := Color(0.85, 0.94, 0.85)
const MUTED_COLOR := Color(0.36, 0.45, 0.62)
const GO_COLOR := Color(0.2, 0.66, 0.29)
const DANGER_COLOR := Color(0.85, 0.25, 0.25)
const CHOICE_COLOR := Color(0.9, 0.92, 0.96)


static func rounded(color: Color, radius: int = 28, border_color := Color.TRANSPARENT, border := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.anti_aliasing = true
	if border > 0:
		style.border_color = border_color
		style.set_border_width_all(border)
	return style


## Solid coloured button; white text on dark colours, dark text on light ones.
static func style_button(button: Button, color: Color, font_size: int = 44, radius: int = 28) -> void:
	var text_color := Color.WHITE if color.get_luminance() < 0.6 else TEXT_COLOR
	var normal := rounded(color, radius)
	var pressed := rounded(color.darkened(0.12), radius)
	var disabled := rounded(Color(color, 0.4), radius)
	for state in ["normal", "hover", "focus"]:
		button.add_theme_stylebox_override(state, normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, text_color)
	button.add_theme_color_override("font_disabled_color", Color(text_color, 0.5))
	button.add_theme_font_size_override("font_size", font_size)


## Toggle button that turns green with a border when selected.
static func style_choice(button: Button, font_size: int = 44) -> void:
	button.toggle_mode = true
	var normal := rounded(CHOICE_COLOR, 24)
	var selected := rounded(GO_COLOR, 24, GO_COLOR.darkened(0.3), 6)
	for state in ["normal", "hover", "focus"]:
		button.add_theme_stylebox_override(state, normal)
	for state in ["pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(state, selected)
	for state in ["font_color", "font_hover_color", "font_focus_color"]:
		button.add_theme_color_override(state, TEXT_COLOR)
	for state in ["font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, Color.WHITE)
	button.add_theme_font_size_override("font_size", font_size)
