class_name TapRound
extends HFlowContainer
## One round of a multi-round TapMatch level. Add under Layout/Rounds; put the
## round's TextureButtons inside it. Rounds are played in order.

## Question for this round (leave empty to keep the previous one).
@export_multiline var prompt: String = ""
## Buttons in this round (paths relative to the round) that count as correct.
@export var correct_items: Array[NodePath] = []
## Optional clue pictures shown in a row above the choices, followed by a "?"
## box that fills in with the right answer (e.g. a pattern: red, blue, red, ?).
@export var clues: Array[Texture2D] = []
