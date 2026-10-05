"""Generates levels 41-50 (World 5: every level a different game, harder,
playable by 6 year olds and still fun at 8) for Doodle Bee."""
import math
import os
import random
import wave
from collections import deque

import numpy as np

from art import *

random.seed(41)

A = "res://Assets/Images/Animals/"
F = "res://Assets/Images/Fruit/"
W5 = "res://Assets/Images/World5/"


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


def vec_array(points):
    return "PackedVector2Array(" + ", ".join(f"{x:.1f}, {y:.1f}" for x, y in points) + ")"


TIMER = lambda s: f"time_limit = {s}.0"


def text_label(parent, text, size):
    return [f'[node name="Text" type="Label" parent="{parent}"]', "layout_mode = 1", "anchors_preset = 15",
            "anchor_right = 1.0", "anchor_bottom = 1.0", "grow_horizontal = 2", "grow_vertical = 2", "mouse_filter = 2",
            "theme_override_colors/font_color = Color(0.2, 0.2, 0.35, 1)", f"theme_override_font_sizes/font_size = {size}",
            f'text = "{text}"', "horizontal_alignment = 1", "vertical_alignment = 1", ""]


# ---- Shared World 5 art -------------------------------------------------------------
write("Assets/Images/World5/LetterTile.svg", svg(256, 256,
      '<rect x="12" y="20" width="232" height="228" rx="34" fill="#c98a4b"/>'
      '<rect x="12" y="8" width="232" height="226" rx="34" fill="#f1c27d" stroke="#c98a4b" stroke-width="8"/>'))
write("Assets/Images/World5/Slot.svg", svg(256, 256,
      '<rect x="14" y="14" width="228" height="228" rx="34" fill="#ffffff" fill-opacity="0.6" '
      'stroke="#5c7399" stroke-width="10" stroke-dasharray="26 16"/>'))
write("Assets/Images/World5/NumberTile.svg", svg(256, 256,
      '<rect x="12" y="12" width="232" height="232" rx="36" fill="#ffffff" stroke="#5c7399" stroke-width="10"/>'))


def flower_pad(petal, centre):
    petals = "".join(f'<ellipse cx="{128 + 62 * math.cos(a):.1f}" cy="{128 + 62 * math.sin(a):.1f}" rx="48" ry="40" '
                     f'transform="rotate({math.degrees(a):.0f} {128 + 62 * math.cos(a):.1f} {128 + 62 * math.sin(a):.1f})" fill="{petal}"/>'
                     for a in [i * 2 * math.pi / 6 for i in range(6)])
    return petals + f'<circle cx="128" cy="128" r="46" fill="{centre}"/><circle cx="114" cy="114" r="12" fill="#fff" opacity="0.5"/>'


PADS = [("RedFlower", "#e63946", "#ffd23f"), ("BlueFlower", "#3a86ff", "#ffd23f"),
        ("YellowFlower", "#ffd23f", "#ff9f1c"), ("PurpleFlower", "#9b5de5", "#ffd23f")]
for name, petal, centre in PADS:
    write(f"Assets/Images/World5/{name}.svg", svg(256, 256, flower_pad(petal, centre)))


def tone_wav(path, freq, seconds=0.45, sr=22050):
    t = np.arange(int(seconds * sr)) / sr
    sig = (np.sin(2 * np.pi * freq * t) + 0.3 * np.sin(2 * np.pi * freq * 2 * t)) * np.exp(-t * 5.5)
    sig[: int(0.005 * sr)] *= np.linspace(0, 1, int(0.005 * sr))
    data = (sig / np.max(np.abs(sig)) * 0.8 * 32767).astype(np.int16)
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with wave.open(full, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data.tobytes())


for i, freq in enumerate([523.25, 659.25, 783.99, 1046.5]):  # C5 E5 G5 C6
    tone_wav(f"Assets/Audio/SFX/Pad{i + 1}.wav", freq)

