"""Zeichnet das App Icon "Wochenkreis" (Variante 3) als PNG und SVG.

Sieben Punkte im Kreis, im Uhrzeigersinn ab 12 Uhr zunehmend deckend, in der Mitte ein Haken.
Aufruf: python3 Branding/render_icon.py
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ICONSET = ROOT / "Habitus/Assets.xcassets/AppIcon.appiconset"
BRANDING = ROOT / "Branding"

SIZE = 1024
SUPERSAMPLE = 4

# Geometrie in Punkten bezogen auf 1024 x 1024.
CENTER = (512, 512)
ORBIT_RADIUS = 270
DOT_RADIUS = 60
OPACITIES = [0.25, 0.40, 0.55, 0.68, 0.80, 0.90, 1.00]
CHECK_POINTS = [(-69, 0), (-20, 45), (69, -45)]
CHECK_WIDTH = 36

# Farben aus Theme.swift (Hintergrundverlauf) und Systemblau.
VARIANTS = {
    "light": {"top": (0xE8, 0xF2, 0xFF), "bottom": (0xF2, 0xEB, 0xFF), "mark": (0x00, 0x7A, 0xFF)},
    "dark": {"top": (0x0A, 0x14, 0x30), "bottom": (0x26, 0x14, 0x3F), "mark": (0x40, 0x9C, 0xFF)},
    "tinted": {"top": (0x00, 0x00, 0x00), "bottom": (0x00, 0x00, 0x00), "mark": (0xFF, 0xFF, 0xFF)},
}


def dot_centers():
    for index in range(7):
        angle = -math.pi / 2 + index * 2 * math.pi / 7
        yield (
            CENTER[0] + ORBIT_RADIUS * math.cos(angle),
            CENTER[1] + ORBIT_RADIUS * math.sin(angle),
        )


def check_path():
    return [(CENTER[0] + dx, CENTER[1] + dy) for dx, dy in CHECK_POINTS]


def gradient(top, bottom, size):
    column = Image.new("RGB", (1, size))
    for y in range(size):
        t = y / (size - 1)
        column.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)))
    return column.resize((size, size))


def render(variant):
    colors = VARIANTS[variant]
    s = SUPERSAMPLE
    canvas = gradient(colors["top"], colors["bottom"], SIZE * s).convert("RGBA")

    for (x, y), opacity in zip(dot_centers(), OPACITIES):
        layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        r = DOT_RADIUS * s
        ImageDraw.Draw(layer).ellipse(
            (x * s - r, y * s - r, x * s + r, y * s + r),
            fill=colors["mark"] + (round(255 * opacity),),
        )
        canvas = Image.alpha_composite(canvas, layer)

    draw = ImageDraw.Draw(canvas)
    points = [(x * s, y * s) for x, y in check_path()]
    width = CHECK_WIDTH * s
    draw.line(points, fill=colors["mark"] + (255,), width=width, joint="curve")
    for x, y in (points[0], points[-1]):
        draw.ellipse((x - width / 2, y - width / 2, x + width / 2, y + width / 2), fill=colors["mark"] + (255,))

    return canvas.resize((SIZE, SIZE), Image.LANCZOS).convert("RGB")


def mark_svg():
    dots = "\n".join(
        f'  <circle cx="{x:.1f}" cy="{y:.1f}" r="{DOT_RADIUS}" fill="#007AFF" fill-opacity="{o}"/>'
        for (x, y), o in zip(dot_centers(), OPACITIES)
    )
    check = " L".join(f"{x} {y}" for x, y in check_path())
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {SIZE} {SIZE}">\n'
        f"{dots}\n"
        f'  <path d="M{check}" fill="none" stroke="#007AFF" stroke-width="{CHECK_WIDTH}" '
        f'stroke-linecap="round" stroke-linejoin="round"/>\n'
        "</svg>\n"
    )


if __name__ == "__main__":
    for variant in VARIANTS:
        render(variant).save(ICONSET / f"AppIcon-{variant}.png")
    (BRANDING / "habitus-mark.svg").write_text(mark_svg())
