extends MechanicLevel
## SequenceMemory mechanic ("Simon says"): the pads light up one after another
## with a note each; the child then taps them in the same order. A wrong tap
## costs a star point and replays the same sequence. Each round's sequence
## length comes from `rounds`; every round starts a fresh random sequence.

@export var pad_textures: Array[Texture2D] = []
## One note per pad (same order as pad_textures). Optional.
@export var pad_sounds: Array[AudioStream] = []
## Sequence length for each round, in order.
@export var rounds: Array[int] = [3, 4, 5]
@export var pad_size: float = 230.0
## Seconds each pad stays lit while the sequence is shown.
@export var light_time: float = 0.55
@export var watch_text: String = "Watch the bee!"
@export var your_turn_text: String = "Your turn!"
@export var watch_again_text: String = "Watch again!"

@onready var pads_row: HBoxContainer = $Layout/PadsRow
@onready var round_label: Label = $RoundLabel

var _pads: Array[TextureButton] = []
var _sequence: Array[int] = []
var _round := 0
var _step := 0
var _listening := false
var _note_player: AudioStreamPlayer


func _ready() -> void:
	super()
	_note_player = AudioStreamPlayer.new()
	add_child(_note_player)
	for i in pad_textures.size():
		var pad := TextureButton.new()
		pad.name = "Pad%d" % (i + 1)
		pad.texture_normal = pad_textures[i]
		pad.ignore_texture_size = true
		pad.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		pad.custom_minimum_size = Vector2(pad_size, pad_size)
		pad.modulate = Color(1, 1, 1, 0.55)
		pad.pressed.connect(_on_pad_pressed.bind(i))
		pads_row.add_child(pad)
		_pads.append(pad)
	if _pads.size() < 2 or rounds.is_empty():
		push_warning("%s: needs at least 2 pad_textures and some rounds" % name)
		return
	_start_round.call_deferred(0)


func _start_round(index: int) -> void:
	_round = index
	round_label.text = "%d / %d" % [index + 1, rounds.size()]
	_sequence.clear()
	for i in rounds[index]:
		_sequence.append(randi() % _pads.size())
	_play_sequence()


## Lights the pads in order, then hands over to the child.
func _play_sequence() -> void:
	_listening = false
	_step = 0
	show_feedback(watch_text, UiStyle.MUTED_COLOR)
	var tween := create_tween()
	tween.tween_interval(0.6)
	for pad_index in _sequence:
		tween.tween_callback(_light.bind(pad_index))
		tween.tween_interval(light_time + 0.2)
	tween.tween_callback(func():
		_listening = true
		show_feedback(your_turn_text))


func _light(pad_index: int) -> void:
	var pad := _pads[pad_index]
	pad.pivot_offset = pad.size / 2.0
	var tween := create_tween()
	tween.tween_property(pad, "modulate", Color.WHITE, 0.08)
	tween.parallel().tween_property(pad, "scale", Vector2(1.15, 1.15), 0.08)
	tween.tween_interval(light_time - 0.16)
	tween.tween_property(pad, "modulate", Color(1, 1, 1, 0.55), 0.08)
	tween.parallel().tween_property(pad, "scale", Vector2.ONE, 0.08)
	if pad_index < pad_sounds.size() and pad_sounds[pad_index]:
		_note_player.stream = pad_sounds[pad_index]
		_note_player.play()


func _on_pad_pressed(pad_index: int) -> void:
	if is_finished or not _listening:
		return
	_light(pad_index)
	if pad_index != _sequence[_step]:
		record_mistake()
		shake(_pads[pad_index])
		play_sound(wrong_sound)
		show_feedback(watch_again_text, TRY_AGAIN_COLOR)
		_listening = false
		var tween := create_tween()
		tween.tween_interval(0.8)
		tween.tween_callback(_play_sequence)
		return
	_step += 1
	if _step < _sequence.size():
		return
	_listening = false
	if _round == rounds.size() - 1:
		finish_level()
		return
	show_feedback("Great!")
	play_sound(correct_sound)
	var next := create_tween()
	next.tween_interval(1.0)
	next.tween_callback(_start_round.bind(_round + 1))


## For tests: the sequence currently being asked for.
func current_sequence() -> Array[int]:
	return _sequence.duplicate()


func is_listening() -> bool:
	return _listening