# ---- 41: spell it! (SortDrag snap, letter tiles + trick letters) --------------------------
lv = Level("Level41_SpellFrog.tscn", "Level41_SpellFrog", "res://Scenes/Mechanics/SortDrag/SortDragLevel.tscn")
lv.props = ["level_number = 41", 'prompt_text = "Spell the word!"', "snap_to_bin = true", TIMER(90)]
bin_script = lv.res("Script", "res://Scenes/Mechanics/SortDrag/SortBin.gd")
item_script = lv.res("Script", "res://Scenes/Mechanics/SortDrag/SortItem.gd")
lv.nodes += rect_node("Picture", "TextureRect", "Layout/PlayArea/Bins", 730, 0, 240, 240,
                      [f"texture = {lv.tex(A + 'Frog.svg')}", "expand_mode = 1", "stretch_mode = 5", "mouse_filter = 2"])
for i, letter in enumerate("FROG"):
    lv.nodes += rect_node(f"Slot{i + 1}", "TextureRect", "Layout/PlayArea/Bins", 475 + i * 190, 280, 170, 170,
                          [f"texture = {lv.tex(W5 + 'Slot.svg')}", "expand_mode = 1", "stretch_mode = 5",
                           f'script = ExtResource("{bin_script}")', f'category = "{letter}"'])
for i, letter in enumerate("GAOFBR"):
    lv.nodes += rect_node(f"Letter{letter}", "TextureRect", "Layout/PlayArea/Items", 300 + i * 190, 560, 150, 150,
                          [f"texture = {lv.tex(W5 + 'LetterTile.svg')}", "expand_mode = 1", "stretch_mode = 5",
                           f'script = ExtResource("{item_script}")', f'category = "{letter}"', f'text = "{letter}"'])
lv.save()

# ---- 42: sliding puzzle 3x3 (your bee artwork) ------------------------------------------
lv = Level("Level42_SlidePuzzle.tscn", "Level42_SlidePuzzle", "res://Scenes/Mechanics/SlidePuzzle/SlidePuzzleLevel.tscn")
lv.props = ["level_number = 42", f"image = {lv.tex('res://Assets/Icon/IconSource.png')}", "grid_size = 3",
            "shuffle_moves = 40", TIMER(180)]
lv.save()

# ---- 43: follow the bee (SequenceMemory) -------------------------------------------------
lv = Level("Level43_FollowTheBee.tscn", "Level43_FollowTheBee", "res://Scenes/Mechanics/SequenceMemory/SequenceMemoryLevel.tscn")
pads = ", ".join(lv.tex(W5 + f"{n}.svg") for n, _, _ in PADS)
sounds = ", ".join(f'ExtResource("{lv.res("AudioStream", f"res://Assets/Audio/SFX/Pad{i + 1}.wav")}")' for i in range(4))
lv.props = ["level_number = 43", 'prompt_text = "Watch the flowers, then tap them in the same order!"',
            f"pad_textures = Array[Texture2D]([{pads}])", f"pad_sounds = Array[AudioStream]([{sounds}])",
            "rounds = Array[int]([3, 4, 5])", TIMER(120)]
lv.save()

# ---- 44: take away (CountSelect take_rounds) ----------------------------------------------
lv = Level("Level44_TakeAway.tscn", "Level44_TakeAway", "res://Scenes/Mechanics/CountSelect/CountSelectLevel.tscn")
lv.props = ["level_number = 44", 'prompt_text = "Some apples are gone! How many are left?"', f"item_texture = {lv.tex(F + 'Apple.svg')}",
            "rounds = Array[int]([5, 7, 6, 9])", "take_rounds = Array[int]([2, 3, 4, 5])", "answer_choices = 4",
            "max_number = 10", "item_size = 120.0", TIMER(90)]
lv.save()

# ---- 45: picture sudoku 4x4 ----------------------------------------------------------------
SOLUTION = ["ABCD", "CDAB", "BADC", "DCBA"]
PUZZLE = ["A.C.", ".D.B", "B..C", ".CB."]
for r in range(4):  # sanity: puzzle agrees with the solution, solution is a valid sudoku
    assert all(p in (".", s) for p, s in zip(PUZZLE[r], SOLUTION[r]))
    assert len(set(SOLUTION[r])) == 4 and len({SOLUTION[x][r] for x in range(4)}) == 4
for br in (0, 2):
    for bc in (0, 2):
        assert len({SOLUTION[br + i][bc + j] for i in range(2) for j in range(2)}) == 4
