extends Control
## Star score card shown over a level when it's finished. MechanicLevel
## instances it and calls show_result().

const CHEERS := ["Well done!", "Great job!", "Amazing!"]
const EARNED_COLOR := Color.WHITE
const MISSED_COLOR := Color(0.3, 0.3, 0.35, 0.35)

@onready var card: PanelContainer = $Card
@onready var title_label: Label = $Card/Content/TitleLabel
@onready var cheer_label: Label = $Card/Content/CheerLabel
@onready var stars_row: HBoxContainer = $Card/Content/Stars
@onready var levels_button: Button = $Card/Content/Buttons/LevelsButton
@onready var again_button: Button = $Card/Content/Buttons/AgainButton
@onready var next_button: Button = $Card/Content/Buttons/NextButton
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer

var _level_number := 0
var _finished_everything := false


func _ready() -> void:
	levels_button.pressed.connect(GameManager.go_to_level_select)
	again_button.pressed.connect(func(): get_tree().reload_current_scene())
	next_button.pressed.connect(_on_next_pressed)


func show_result(level_number: int, stars: int, finished_everything: bool) -> void:
	_level_number = level_number
	_finished_everything = finished_everything
	title_label.text = "Level %d" % level_number if level_number > 0 else ""
	cheer_label.text = CHEERS[clampi(stars, 1, 3) - 1]
	if finished_everything:
		next_button.text = "Surprise! ▶"

	# Card pops in, then each earned star pops in turn with a sparkle.
	# Wait a frame so containers have laid out and pivots use real sizes.
	modulate.a = 0.0
	await get_tree().process_frame
	card.pivot_offset = card.size / 2.0
	card.scale = Vector2(0.6, 0.6)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(card, "scale", Vector2.ONE, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in stars_row.get_child_count():
		var star: TextureRect = stars_row.get_child(i)
		star.pivot_offset = star.size / 2.0
		star.scale = Vector2.ZERO
		star.modulate = EARNED_COLOR if i < stars else MISSED_COLOR
		tween.tween_interval(0.15)
		if i < stars:
			tween.tween_callback(sfx_player.play)
		tween.tween_property(star, "scale", Vector2.ONE, 0.3) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_next_pressed() -> void:
	if _finished_everything:
		GameManager.go_to_celebration()
	else:
		GameManager.go_to_next_level(_level_number)
