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
@export_group("Timer")
## Seconds to finish for full stars; 0 = no timer. When time runs out the
## child keeps playing, but can earn at most 1 star.
@export var time_limit: float = 0.0
@export_group("")

@onready var prompt_label: Label = $Layout/PromptLabel
@onready var feedback_label: Label = $Layout/FeedbackLabel
@onready var back_button: Button = $BackButton
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer

var is_finished := false
var mistakes := 0
var elapsed := 0.0
var time_up := false

var _timer_fill: Panel
var _timer_back: Panel
var _pulse: Tween


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
	if time_limit > 0.0:
		_build_timer_bar()
	set_process(time_limit > 0.0)


func _process(delta: float) -> void:
	if is_finished or time_up:
		return
	elapsed += delta
	var left := clampf(1.0 - elapsed / time_limit, 0.0, 1.0)
	_timer_fill.size.x = maxf((_timer_back.size.x - 12.0) * left, 0.0)
	var colour := UiStyle.GO_COLOR
	if left < 0.2:
		colour = Color(0.93, 0.45, 0.15)
		if _pulse == null:
			_pulse = create_tween().set_loops()
			_pulse.tween_property(_timer_back, "modulate:a", 0.55, 0.35)
			_pulse.tween_property(_timer_back, "modulate:a", 1.0, 0.35)
	elif left < 0.5:
		colour = Color(0.98, 0.75, 0.15)
	_set_fill_colour(colour)
	if left <= 0.0:
		_on_time_up()


## True if the level has a timer and was finished before it ran out.
func beat_the_clock() -> bool:
	return time_limit > 0.0 and is_finished and not time_up


func _on_time_up() -> void:
	time_up = true
	if _pulse:
		_pulse.kill()
	_timer_back.modulate.a = 1.0
	_timer_back.add_theme_stylebox_override("panel", UiStyle.rounded(Color(0.75, 0.75, 0.8), 18))
	show_feedback("Keep going!", TRY_AGAIN_COLOR)


## Countdown bar centred at the top of the screen, built in code so every
## mechanic scene gets it without scene changes.
func _build_timer_bar() -> void:
	_timer_back = Panel.new()
	_timer_back.name = "TimerBar"
	_timer_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer_back.add_theme_stylebox_override("panel", UiStyle.rounded(Color(1, 1, 1, 0.85), 18, Color(0.36, 0.45, 0.62), 4))
	_timer_back.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_timer_back.offset_left = -320
	_timer_back.offset_right = 320
	_timer_back.offset_top = 44
	_timer_back.offset_bottom = 84
	add_child(_timer_back)
	_timer_fill = Panel.new()
	_timer_fill.name = "Fill"
	_timer_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer_fill.position = Vector2(6, 6)
	_timer_fill.size = Vector2(640 - 12, 28)
	_timer_back.add_child(_timer_fill)
	_set_fill_colour(UiStyle.GO_COLOR)


func _set_fill_colour(colour: Color) -> void:
	_timer_fill.add_theme_stylebox_override("panel", UiStyle.rounded(colour, 14))


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
	if time_up:
		return 1
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
	card.show_result(level_number, stars, finished_everything, time_limit > 0.0, beat_the_clock())
