class_name MechanicLevel
extends Control
## Base for every mechanic scene. Handles the prompt, feedback, sounds,
## mistake counting, the Back button, and on completion reports to
## GameManager and shows the star score card.
##
## Mechanic scenes must contain these nodes:
##   Layout/PromptLabel, Layout/FeedbackLabel, BackButton, SfxPlayer

const SUCCESS_COLOR := Color(0.15, 0.55, 0.25)
const TRY_AGAIN_COLOR := Color(0.85, 0.4, 0.1)
const SCORE_CARD_SCENE: PackedScene = preload("res://Scenes/UI/ScoreCard.tscn")
const DEFAULT_CORRECT_SOUND: AudioStream = preload("res://Assets/Audio/SFX/Correct.wav")
const DEFAULT_WRONG_SOUND: AudioStream = preload("res://Assets/Audio/SFX/Wrong.wav")
const DEFAULT_SUCCESS_SOUND: AudioStream = preload("res://Assets/Audio/SFX/Success.wav")
const DEFAULT_TAP_SOUND: AudioStream = preload("res://Assets/Audio/SFX/Tap.wav")

@export var level_number: int = 0
## Leave empty to keep the text already on PromptLabel in the mechanic scene.
@export_multiline var prompt_text: String = ""
@export var success_text: String = "Well done!"
@export var try_again_text: String = "Try again!"
@export_group("Sounds")
## Leave any of these empty to use the game's default sound.
@export var correct_sound: AudioStream
@export var wrong_sound: AudioStream
@export var success_sound: AudioStream
@export var tap_sound: AudioStream
@export_group("Stars")
## Up to this many mistakes still earns 3 stars.
@export var three_star_max_mistakes: int = 0
## Up to this many mistakes earns 2 stars; more earns 1.
@export var two_star_max_mistakes: int = 2
@export_group("")

@onready var prompt_label: Label = $Layout/PromptLabel
@onready var feedback_label: Label = $Layout/FeedbackLabel
@onready var back_button: Button = $BackButton
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer

var is_finished := false
var mistakes := 0


func _ready() -> void:
	if prompt_text != "":
		prompt_label.text = prompt_text
	feedback_label.text = ""
	back_button.pressed.connect(GameManager.go_to_level_select)
	if correct_sound == null:
		correct_sound = DEFAULT_CORRECT_SOUND
	if wrong_sound == null:
		wrong_sound = DEFAULT_WRONG_SOUND
	if success_sound == null:
		success_sound = DEFAULT_SUCCESS_SOUND
	if tap_sound == null:
		tap_sound = DEFAULT_TAP_SOUND


## Call when the child has solved the level.
func finish_level() -> void:
	if is_finished:
		return
	is_finished = true
	show_feedback(success_text)
	play_sound(success_sound)
	var stars := stars_earned()
	var finished_everything := false
	if level_number > 0:
		finished_everything = GameManager.complete_level(level_number, stars)
	# Short pause so the child sees the finished puzzle before the card.
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(_show_score_card.bind(stars, finished_everything))


func stars_earned() -> int:
	if mistakes <= three_star_max_mistakes:
		return 3
	if mistakes <= two_star_max_mistakes:
		return 2
	return 1


## Counts towards the star score without showing any message.
func record_mistake() -> void:
	mistakes += 1


func show_try_again() -> void:
	record_mistake()
	show_feedback(try_again_text, TRY_AGAIN_COLOR)
	play_sound(wrong_sound)


func show_feedback(text: String, color: Color = SUCCESS_COLOR) -> void:
	feedback_label.text = text
	feedback_label.add_theme_color_override("font_color", color)


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


func _show_score_card(stars: int, finished_everything: bool) -> void:
	var card := SCORE_CARD_SCENE.instantiate()
	add_child(card)
	card.show_result(level_number, stars, finished_everything)
