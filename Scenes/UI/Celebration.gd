extends Control
## Shown once the child has finished all levels: fireworks, trophy, fanfare.

const FIREWORK_COLORS := [
	Color("ff4d6d"), Color("ffd23f"), Color("3a86ff"), Color("43d17a"),
	Color("ff9f1c"), Color("c77dff"), Color("4cc9f0"), Color("ffffff"),
]
const FIREWORK_SOUND: AudioStream = preload("res://Assets/Audio/SFX/Firework.wav")
const ROCKET_TIME := 0.35

## Seconds between launches.
@export var launch_interval: Vector2 = Vector2(0.25, 0.6)

@onready var fireworks: Node2D = $Fireworks
@onready var trophy: TextureRect = $Layout/Trophy
@onready var title_label: Label = $Layout/TitleLabel
@onready var stars_label: Label = $Layout/StarsRow/StarsLabel
@onready var play_again_button: Button = $Layout/Buttons/PlayAgainButton
@onready var menu_button: Button = $Layout/Buttons/MenuButton
@onready var fanfare_player: AudioStreamPlayer = $FanfarePlayer
@onready var firework_player: AudioStreamPlayer = $FireworkPlayer

var _spark_texture: Texture2D


func _ready() -> void:
	play_again_button.pressed.connect(GameManager.go_to_level_select)
	menu_button.pressed.connect(GameManager.go_to_main_menu)
	stars_label.text = "x %d" % GameManager.total_stars()
	_spark_texture = _make_spark_texture()
	firework_player.stream = FIREWORK_SOUND
	firework_player.max_polyphony = 6

	MusicPlayer.duck(3.0)
	fanfare_player.play()
	_animate_title()
	_launch_loop()


func _animate_title() -> void:
	await get_tree().process_frame
	trophy.pivot_offset = trophy.size / 2.0
	title_label.pivot_offset = title_label.size / 2.0
	var bob := create_tween().set_loops()
	bob.tween_property(trophy, "position:y", trophy.position.y - 24, 0.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(trophy, "position:y", trophy.position.y, 0.6).set_trans(Tween.TRANS_SINE)
	var pulse := create_tween().set_loops()
	pulse.tween_property(title_label, "scale", Vector2(1.08, 1.08), 0.5).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(title_label, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)


func _launch_loop() -> void:
	# Open with a volley so the screen lights up straight away.
	for i in 3:
		launch_firework()
	while is_inside_tree():
		launch_firework()
		await get_tree().create_timer(randf_range(launch_interval.x, launch_interval.y)).timeout


## A rocket streaks up from the bottom and bursts into sparks.
func launch_firework() -> void:
	var screen := get_viewport_rect().size
	var target := Vector2(randf_range(0.1, 0.9) * screen.x, randf_range(0.1, 0.5) * screen.y)
	var color: Color = FIREWORK_COLORS.pick_random()

	var rocket := Sprite2D.new()
	rocket.texture = _spark_texture
	rocket.scale = Vector2(0.8, 0.8)
	rocket.modulate = color
	rocket.position = Vector2(target.x + randf_range(-80, 80), screen.y + 20)
	fireworks.add_child(rocket)
	var rise := create_tween()
	rise.tween_property(rocket, "position", target, ROCKET_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	rise.tween_callback(rocket.queue_free)
	rise.tween_callback(_burst.bind(target, color))
	firework_player.play()


func _burst(at: Vector2, color: Color) -> void:
	var sparks := CPUParticles2D.new()
	sparks.position = at
	sparks.texture = _spark_texture
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = 140
	sparks.lifetime = 1.4
	sparks.spread = 180.0
	sparks.direction = Vector2.UP
	sparks.initial_velocity_min = 200.0
	sparks.initial_velocity_max = 460.0
	sparks.gravity = Vector2(0, 220)
	sparks.damping_min = 40.0
	sparks.damping_max = 80.0
	sparks.scale_amount_min = 0.5
	sparks.scale_amount_max = 0.9
	var fade := Gradient.new()
	fade.set_color(0, Color(color, 1.0))
	fade.set_color(1, Color(color, 0.0))
	sparks.color_ramp = fade
	sparks.finished.connect(sparks.queue_free)
	fireworks.add_child(sparks)
	sparks.emitting = true


## Soft round glow used for rockets and sparks.
func _make_spark_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.35, Color(1, 1, 1, 0.9))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 32
	texture.height = 32
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture
