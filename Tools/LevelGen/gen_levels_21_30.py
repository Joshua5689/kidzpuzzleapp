"""Generates levels 21-30 (World 3, timed) for Puddle Jump."""
import math
import random
import re
from collections import deque

from art import *

random.seed(21)

A = "res://Assets/Images/Animals/"
T = "res://Assets/Images/Toys/"
F = "res://Assets/Images/Fruit/"
C = "res://Assets/Images/Colours/"
W3 = "res://Assets/Images/World3/"


class Level:
    def __init__(self, file, root, base):
        self.file, self.root = file, root
        self.ext = [("PackedScene", base, "1_base")]
        self.props, self.overrides, self.nodes = [], [], []

    def res(self, kind, path):
        for k, p, i in self.ext:
            if p == path:
                return i
        rid = f"r{len(self.ext) + 1}"
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


def packed(poly):
    return ", ".join(f"{x:.1f}, {y:.1f}" for x, y in poly)


def chaikin(pts, rounds=3):
    for _ in range(rounds):
        out = [pts[0]]
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            out += [(0.75 * x0 + 0.25 * x1, 0.75 * y0 + 0.25 * y1), (0.25 * x0 + 0.75 * x1, 0.25 * y0 + 0.75 * y1)]
        out.append(pts[-1])
        pts = out
    return pts


def silhouette(body):
    body = re.sub(r'(fill|stroke)="#[0-9a-fA-F]{3,6}"', r'\1="#3b4060"', body)
    return f'<g opacity="0.5">{body}</g>'


def balloon(fill, dark):
    return (f'<path d="M100 212 C 92 240, 112 255, 98 275 S 104 292, 100 298" stroke="#666" stroke-width="3" fill="none"/>'
            f'<polygon points="100,196 88,216 112,216" fill="{dark}"/><ellipse cx="100" cy="105" rx="82" ry="98" fill="{fill}"/>'
            '<ellipse cx="68" cy="62" rx="16" ry="28" fill="#fff" opacity="0.55" transform="rotate(-25 68 62)"/>')


def present(x, y, w, h, box, ribbon):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="6" fill="{box}"/>'
            f'<rect x="{x + w / 2 - 8}" y="{y}" width="16" height="{h}" fill="{ribbon}"/>'
            f'<rect x="{x}" y="{y + h / 2 - 8}" width="{w}" height="16" fill="{ribbon}"/>'
            f'<ellipse cx="{x + w / 2 - 16}" cy="{y - 10}" rx="18" ry="12" fill="{ribbon}"/>'
            f'<ellipse cx="{x + w / 2 + 16}" cy="{y - 10}" rx="18" ry="12" fill="{ribbon}"/>')


def cake():
    return ('<rect x="40" y="130" width="176" height="96" rx="14" fill="#ffb3c6"/>'
            '<rect x="40" y="130" width="176" height="26" rx="12" fill="#fff"/>'
            '<path d="M40 150 Q62 172 84 150 Q106 172 128 150 Q150 172 172 150 Q194 172 216 150" fill="#fff"/>'
            '<rect x="24" y="222" width="208" height="16" rx="8" fill="#c9a66b"/>'
            + "".join(f'<rect x="{x}" y="86" width="12" height="46" rx="4" fill="{c}"/>'
                      f'<ellipse cx="{x + 6}" cy="76" rx="8" ry="13" fill="#ffd23f"/>'
                      for x, c in [(78, "#3a86ff"), (122, "#43b649"), (166, "#e63946")])
            + "".join(f'<circle cx="{x}" cy="{y}" r="6" fill="{c}"/>'
                      for x, y, c in [(70, 190, "#3a86ff"), (110, 205, "#ffd23f"), (150, 188, "#43b649"), (190, 206, "#e63946")]))


def colour_box(colour, dark):
    return (f'<rect x="24" y="96" width="208" height="140" rx="14" fill="{colour}"/>'
            f'<rect x="14" y="74" width="228" height="40" rx="10" fill="{dark}"/>'
            '<circle cx="128" cy="170" r="40" fill="#fff" opacity="0.85"/>'
            f'<circle cx="128" cy="170" r="26" fill="{colour}"/>')