lv = Level("Level45_FruitSudoku.tscn", "Level45_FruitSudoku", "res://Scenes/Mechanics/PictureSudoku/PictureSudokuLevel.tscn")
syms = ", ".join(lv.tex(F + f"{n}.svg") for n in ["Apple", "Banana", "Grapes", "Orange"])
lv.props = ["level_number = 45", f"symbols = Array[Texture2D]([{syms}])",
            "solution = PackedStringArray(" + ", ".join(f'"{r}"' for r in SOLUTION) + ")",
            "puzzle = PackedStringArray(" + ", ".join(f'"{r}"' for r in PUZZLE) + ")", TIMER(150)]
lv.save()

# ---- 46: star maze (collect every star first) -------------------------------------------------
MAZE = [
    "###############",
    "#S..#*....#..*#",
    "#.#.#.###.#.#.#",
    "#.#...#...#.#.#",
    "#.#####.#####.#",
    "#*..#.....#...#",
    "###.#.###.#.###",
    "#*....#......E#",
    "###############",
]


def reachable(grid, start):
    seen, q = {start}, deque([start])
    while q:
        x, y = q.popleft()
        for dx, dy in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
            n = (x + dx, y + dy)
            if grid[n[1]][n[0]] != "#" and n not in seen:
                seen.add(n)
                q.append(n)
    return seen


start = next((x, y) for y, r in enumerate(MAZE) for x, c in enumerate(r) if c == "S")
targets = [(x, y) for y, r in enumerate(MAZE) for x, c in enumerate(r) if c in "*E"]
seen = reachable(MAZE, start)
assert all(t in seen for t in targets), "star maze: something can't be reached"
print("level 46: stars", sum(r.count("*") for r in MAZE), "all reachable")
lv = Level("Level46_StarMaze.tscn", "Level46_StarMaze", "res://Scenes/Mechanics/MazeDrag/MazeDragLevel.tscn")
lv.props = ["level_number = 46", 'prompt_text = "Collect every star, then fly to the flower!"',
            "layout = PackedStringArray(" + ", ".join(f'"{r}"' for r in MAZE) + ")",
            f"player_texture = {lv.tex(A + 'Bee.svg')}", f"goal_texture = {lv.tex(A + 'Flower.svg')}",
            f"collectible_texture = {lv.tex(A + 'Star.svg')}",
            "wall_color = Color(0.45, 0.4, 0.75, 1)", "path_color = Color(0.97, 0.95, 1, 1)", TIMER(90)]
lv.save()

# ---- 47: number patterns (TapMatch rounds with text clues) -------------------------------------
lv = Level("Level47_NumberPatterns.tscn", "Level47_NumberPatterns", "res://Scenes/Mechanics/TapMatch/TapMatchLevel.tscn")
lv.props = ["level_number = 47", 'prompt_text = "What number comes next?"', "clue_size = 140.0", TIMER(75)]
round_script = lv.res("Script", "res://Scenes/Mechanics/TapMatch/TapRound.gd")
NUMBER_ROUNDS = [(["2", "4", "6", "8"], ["9", "10", "12"], "10"),
                 (["10", "9", "8", "7"], ["5", "8", "6"], "6"),
                 (["5", "10", "15", "20"], ["21", "30", "25"], "25")]
for i, (clues, choices, answer) in enumerate(NUMBER_ROUNDS):
    rname = f"Round{i + 1}"
    lv.nodes += [f'[node name="{rname}" type="HFlowContainer" parent="Layout/Rounds"]', "layout_mode = 2",
                 "theme_override_constants/h_separation = 48", "alignment = 1", f'script = ExtResource("{round_script}")',
                 'prompt = "What number comes next?"', f'correct_items = Array[NodePath]([NodePath("N{answer}")])',
                 "clue_texts = PackedStringArray(" + ", ".join(f'"{c}"' for c in clues) + ")", ""]
    for c in choices:
        lv.nodes += [f'[node name="N{c}" type="TextureButton" parent="Layout/Rounds/{rname}"]',
                     "custom_minimum_size = Vector2(190, 190)", "layout_mode = 2",
                     f"texture_normal = {lv.tex(W5 + 'NumberTile.svg')}", "ignore_texture_size = true", "stretch_mode = 5", ""]
        lv.nodes += text_label(f"Layout/Rounds/{rname}/N{c}", c, 96)
lv.save()


