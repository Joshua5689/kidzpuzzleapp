"""Generates levels 31-40 (World 4, bee themed, timed) for Doodle Bee."""
import math
import random
from collections import deque

from art import *

random.seed(31)

A = "res://Assets/Images/Animals/"
W3 = "res://Assets/Images/World3/"
W4 = "res://Assets/Images/World4/"
C = "res://Assets/Images/Colours/"
CF = "res://Assets/Images/ColourFill/"


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


def pts_attr(poly):
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in poly)


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
    out = []
    for i in range(n):
        a = 2 * math.pi * i / n
        x, y = rx * math.cos(a), ry * math.sin(a)
        out.append((cx + x * c - y * s, cy + x * s + y * c))
    return out


def inside(p, poly):
    x, y = p
    r = False
    for i in range(len(poly)):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % len(poly)]
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
            r = not r
    return r


TIMER = lambda s: f"time_limit = {s}.0"


# ---- Art -------------------------------------------------------------------------

def hive():
    rows = "".join(f'<rect x="{128 - w / 2}" y="{y}" width="{w}" height="34" rx="17" fill="{c}"/>'
                   for y, w, c in [(40, 110, "#f7b733"), (70, 160, "#f2a71b"), (100, 196, "#f7b733"),
                                   (130, 210, "#f2a71b"), (160, 200, "#f7b733"), (190, 170, "#f2a71b")])
    return (rows + '<path d="M106 224 A22 22 0 0 1 150 224 Z" fill="#5a3a12"/>'
            '<rect x="118" y="18" width="20" height="26" rx="6" fill="#7a4e2d"/>')


def shape(kind, colour):
    if kind == "Circle":
        return f'<circle cx="128" cy="128" r="100" fill="{colour}"/>'
    if kind == "Triangle":
        return f'<polygon points="128,22 236,222 20,222" fill="{colour}" stroke-linejoin="round"/>'
    return f'<rect x="30" y="30" width="196" height="196" rx="14" fill="{colour}"/>'


def shape_box(kind):
    symbol = {"Circle": '<circle cx="128" cy="168" r="44" fill="none" stroke="#fff" stroke-width="12"/>',
              "Triangle": '<polygon points="128,120 178,212 78,212" fill="none" stroke="#fff" stroke-width="12" stroke-linejoin="round"/>',
              "Square": '<rect x="86" y="126" width="84" height="84" fill="none" stroke="#fff" stroke-width="12"/>'}[kind]
    return ('<rect x="24" y="96" width="208" height="140" rx="14" fill="#8a6fd1"/>'
            '<rect x="14" y="74" width="228" height="40" rx="10" fill="#6b52b3"/>' + symbol)


write("Assets/Images/World4/Hive.svg", svg(256, 256, hive()))
SHAPE_ITEMS = [("Circle", "Red", "#e63946"), ("Triangle", "Green", "#43b649"), ("Square", "Pink", "#ff6fb5"),
               ("Circle", "Blue", "#3a86ff"), ("Triangle", "Orange", "#ff9f1c"), ("Square", "Yellow", "#ffd23f"),
               ("Circle", "Yellow", "#ffd23f"), ("Triangle", "Purple", "#9b5de5"), ("Square", "Blue", "#3a86ff")]
for kind, cname, colour in SHAPE_ITEMS:
    write(f"Assets/Images/World4/{cname}{kind}.svg", svg(256, 256, shape(kind, colour)))
for kind in ["Circle", "Triangle", "Square"]:
    write(f"Assets/Images/World4/{kind}Box.svg", svg(256, 256, shape_box(kind)))
    write(f"Assets/Images/World4/{kind}Clue.svg", svg(256, 256, shape(kind, "#5c7399")))