# ---- Shared art for World 3 ------------------------------------------------------
SHADOW_ANIMALS = {"Frog": frog, "Duck": duck, "Owl": owl, "Bee": bee, "Fish": fish}
for name, fn in SHADOW_ANIMALS.items():
    write(f"Assets/Images/World3/{name}Shadow.svg", svg(256, 256, silhouette(fn())))
write("Assets/Images/World3/RedBox.svg", svg(256, 256, colour_box("#e63946", "#b02a35")))
write("Assets/Images/World3/BlueBox.svg", svg(256, 256, colour_box("#3a86ff", "#2a62c0")))
write("Assets/Images/World3/YellowBox.svg", svg(256, 256, colour_box("#ffd23f", "#d9a915")))
write("Assets/Images/World3/BlueFish.svg", svg(256, 256, fish().replace("#ff8c3a", "#3a86ff").replace("#e0701f", "#2a62c0")))
write("Assets/Images/World3/Cake.svg", svg(256, 256, cake()))
write("Assets/Images/World3/Present.svg", svg(256, 256, present(38, 88, 180, 150, "#c77dff", "#ffd23f")))

TIMER = lambda s: f"time_limit = {s}.0"

# ---- 21: shadow match (SortDrag, snap) -------------------------------------------
lv = Level("Level21_ShadowMatch.tscn", "Level21_ShadowMatch", "res://Scenes/Mechanics/SortDrag/SortDragLevel.tscn")
lv.props = ["level_number = 21", 'prompt_text = "Drag each animal to its shadow!"', "snap_to_bin = true", TIMER(60)]
bin_script = lv.res("Script", "res://Scenes/Mechanics/SortDrag/SortBin.gd")
item_script = lv.res("Script", "res://Scenes/Mechanics/SortDrag/SortItem.gd")
names = list(SHADOW_ANIMALS)
shadow_order = ["Owl", "Fish", "Frog", "Bee", "Duck"]
for i, name in enumerate(shadow_order):
    lv.nodes += rect_node(f"{name}Shadow", "TextureRect", "Layout/PlayArea/Bins", 110 + i * 320, 470, 220, 220,
                          [f"texture = {lv.tex(W3 + name + 'Shadow.svg')}", "expand_mode = 1", "stretch_mode = 5",
                           f'script = ExtResource("{bin_script}")', f'category = "{name.lower()}"'])
for i, name in enumerate(names):
    lv.nodes += rect_node(name, "TextureRect", "Layout/PlayArea/Items", 110 + i * 320, 40 if i % 2 == 0 else 110, 220, 220,
                          [f"texture = {lv.tex(A + name + '.svg')}", "expand_mode = 1", "stretch_mode = 5",
                           f'script = ExtResource("{item_script}")', f'category = "{name.lower()}"'])
lv.save()


# ---- TapMatch rounds helper (22, 26) -----------------------------------------------
def tap_rounds(lv, rounds):
    """rounds: [(prompt, [(button_name, texture, size)], correct_name, clues)]"""
    script = lv.res("Script", "res://Scenes/Mechanics/TapMatch/TapRound.gd")
    for i, (prompt, buttons, correct, clues) in enumerate(rounds):
        rname = f"Round{i + 1}"
        node = [f'[node name="{rname}" type="HFlowContainer" parent="Layout/Rounds"]', "layout_mode = 2",
                "theme_override_constants/h_separation = 48", "alignment = 1",
                f'script = ExtResource("{script}")', f'prompt = "{prompt}"',
                f'correct_items = Array[NodePath]([NodePath("{correct}")])']
        if clues:
            node.append(f"clues = Array[Texture2D]([{', '.join(lv.tex(c) for c in clues)}])")
        lv.nodes += node + [""]
        for bname, texture, size in buttons:
            lv.nodes += [f'[node name="{bname}" type="TextureButton" parent="Layout/Rounds/{rname}"]',
                         f"custom_minimum_size = Vector2({size}, {size})", "layout_mode = 2", "size_flags_vertical = 4",
                         f"texture_normal = {lv.tex(texture)}", "ignore_texture_size = true", "stretch_mode = 5", ""]