# ---- 48: spot 10 differences under the sea ---------------------------------------------------
def sea(b):
    def fish_at(x, y, s, col, flip=False):
        body = fish().replace("#ff8c3a", col).replace("#e0701f", col)
        tr = f"translate({x + (s if flip else 0)} {y}) scale({-s / 256 if flip else s / 256:.4f} {s / 256:.4f})"
        return f'<g transform="{tr}">{body}</g>'
    p = ['<defs><linearGradient id="w" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7fd0f5"/>'
         '<stop offset="1" stop-color="#1f7fb8"/></linearGradient></defs>',
         '<rect width="700" height="525" fill="url(#w)"/>',
         '<path d="M0 455 Q120 430 240 455 T480 450 T700 455 L700 525 L0 525 Z" fill="#f2d79b"/>']
    if not b:
        p.append('<path d="M520 40 L600 40 L585 62 L535 62 Z" fill="#8b5a2b"/><rect x="558" y="8" width="4" height="34" fill="#555"/>'
                 '<polygon points="562,10 562,38 590,38" fill="#fff"/>')
    weed_h = 150 if b else 110
    p += [f'<path d="M60 455 Q40 {455 - weed_h / 2} 70 {455 - weed_h} Q90 {455 - weed_h / 2} 75 455 Z" fill="#2e8b3e"/>',
          '<path d="M620 455 Q600 380 630 330 Q650 380 640 455 Z" fill="#3fae49"/>',
          f'<ellipse cx="420" cy="470" rx="46" ry="22" fill="{"#8a8a8a" if b else "#6b6b6b"}"/>']
    p.append(fish_at(150, 150, 110, "#ff8c3a"))
    p.append(fish_at(430, 210, 90, "#3a86ff" if not b else "#9b5de5", flip=True))
    p.append(fish_at(250, 330, 80, "#ffd23f"))
    if b:
        p.append(fish_at(560, 120, 50, "#ff6fb5"))
    p.append(f'<g fill="{"#e63946" if not b else "#ff9f1c"}"><ellipse cx="300" cy="478" rx="30" ry="18"/>'
             '<path d="M272 470 L258 456 M328 470 L342 456" stroke-width="6"/></g>'
             '<circle cx="290" cy="462" r="5" fill="#222"/><circle cx="310" cy="462" r="5" fill="#222"/>')
    if not b:
        p.append('<polygon points="520,470 530,490 552,492 535,506 540,526 520,514 500,526 505,506 488,492 510,490" fill="#ff6fb5"/>')
        p.append('<path d="M160 490 Q175 465 190 490 Z" fill="#fff3e0" stroke="#e0b98a" stroke-width="3"/>')
    bubbles = [(110, 90), (118, 60), (104, 35)] + ([(470, 120), (478, 92)] if b else [])
    p += [f'<circle cx="{x}" cy="{y}" r="9" fill="none" stroke="#fff" stroke-width="3" opacity="0.8"/>' for x, y in bubbles]
    if not b:
        p.append('<ellipse cx="330" cy="70" rx="34" ry="24" fill="#f6b5ff" opacity="0.85"/>'
                 '<path d="M310 90 Q305 115 312 130 M330 92 Q332 118 326 134 M350 90 Q356 114 348 128" stroke="#f6b5ff" stroke-width="4" fill="none"/>')
    return "\n".join(p)


write("Assets/Images/World5/SeaA.svg", svg(700, 525, sea(False)))
write("Assets/Images/World5/SeaB.svg", svg(700, 525, sea(True)))
lv = Level("Level48_SeaDifferences.tscn", "Level48_SeaDifferences", "res://Scenes/Mechanics/HiddenObjectHunt/HiddenObjectHuntLevel.tscn")
lv.props = ["level_number = 48", 'prompt_text = "Find the 10 differences!"', TIMER(150)]
hot = lv.res("Script", "res://Scenes/Mechanics/HiddenObjectHunt/Hotspot.gd")
pics = "Layout/PlayArea/Pictures"
lv.overrides = [f'[node name="SceneImage" parent="{pics}" index="0"]', "custom_minimum_size = Vector2(700, 525)",
                f"texture = {lv.tex(W5 + 'SeaA.svg')}", "",
                f'[node name="CompareImage" parent="{pics}" index="1"]', f"texture = {lv.tex(W5 + 'SeaB.svg')}", ""]