def garden(w, h, bees=(), butterflies=(), hive_at=None, extra_flowers=12):
    p = [f'<rect width="{w}" height="{h}" fill="#bfe6ff"/>',
         f'<ellipse cx="{w * 0.3}" cy="{h * 0.62}" rx="{w * 0.5}" ry="{h * 0.2}" fill="#8fd66b"/>',
         f'<ellipse cx="{w * 0.8}" cy="{h * 0.6}" rx="{w * 0.45}" ry="{h * 0.18}" fill="#7ccf5a"/>',
         f'<rect y="{h * 0.6}" width="{w}" height="{h * 0.4}" fill="#6cc24a"/>',
         f'<circle cx="{w * 0.1}" cy="{h * 0.14}" r="{h * 0.08}" fill="#ffd23f"/>']
    for i in range(extra_flowers):
        x = random.uniform(0.03, 0.97) * w
        y = random.uniform(0.66, 0.95) * h
        col = random.choice(["#ff6fb5", "#e63946", "#ffffff", "#c77dff", "#ff9f1c"])
        p.append(f'<rect x="{x - 3}" y="{y}" width="6" height="{h * 0.06}" fill="#2e8b3e"/>')
        p += [f'<circle cx="{x + 14 * math.cos(a):.1f}" cy="{y + 14 * math.sin(a):.1f}" r="11" fill="{col}"/>'
              for a in [i * 2 * math.pi / 5 for i in range(5)]]
        p.append(f'<circle cx="{x}" cy="{y}" r="9" fill="#ffd23f"/>')
    if hive_at:
        x, y, s = hive_at
        p.append(f'<rect x="{x + s * 0.42}" y="{y - s * 0.6}" width="{s * 0.16}" height="{s * 0.7}" fill="#7a4e2d"/>')
        p.append(place(hive(), x, y, s))
    for x, y, s in butterflies:
        p.append(place(butterfly_icon(), x, y, s))
    for x, y, s in bees:
        p.append(place(bee(), x, y, s))
    return "\n".join(p)


# ---- 31: count the bees ----------------------------------------------------------
lv = Level("Level31_CountBees.tscn", "Level31_CountBees", "res://Scenes/Mechanics/CountSelect/CountSelectLevel.tscn")
lv.props = ["level_number = 31", 'prompt_text = "How many bees?"', f"item_texture = {lv.tex(A + 'Bee.svg')}",
            "rounds = Array[int]([6, 9, 7, 10])", "answer_choices = 4", "max_number = 10", "item_size = 110.0", TIMER(90)]
lv.save()

# ---- 32: bee garden jigsaw 4x3 ----------------------------------------------------
jig = garden(1200, 900, bees=[(470, 260, 170), (930, 120, 110)], butterflies=[(130, 330, 120)],
             hive_at=(760, 300, 200), extra_flowers=16)
write("Assets/Images/World4/BeeGarden.svg", svg(1200, 900, jig))
lv = Level("Level32_GardenPuzzle.tscn", "Level32_GardenPuzzle", "res://Scenes/Mechanics/DragRearrange/DragRearrangeLevel.tscn")
lv.props = ["level_number = 32", 'prompt_text = "Put the bee garden back together!"', f"image = {lv.tex(W4 + 'BeeGarden.svg')}",
            "rows = 3", "columns = 4", "board_width = 900.0", TIMER(180)]
lv.save()

# ---- 33: huge memory, 16 cards ---------------------------------------------------
lv = Level("Level33_HugeMemory.tscn", "Level33_HugeMemory", "res://Scenes/Mechanics/MemoryMatch/MemoryMatchLevel.tscn")
faces = ", ".join(lv.tex(A + f"{n}.svg") for n in ["Frog", "Duck", "Bee", "Owl", "Dog", "Fish", "Butterfly", "Flower"])
lv.props = ["level_number = 33", 'prompt_text = "Find all 8 pairs!"', f"card_faces = Array[Texture2D]([{faces}])",
            "columns = 8", "card_size = Vector2(180, 215)", "three_star_max_mistakes = 8", "two_star_max_mistakes = 16", TIMER(150)]
lv.save()


