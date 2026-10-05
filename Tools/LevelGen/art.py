"""Shared SVG drawing helpers for Doodle Bee placeholder art.

Each animal / thing function draws into a 256x256 box; use place() to put it
somewhere else at another size. The generators in this folder import this
module and write straight into the project (ROOT is the project folder).
"""
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def write(rel, text):
    path = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def svg(w, h, body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n{body}\n</svg>\n'


def place(body, x, y, size=256):
    """Places a 256-box drawing with its top-left at (x, y), scaled to `size`."""
    s = size / 256
    return f'<g transform="translate({x} {y}) scale({s:.4f})">{body}</g>'


def eye(x, y, r=11):
    return (f'<circle cx="{x}" cy="{y}" r="{r}" fill="#fff"/>'
            f'<circle cx="{x + 2}" cy="{y + 1}" r="{r * 0.55:.1f}" fill="#222"/>'
            f'<circle cx="{x + 4}" cy="{y - 2}" r="{r * 0.2:.1f}" fill="#fff"/>')


# ---- Animals (256 box) --------------------------------------------------------

def frog():
    return ('<ellipse cx="128" cy="160" rx="92" ry="66" fill="#3fae49"/>'
            '<circle cx="84" cy="96" r="30" fill="#3fae49"/><circle cx="172" cy="96" r="30" fill="#3fae49"/>'
            + eye(84, 94, 17) + eye(172, 94, 17) +
            '<path d="M86 172 Q128 204 170 172" stroke="#1f6b2a" stroke-width="8" fill="none" stroke-linecap="round"/>'
            '<ellipse cx="80" cy="160" rx="12" ry="8" fill="#ff8fa3" opacity="0.7"/>'
            '<ellipse cx="176" cy="160" rx="12" ry="8" fill="#ff8fa3" opacity="0.7"/>')


def duck():
    return ('<ellipse cx="120" cy="170" rx="88" ry="56" fill="#ffd23f"/>'
            '<path d="M60 150 Q90 130 118 158" stroke="#e8a317" stroke-width="7" fill="none" stroke-linecap="round"/>'
            '<circle cx="168" cy="98" r="48" fill="#ffd23f"/>'
            '<path d="M204 100 L246 110 L206 124 Z" fill="#ff9f1c"/>'
            + eye(180, 88, 11) +
            '<path d="M40 150 L24 128 L52 138 Z" fill="#ffd23f"/>')


def bee():
    return ('<ellipse cx="96" cy="70" rx="40" ry="28" fill="#dff3ff" stroke="#9fd0ee" stroke-width="5" transform="rotate(-25 96 70)"/>'
            '<ellipse cx="152" cy="66" rx="40" ry="28" fill="#dff3ff" stroke="#9fd0ee" stroke-width="5" transform="rotate(20 152 66)"/>'
            '<ellipse cx="128" cy="146" rx="96" ry="66" fill="#ffd23f"/>'
            '<rect x="80" y="84" width="24" height="124" fill="#2b2b3a" opacity="0.9"/>'
            '<rect x="130" y="80" width="24" height="132" fill="#2b2b3a" opacity="0.9"/>'
            '<path d="M222 146 L248 146" stroke="#2b2b3a" stroke-width="10" stroke-linecap="round"/>'
            '<circle cx="54" cy="136" r="28" fill="#ffd23f"/>'
            + eye(48, 128, 10) +
            '<path d="M40 152 Q52 162 64 152" stroke="#2b2b3a" stroke-width="4" fill="none"/>')


def owl():
    return ('<ellipse cx="128" cy="150" rx="86" ry="92" fill="#9c6b3f"/>'
            '<polygon points="56,70 72,26 98,62" fill="#9c6b3f"/><polygon points="200,70 184,26 158,62" fill="#9c6b3f"/>'
            '<ellipse cx="128" cy="176" rx="54" ry="58" fill="#e2c29b"/>'
            '<circle cx="92" cy="104" r="34" fill="#fff"/><circle cx="164" cy="104" r="34" fill="#fff"/>'
            '<circle cx="96" cy="106" r="16" fill="#222"/><circle cx="160" cy="106" r="16" fill="#222"/>'
            '<circle cx="101" cy="100" r="5" fill="#fff"/><circle cx="165" cy="100" r="5" fill="#fff"/>'
            '<polygon points="118,130 138,130 128,150" fill="#ff9f1c"/>'
            '<path d="M100 196 Q108 204 116 196 M140 196 Q148 204 156 196" stroke="#9c6b3f" stroke-width="5" fill="none"/>')


def dog():
    return ('<ellipse cx="128" cy="140" rx="84" ry="80" fill="#c8864a"/>'
            '<ellipse cx="54" cy="116" rx="28" ry="56" fill="#7a4e2d" transform="rotate(15 54 116)"/>'
            '<ellipse cx="202" cy="116" rx="28" ry="56" fill="#7a4e2d" transform="rotate(-15 202 116)"/>'
            '<ellipse cx="128" cy="176" rx="50" ry="38" fill="#e2b184"/>'
            + eye(96, 124, 13) + eye(160, 124, 13) +
            '<ellipse cx="128" cy="160" rx="18" ry="13" fill="#222"/>'
            '<path d="M110 186 Q128 200 146 186" stroke="#222" stroke-width="5" fill="none" stroke-linecap="round"/>'
            '<ellipse cx="136" cy="202" rx="10" ry="12" fill="#ff6f91"/>')


def fish():
    return ('<polygon points="190,128 244,84 244,172" fill="#ff8c3a"/>'
            '<ellipse cx="120" cy="128" rx="92" ry="60" fill="#ff8c3a"/>'
            '<path d="M100 72 Q130 40 160 76" fill="#ff8c3a"/>'
            '<path d="M120 90 Q140 128 120 166" stroke="#e0701f" stroke-width="6" fill="none"/>'
            + eye(70, 116, 13) +
            '<path d="M36 140 Q46 148 56 142" stroke="#222" stroke-width="4" fill="none"/>')


def butterfly_icon():
    return ('<ellipse cx="84" cy="96" rx="58" ry="50" fill="#c77dff"/><ellipse cx="172" cy="96" rx="58" ry="50" fill="#c77dff"/>'
            '<ellipse cx="92" cy="172" rx="42" ry="38" fill="#ff6fb5"/><ellipse cx="164" cy="172" rx="42" ry="38" fill="#ff6fb5"/>'
            '<circle cx="84" cy="96" r="18" fill="#ffd23f"/><circle cx="172" cy="96" r="18" fill="#ffd23f"/>'
            '<rect x="118" y="70" width="20" height="140" rx="10" fill="#2b2b3a"/>'
            '<path d="M124 72 Q110 40 96 34 M132 72 Q146 40 160 34" stroke="#2b2b3a" stroke-width="5" fill="none" stroke-linecap="round"/>')


def flower():
    petals = "".join(f'<circle cx="{128 + 52 * c:.1f}" cy="{110 + 52 * s:.1f}" r="34" fill="#ff6fb5"/>'
                     for c, s in [(1, 0), (0.31, 0.95), (-0.81, 0.59), (-0.81, -0.59), (0.31, -0.95)])
    return ('<rect x="120" y="150" width="16" height="100" fill="#43b649"/>'
            '<ellipse cx="160" cy="210" rx="30" ry="14" fill="#43b649" transform="rotate(-30 160 210)"/>'
            + petals + '<circle cx="128" cy="110" r="34" fill="#ffd23f"/>')


def moon():
    # Crescent: outer circle arc on the left, flatter inner arc back.
    return '<path d="M160 38 A96 96 0 1 0 160 218 A110 110 0 0 1 160 38 Z" fill="#fff3b0"/>'


def star():
    return ('<polygon points="128,14 161,94 247,99 180,154 202,238 128,192 54,238 76,154 9,99 95,94" '
            'fill="#ffd23f" stroke="#e8a317" stroke-width="10" stroke-linejoin="round"/>')


# ---- Toys & things (256 box) ------------------------------------------------------

def ball():
    return ('<circle cx="128" cy="128" r="100" fill="#e63946"/>'
            '<path d="M28 128 Q128 60 228 128" stroke="#fff" stroke-width="18" fill="none"/>'
            '<path d="M28 128 Q128 196 228 128" stroke="#3a86ff" stroke-width="18" fill="none"/>'
            '<ellipse cx="90" cy="80" rx="18" ry="28" fill="#fff" opacity="0.4" transform="rotate(30 90 80)"/>')


def teddy():
    return ('<circle cx="66" cy="62" r="32" fill="#a0612c"/><circle cx="190" cy="62" r="32" fill="#a0612c"/>'
            '<circle cx="66" cy="62" r="16" fill="#e2b184"/><circle cx="190" cy="62" r="16" fill="#e2b184"/>'
            '<ellipse cx="128" cy="200" rx="70" ry="56" fill="#a0612c"/>'
            '<circle cx="128" cy="110" r="74" fill="#c8864a"/>'
            '<ellipse cx="128" cy="140" rx="34" ry="26" fill="#e2b184"/>'
            + eye(100, 100, 10) + eye(156, 100, 10) +
            '<ellipse cx="128" cy="128" rx="12" ry="9" fill="#222"/>'
            '<path d="M116 150 Q128 158 140 150" stroke="#222" stroke-width="4" fill="none"/>'
            '<ellipse cx="128" cy="210" rx="36" ry="30" fill="#e2b184"/>')


def blocks():
    # Godot's SVG importer can't draw text, so the blocks get dots, not letters.
    def dots(x, y, n):
        return "".join(f'<circle cx="{x + dx}" cy="{y + dy}" r="9" fill="#fff"/>'
                       for dx, dy in [(0, 0), (-22, -22), (22, 22), (22, -22), (-22, 22)][:n])
    return ('<rect x="24" y="136" width="96" height="96" rx="8" fill="#3a86ff"/>'
            '<rect x="136" y="136" width="96" height="96" rx="8" fill="#43b649"/>'
            '<rect x="80" y="30" width="96" height="96" rx="8" fill="#e63946"/>'
            + dots(72, 184, 3) + dots(184, 184, 2) + dots(128, 78, 1))


def toy_car():
    return ('<path d="M20 170 L20 132 Q24 116 44 112 L72 112 L100 70 L176 70 L208 112 L226 116 Q238 120 238 138 L238 170 Z" fill="#3a86ff"/>'
            '<path d="M110 82 L168 82 L190 112 L94 112 Z" fill="#dff3ff"/>'
            '<line x1="140" y1="82" x2="140" y2="112" stroke="#3a86ff" stroke-width="8"/>'
            '<circle cx="72" cy="176" r="30" fill="#2b2b3a"/><circle cx="72" cy="176" r="12" fill="#aaa"/>'
            '<circle cx="190" cy="176" r="30" fill="#2b2b3a"/><circle cx="190" cy="176" r="12" fill="#aaa"/>'
            '<circle cx="226" cy="134" r="8" fill="#ffd23f"/>')


def basket():
    weave = "".join(f'<line x1="{x}" y1="140" x2="{x}" y2="236" stroke="#a0612c" stroke-width="6"/>' for x in range(48, 220, 28))
    return ('<path d="M52 140 Q128 20 204 140" stroke="#a0612c" stroke-width="14" fill="none"/>'
            '<path d="M24 136 L232 136 L208 236 L48 236 Z" fill="#d9a066"/>' + weave +
            '<rect x="18" y="126" width="220" height="24" rx="12" fill="#b77b42"/>')


def toy_box():
    return ('<rect x="24" y="100" width="208" height="140" rx="12" fill="#e63946"/>'
            '<rect x="16" y="76" width="224" height="40" rx="10" fill="#c1272d"/>'
            '<circle cx="80" cy="170" r="24" fill="#ffd23f"/><rect x="118" y="148" width="44" height="44" fill="#3a86ff"/>'
            '<polygon points="200,146 222,190 178,190" fill="#43b649"/>')
