import os

ROOT = r"C:\Kidzpuzzleapp\kidzpuzzle-app"


def write(rel, text):
    path = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def svg(w, h, body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n{body}\n</svg>\n'


# ---- Balloons (200x300) ---------------------------------------------------

BALLOONS = {
    "Red": ("#e63946", "#b02a35"),
    "Blue": ("#3a86ff", "#2a62c0"),
    "Yellow": ("#ffd23f", "#d9a915"),
    "Green": ("#43b649", "#2e8b3e"),
}
for name, (fill, dark) in BALLOONS.items():
    write(f"Assets/Images/Colours/{name}Balloon.svg", svg(200, 300, "\n".join([
        '<path d="M100 212 C 92 240, 112 255, 98 275 S 104 292, 100 298" stroke="#666" stroke-width="3" fill="none"/>',
        f'<polygon points="100,196 88,216 112,216" fill="{dark}"/>',
        f'<ellipse cx="100" cy="105" rx="82" ry="98" fill="{fill}"/>',
        f'<path d="M100 203 C 60 200, 18 160, 18 105" stroke="{dark}" stroke-width="6" fill="none" opacity="0.35"/>',
        '<ellipse cx="68" cy="62" rx="16" ry="28" fill="#fff" opacity="0.55" transform="rotate(-25 68 62)"/>',
    ])))

# ---- Fruit (256x256) ------------------------------------------------------

write("Assets/Images/Fruit/Apple.svg", svg(256, 256, "\n".join([
    '<path d="M128 70 C 90 40, 30 60, 32 130 C 34 200, 80 240, 110 232 C 120 229, 136 229, 146 232 '
    'C 176 240, 222 200, 224 130 C 226 60, 166 40, 128 70 Z" fill="#e63946"/>',
    '<path d="M128 72 C 126 50, 130 34, 140 20" stroke="#6b3e1f" stroke-width="10" stroke-linecap="round" fill="none"/>',
    '<path d="M138 44 C 160 18, 196 22, 206 34 C 184 52, 156 54, 138 44 Z" fill="#43b649"/>',
    '<ellipse cx="78" cy="110" rx="14" ry="30" fill="#fff" opacity="0.45" transform="rotate(20 78 110)"/>',
])))

write("Assets/Images/Fruit/Banana.svg", svg(256, 256, "\n".join([
    '<path d="M44 76 C 40 170, 120 226, 214 190 C 222 186, 222 176, 212 176 '
    'C 136 190, 76 150, 70 72 C 68 60, 46 60, 44 76 Z" fill="#ffd23f" stroke="#d9a915" stroke-width="6" stroke-linejoin="round"/>',
    '<path d="M58 90 C 66 158, 124 196, 196 186" stroke="#d9a915" stroke-width="4" fill="none" opacity="0.7"/>',
    '<rect x="46" y="52" width="20" height="24" rx="5" fill="#6b3e1f" transform="rotate(-8 56 64)"/>',
    '<circle cx="214" cy="183" r="7" fill="#6b3e1f"/>',
])))

grape_centres = [(98, 92), (138, 92), (178, 92), (78, 128), (118, 128), (158, 128), (198, 128),
                 (98, 164), (138, 164), (178, 164), (118, 198), (158, 198), (138, 230)]
write("Assets/Images/Fruit/Grapes.svg", svg(256, 256, "\n".join(
    ['<path d="M138 70 C 136 50, 140 34, 150 22" stroke="#6b3e1f" stroke-width="9" stroke-linecap="round" fill="none"/>',
     '<path d="M146 46 C 170 22, 206 28, 214 42 C 190 58, 164 58, 146 46 Z" fill="#43b649"/>']
    + [f'<circle cx="{x}" cy="{y - 8}" r="22" fill="#7b3fa0" stroke="#5a2b78" stroke-width="3"/>'
       f'<circle cx="{x - 7}" cy="{y - 16}" r="6" fill="#fff" opacity="0.4"/>' for x, y in grape_centres]
)))

write("Assets/Images/Fruit/Orange.svg", svg(256, 256, "\n".join(
    ['<circle cx="128" cy="140" r="98" fill="#ff9f1c"/>',
     '<path d="M128 44 C 126 32, 130 24, 136 18" stroke="#6b3e1f" stroke-width="8" stroke-linecap="round" fill="none"/>',
     '<path d="M134 34 C 156 12, 190 18, 198 30 C 176 46, 150 46, 134 34 Z" fill="#43b649"/>',
     '<ellipse cx="88" cy="104" rx="14" ry="26" fill="#fff" opacity="0.4" transform="rotate(30 88 104)"/>']
    + [f'<circle cx="{x}" cy="{y}" r="3" fill="#e0850f"/>'
       for x, y in [(150, 100), (170, 140), (120, 180), (160, 190), (100, 150), (140, 150), (190, 170)]]
)))

# ---- Level scenes ---------------------------------------------------------

BASE = "res://Scenes/Mechanics/TapMatch/TapMatchLevel.tscn"


def level(file, root, props, items, folder, item_size):
    textures = sorted({tex for _, tex in items})
    out = ["[gd_scene format=3]", "",
           f'[ext_resource type="PackedScene" path="{BASE}" id="1_base"]']
    out += [f'[ext_resource type="Texture2D" path="res://Assets/Images/{folder}/{t}.svg" id="tex_{t}"]' for t in textures]
    out += ["", f'[node name="{root}" instance=ExtResource("1_base")]'] + props + [""]
    for name, tex in items:
        out += [f'[node name="{name}" type="TextureButton" parent="Layout/ItemsContainer"]',
                f"custom_minimum_size = Vector2({item_size[0]}, {item_size[1]})",
                "layout_mode = 2",
                f'texture_normal = ExtResource("tex_{tex}")',
                "ignore_texture_size = true",
                "stretch_mode = 5", ""]
    write(f"Scenes/Levels/{file}", "\n".join(out))


level("Level03_FindColours.tscn", "Level03_FindColours",
      ["level_number = 3", 'prompt_text = "Find all the RED balloons!"',
       'correct_items = Array[NodePath]([NodePath("Layout/ItemsContainer/RedBalloon1"), '
       'NodePath("Layout/ItemsContainer/RedBalloon2"), NodePath("Layout/ItemsContainer/RedBalloon3")])'],
      [("RedBalloon1", "RedBalloon"), ("BlueBalloon", "BlueBalloon"), ("RedBalloon2", "RedBalloon"),
       ("YellowBalloon", "YellowBalloon"), ("GreenBalloon", "GreenBalloon"), ("RedBalloon3", "RedBalloon")],
      "Colours", (180, 270))

level("Level04_FindFruit.tscn", "Level04_FindFruit",
      ["level_number = 4", 'prompt_text = "Find the apple!"',
       'correct_items = Array[NodePath]([NodePath("Layout/ItemsContainer/Apple")])'],
      [("Banana", "Banana"), ("Grapes", "Grapes"), ("Apple", "Apple"), ("Orange", "Orange")],
      "Fruit", (240, 240))
print("ok")