# ---- 34: colour the bee ------------------------------------------------------------
def band(cx, cy, rx, ry, x0, x1, steps=12):
    """Vertical stripe of an ellipse between x0 and x1."""
    top, bottom = [], []
    for i in range(steps + 1):
        x = x0 + (x1 - x0) * i / steps
        dy = ry * math.sqrt(max(0.0, 1 - ((x - cx) / rx) ** 2)) * 0.97
        top.append((x, cy - dy))
        bottom.append((x, cy + dy))
    return top + bottom[::-1]


BODY = (560, 380, 210, 135)
BEE_REGIONS = [
    ("LeftWing", ellipse(465, 138, 92, 60, 32, rot=-0.3)),
    ("RightWing", ellipse(690, 132, 92, 60, 32, rot=0.3)),
    ("Body", ellipse(*BODY, 48)),
    ("Stripe1", band(*BODY, 480, 540)),
    ("Stripe2", band(*BODY, 610, 670)),
    ("Stinger", [(778, 364), (842, 380), (778, 396)]),
    ("Head", ellipse(245, 350, 98, 98, 40)),
    ("LeftAntennaTip", ellipse(185, 160, 22, 22, 20)),
    ("RightAntennaTip", ellipse(300, 150, 22, 22, 20)),
]
parts = {n: p for n, p in BEE_REGIONS if not n.startswith("Stripe")}
names = list(parts)
for i, a in enumerate(names):
    for b in names[i + 1:]:
        assert not (any(inside(p, parts[b]) for p in parts[a]) or any(inside(p, parts[a]) for p in parts[b])), (a, b)
for n, p in BEE_REGIONS:
    if n.startswith("Stripe"):
        assert all(inside(q, parts["Body"]) for q in p), n
lines = [f'<polygon points="{pts_attr(p)}" fill="none" stroke="#2b2b3a" stroke-width="8" stroke-linejoin="round"/>' for _, p in BEE_REGIONS]
lines += ['<path d="M220 255 Q205 205 188 182 M270 255 Q285 205 298 172" stroke="#2b2b3a" stroke-width="8" fill="none" stroke-linecap="round"/>',
          '<circle cx="215" cy="335" r="13" fill="#2b2b3a"/><circle cx="285" cy="335" r="13" fill="#2b2b3a"/>',
          '<path d="M215 385 Q245 412 280 385" stroke="#2b2b3a" stroke-width="7" fill="none" stroke-linecap="round"/>']
write("Assets/Images/ColourFill/BeeLineArt.svg", svg(1000, 600, "\n".join(lines)))
lv = Level("Level34_ColourBee.tscn", "Level34_ColourBee", "res://Scenes/Mechanics/ColourFill/ColourFillLevel.tscn")
lv.props = ["level_number = 34", 'prompt_text = "Colour the bee!"', TIMER(150)]
lv.overrides = ['[node name="LineArt" parent="Layout/Canvas" index="1"]', f"texture = {lv.tex(CF + 'BeeLineArt.svg')}", ""]
for name, poly in BEE_REGIONS:
    lv.nodes += [f'[node name="{name}" type="Polygon2D" parent="Layout/Canvas/Regions"]', f"polygon = PackedVector2Array({packed(poly)})", ""]
lv.save()

# ---- 35: sort the shapes -------------------------------------------------------------
lv = Level("Level35_SortShapes.tscn", "Level35_SortShapes", "res://Scenes/Mechanics/SortDrag/SortDragLevel.tscn")
lv.props = ["level_number = 35", 'prompt_text = "Put each shape in its box!"', "sorted_scale = 0.4", TIMER(90)]
bin_script = lv.res("Script", "res://Scenes/Mechanics/SortDrag/SortBin.gd")
item_script = lv.res("Script", "res://Scenes/Mechanics/SortDrag/SortItem.gd")
for i, kind in enumerate(["Circle", "Triangle", "Square"]):
    lv.nodes += rect_node(f"{kind}Box", "TextureRect", "Layout/PlayArea/Bins", 140 + i * 540, 430, 340, 340,
                          [f"texture = {lv.tex(W4 + kind + 'Box.svg')}", "expand_mode = 1", "stretch_mode = 5",
                           f'script = ExtResource("{bin_script}")', f'category = "{kind.lower()}"'])
