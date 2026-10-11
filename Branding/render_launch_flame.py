"""Baut das Bild für den Startbildschirm aus Branding/flame-mark.png (erzeugt von render_flame_icon.py).

Die Flamme wird auf ihre Kontur zugeschnitten und auf FLAME_POINTS Höhe gebracht (in @2x und @3x).
Hell ist sie Blau, dunkel Papier, jeweils auf transparentem Grund. Die Fläche dahinter kommt aus der
Farbe LaunchBackground (hell Papier, dunkel Nachtblau), die das Skript ebenfalls schreibt.
Aufruf: python3 -I Branding/render_launch_flame.py
"""

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
MARK = ROOT / "Branding/flame-mark.png"
ASSETS = ROOT / "Hestia/Assets.xcassets"

FLAME_POINTS = 560  # fast bildschirmfüllend: Breite dann etwa 345 pt, passt auch auf 375 pt breite iPhones
SCALES = (2, 3)

BRAND = (0x00, 0x00, 0xF2)
PAPER = (0xF2, 0xF2, 0xF2)
NIGHT = (0x00, 0x00, 0x30)

VARIANTS = {"light": BRAND, "dark": PAPER}
DARK = [{"appearance": "luminosity", "value": "dark"}]
INFO = {"author": "xcode", "version": 1}


def cropped_mark():
    mark = Image.open(MARK).convert("L")
    rows, cols = np.nonzero(np.asarray(mark) > 0)
    return mark.crop((cols.min(), rows.min(), cols.max() + 1, rows.max() + 1))


def write_image(mark):
    folder = ASSETS / "LaunchFlame.imageset"
    folder.mkdir(exist_ok=True)
    images = []
    for variant, color in VARIANTS.items():
        for scale in SCALES:
            height = FLAME_POINTS * scale
            width = round(mark.width * height / mark.height)
            alpha = mark.resize((width, height), Image.LANCZOS)
            flame = Image.new("RGBA", (width, height), color + (0,))
            flame.putalpha(alpha)
            name = f"LaunchFlame-{variant}@{scale}x.png"
            flame.save(folder / name)
            entry = {"filename": name, "idiom": "universal", "scale": f"{scale}x"}
            if variant == "dark":
                entry["appearances"] = DARK
            images.append(entry)
    (folder / "Contents.json").write_text(json.dumps({"images": images, "info": INFO}, indent=2) + "\n")


def color_entry(rgb, appearances=None):
    components = {"alpha": "1.000", "red": f"0x{rgb[0]:02X}", "green": f"0x{rgb[1]:02X}", "blue": f"0x{rgb[2]:02X}"}
    entry = {"color": {"color-space": "srgb", "components": components}, "idiom": "universal"}
    if appearances:
        entry["appearances"] = appearances
    return entry


def write_background():
    folder = ASSETS / "LaunchBackground.colorset"
    folder.mkdir(exist_ok=True)
    colors = [color_entry(PAPER), color_entry(NIGHT, DARK)]
    (folder / "Contents.json").write_text(json.dumps({"colors": colors, "info": INFO}, indent=2) + "\n")


if __name__ == "__main__":
    write_image(cropped_mark())
    write_background()
