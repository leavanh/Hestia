"""Baut das App Icon "Flamme": drei ineinander liegende Flammen im Linolschnitt Look.

Innen eine Flamme mit einem Züngel, darum eine mit zwei, außen die mit drei. Zwischen den Flammen
bleibt eine ausgehobene Rille stehen. Die Formen sind unten als Eckpunkte angegeben, alles Weitere
(Rillen im Druck, wellige Kante, Fehlstellen in der Tinte) entsteht im Skript mit fester Seed.
Schreibt Branding/flame-mark.png (Tinte als Weiß auf Schwarz) und die drei Icons in den Asset Katalog.
Aufruf: python3 -I Branding/render_flame_icon.py [Ausgabeordner für eine Vorschau]
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
BRANDING = ROOT / "Branding"
ICONSET = ROOT / "Habitus/Assets.xcassets/AppIcon.appiconset"

SIZE = 1024
SUPERSAMPLE = 2  # Die Formen werden doppelt so groß gezeichnet und verkleinert, das glättet die Kanten

# Rille zwischen den Flammen, in Pixeln des fertigen Icons. Zum Boden hin wird sie schmaler: dort wachsen die Flammen zusammen
GROOVE = 20
GROOVE_TAPER = (680, 940, 0.3)  # (Höhe, ab der sie schmaler wird; Höhe am Boden; Anteil der Breite dort)
GROOVE_JITTER = 6  # Wie stark die Rille in der Breite schwankt

# Rauheit des Drucks. Feste Seed, damit das Ergebnis reproduzierbar bleibt.
SEED = 11
EDGE_WOBBLE = ((3, 0.7), (9, 1.1), (30, 1.0))  # (Wellenlänge, Ausschlag): Kante springt rein und raus
VOID_COVERAGE = 0.012  # Anteil der Tintenfläche, der als Fehlstelle unbedruckt bleibt
VOID_GRAIN = 1.4  # Korngröße der Fehlstellen (Sigma des Rauschens)
EDGE_BITES = 0.07  # Anteil der Randzone, aus dem der Druck ausbricht

# Rillen im Druck, parallel zur Kante: (Abstand zur Kante, größte Breite, Länge der Stücke)
GOUGES = ((28, 12.0, 70),)
GOUGE_MIN_DEPTH = 20  # Nur in Tintenflächen, die so viel tiefer sind als die Rille. In schmalen Streifen würde sie die Fläche zerschneiden

BRAND = (0x00, 0x00, 0xF2)
PAPER = (0xF2, 0xF2, 0xF2)
NIGHT = (0x00, 0x00, 0x30)
BLACK = (0x00, 0x00, 0x00)
WHITE = (0xFF, 0xFF, 0xFF)

# Vordergrund und Hintergrund je Variante. Hell ist der Druck selbst (Blau auf Papier), dunkel und getönt sind invertiert.
VARIANTS = {
    "light": {"background": PAPER, "flame": BRAND},
    "dark": {"background": NIGHT, "flame": PAPER},
    "tinted": {"background": BLACK, "flame": WHITE},
}

# Umrisse im Uhrzeigersinn, als Ketten glatter Kurven. Jede Kette läuft von einer Ecke (Spitze oder Tal)
# zur nächsten, die Ecken bleiben scharf. Koordinaten auf 1024 x 1024, y wächst nach unten.
OUTER = (  # drei Züngel
    ((512, 952), (385, 932), (285, 865), (230, 760), (240, 650), (290, 560), (312, 470), (298, 375), (268, 262)),
    ((268, 262), (322, 298), (366, 350), (384, 425)),
    ((384, 425), (386, 340), (414, 245), (478, 148), (562, 58)),
    ((562, 58), (546, 140), (568, 228), (626, 310), (676, 385), (688, 445)),
    ((688, 445), (704, 402), (726, 362), (752, 318)),
    ((752, 318), (746, 392), (762, 468), (792, 548), (800, 645), (784, 750), (730, 858), (634, 929), (512, 952)),
)
# Mittlere und innere Flamme reichen unten über den Rand der äußeren hinaus und werden dort von ihr beschnitten,
# so setzen alle drei am Boden an und die Rillen laufen am Rand aus.
MIDDLE = (  # zwei Züngel
    ((505, 1030), (440, 995), (392, 925), (352, 830), (335, 730), (350, 640), (386, 578), (396, 535), (392, 485)),
    ((392, 485), (424, 520), (445, 545), (456, 568)),
    ((456, 568), (458, 500), (470, 420), (494, 330), (528, 240)),
    ((528, 240), (536, 320), (582, 395), (626, 475), (656, 565), (662, 670), (645, 780), (608, 890), (560, 975), (505, 1030)),
)
INNER = (  # ein Züngel
    ((505, 1030), (470, 975), (448, 900), (436, 810), (440, 730), (462, 660), (490, 600), (512, 545), (528, 488), (545, 428)),
    ((545, 428), (568, 486), (594, 546), (606, 614), (604, 700), (588, 800), (560, 900), (528, 975), (505, 1030)),
)


def catmull_rom(points, steps=24):
    """Glatte Kurve durch die Punkte, Anfang und Ende laufen gerade aus."""
    pts = np.array([points[0], *points, points[-1]], dtype=float)
    curve = []
    for i in range(1, len(pts) - 2):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[i + 1], pts[i + 2]
        for t in np.linspace(0, 1, steps, endpoint=False):
            curve.append(
                0.5 * (2 * p1 + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t**2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t**3)
            )
    return curve


def flame_mask(chains):
    """Gefüllte Flamme als boolesche Maske in 1024 x 1024."""
    outline = []
    for chain in chains:
        outline += catmull_rom(chain)
    scaled = [(x * SUPERSAMPLE, y * SUPERSAMPLE) for x, y in outline]
    canvas = Image.new("L", (SIZE * SUPERSAMPLE,) * 2, 0)
    ImageDraw.Draw(canvas).polygon(scaled, fill=255)
    return np.asarray(canvas.resize((SIZE, SIZE), Image.LANCZOS), dtype=float) > 127


def smooth_noise(rng, sigma, shape):
    field = ndimage.gaussian_filter(rng.standard_normal(shape), sigma)
    return field / field.std()


def grooved_flames(rng):
    """Die drei Flammen als Tinte, getrennt durch je eine Rille mit schwankender Breite."""
    outer, middle, inner = (flame_mask(chains) for chains in (OUTER, MIDDLE, INNER))

    top, bottom, share = GROOVE_TAPER
    rows = np.arange(SIZE)[:, None] * np.ones((1, SIZE))
    taper = 1 - (1 - share) * np.clip((rows - top) / (bottom - top), 0, 1)

    def groove_around(shape):
        reach = (GROOVE + GROOVE_JITTER * np.tanh(smooth_noise(rng, 18, shape.shape))) * taper
        return ndimage.distance_transform_edt(~shape) <= reach

    middle &= outer
    inner &= outer
    return (outer & ~groove_around(middle)) | (middle & ~groove_around(inner)) | inner


def carved(ink, rng):
    """Schnitzt kurze, spitz zulaufende Rillen parallel zur Kante in die Tintenflächen."""
    depth = ndimage.distance_transform_edt(ink)
    for offset, width, length in GOUGES:
        # Dort, wo das Rauschen positiv ist, liegt ein Stück der Rille. Seine Breite wächst zur Mitte des Stücks hin.
        along = smooth_noise(rng, length / 2, ink.shape)
        reach = np.clip((along - 0.35) / 0.9, 0, 1) * width / 2
        thick = ndimage.maximum_filter(depth, size=2 * GOUGE_MIN_DEPTH + 1) >= offset + GOUGE_MIN_DEPTH
        cut = (np.abs(depth - offset) <= reach) & thick
        ink = ink & ~cut
    return ink


def roughened(ink, rng):
    """Macht Kante und Fläche rau wie einen echten Abzug: wellige Kante, Fehlstellen, Ausbrüche am Rand."""
    inside = ink
    signed = ndimage.distance_transform_edt(inside) - ndimage.distance_transform_edt(~inside)
    noise = np.zeros_like(signed)
    for wavelength, amplitude in EDGE_WOBBLE:
        noise += amplitude * smooth_noise(rng, wavelength / 2, signed.shape)
    result = np.clip(signed + noise + 0.5, 0, 1)

    # Fehlstellen: organische Flecken aus geglättetem Rauschen, nur in der Tinte. Am Rand mehr davon.
    deep = ndimage.distance_transform_edt(inside)
    grain = smooth_noise(rng, VOID_GRAIN, signed.shape)
    band = np.clip(1 - deep / 14, 0, 1)
    inner_cut = np.quantile(grain[deep > 3], 1 - VOID_COVERAGE)
    edge_cut = np.quantile(grain[(deep > 0) & (deep <= 6)], 1 - EDGE_BITES)
    voids = (grain > np.where(band > 0, inner_cut + (edge_cut - inner_cut) * band, inner_cut)) & (deep > 1.5)
    result[voids] = 0.0

    return Image.fromarray((np.clip(result, 0, 1) * 255).astype(np.uint8))


def placed(ink):
    """Setzt die Flamme optisch mittig: Mitte überwiegend aus dem Zuschnitt, etwas aus dem Schwerpunkt."""
    rows, cols = np.nonzero(ink)
    height = rows.max() + 1 - rows.min()
    centroid_y = rows.mean()
    center_y = 0.75 * (rows.min() + height / 2) + 0.25 * centroid_y
    center_x = (cols.min() + cols.max() + 1) / 2
    return np.roll(ink, (round(SIZE / 2 - center_y), round(SIZE / 2 - center_x)), axis=(0, 1))


def render(variant, mark):
    colors = VARIANTS[variant]
    background = Image.new("RGB", (SIZE, SIZE), colors["background"])
    flame = Image.new("RGB", (SIZE, SIZE), colors["flame"])
    return Image.composite(flame, background, mark)


if __name__ == "__main__":
    rng = np.random.default_rng(SEED)
    ink = placed(grooved_flames(rng))
    mark = roughened(carved(ink, rng), rng)
    preview = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    if preview:
        render("light", mark).save(preview / "preview-light.png")
    else:
        mark.save(BRANDING / "flame-mark.png")
        for variant in VARIANTS:
            render(variant, mark).save(ICONSET / f"AppIcon-{variant}.png")