order = [0, 4, 8, 3, 1, 5, 6, 2, 7]
for slot, idx in enumerate(order):
    kind, cname, _ = SHAPE_ITEMS[idx]
    size = 150 if slot % 3 else 120
    lv.nodes += rect_node(f"{cname}{kind}", "TextureRect", "Layout/PlayArea/Items", 40 + slot * 186, 40 if slot % 2 == 0 else 170, size, size,
                          [f"texture = {lv.tex(W4 + cname + kind + '.svg')}", "expand_mode = 1", "stretch_mode = 5",
                           f'script = ExtResource("{item_script}")', f'category = "{kind.lower()}"'])
lv.save()


# ---- 36: trickier patterns (TapMatch rounds + clues) --------------------------------
def tap_rounds(lv, rounds):
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


RB, BB, YB, GB = (C + f"{c}Balloon.svg" for c in ["Red", "Blue", "Yellow", "Green"])
CIR, TRI, SQU = (W4 + f"{k}Clue.svg" for k in ["Circle", "Triangle", "Square"])
lv = Level("Level36_TrickyPatterns.tscn", "Level36_TrickyPatterns", "res://Scenes/Mechanics/TapMatch/TapMatchLevel.tscn")
lv.props = ["level_number = 36", 'prompt_text = "What comes next?"', "clue_size = 120.0", TIMER(75)]
tap_rounds(lv, [
    ("What comes next?", [("Blue", BB, 190), ("Green", GB, 190), ("Yellow", YB, 190), ("Red", RB, 190)], "Yellow",
     [RB, BB, YB, RB, BB]),
    ("What comes next?", [("Square", SQU, 170), ("Triangle", TRI, 170), ("Circle", CIR, 170)], "Triangle",
     [CIR, SQU, TRI, CIR, SQU]),
    ("What comes next?", [("Duck", A + "Duck.svg", 190), ("Bee", A + "Bee.svg", 190), ("Frog", A + "Frog.svg", 190)], "Bee",
     [A + "Duck.svg", A + "Duck.svg", A + "Bee.svg", A + "Duck.svg", A + "Duck.svg"]),
])
lv.save()

# ---- 37: trace 7 8 9 ---------------------------------------------------------------
eight = chaikin([(420, 150), (335, 172), (305, 240), (350, 315), (420, 352), (498, 398), (530, 478), (492, 566),
                 (412, 600), (332, 568), (300, 480), (340, 400), (420, 352), (488, 315), (530, 240), (502, 172), (418, 150)])
nine_loop = [(410 + 100 * math.cos(math.radians(a)), 250 + 100 * math.sin(math.radians(a))) for a in range(0, -361, -15)]
NUMBERS = {
    "Number7": [[(285, 140), (525, 140), (365, 612)]],
    "Number8": [eight],
    "Number9": [nine_loop + [(500, 330), (482, 612)]],
}
lv = Level("Level37_TraceNumbers789.tscn", "Level37_TraceNumbers789", "res://Scenes/Mechanics/TraceInput/TraceInputLevel.tscn")
lv.props = ["level_number = 37", 'prompt_text = "Trace the number!"', TIMER(120)]
for shape_name, strokes in NUMBERS.items():
    lv.nodes += [f'[node name="{shape_name}" type="Node2D" parent="Layout/Board/Guides"]', ""]
    for i, pts in enumerate(strokes):
        lv.nodes += [f'[node name="Stroke{i + 1}" type="Line2D" parent="Layout/Board/Guides/{shape_name}"]',
                     f"points = PackedVector2Array({packed(pts)})", "width = 70.0",
                     "default_color = Color(0.82, 0.86, 0.92, 1)", "joint_mode = 2", "begin_cap_mode = 2", "end_cap_mode = 2", ""]
lv.save()

