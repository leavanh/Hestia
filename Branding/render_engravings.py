"""Baut die zwei Stiche für die Leerzustände (Phase 12) aus Branding/engravings-source/.

Jeder Stich wird auf das Motiv zugeschnitten, aus dem Rotkanal als Tinte gelesen (Papier, Flecken und
Bleistiftnotizen fallen weg, die Linien bleiben) und als Alphakanal eingefärbt: hell in Markenblau, dunkel
in Papier, jeweils auf transparentem Grund. Ergebnis in @2x und @3x im Asset Katalog.
Quellen und Lizenzen: Branding/QUELLEN.md. Aufruf: python3 -I Branding/render_engravings.py
"""

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCES = ROOT / "Branding/engravings-source"
ASSETS = ROOT / "Hestia/Assets.xcassets"

HEIGHT_POINTS = 200
SCALES = (2, 3)

BRAND = (0x00, 0x00, 0xF2)
PAPER = (0xF2, 0xF2, 0xF2)
VARIANTS = {"light": BRAND, "dark": PAPER}
DARK = [{"appearance": "luminosity", "value": "dark"}]
INFO = {"author": "xcode", "version": 1}

# Asset Name: Quelldatei, Zuschnitt (links, oben, rechts, unten) in Pixeln der Quelle, Tinte von/bis im Rotkanal.
ENGRAVINGS = {
    "EngravingTorch": {"file": "met-371844-torch.jpg", "crop": (30, 24, 512, 560), "ink": (70, 175)},
    "EngravingVestal": {"file": "met-402697-vestal.jpg", "crop": (62, 26, 345, 612), "ink": (60, 165)},
}


def ink_alpha(spec):
    """Deckkraft der Tinte: Rotkanal unter dem unteren Wert ist volle Tinte, über dem oberen Papier."""
    image = Image.open(SOURCES / spec["file"]).convert("RGB").crop(spec["crop"])
    red = np.asarray(image, dtype=float)[..., 0]
    low, high = spec["ink"]
    alpha = np.clip((high - red) / (high - low), 0, 1)
    return Image.fromarray((alpha * 255).astype(np.uint8))


def write(name, alpha):
    folder = ASSETS / f"{name}.imageset"
    folder.mkdir(exist_ok=True)
    images = []
    for variant, color in VARIANTS.items():
        for scale in SCALES:
            height = HEIGHT_POINTS * scale
            width = round(alpha.width * height / alpha.height)
            image = Image.new("RGBA", (width, height), color + (0,))
            image.putalpha(alpha.resize((width, height), Image.LANCZOS))
            filename = f"{name}-{variant}@{scale}x.png"
            image.save(folder / filename, optimize=True)
            entry = {"filename": filename, "idiom": "universal", "scale": f"{scale}x"}
            if variant == "dark":
                entry["appearances"] = DARK
            images.append(entry)
    (folder / "Contents.json").write_text(json.dumps({"images": images, "info": INFO}, indent=2) + "\n")


if __name__ == "__main__":
    for name, spec in ENGRAVINGS.items():
        write(name, ink_alpha(spec))
