"""Generates levels 11-20 for Puddle Jump: new mechanic base scenes
(MemoryMatch, SortDrag), placeholder art and the level scenes."""
import math
import random
from collections import deque

from art import *

random.seed(11)

# ---- Shared scene fragments ---------------------------------------------------

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


def base_scene(mech, prompt, middle, root_props=""):
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

[node name="SfxPlayer" type="AudioStreamPlayer" parent="."]
"""


write("Scenes/Mechanics/MemoryMatch/MemoryMatchLevel.tscn", base_scene("MemoryMatch", "Find the pairs!", """[node name="CardsGrid" type="GridContainer" parent="Layout"]
layout_mode = 2
size_flags_horizontal = 4
theme_override_constants/h_separation = 28
theme_override_constants/v_separation = 28
columns = 4
""", "three_star_max_mistakes = 3\ntwo_star_max_mistakes = 7\n"))

write("Scenes/Mechanics/SortDrag/SortDragLevel.tscn", base_scene("SortDrag", "Put each thing where it belongs!", f"""[node name="PlayArea" type="Control" parent="Layout"]
custom_minimum_size = Vector2(1700, 780)
layout_mode = 2
size_flags_horizontal = 4

[node name="Bins" type="Control" parent="Layout/PlayArea"]
layout_mode = 1
{FULL}
mouse_filter = 2