# ---- 38: adding bees up to 10 ---------------------------------------------------------
lv = Level("Level38_AddBees.tscn", "Level38_AddBees", "res://Scenes/Mechanics/CountSelect/CountSelectLevel.tscn")
lv.props = ["level_number = 38", 'prompt_text = "How many bees altogether?"', f"item_texture = {lv.tex(A + 'Bee.svg')}",
            "rounds = Array[int]([3, 5, 4, 6])", "add_rounds = Array[int]([4, 3, 5, 4])", "answer_choices = 4",
            "max_number = 10", "item_size = 100.0", TIMER(120)]
lv.save()

# ---- 39: fly the bee home (big maze) ------------------------------------------------
MAZE = [
    "#################",
    "#S....#.....#...#",
    "#.###.#.###.#.#.#",
    "#.#...#...#...#.#",
    "#.#.#####.#####.#",
    "#.#...........#.#",
    "#.#####.#####.#.#",
    "#.....#.....#.#.#",
    "#####.#####.#.#.#",
    "#...........#..E#",
    "#################",
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
assert steps, "level 39 maze has no path"
print("level 39 maze shortest path:", steps, "steps")
lv = Level("Level39_BeeHome.tscn", "Level39_BeeHome", "res://Scenes/Mechanics/MazeDrag/MazeDragLevel.tscn")
rows = ", ".join(f'"{r}"' for r in MAZE)
lv.props = ["level_number = 39", 'prompt_text = "Fly the bee home to the hive!"', f"layout = PackedStringArray({rows})",
            f"player_texture = {lv.tex(A + 'Bee.svg')}", f"goal_texture = {lv.tex(W4 + 'Hive.svg')}",
            "wall_color = Color(0.95, 0.66, 0.2, 1)", "path_color = Color(1, 0.97, 0.85, 1)", TIMER(75)]
lv.save()

# ---- 40: bee garden hunt ----------------------------------------------------------------
BEES = [(150, 140, 70), (520, 60, 64), (880, 250, 60), (330, 470, 62), (1090, 520, 66)]
BUTTERFLIES = [(640, 300, 80), (60, 380, 76)]
HIVE = (1000, 130, 150)
hunt_art = garden(1280, 680, bees=BEES, butterflies=BUTTERFLIES, hive_at=HIVE, extra_flowers=22)
write("Assets/Images/World4/BeeHunt.svg", svg(1280, 680, hunt_art))
lv = Level("Level40_BeeHunt.tscn", "Level40_BeeHunt", "res://Scenes/Mechanics/HiddenObjectHunt/HiddenObjectHuntLevel.tscn")
lv.props = ["level_number = 40", 'prompt_text = "Find 5 bees, 2 butterflies and the hive!"', TIMER(150)]
script = lv.res("Script", "res://Scenes/Mechanics/HiddenObjectHunt/Hotspot.gd")
pics = "Layout/PlayArea/Pictures"
lv.overrides = [f'[node name="SceneImage" parent="{pics}" index="0"]', "custom_minimum_size = Vector2(1280, 680)",
                f"texture = {lv.tex(W4 + 'BeeHunt.svg')}", ""]
spots = [(f"Bee{i + 1}", "Bee", A + "Bee.svg", x, y, s, s) for i, (x, y, s) in enumerate(BEES)]
spots += [(f"Butterfly{i + 1}", "Butterfly", A + "Butterfly.svg", x, y, s, s) for i, (x, y, s) in enumerate(BUTTERFLIES)]
spots += [("Hive", "Hive", W4 + "Hive.svg", HIVE[0], HIVE[1], HIVE[2], HIVE[2])]
for name, cat, icon, x, y, w, h in spots:
    lv.nodes += rect_node(name, "ReferenceRect", f"{pics}/SceneImage/Hotspots", x, y, w, h,
                          ["border_width = 3.0", f'script = ExtResource("{script}")', f'category = "{cat}"', f"icon = {lv.tex(icon)}"])
lv.save()

print("levels 31-40 generated")