SEA_SPOTS = [("Boat", 515, 4, 90, 64), ("Seaweed", 40, 300, 60, 155), ("Rock", 372, 446, 96, 48),
             ("BlueFish", 425, 205, 100, 75), ("PinkFish", 555, 115, 60, 40), ("Crab", 256, 448, 90, 44),
             ("Starfish", 486, 466, 70, 62), ("Shell", 155, 462, 40, 32), ("Bubbles", 455, 78, 40, 56),
             ("Jellyfish", 294, 44, 72, 92)]
for name, x, y, w, h in SEA_SPOTS:
    lv.nodes += rect_node(name, "ReferenceRect", f"{pics}/SceneImage/Hotspots", x, y, w, h,
                          ["border_width = 3.0", f'script = ExtResource("{hot}")', 'category = "Differences"'])
lv.save()

# ---- 49: connect the dots (star, then fish) ------------------------------------------------
star_pts = []
for i in range(10):
    a = -math.pi / 2 + i * math.pi / 5
    r = 300 if i % 2 == 0 else 125
    star_pts.append((550 + r * math.cos(a), 390 + r * math.sin(a)))
S, OX, OY = 2.34, 250, 80
fish_pts = [(120 + 92 * math.cos(math.radians(a)), 128 - 60 * math.sin(math.radians(a))) for a in (180, 150, 120, 90, 60, 35)]
fish_pts += [(244, 84), (244, 172)]
fish_pts += [(120 + 92 * math.cos(math.radians(a)), 128 - 60 * math.sin(math.radians(a))) for a in (325, 300, 270, 240, 210)]
fish_pts = [(OX + x * S, OY + y * S) for x, y in fish_pts]
lv = Level("Level49_ConnectDots.tscn", "Level49_ConnectDots", "res://Scenes/Mechanics/ConnectDots/ConnectDotsLevel.tscn")
lv.props = ["level_number = 49", 'prompt_text = "Join the dots from 1 upwards!"',
            f"shapes = Array[PackedVector2Array]([{vec_array(star_pts)}, {vec_array(fish_pts)}])",
            f"reveals = Array[Texture2D]([{lv.tex(A + 'Star.svg')}, {lv.tex(W5 + 'BlueFish.svg')}])",
            f"reveal_rects = Array[Rect2]([Rect2(250, 90, 600, 600), Rect2({OX}, {OY}, {256 * S:.0f}, {256 * S:.0f})])",
            "board_size = Vector2(1100, 760)", TIMER(120)]
write("Assets/Images/World5/BlueFish.svg", svg(256, 256, fish().replace("#ff8c3a", "#3a86ff").replace("#e0701f", "#2a62c0")))
lv.save()


# ---- 50: treasure island (grand finale hunt) -------------------------------------------------
def key(x, y, s=1.0):
    return (f'<g transform="translate({x} {y}) scale({s})"><circle cx="0" cy="0" r="14" fill="none" stroke="#e8a317" stroke-width="7"/>'
            '<rect x="12" y="-4" width="34" height="8" fill="#e8a317"/><rect x="34" y="4" width="6" height="10" fill="#e8a317"/>'
            '<rect x="42" y="4" width="5" height="8" fill="#e8a317"/></g>')


def coin(x, y, r=17):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="#ffd23f" stroke="#e8a317" stroke-width="5"/><circle cx="{x}" cy="{y}" r="{r * 0.45:.0f}" fill="none" stroke="#e8a317" stroke-width="3"/>'


def parrot(x, y, s=1.0, body="#e63946"):
    return (f'<g transform="translate({x} {y}) scale({s})"><ellipse cx="0" cy="20" rx="22" ry="34" fill="{body}"/>'
            '<circle cx="0" cy="-18" r="20" fill="' + body + '"/><polygon points="14,-22 34,-14 16,-6" fill="#ffd23f"/>'
            '<circle cx="6" cy="-22" r="5" fill="#fff"/><circle cx="7" cy="-22" r="2.5" fill="#222"/>'
            '<path d="M-20 10 Q-40 40 -14 54" fill="#3a86ff"/><path d="M-8 50 L-14 80 L4 52 Z" fill="#43b649"/></g>')


def chest(x, y, s=1.0):
    return (f'<g transform="translate({x} {y}) scale({s})"><rect x="0" y="30" width="120" height="70" rx="8" fill="#8b5a2b"/>'
            '<path d="M0 34 Q60 -10 120 34 Z" fill="#a0612c"/><rect x="0" y="44" width="120" height="10" fill="#e8a317"/>'
            '<rect x="52" y="44" width="16" height="26" rx="3" fill="#ffd23f"/></g>')