[node name="Items" type="Control" parent="Layout/PlayArea"]
layout_mode = 1
{FULL}
mouse_filter = 2
"""))


class Level:
    """Small builder for inherited level scenes."""

    def __init__(self, file, root, base):
        self.file, self.root, self.base = file, root, base
        self.ext = [("PackedScene", base, "1_base")]
        self.props, self.overrides, self.nodes = [], [], []

    def res(self, kind, path):
        rid = f"r{len(self.ext) + 1}"
        for k, p, i in self.ext:
            if p == path:
                return i
        self.ext.append((kind, path, rid))
        return rid

    def tex(self, path):
        return f'ExtResource("{self.res("Texture2D", path)}")'

    def save(self):
        out = ["[gd_scene format=3]", ""]
        out += [f'[ext_resource type="{k}" path="{p}" id="{i}"]' for k, p, i in self.ext]
        out += ["", f'[node name="{self.root}" instance=ExtResource("1_base")]'] + self.props + [""]
        out += self.overrides + self.nodes
        write(f"Scenes/Levels/{self.file}", "\n".join(out))


def rect_node(name, kind, parent, x, y, w, h, extra):
    return [f'[node name="{name}" type="{kind}" parent="{parent}"]', "layout_mode = 0",
            f"offset_left = {x}.0", f"offset_top = {y}.0", f"offset_right = {x + w}.0", f"offset_bottom = {y + h}.0"] + extra + [""]


def chaikin(pts, rounds=3):
    for _ in range(rounds):
        out = [pts[0]]
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            out += [(0.75 * x0 + 0.25 * x1, 0.75 * y0 + 0.25 * y1), (0.25 * x0 + 0.75 * x1, 0.25 * y0 + 0.75 * y1)]
        out.append(pts[-1])
        pts = out
    return pts


def ellipse(cx, cy, rx, ry, n=40, rot=0.0):
    c, s = math.cos(rot), math.sin(rot)
    pts = []
    for i in range(n):
        a = 2 * math.pi * i / n
        x, y = rx * math.cos(a), ry * math.sin(a)
        pts.append((cx + x * c - y * s, cy + x * s + y * c))
    return pts


def pts_attr(poly):
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in poly)


def packed(poly):
    return ", ".join(f"{x:.1f}, {y:.1f}" for x, y in poly)


A = "res://Assets/Images/Animals/"
T = "res://Assets/Images/Toys/"
F = "res://Assets/Images/Fruit/"

# ---- Level 11: count the ducks (CountSelect) -------------------------------------
lv = Level("Level11_CountDucks.tscn", "Level11_CountDucks", "res://Scenes/Mechanics/CountSelect/CountSelectLevel.tscn")
lv.props = ["level_number = 11", 'prompt_text = "How many ducks?"', f"item_texture = {lv.tex(A + 'Duck.svg')}",
            "rounds = Array[int]([4, 6, 8, 5])", "answer_choices = 4", "max_number = 10", "item_size = 130.0"]
lv.save()

# ---- Level 12: farm jigsaw 3x3 (DragRearrange) -------------------------------------
cow = ('<ellipse cx="0" cy="0" rx="95" ry="58" fill="#fff" stroke="#333" stroke-width="5"/>'
       '<ellipse cx="-30" cy="-12" rx="28" ry="20" fill="#333"/><ellipse cx="40" cy="14" rx="22" ry="16" fill="#333"/>'
       '<rect x="-72" y="40" width="20" height="56" fill="#fff" stroke="#333" stroke-width="4"/>'
       '<rect x="50" y="40" width="20" height="56" fill="#fff" stroke="#333" stroke-width="4"/>'
       '<ellipse cx="112" cy="-30" rx="44" ry="36" fill="#fff" stroke="#333" stroke-width="5"/>'
       '<ellipse cx="130" cy="-14" rx="26" ry="18" fill="#ffb3c1"/>'
       '<circle cx="104" cy="-44" r="6" fill="#222"/>'
       '<path d="M84 -64 L76 -84 M140 -64 L150 -84" stroke="#c9a66b" stroke-width="8" stroke-linecap="round"/>')
chicken = ('<ellipse cx="0" cy="0" rx="46" ry="38" fill="#fff" stroke="#ccc" stroke-width="3"/>'
           '<circle cx="34" cy="-36" r="24" fill="#fff" stroke="#ccc" stroke-width="3"/>'
           '<path d="M26 -62 Q34 -76 42 -62 Q48 -74 54 -60" fill="#e63946"/>'
           '<polygon points="56,-38 72,-32 56,-26" fill="#ff9f1c"/><circle cx="40" cy="-40" r="4" fill="#222"/>'
           '<path d="M-6 36 L-10 56 M10 36 L14 56" stroke="#ff9f1c" stroke-width="5"/>')
farm = [
    '<rect width="1200" height="900" fill="#8fd3ff"/>',
    '<ellipse cx="300" cy="560" rx="520" ry="160" fill="#7ccf5a"/><ellipse cx="950" cy="560" rx="480" ry="170" fill="#6cc24a"/>',
    '<rect y="560" width="1200" height="340" fill="#6cc24a"/>',
    '<circle cx="130" cy="120" r="75" fill="#ffd23f"/>',
    '<g fill="#fff"><circle cx="330" cy="120" r="38"/><circle cx="375" cy="100" r="50"/><circle cx="425" cy="125" r="38"/></g>',
    '<g fill="#fff"><circle cx="820" cy="90" r="30"/><circle cx="858" cy="74" r="40"/><circle cx="898" cy="92" r="30"/></g>',
    # barn
    '<rect x="470" y="330" width="300" height="300" fill="#c1272d"/>',
    '<polygon points="440,340 620,200 800,340" fill="#8b1a1f"/>',
    '<rect x="560" y="470" width="120" height="160" fill="#fff"/><path d="M560 470 L680 630 M680 470 L560 630" stroke="#c1272d" stroke-width="10"/>',
    '<rect x="585" y="360" width="70" height="60" fill="#fff3b0" stroke="#fff" stroke-width="8"/>',
    # tree
    '<rect x="1000" y="330" width="44" height="220" fill="#7a4e2d"/><circle cx="1022" cy="290" r="120" fill="#2e8b3e"/>',
    '<circle cx="980" cy="260" r="16" fill="#e63946"/><circle cx="1060" cy="310" r="16" fill="#e63946"/><circle cx="1010" cy="340" r="14" fill="#e63946"/>',
    # fence
    '<g fill="#e8d5b0" stroke="#b89b6a" stroke-width="3">' +
    "".join(f'<rect x="{x}" y="520" width="18" height="90"/>' for x in range(20, 440, 60)) +
    '<rect x="10" y="540" width="430" height="14"/><rect x="10" y="580" width="430" height="14"/></g>',
    f'<g transform="translate(230 740)">{cow}</g>',
    f'<g transform="translate(900 760)">{chicken}</g>',
    "".join(f'<circle cx="{x}" cy="{y}" r="12" fill="#ff6fb5"/><circle cx="{x}" cy="{y}" r="5" fill="#ffd23f"/>'
            for x, y in [(520, 800), (600, 840), (700, 790), (1100, 850), (60, 860)]),
]
write("Assets/Images/Puzzle/Farm.svg", svg(1200, 900, "\n".join(farm)))
lv = Level("Level12_FarmPuzzle.tscn", "Level12_FarmPuzzle", "res://Scenes/Mechanics/DragRearrange/DragRearrangeLevel.tscn")
lv.props = ["level_number = 12", 'prompt_text = "Put the farm back together!"', f"image = {lv.tex('res://Assets/Images/Puzzle/Farm.svg')}",
            "rows = 3", "columns = 3", "board_width = 880.0"]
lv.save()

# ---- Level 13: odd one out (TapMatch) ------------------------------------------
lv = Level("Level13_OddOneOut.tscn", "Level13_OddOneOut", "res://Scenes/Mechanics/TapMatch/TapMatchLevel.tscn")
lv.props = ["level_number = 13", 'prompt_text = "Which one is different?"',
            'correct_items = Array[NodePath]([NodePath("Layout/ItemsContainer/ToyCar")])']
for name, path in [("Apple", F + "Apple.svg"), ("Banana", F + "Banana.svg"), ("ToyCar", T + "ToyCar.svg"), ("Orange", F + "Orange.svg")]:
    lv.nodes += [f'[node name="{name}" type="TextureButton" parent="Layout/ItemsContainer"]',
                 "custom_minimum_size = Vector2(250, 250)", "layout_mode = 2", f"texture_normal = {lv.tex(path)}",
                 "ignore_texture_size = true", "stretch_mode = 5", ""]
lv.save()

# ---- Level 14: memory pairs (MemoryMatch) ----------------------------------------
lv = Level("Level14_MemoryPairs.tscn", "Level14_MemoryPairs", "res://Scenes/Mechanics/MemoryMatch/MemoryMatchLevel.tscn")
faces = ", ".join(lv.tex(A + f"{n}.svg") for n in ["Frog", "Duck", "Bee", "Owl"])
lv.props = ["level_number = 14", 'prompt_text = "Find the pairs!"', f"card_faces = Array[Texture2D]([{faces}])"]
lv.save()

# ---- Level 15: colour the butterfly (ColourFill) ---------------------------------
# Laid out so no two parts overlap (spots sit inside their wings), which keeps
# the outlines clean and every part easy to tap.
regions = [
    ("TopLeftWing", ellipse(292, 222, 160, 120, rot=-0.35)),
    ("TopRightWing", ellipse(708, 222, 160, 120, rot=0.35)),
    ("BottomLeftWing", ellipse(365, 450, 105, 90, rot=0.4)),
    ("BottomRightWing", ellipse(635, 450, 105, 90, rot=-0.4)),
    ("TopLeftSpot", ellipse(278, 217, 55, 45, 28)),
    ("TopRightSpot", ellipse(722, 217, 55, 45, 28)),
    ("BottomLeftSpot", ellipse(360, 455, 38, 34, 24)),
    ("BottomRightSpot", ellipse(640, 455, 38, 34, 24)),
    ("Body", ellipse(500, 360, 28, 160, 32)),
    ("Head", ellipse(500, 152, 44, 42, 28)),
]
art_lines = [f'<polygon points="{pts_attr(p)}" fill="none" stroke="#2b2b3a" stroke-width="8" stroke-linejoin="round"/>' for _, p in regions]
art_lines.append('<path d="M486 114 Q455 55 425 42 M514 114 Q545 55 575 42" stroke="#2b2b3a" stroke-width="8" fill="none" stroke-linecap="round"/>')
art_lines.append('<circle cx="425" cy="42" r="12" fill="#2b2b3a"/><circle cx="575" cy="42" r="12" fill="#2b2b3a"/>')
art_lines.append('<circle cx="486" cy="146" r="6" fill="#2b2b3a"/><circle cx="514" cy="146" r="6" fill="#2b2b3a"/>')
write("Assets/Images/ColourFill/ButterflyLineArt.svg", svg(1000, 600, "\n".join(art_lines)))
lv = Level("Level15_ColourButterfly.tscn", "Level15_ColourButterfly", "res://Scenes/Mechanics/ColourFill/ColourFillLevel.tscn")
lv.props = ["level_number = 15", 'prompt_text = "Colour the butterfly!"']
lv.overrides = ['[node name="LineArt" parent="Layout/Canvas" index="1"]', f"texture = {lv.tex('res://Assets/Images/ColourFill/ButterflyLineArt.svg')}", ""]
for name, poly in regions:
    lv.nodes += [f'[node name="{name}" type="Polygon2D" parent="Layout/Canvas/Regions"]', f"polygon = PackedVector2Array({packed(poly)})", ""]
lv.save()

# ---- Level 16: bee maze (MazeDrag) ---------------------------------------------
MAZE = [
    "#############",
    "#S....#.....#",
    "#.###.#.###.#",
    "#...#...#...#",
    "###.#####.#.#",
    "#...#.....#.#",
    "#.###.#####.#",
    "#.....#....E#",
    "#############",
]


def solvable(grid):
    start = next((x, y) for y, r in enumerate(grid) for x, c in enumerate(r) if c == "S")
    seen, queue = {start}, deque([start])
    while queue:
        x, y = queue.popleft()
        if grid[y][x] == "E":
            return True
        for dx, dy in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
            n = (x + dx, y + dy)
            if grid[n[1]][n[0]] != "#" and n not in seen:
                seen.add(n)
                queue.append(n)
    return False


assert solvable(MAZE), "bee maze has no path!"
lv = Level("Level16_BeeMaze.tscn", "Level16_BeeMaze", "res://Scenes/Mechanics/MazeDrag/MazeDragLevel.tscn")
rows = ", ".join(f'"{r}"' for r in MAZE)
lv.props = ["level_number = 16", 'prompt_text = "Help the bee find the flower!"', f"layout = PackedStringArray({rows})",
            f"player_texture = {lv.tex(A + 'Bee.svg')}", f"goal_texture = {lv.tex(A + 'Flower.svg')}",
            "wall_color = Color(0.55, 0.78, 0.4, 1)", "path_color = Color(1, 0.97, 0.85, 1)"]
lv.save()

# ---- Level 17: sort fruit and toys (SortDrag) -----------------------------------
lv = Level("Level17_SortToys.tscn", "Level17_SortToys", "res://Scenes/Mechanics/SortDrag/SortDragLevel.tscn")
lv.props = ["level_number = 17", 'prompt_text = "Fruit in the basket, toys in the box!"']
bin_script = lv.res("Script", "res://Scenes/Mechanics/SortDrag/SortBin.gd")
item_script = lv.res("Script", "res://Scenes/Mechanics/SortDrag/SortItem.gd")
for name, path, x, cat in [("Basket", T + "Basket.svg", 160, "fruit"), ("ToyBox", T + "ToyBox.svg", 1160, "toy")]:
    lv.nodes += rect_node(name, "TextureRect", "Layout/PlayArea/Bins", x, 390, 380, 380,
                          [f"texture = {lv.tex(path)}", "expand_mode = 1", "stretch_mode = 5",
                           f'script = ExtResource("{bin_script}")', f'category = "{cat}"'])
things = [("Apple", F, "fruit"), ("Ball", T, "toy"), ("Banana", F, "fruit"), ("Teddy", T, "toy"),
          ("Grapes", F, "fruit"), ("Blocks", T, "toy"), ("Orange", F, "fruit"), ("ToyCar", T, "toy")]
for i, (name, folder, cat) in enumerate(things):
    x = 45 + i * 205
    y = 60 if i % 2 == 0 else 150
    lv.nodes += rect_node(name, "TextureRect", "Layout/PlayArea/Items", x, y, 180, 180,
                          [f"texture = {lv.tex(folder + name + '.svg')}", "expand_mode = 1", "stretch_mode = 5",
                           f'script = ExtResource("{item_script}")', f'category = "{cat}"'])
lv.save()

# ---- Level 18: spot 6 differences in the park (HiddenObjectHunt) ----------------


def park(b):
    kite = "#3a86ff" if b else "#e63946"
    slide = "#43b649" if b else "#ffd23f"
    flower = "#9b5de5" if b else "#ff6fb5"
    parts = ['<rect width="700" height="525" fill="#8fd3ff"/>', '<rect y="360" width="700" height="165" fill="#6cc24a"/>',
             '<g fill="#fff"><circle cx="280" cy="70" r="26"/><circle cx="310" cy="58" r="34"/><circle cx="342" cy="72" r="26"/></g>']
    if b:
        parts.append('<g fill="#fff" stroke="#c9dcea" stroke-width="4"><circle cx="395" cy="128" r="28"/><circle cx="428" cy="112" r="36"/><circle cx="462" cy="130" r="28"/></g><g fill="#fff"><circle cx="395" cy="128" r="25"/><circle cx="428" cy="112" r="33"/><circle cx="462" cy="130" r="25"/></g>')
    parts += ['<rect x="72" y="250" width="26" height="130" fill="#7a4e2d"/><circle cx="85" cy="215" r="62" fill="#2e8b3e"/>']
    if b:
        parts.append('<ellipse cx="150" cy="178" rx="18" ry="13" fill="#7a4e2d"/><circle cx="163" cy="168" r="9" fill="#7a4e2d"/>'
                     '<polygon points="170,168 180,171 170,174" fill="#ff9f1c"/>')
    parts += [f'<polygon points="520,45 555,90 520,135 485,90" fill="{kite}"/>',
              '<path d="M520 135 Q500 180 530 220 Q510 260 540 300" stroke="#555" stroke-width="3" fill="none"/>',
              '<rect x="390" y="250" width="12" height="150" fill="#888"/><rect x="430" y="250" width="12" height="150" fill="#888"/>'
              + "".join(f'<rect x="390" y="{y}" width="52" height="8" fill="#888"/>' for y in (280, 310, 340, 370)),
              f'<polygon points="440,250 470,250 590,395 555,400" fill="{slide}"/>',
              '<rect x="380" y="244" width="94" height="14" fill="#888"/>']
    if not b:
        parts.append('<circle cx="220" cy="450" r="24" fill="#e63946"/><path d="M198 445 Q220 430 242 445" stroke="#fff" stroke-width="5" fill="none"/>')
    parts += [f'<circle cx="620" cy="470" r="18" fill="{flower}"/><circle cx="620" cy="470" r="7" fill="#ffd23f"/>',
              '<rect x="617" y="488" width="6" height="30" fill="#2e8b3e"/>',
              '<circle cx="80" cy="470" r="16" fill="#ff9f1c"/><circle cx="80" cy="470" r="6" fill="#ffd23f"/>']
    return "\n".join(parts)


write("Assets/Images/HiddenObjects/ParkA.svg", svg(700, 525, park(False)))
write("Assets/Images/HiddenObjects/ParkB.svg", svg(700, 525, park(True)))
HOTSPOT = "res://Scenes/Mechanics/HiddenObjectHunt/Hotspot.gd"
PICS = "Layout/PlayArea/Pictures"


def hunt(file, root, props, image, size, spots, compare=None):
    lv = Level(file, root, "res://Scenes/Mechanics/HiddenObjectHunt/HiddenObjectHuntLevel.tscn")
    lv.props = props
    script = lv.res("Script", HOTSPOT)
    lv.overrides = [f'[node name="SceneImage" parent="{PICS}" index="0"]', f"custom_minimum_size = Vector2({size[0]}, {size[1]})",
                    f"texture = {lv.tex(image)}", ""]
    if compare:
        lv.overrides += [f'[node name="CompareImage" parent="{PICS}" index="1"]', f"texture = {lv.tex(compare)}", ""]
    for name, cat, icon, x, y, w, h in spots:
        extra = ["border_width = 3.0", f'script = ExtResource("{script}")', f'category = "{cat}"']
        if icon:
            extra.append(f"icon = {lv.tex(icon)}")
        lv.nodes += rect_node(name, "ReferenceRect", f"{PICS}/SceneImage/Hotspots", x, y, w, h, extra)
    lv.save()


hunt("Level18_ParkDifferences.tscn", "Level18_ParkDifferences",
     ["level_number = 18", 'prompt_text = "Find the 6 differences!"'],
     "res://Assets/Images/HiddenObjects/ParkA.svg", (700, 525),
     [("Kite", "Differences", None, 480, 40, 80, 100),
      ("Cloud", "Differences", None, 364, 74, 130, 86),
      ("Bird", "Differences", None, 128, 152, 58, 40),
      ("Slide", "Differences", None, 440, 250, 150, 150),
      ("Ball", "Differences", None, 192, 422, 56, 56),
      ("Flower", "Differences", None, 596, 446, 48, 48)],
     compare="res://Assets/Images/HiddenObjects/ParkB.svg")

# ---- Level 19: trace the letters A B C (TraceInput) -----------------------------
arc_c = [(400 + 190 * math.cos(math.radians(a)), 370 + 190 * math.sin(math.radians(a))) for a in range(-40, -321, -10)]
b_bumps = chaikin([(300, 130), (430, 130), (495, 175), (495, 245), (440, 295), (300, 300)]) + \
    chaikin([(300, 300), (450, 305), (515, 360), (515, 470), (455, 590), (300, 600)])[1:]
LETTERS = {
    "LetterA": [[(400, 130), (250, 600)], [(400, 130), (550, 600)], [(310, 420), (490, 420)]],
    "LetterB": [[(300, 130), (300, 600)], b_bumps],
    "LetterC": [arc_c],
}
lv = Level("Level19_TraceLetters.tscn", "Level19_TraceLetters", "res://Scenes/Mechanics/TraceInput/TraceInputLevel.tscn")
lv.props = ["level_number = 19", 'prompt_text = "Trace the letter!"']
for shape, strokes in LETTERS.items():
    lv.nodes += [f'[node name="{shape}" type="Node2D" parent="Layout/Board/Guides"]', ""]
    for i, pts in enumerate(strokes):
        lv.nodes += [f'[node name="Stroke{i + 1}" type="Line2D" parent="Layout/Board/Guides/{shape}"]',
                     f"points = PackedVector2Array({packed(pts)})", "width = 70.0",
                     "default_color = Color(0.82, 0.86, 0.92, 1)", "joint_mode = 2", "begin_cap_mode = 2", "end_cap_mode = 2", ""]
lv.save()

# ---- Level 20: night sky — moon, stars, owl (HiddenObjectHunt) -------------------
STARS = [(150, 60), (460, 110), (690, 40), (860, 210), (560, 250)]
night = ['<defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#141838"/>'
         '<stop offset="1" stop-color="#3a2f6b"/></linearGradient></defs>',
         '<rect width="1280" height="680" fill="url(#sky)"/>']
night += [f'<circle cx="{random.randint(20, 1260)}" cy="{random.randint(15, 420)}" r="{random.choice([2, 2, 3, 4])}" fill="#fff" opacity="{random.choice([0.4, 0.6, 0.8])}"/>'
          for _ in range(70)]
night.append(place(moon(), 1000, 50, 180))
night += [place(star(), x, y, 56) for x, y in STARS]
night += ['<ellipse cx="640" cy="720" rx="900" ry="200" fill="#1e3a2a"/>',
          '<rect x="880" y="470" width="150" height="120" fill="#4a3b6b"/><polygon points="865,475 955,410 1045,475" fill="#2b2250"/>',
          '<rect x="905" y="500" width="40" height="36" fill="#ffd23f"/><rect x="965" y="500" width="40" height="36" fill="#ffd23f"/>',
          '<rect x="255" y="300" width="100" height="330" fill="#3b2a1a"/><circle cx="305" cy="220" r="160" fill="#16452c"/>',
          '<circle cx="200" cy="170" r="70" fill="#1b5234"/><circle cx="410" cy="190" r="80" fill="#1b5234"/>',
          '<ellipse cx="305" cy="385" rx="52" ry="62" fill="#1a120a"/>',
          place(owl(), 257, 330, 96)]
write("Assets/Images/HiddenObjects/NightSky.svg", svg(1280, 680, "\n".join(night)))
spots = [("Moon", "Moon", A + "Moon.svg", 1015, 70, 105, 140), ("Owl", "Owl", A + "Owl.svg", 257, 330, 96, 96)]
spots += [(f"Star{i + 1}", "Star", A + "Star.svg", x, y, 56, 56) for i, (x, y) in enumerate(STARS)]
hunt("Level20_NightSky.tscn", "Level20_NightSky",
     ["level_number = 20", 'prompt_text = "Find the moon, the stars and the owl!"'],
     "res://Assets/Images/HiddenObjects/NightSky.svg", (1280, 680), spots)

print("levels 11-20 generated")