# ---- 22: what comes next? (TapMatch rounds + clues) ----------------------------------
lv = Level("Level22_WhatComesNext.tscn", "Level22_WhatComesNext", "res://Scenes/Mechanics/TapMatch/TapMatchLevel.tscn")
lv.props = ["level_number = 22", 'prompt_text = "What comes next?"', TIMER(60), "clue_size = 140.0"]
RB, BB, YB = C + "RedBalloon.svg", C + "BlueBalloon.svg", C + "YellowBalloon.svg"
tap_rounds(lv, [
    ("What comes next?", [("Yellow", YB, 200), ("Red", RB, 200), ("Blue", BB, 200)], "Red", [RB, BB, RB, BB]),
    ("What comes next?", [("Orange", F + "Orange.svg", 200), ("Banana", F + "Banana.svg", 200), ("Apple", F + "Apple.svg", 200)],
     "Banana", [F + "Apple.svg", F + "Banana.svg", F + "Apple.svg", F + "Banana.svg", F + "Apple.svg"]),
    ("What comes next?", [("Duck", A + "Duck.svg", 200), ("Owl", A + "Owl.svg", 200), ("Frog", A + "Frog.svg", 200)],
     "Frog", [A + "Frog.svg", A + "Duck.svg", A + "Duck.svg", A + "Frog.svg", A + "Duck.svg", A + "Duck.svg"]),
])
lv.save()

# ---- 23: big memory game (MemoryMatch, 12 cards) --------------------------------------
lv = Level("Level23_BigMemory.tscn", "Level23_BigMemory", "res://Scenes/Mechanics/MemoryMatch/MemoryMatchLevel.tscn")
faces = ", ".join(lv.tex(p) for p in [F + "Apple.svg", F + "Banana.svg", F + "Grapes.svg", F + "Orange.svg", T + "Ball.svg", T + "Teddy.svg"])
lv.props = ["level_number = 23", 'prompt_text = "Find all the pairs!"', f"card_faces = Array[Texture2D]([{faces}])",
            "columns = 6", "card_size = Vector2(200, 240)", "three_star_max_mistakes = 6", "two_star_max_mistakes = 12", TIMER(120)]
lv.save()

# ---- 24: trace the numbers 4 5 6 (TraceInput) ----------------------------------------
five_belly = chaikin([(292, 330), (380, 292), (470, 310), (522, 380), (522, 470), (470, 560), (380, 600), (298, 580)])
six = chaikin([(480, 150), (400, 128), (330, 170), (288, 262), (280, 400), (300, 520), (370, 600), (452, 592),
               (512, 520), (506, 440), (440, 382), (360, 386), (296, 440)])
NUMBERS = {
    "Number4": [[(420, 130), (260, 440), (545, 440)], [(440, 250), (440, 610)]],
    "Number5": [[(300, 130), (292, 330)] + five_belly[1:], [(300, 130), (505, 130)]],
    "Number6": [six],
}
lv = Level("Level24_TraceNumbers456.tscn", "Level24_TraceNumbers456", "res://Scenes/Mechanics/TraceInput/TraceInputLevel.tscn")
lv.props = ["level_number = 24", 'prompt_text = "Trace the number!"', TIMER(90)]
for shape, strokes in NUMBERS.items():
    lv.nodes += [f'[node name="{shape}" type="Node2D" parent="Layout/Board/Guides"]', ""]
    for i, pts in enumerate(strokes):
        lv.nodes += [f'[node name="Stroke{i + 1}" type="Line2D" parent="Layout/Board/Guides/{shape}"]',
                     f"points = PackedVector2Array({packed(pts)})", "width = 70.0",
                     "default_color = Color(0.82, 0.86, 0.92, 1)", "joint_mode = 2", "begin_cap_mode = 2", "end_cap_mode = 2", ""]
lv.save()

# ---- 25: adding with pictures (CountSelect add mode) ----------------------------------
lv = Level("Level25_AddApples.tscn", "Level25_AddApples", "res://Scenes/Mechanics/CountSelect/CountSelectLevel.tscn")
lv.props = ["level_number = 25", 'prompt_text = "How many apples altogether?"', f"item_texture = {lv.tex(F + 'Apple.svg')}",
            "rounds = Array[int]([2, 3, 1, 4])", "add_rounds = Array[int]([1, 2, 3, 2])", "answer_choices = 4",
            "max_number = 10", "item_size = 120.0", TIMER(90)]
lv.save()