KEYS = [(250, 520, 0.9), (930, 300, 0.8), (690, 560, 0.85)]
COINS = [(470, 470), (1110, 450), (150, 400), (800, 420)]
PARROTS = [(380, 190, 1.0, "#e63946"), (1050, 150, 0.9, "#43b649")]
CHEST = (600, 430, 1.0)
island = ['<rect width="1280" height="680" fill="#8fd3ff"/>', '<rect y="300" width="1280" height="380" fill="#3a9bdc"/>',
          '<ellipse cx="640" cy="560" rx="620" ry="210" fill="#f2d79b"/>',
          '<circle cx="1180" cy="80" r="50" fill="#ffd23f"/>',
          '<path d="M380 520 Q360 380 400 250" stroke="#8b5a2b" stroke-width="24" fill="none"/>',
          '<path d="M1060 520 Q1080 380 1040 230" stroke="#8b5a2b" stroke-width="24" fill="none"/>']
for cx, cy in [(400, 250), (1040, 230)]:
    island += [f'<path d="M{cx} {cy} Q{cx + dx} {cy + dy - 40} {cx + dx * 1.6:.0f} {cy + dy}" stroke="#2e8b3e" stroke-width="22" fill="none" stroke-linecap="round"/>'
               for dx, dy in [(-110, 30), (110, 30), (-70, -40), (70, -40), (0, -70)]]
island += ['<path d="M80 600 Q140 560 200 600 Z" fill="#3fae49"/>', '<path d="M980 620 Q1040 580 1100 620 Z" fill="#3fae49"/>',
           '<ellipse cx="560" cy="560" rx="70" ry="18" fill="#e3c27e"/>', '<ellipse cx="880" cy="600" rx="60" ry="14" fill="#e3c27e"/>']
island += [key(x, y, s) for x, y, s in KEYS] + [coin(x, y) for x, y in COINS]
island += [parrot(x, y, s, c) for x, y, s, c in PARROTS] + [chest(*CHEST)]
write("Assets/Images/World5/TreasureIsland.svg", svg(1280, 680, "\n".join(island)))
write("Assets/Images/World5/Key.svg", svg(256, 256, key(60, 128, 2.6)))
write("Assets/Images/World5/Coin.svg", svg(256, 256, coin(128, 128, 90)))
write("Assets/Images/World5/Parrot.svg", svg(256, 256, parrot(128, 120, 2.4)))
write("Assets/Images/World5/Chest.svg", svg(256, 256, chest(18, 60, 1.84)))
lv = Level("Level50_TreasureIsland.tscn", "Level50_TreasureIsland", "res://Scenes/Mechanics/HiddenObjectHunt/HiddenObjectHuntLevel.tscn")
lv.props = ["level_number = 50", 'prompt_text = "Find keys, coins, parrots and the treasure!"', TIMER(180)]
hot = lv.res("Script", "res://Scenes/Mechanics/HiddenObjectHunt/Hotspot.gd")
lv.overrides = [f'[node name="SceneImage" parent="{pics}" index="0"]', "custom_minimum_size = Vector2(1280, 680)",
                f"texture = {lv.tex(W5 + 'TreasureIsland.svg')}", ""]
spots = [(f"Key{i + 1}", "Key", "Key", x - 16, y - 18, int(64 * s), 36) for i, (x, y, s) in enumerate(KEYS)]
spots += [(f"Coin{i + 1}", "Coin", "Coin", x - 20, y - 20, 40, 40) for i, (x, y) in enumerate(COINS)]
spots += [(f"Parrot{i + 1}", "Parrot", "Parrot", x - 42 * s, y - 40 * s, 84 * s, 125 * s) for i, (x, y, s, _) in enumerate(PARROTS)]
spots += [("Chest", "Chest", "Chest", CHEST[0], CHEST[1], 120, 100)]
for name, cat, icon, x, y, w, h in spots:
    lv.nodes += rect_node(name, "ReferenceRect", f"{pics}/SceneImage/Hotspots", int(x), int(y), int(w), int(h),
                          ["border_width = 3.0", f'script = ExtResource("{hot}")', f'category = "{cat}"', f"icon = {lv.tex(W5 + icon + '.svg')}"])
lv.save()
print("levels 41-50 generated")
