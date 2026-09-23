extends MechanicLevel
## TapMatch mechanic: the child taps every correct item among the ones shown.
## Level scenes inherit TapMatchLevel.tscn, add TextureButtons under
## Layout/ItemsContainer and pick the correct ones in `correct_items`.

## Buttons under ItemsContainer that count as correct. All must be tapped.
@export var correct_items: Array[NodePath] = []

@onready var items_container: Container = $Layout/ItemsContainer

var _correct_buttons: Array[BaseButton] = []
var _found: Array[BaseButton] = []


func _ready() -> void:
	super()
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
	if is_finished or _found.has(button):
		return
	if _correct_buttons.has(button):
		_found.append(button)
		button.disabled = true
		bounce(button)
		if _found.size() == _correct_buttons.size():
			_disable_all_items()
			finish_level()
		else:
			play_sound(correct_sound)
			clear_feedback()
	else:
		shake(button)
		show_try_again()


func _disable_all_items() -> void:
	for child in items_container.get_children():
		if child is BaseButton:
			child.disabled = true