# ---- 26: big and small (TapMatch rounds) ------------------------------------------------
lv = Level("Level26_BigAndSmall.tscn", "Level26_BigAndSmall", "res://Scenes/Mechanics/TapMatch/TapMatchLevel.tscn")
lv.props = ["level_number = 26", 'prompt_text = "Tap the BIGGEST ball!"', TIMER(45)]
tap_rounds(lv, [
    ("Tap the BIGGEST ball!", [("Ball1", T + "Ball.svg", 120), ("Ball2", T + "Ball.svg", 270), ("Ball3", T + "Ball.svg", 180),
                                ("Ball4", T + "Ball.svg", 150)], "Ball2", []),
    ("Tap the SMALLEST duck!", [("Duck1", A + "Duck.svg", 230), ("Duck2", A + "Duck.svg", 180), ("Duck3", A + "Duck.svg", 100),
                                 ("Duck4", A + "Duck.svg", 260)], "Duck3", []),
    ("Tap the BIGGEST star!", [("Star1", A + "Star.svg", 140), ("Star2", A + "Star.svg", 190), ("Star3", A + "Star.svg", 280),
                                ("Star4", A + "Star.svg", 100)], "Star3", []),
])
lv.save()

# ---- 27: sort by colour (SortDrag, 3 bins) -------------------------------------------------
lv = Level("Level27_SortColours.tscn", "Level27_SortColours", "res://Scenes/Mechanics/SortDrag/SortDragLevel.tscn")
lv.props = ["level_number = 27", 'prompt_text = "Put each thing in the box of the same colour!"', TIMER(75),
            "sorted_scale = 0.4"]
bin_script = lv.res("Script", "res://Scenes/Mechanics/SortDrag/SortBin.gd")
item_script = lv.res("Script", "res://Scenes/Mechanics/SortDrag/SortItem.gd")
for i, (name, cat) in enumerate([("RedBox", "red"), ("BlueBox", "blue"), ("YellowBox", "yellow")]):
    lv.nodes += rect_node(name, "TextureRect", "Layout/PlayArea/Bins", 140 + i * 540, 430, 340, 340,
                          [f"texture = {lv.tex(W3 + name + '.svg')}", "expand_mode = 1", "stretch_mode = 5",
                           f'script = ExtResource("{bin_script}")', f'category = "{cat}"'])
things = [("Apple", F + "Apple.svg", "red"), ("BlueBalloon", BB, "blue"), ("Banana", F + "Banana.svg", "yellow"),
          ("Ball", T + "Ball.svg", "red"), ("ToyCar", T + "ToyCar.svg", "blue"), ("Duck", A + "Duck.svg", "yellow"),
          ("RedBalloon", RB, "red"), ("BlueFish", W3 + "BlueFish.svg", "blue"), ("YellowBalloon", YB, "yellow")]
for i, (name, path, cat) in enumerate(things):
    lv.nodes += rect_node(name, "TextureRect", "Layout/PlayArea/Items", 30 + i * 186, 40 if i % 2 == 0 else 170, 160, 160,
                          [f"texture = {lv.tex(path)}", "expand_mode = 1", "stretch_mode = 5",
                           f'script = ExtResource("{item_script}")', f'category = "{cat}"'])
lv.save()

# ---- 28: race the bee (MazeDrag, bigger) --------------------------------------------------
MAZE = [
    "###############",
    "#S..#.......#.#",
    "#.#.#.#####.#.#",
    "#.#...#...#...#",
    "#.#####.#.###.#",
    "#.....#.#...#.#",
    "#####.#.###.#.#",
    "#.....#...#..E#",
    "###############",
]


def bfs(grid):
    start = next((x, y) for y, r in enumerate(grid) for x, c in enumerate(r) if c == "S")
    seen, q = {start: 0}, deque([start])
    while q:
        x, y = q.popleft()
        if grid[y][x] == "E":
            return seen[(x, y)]
        for dx, dy in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
            n = (x + dx, y + dy)
            if grid[n[1]][n[0]] != "#" and n not in seen:
                seen[n] = seen[(x, y)] + 1
                q.append(n)
    return None


steps = bfs(MAZE)
assert steps, "level 28 maze has no path"
print("level 28 maze shortest path:", steps, "steps")
lv = Level("Level28_BeeRace.tscn", "Level28_BeeRace", "res://Scenes/Mechanics/MazeDrag/MazeDragLevel.tscn")
rows = ", ".join(f'"{r}"' for r in MAZE)
lv.props = ["level_number = 28", 'prompt_text = "Race the bee to the flower!"', f"layout = PackedStringArray({rows})",
            f"player_texture = {lv.tex(A + 'Bee.svg')}", f"goal_texture = {lv.tex(A + 'Flower.svg')}",
            "wall_color = Color(0.36, 0.66, 0.84, 1)", "path_color = Color(1, 0.97, 0.85, 1)", TIMER(60)]
