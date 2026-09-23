extends Control
## TapMatch mechanic: the child taps every correct item among the ones shown.
## Level scenes inherit TapMatchLevel.tscn, add TextureButtons under
## Layout/ItemsContainer and pick the correct ones in `correct_items`.

@export var level_number: int = 0
@export_multiline var prompt_text: String = "Tap the right one!"
## Buttons under ItemsContainer that count as correct. All must be tapped.
@export var correct_items: Array[NodePath] = []
@export var success_text: String = "Well done!"
@export var try_again_text: String = "Try again!"
@export var correct_sound: AudioStream
@export var wrong_sound: AudioStream
@export var success_sound: AudioStream

@onready var prompt_label: Label = $Layout/PromptLabel
@onready var items_container: Container = $Layout/ItemsContainer
@onready var feedback_label: Label = $Layout/FeedbackLabel
@onready var next_button: Button = $Layout/NextButton
@onready var back_button: Button = $BackButton
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer

var _correct_buttons: Array[BaseButton] = []
var _found: Array[BaseButton] = []


func _ready() -> void:
	prompt_label.text = prompt_text
	feedback_label.text = ""
	next_button.visible = false
	next_button.pressed.connect(_on_next_pressed)
	back_button.pressed.connect(GameManager.go_to_level_select)

	for path in correct_items:
		var button := get_node_or_null(path) as BaseButton
		if button == null:
			push_warning("%s: correct item '%s' is not a button in this scene" % [name, path])
			continue
		_correct_buttons.append(button)
	if _correct_buttons.is_empty():
		push_warning("%s: no correct_items set, level can't be finished" % name)

	for child in items_container.get_children():
		if child is BaseButton:
			child.pressed.connect(_on_item_pressed.bind(child))


func _on_item_pressed(button: BaseButton) -> void:
	if _found.has(button):
		return
	if _correct_buttons.has(button):
		_found.append(button)
		button.disabled = true
		_bounce(button)
		if _found.size() == _correct_buttons.size():
			_finish()
		else:
			_play(correct_sound)
			feedback_label.text = ""
	else:
		_shake(button)
		_play(wrong_sound)
		feedback_label.text = try_again_text


func _finish() -> void:
	feedback_label.text = success_text
	_play(success_sound if success_sound else correct_sound)
	for child in items_container.get_children():
		if child is BaseButton:
			child.disabled = true
	next_button.visible = true
	if level_number > 0:
		GameManager.complete_level(level_number)


func _on_next_pressed() -> void:
	GameManager.go_to_next_level(level_number)


func _bounce(control: Control) -> void:
	control.pivot_offset = control.size / 2.0
	var tween := create_tween()
	tween.tween_property(control, "scale", Vector2(1.25, 1.25), 0.12)
	tween.tween_property(control, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


func _shake(control: Control) -> void:
	# Containers own position, so shake via rotation rather than moving the node.
	control.pivot_offset = control.size / 2.0
	var tween := create_tween()
	for angle in [-0.15, 0.15, -0.1, 0.1, 0.0]:
		tween.tween_property(control, "rotation", angle, 0.05)


func _play(stream: AudioStream) -> void:
	if stream == null:
		return
	sfx_player.stream = stream
	sfx_player.play()
