class_name Hotspot
extends ReferenceRect
## Something to find in a HiddenObjectHunt level. Add as a child of
## SceneImage/Hotspots and size it over the object in the picture.
## ReferenceRect is editor-only, so it's invisible in game.

## Hotspots with the same category are counted together in the checklist.
@export var category: String = "Item"
## Shown in the checklist for this category. Falls back to the category name.
@export var icon: Texture2D
