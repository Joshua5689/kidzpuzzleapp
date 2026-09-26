extends Control
## Title screen shown when the app starts: the title picture fades in,
## the title bounces in, then after a moment (or a tap) it moves on to
## "Who's playing?".

@export var show_seconds: float = 2.5

@onready var picture: TextureRect = $Picture
@onready var title_label: Label = $TitleLabel
@onready var hint_label: Label = $HintLabel

var _leaving := false


func _ready() -> void:
	picture.modulate.a = 0.0
	title_label.modulate.a = 0.0
	hint_label.modulate.a = 0.0
	await get_tree().process_frame
	title_label.pivot_offset = title_label.size / 2.0
	title_label.scale = Vector2(0.4, 0.4)

	var tween := create_tween()
	tween.tween_property(picture, "modulate:a", 1.0, 0.5)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(title_label, "scale", Vector2.ONE, 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(hint_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(show_seconds)
	tween.tween_callback(_leave)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_leave()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(GameManager.go_to_profile_select)
