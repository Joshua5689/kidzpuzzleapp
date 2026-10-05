"""Base scenes for the World 5 mechanics: SlidePuzzle, SequenceMemory,
ConnectDots, PictureSudoku. Same layout conventions as the other mechanics
(Layout/PromptLabel, Layout/FeedbackLabel, BackButton, SfxPlayer)."""
from art import write

BG = """[sub_resource type="Gradient" id="Gradient_bg"]
colors = PackedColorArray(0.84, 0.94, 1, 1, 1, 0.97, 0.86, 1)

[sub_resource type="GradientTexture2D" id="GradientTexture2D_bg"]
gradient = SubResource("Gradient_bg")
fill_to = Vector2(0, 1)
"""
FULL = """anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2"""
ROUND_LABEL = """
[node name="RoundLabel" type="Label" parent="."]
layout_mode = 1
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -224.0
offset_top = 40.0
offset_right = -32.0
offset_bottom = 120.0
grow_horizontal = 0
theme_override_colors/font_color = Color(0.2, 0.2, 0.35, 0.6)
theme_override_font_sizes/font_size = 48
text = "1 / 3"
horizontal_alignment = 2
"""


def base_scene(mech, prompt, middle, extra_nodes="", root_props=""):
    return f"""[gd_scene format=3]

[ext_resource type="Script" path="res://Scenes/Mechanics/{mech}/{mech}Level.gd" id="1_script"]

{BG}
[node name="{mech}Level" type="Control"]
layout_mode = 3
{FULL}
script = ExtResource("1_script")
{root_props}
[node name="Background" type="TextureRect" parent="."]
layout_mode = 1
{FULL}
mouse_filter = 2
texture = SubResource("GradientTexture2D_bg")
expand_mode = 1
stretch_mode = 6

[node name="Layout" type="VBoxContainer" parent="."]
layout_mode = 1
{FULL}
offset_left = 48.0
offset_top = 32.0
offset_right = -48.0
offset_bottom = -32.0
theme_override_constants/separation = 24
alignment = 1

[node name="PromptLabel" type="Label" parent="Layout"]
layout_mode = 2
theme_override_colors/font_color = Color(0.2, 0.2, 0.35, 1)
theme_override_font_sizes/font_size = 72
text = "{prompt}"
horizontal_alignment = 1
autowrap_mode = 3

{middle}
[node name="FeedbackLabel" type="Label" parent="Layout"]
custom_minimum_size = Vector2(0, 90)
layout_mode = 2
theme_override_colors/font_color = Color(0.15, 0.55, 0.25, 1)
theme_override_font_sizes/font_size = 64
horizontal_alignment = 1

[node name="BackButton" type="Button" parent="."]
custom_minimum_size = Vector2(120, 120)
layout_mode = 0
offset_left = 24.0
offset_top = 24.0
offset_right = 144.0
offset_bottom = 144.0
theme_override_font_sizes/font_size = 56
text = "◀"
{extra_nodes}
[node name="SfxPlayer" type="AudioStreamPlayer" parent="."]
"""


write("Scenes/Mechanics/SlidePuzzle/SlidePuzzleLevel.tscn", base_scene("SlidePuzzle", "Slide the pieces to fix the picture!", """[node name="PlayArea" type="HBoxContainer" parent="Layout"]
layout_mode = 2
theme_override_constants/separation = 48
alignment = 1

[node name="Board" type="Control" parent="Layout/PlayArea"]
layout_mode = 2
size_flags_vertical = 4

[node name="PreviewImage" type="TextureRect" parent="Layout/PlayArea"]
custom_minimum_size = Vector2(280, 280)
layout_mode = 2
size_flags_vertical = 0
mouse_filter = 2
expand_mode = 1
stretch_mode = 5
""", root_props="three_star_max_mistakes = 4\ntwo_star_max_mistakes = 10\n"))

write("Scenes/Mechanics/SequenceMemory/SequenceMemoryLevel.tscn", base_scene("SequenceMemory", "Follow the bee!", """[node name="PadsRow" type="HBoxContainer" parent="Layout"]
custom_minimum_size = Vector2(0, 300)
layout_mode = 2
theme_override_constants/separation = 48
alignment = 1
""", extra_nodes=ROUND_LABEL, root_props="three_star_max_mistakes = 0\ntwo_star_max_mistakes = 2\n"))

write("Scenes/Mechanics/ConnectDots/ConnectDotsLevel.tscn", base_scene("ConnectDots", "Join the dots in order!", """[node name="Board" type="Control" parent="Layout"]
layout_mode = 2
size_flags_horizontal = 4
""", extra_nodes=ROUND_LABEL, root_props="three_star_max_mistakes = 1\ntwo_star_max_mistakes = 4\n"))

write("Scenes/Mechanics/PictureSudoku/PictureSudokuLevel.tscn", base_scene("PictureSudoku", "Each fruit once in every row, column and box!", """[node name="PlayArea" type="HBoxContainer" parent="Layout"]
layout_mode = 2
theme_override_constants/separation = 64
alignment = 1

[node name="Grid" type="GridContainer" parent="Layout/PlayArea"]
layout_mode = 2
theme_override_constants/h_separation = 10
theme_override_constants/v_separation = 10
columns = 4

[node name="Palette" type="VBoxContainer" parent="Layout/PlayArea"]
layout_mode = 2
theme_override_constants/separation = 16
alignment = 1
""", root_props="three_star_max_mistakes = 1\ntwo_star_max_mistakes = 4\n"))
print("World 5 mechanic scenes written")
