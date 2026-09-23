class_name MechanicLevel
extends Control
## Base for every mechanic scene. Handles the prompt, feedback, sounds, the
## Back/Next buttons and reporting completion to GameManager.
##
## Mechanic scenes must contain these nodes:
##   Layout/PromptLabel, Layout/FeedbackLabel, Layout/NextButton,
##   BackButton, SfxPlayer

@export var level_number: int = 0
## Leave empty to keep the text already on PromptLabel in the mechanic scene.
@export_multiline var prompt_text: String = ""
@export var success_text: String = "Well done!"
@export var try_again_text: String = "Try again!"
@export var correct_sound: AudioStream
@export var wrong_sound: AudioStream
@export var success_sound: AudioStream

@onready var prompt_label: Label = $Layout/PromptLabel
@onready var feedback_label: Label = $Layout/FeedbackLabel
@onready var next_button: Button = $Layout/NextButton
@onready var back_button: Button = $BackButton
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer

var is_finished := false


func _ready() -> void:
	if prompt_text != "":
		prompt_label.text = prompt_text
	feedback_label.text = ""
	next_button.visible = false
	next_button.pressed.connect(_on_next_pressed)
	back_button.pressed.connect(GameManager.go_to_level_select)


## Call when the child has solved the level.
func finish_level() -> void:
	if is_finished:
		return
	is_finished = true
	feedback_label.text = success_text
	play_sound(success_sound if success_sound else correct_sound)
	next_button.visible = true
	if level_number > 0:
		GameManager.complete_level(level_number)


func show_try_again() -> void:
	feedback_label.text = try_again_text
	play_sound(wrong_sound)


func clear_feedback() -> void:
	feedback_label.text = ""


func play_sound(stream: AudioStream) -> void:
	if stream == null:
		return
	sfx_player.stream = stream
	sfx_player.play()


func bounce(control: Control) -> void:
	control.pivot_offset = control.size / 2.0
	var tween := create_tween()
	tween.tween_property(control, "scale", Vector2(1.2, 1.2), 0.12)
	tween.tween_property(control, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


## Wobbles in place via rotation, so it's safe on children of Containers.
func shake(control: Control) -> void:
	control.pivot_offset = control.size / 2.0
	var tween := create_tween()
	for angle in [-0.15, 0.15, -0.1, 0.1, 0.0]:
		tween.tween_property(control, "rotation", angle, 0.05)


func _on_next_pressed() -> void:
	GameManager.go_to_next_level(level_number)
