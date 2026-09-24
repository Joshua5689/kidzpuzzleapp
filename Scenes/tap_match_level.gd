extends Control

# Set this in the Inspector per level.
# Must exactly match the name of the correct TextureButton node.
# e.g. "Red" for the colours level, "Apple" for the fruit level.
@export var correct_item: String = ""

signal level_complete

func _ready() -> void:
	# Hook up every TextureButton inside ItemsContainer automatically,
	# so you never have to wire signals by hand in the editor.
	for child in $ItemsContainer.get_children():
		if child is TextureButton:
			child.pressed.connect(_on_item_pressed.bind(child.name))

	$FeedbackLabel.visible = false
	$NextButton.visible = false
	$NextButton.pressed.connect(_on_next_pressed)


func _on_item_pressed(item_name: String) -> void:
	if item_name == correct_item:
		_show_feedback("Great job! 🎉", true)
	else:
		_show_feedback("Try again!", false)


func _show_feedback(text: String, correct: bool) -> void:
	$FeedbackLabel.text = text
	$FeedbackLabel.visible = true

	if correct:
		$NextButton.visible = true
		if has_node("SuccessSound"):
			$SuccessSound.play()
	else:
		if has_node("FailSound"):
			$FailSound.play()
		# Hide the "try again" message after a moment so the child can try another item.
		await get_tree().create_timer(0.8).timeout
		$FeedbackLabel.visible = false


func _on_next_pressed() -> void:
	level_complete.emit()
