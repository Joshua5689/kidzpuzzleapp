extends MechanicLevel
## MemoryMatch mechanic: cards lie face down; tap two to flip them. A matching
## pair stays face up, otherwise both flip back. Every face in `card_faces`
## appears twice, shuffled. Mismatches cost stars (quietly — forgetting is
## part of the game).

@export var card_faces: Array[Texture2D] = []
@export var columns: int = 4
@export var card_size: Vector2 = Vector2(220, 260)
@export var card_back_color: Color = Color("3a86ff")
## Seconds both cards of a mismatch stay visible before turning back.
@export var mismatch_delay: float = 1.0

@onready var cards_grid: GridContainer = $Layout/CardsGrid

var _cards: Array[Button] = []
var _face_up: Array[Button] = []
var _matched := 0
var _busy := false


func _ready() -> void:
	super()
	if card_faces.size() < 2:
		push_warning("%s: needs at least 2 card_faces" % name)
		return
	cards_grid.columns = columns
	var deck: Array[Texture2D] = []
	for face in card_faces:
		deck.append(face)
		deck.append(face)
	deck.shuffle()
	for i in deck.size():
		var card := _make_card(deck[i])
		card.name = "Card%02d" % i
		cards_grid.add_child(card)
		_cards.append(card)


func _make_card(face: Texture2D) -> Button:
	var card := Button.new()
	card.custom_minimum_size = card_size
	card.set_meta("face", face)
	card.pressed.connect(_on_card_pressed.bind(card))
	var picture := TextureRect.new()
	picture.name = "Face"
	picture.texture = face
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.offset_left = 24
	picture.offset_top = 24
	picture.offset_right = -24
	picture.offset_bottom = -24
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(picture)
	_show_side(card, false)
	return card


## Face-up: white card showing the picture. Face-down: coloured back with "?".
func _show_side(card: Button, face_up: bool) -> void:
	card.get_node("Face").visible = face_up
	card.text = "" if face_up else "?"
	var color := Color.WHITE if face_up else card_back_color
	UiStyle.style_button(card, color, 110, 28)
	var border := UiStyle.rounded(color, 28, card_back_color.darkened(0.25), 6)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		card.add_theme_stylebox_override(state, border)


## True from the moment a flip starts, so a fast double tap can't count twice.
func is_face_up(card: Button) -> bool:
	return card.get_meta("up", false)


func _on_card_pressed(card: Button) -> void:
	if is_finished or _busy or is_face_up(card):
		return
	play_sound(tap_sound)
	_flip(card, true)
	_face_up.append(card)
	if _face_up.size() < 2:
		return

	var first := _face_up[0]
	var second := _face_up[1]
	_face_up.clear()
	if first.get_meta("face") == second.get_meta("face"):
		first.disabled = true
		second.disabled = true
		_matched += 2
		var tween := create_tween()
		tween.tween_interval(0.25)
		tween.tween_callback(func():
			bounce(first)
			bounce(second)
			if _matched == _cards.size():
				finish_level()
			else:
				play_sound(correct_sound))
	else:
		record_mistake()
		_busy = true
		var tween := create_tween()
		tween.tween_interval(mismatch_delay)
		tween.tween_callback(func():
			_flip(first, false)
			_flip(second, false)
			_busy = false)


## Squash to nothing sideways, swap the side, grow back.
func _flip(card: Button, face_up: bool) -> void:
	card.set_meta("up", face_up)
	card.pivot_offset = card.size / 2.0
	var tween := create_tween()
	tween.tween_property(card, "scale:x", 0.0, 0.1)
	tween.tween_callback(_show_side.bind(card, face_up))
	tween.tween_property(card, "scale:x", 1.0, 0.1)