lv.save()


# ---- HiddenObjectHunt helper (29, 30) ----------------------------------------------------
def hunt(file, root, props, image, size, spots, compare=None):
    lv = Level(file, root, "res://Scenes/Mechanics/HiddenObjectHunt/HiddenObjectHuntLevel.tscn")
    lv.props = props
    script = lv.res("Script", "res://Scenes/Mechanics/HiddenObjectHunt/Hotspot.gd")
    pics = "Layout/PlayArea/Pictures"
    lv.overrides = [f'[node name="SceneImage" parent="{pics}" index="0"]', f"custom_minimum_size = Vector2({size[0]}, {size[1]})",
                    f"texture = {lv.tex(image)}", ""]
    if compare:
        lv.overrides += [f'[node name="CompareImage" parent="{pics}" index="1"]', f"texture = {lv.tex(compare)}", ""]
    for name, cat, icon, x, y, w, h in spots:
        extra = ["border_width = 3.0", f'script = ExtResource("{script}")', f'category = "{cat}"']
        if icon:
            extra.append(f"icon = {lv.tex(icon)}")
        lv.nodes += rect_node(name, "ReferenceRect", f"{pics}/SceneImage/Hotspots", x, y, w, h, extra)
    lv.save()


# ---- 29: spot 7 differences at the beach -----------------------------------------------------
def beach(b):
    sail = "#3a86ff" if b else "#e63946"
    stripe = "#43b649" if b else "#ff9f1c"
    bucket = "#c77dff" if b else "#3a86ff"
    p = ['<rect width="700" height="525" fill="#8fd3ff"/>', '<rect y="250" width="700" height="120" fill="#3a9bdc"/>',
         '<path d="M0 262 Q60 252 120 262 T240 262 T360 262 T480 262 T600 262 T720 262" stroke="#fff" stroke-width="5" fill="none" opacity="0.6"/>',
         '<rect y="360" width="700" height="165" fill="#f6d98b"/>']
    if not b:
        p.append('<circle cx="600" cy="80" r="46" fill="#ffd23f"/>')
    if b:
        p.append('<path d="M250 90 q14 -14 28 0 q14 -14 28 0" stroke="#333" stroke-width="5" fill="none"/>')
    p += ['<rect x="148" y="300" width="130" height="24" rx="10" fill="#8b5a2b"/>',
          '<rect x="210" y="200" width="6" height="100" fill="#555"/>',
          f'<polygon points="216,205 216,295 280,295" fill="{sail}"/>',
          '<rect x="440" y="250" width="8" height="190" fill="#8b5a2b"/>',
          f'<path d="M340 262 Q444 170 548 262 Z" fill="#fff"/>',
          f'<path d="M392 262 Q420 205 444 196 Q468 205 496 262 Z" fill="{stripe}"/>',
          '<rect x="540" y="430" width="90" height="50" fill="#e0b55c"/>',
          '<rect x="548" y="400" width="26" height="30" fill="#e0b55c"/><rect x="596" y="400" width="26" height="30" fill="#e0b55c"/>']
    if not b:
        p.append('<rect x="583" y="360" width="4" height="40" fill="#555"/><polygon points="587,362 612,370 587,378" fill="#e63946"/>')
    p += [f'<path d="M90 430 L150 430 L142 490 L98 490 Z" fill="{bucket}"/>',
          '<path d="M95 432 Q120 395 145 432" stroke="#555" stroke-width="4" fill="none"/>']
    if not b:
        p.append('<ellipse cx="330" cy="470" rx="30" ry="20" fill="#e63946"/><circle cx="318" cy="452" r="5" fill="#222"/>'
                 '<circle cx="342" cy="452" r="5" fill="#222"/><path d="M300 462 L286 450 M360 462 L374 450" stroke="#e63946" stroke-width="6"/>')
    p.append('<rect x="200" y="410" width="120" height="30" rx="6" fill="#ff6fb5"/>')
    return "\n".join(p)


write("Assets/Images/World3/BeachA.svg", svg(700, 525, beach(False)))
write("Assets/Images/World3/BeachB.svg", svg(700, 525, beach(True)))
hunt("Level29_BeachDifferences.tscn", "Level29_BeachDifferences",
     ["level_number = 29", 'prompt_text = "Find the 7 differences!"', TIMER(120)],
     W3 + "BeachA.svg", (700, 525),
     [("Sun", "Differences", None, 550, 30, 100, 100),
      ("Bird", "Differences", None, 240, 70, 76, 34),
      ("Sail", "Differences", None, 212, 200, 72, 100),
      ("Umbrella", "Differences", None, 385, 192, 118, 72),
      ("Flag", "Differences", None, 578, 356, 40, 48),
      ("Bucket", "Differences", None, 86, 396, 68, 98),
      ("Crab", "Differences", None, 280, 440, 100, 55)])

# ---- 30: frog's birthday party ---------------------------------------------------------------
BALLOONS = [(70, 60, "#e63946", "#b02a35"), (1050, 40, "#3a86ff", "#2a62c0"), (430, 120, "#ffd23f", "#d9a915"),
            (820, 150, "#43b649", "#2e8b3e")]
PRESENTS = [(180, 520, 110, 90, "#3a86ff", "#fff"), (1040, 500, 130, 110, "#43b649", "#ffd23f"), (720, 250, 80, 70, "#ff9f1c", "#e63946")]
party = ['<rect width="1280" height="680" fill="#fde7f0"/>', '<rect y="520" width="1280" height="160" fill="#c9a66b"/>',
         '<rect y="512" width="1280" height="12" fill="#a0612c"/>',
         '<path d="M0 30 Q320 110 640 30 Q960 110 1280 30" stroke="#888" stroke-width="3" fill="none"/>']
for i in range(16):
    x = 20 + i * 80
    y = 30 + 40 * math.sin(math.pi * ((x % 640) / 640))
    col = ["#e63946", "#ffd23f", "#3a86ff", "#43b649"][i % 4]
    party.append(f'<polygon points="{x},{y:.0f} {x + 40},{y + 4:.0f} {x + 18},{y + 50:.0f}" fill="{col}"/>')
party += ['<rect x="880" y="90" width="220" height="170" rx="10" fill="#bfe6ff" stroke="#fff" stroke-width="12"/>',
          '<rect x="986" y="90" width="10" height="170" fill="#fff"/>',
          '<rect x="660" y="300" width="160" height="16" fill="#a0612c"/>',
          '<rect x="440" y="400" width="400" height="24" rx="8" fill="#e8d5b0"/>',
          '<rect x="470" y="424" width="20" height="100" fill="#a0612c"/><rect x="790" y="424" width="20" height="100" fill="#a0612c"/>',
          place(cake(), 520, 230, 180)]
party += [place(balloon(f, d), x, y, 150) for x, y, f, d in BALLOONS]
party += [present(x, y, w, h, c, r) for x, y, w, h, c, r in PRESENTS]
# Puddle the frog peeks out from behind the big present, with a party hat.
party += [place(frog(), 1110, 400, 130),
          '<polygon points="1155,436 1175,362 1195,436" fill="#c77dff"/><circle cx="1175" cy="360" r="9" fill="#ffd23f"/>',
          present(1040, 500, 130, 110, "#43b649", "#ffd23f")]
write("Assets/Images/World3/Party.svg", svg(1280, 680, "\n".join(party)))
spots = [(f"Balloon{i + 1}", "Balloon", C + "RedBalloon.svg", x + 14, y, 122, 190) for i, (x, y, _, _) in enumerate(BALLOONS)]
spots += [(f"Present{i + 1}", "Present", W3 + "Present.svg", x - 6, y - 24, w + 12, h + 28) for i, (x, y, w, h, _, _) in enumerate(PRESENTS)]
spots += [("Cake", "Cake", W3 + "Cake.svg", 540, 280, 140, 130), ("Frog", "Frog", A + "Frog.svg", 1112, 360, 128, 140)]
hunt("Level30_FrogParty.tscn", "Level30_FrogParty",
     ["level_number = 30", 'prompt_text = "Find the balloons, presents, cake and the frog!"', TIMER(120)],
     W3 + "Party.svg", (1280, 680), spots)

print("levels 21-30 generated")
