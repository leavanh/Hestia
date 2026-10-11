"""Baut das App Icon "Flamme" aus dem Linolschnitt in Branding/flame-linocut-source.webp.

Die Flamme wird als Alphakanal aus dem blauen Druck gelesen (Staubpunkte außen entfernt, winzige
Löcher in der Tinte gefüllt), zugeschnitten, optisch mittig gesetzt und in drei Varianten eingefärbt.
Schreibt Branding/flame-mark.png (Alphakanal als Weiß auf Schwarz) und die drei Icons in den Asset Katalog.
Aufruf: python3 -I Branding/render_flame_icon.py
"""

from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
BRANDING = ROOT / "Branding"
ICONSET = ROOT / "Habitus/Assets.xcassets/AppIcon.appiconset"
SOURCE = BRANDING / "flame-linocut-source.webp"

SIZE = 1024
FLAME_HEIGHT = 880  # Anteil der Fläche: etwa 86 %, nur möglich, weil die Flamme schmal ist und die Spitze mittig sitzt
MAX_PINHOLE = 40  # Löcher in der Tinte bis zu dieser Fläche (Pixel) werden gefüllt

# Rauheit des Drucks, in Pixeln des fertigen 1024er Icons. Feste Seed, damit das Ergebnis reproduzierbar bleibt.
SEED = 7
EDGE_WOBBLE = ((3, 0.6), (9, 0.9), (30, 0.8))  # (Wellenlänge, Ausschlag): Kante springt rein und raus
VOID_COVERAGE = 0.012  # Anteil der Tintenfläche, der als Fehlstelle unbedruckt bleibt
VOID_GRAIN = 1.3  # Korngröße der Fehlstellen (Sigma des Rauschens)
EDGE_BITES = 0.05  # Anteil der Randzone, aus dem der Druck ausbricht
INK_BELOW = 140  # Rotkanal unter diesem Wert ist Tinte
EDGE_SOFT = (60, 200)  # Rotkanal Bereich für die weiche Kante

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


def flame_alpha():
    """Alphakanal der Flamme, Wert 1 = Tinte, im Format der Quelle."""
    red = np.asarray(Image.open(SOURCE).convert("RGB"), dtype=float)[..., 0]
    ink = red < INK_BELOW

    labels, count = ndimage.label(ink)
    sizes = ndimage.sum(ink, labels, range(1, count + 1))
    ink = labels == (1 + int(np.argmax(sizes)))

    holes, hole_count = ndimage.label(~ink)
    hole_sizes = ndimage.sum(~ink, holes, range(1, hole_count + 1))
    for index, size in enumerate(hole_sizes, start=1):
        if size <= MAX_PINHOLE:
            ink |= holes == index

    low, high = EDGE_SOFT
    soft = 1 - np.clip((red - low) / (high - low), 0, 1)
    near_ink = ndimage.binary_dilation(ink, iterations=3)
    return np.where(near_ink, np.maximum(soft, ink), 0.0)


def placed_mark(alpha):
    """Schneidet zu, skaliert auf FLAME_HEIGHT und setzt die Flamme optisch mittig auf 1024 x 1024."""
    rows, cols = np.nonzero(alpha > 0.5)
    box = (cols.min(), rows.min(), cols.max() + 1, rows.max() + 1)
    cropped = alpha[box[1] : box[3], box[0] : box[2]]

    scale = FLAME_HEIGHT / cropped.shape[0]
    width = round(cropped.shape[1] * scale)
    mark = Image.fromarray((cropped * 255).astype(np.uint8)).resize((width, FLAME_HEIGHT), Image.LANCZOS)

    # Die Flamme ist unten schwerer, die Spitze aber dünn. Mitte überwiegend aus dem Zuschnitt, etwas aus dem Schwerpunkt.
    weights = np.asarray(mark, dtype=float)
    centroid_y = (weights.sum(axis=1) * np.arange(FLAME_HEIGHT)).sum() / weights.sum()
    center_y = 0.75 * FLAME_HEIGHT / 2 + 0.25 * centroid_y
    left = round((SIZE - width) / 2)
    top = round(SIZE / 2 - center_y)

    canvas = Image.new("L", (SIZE, SIZE), 0)
    canvas.paste(mark, (left, top))
    return canvas


def roughened(mark):
    """Macht Kante und Fläche rau wie einen echten Abzug: wellige Kante, Fehlstellen, Ausbrüche am Rand."""
    rng = np.random.default_rng(SEED)
    alpha = np.asarray(mark, dtype=float) / 255
    inside = alpha > 0.5

    # Vorzeichenbehafteter Abstand zur Kante, plus Rauschen auf mehreren Skalen. Danach weich geschwellt.
    signed = ndimage.distance_transform_edt(inside) - ndimage.distance_transform_edt(~inside)
    noise = np.zeros_like(signed)
    for wavelength, amplitude in EDGE_WOBBLE:
        field = ndimage.gaussian_filter(rng.standard_normal(signed.shape), wavelength / 2)
        noise += amplitude * field / field.std()
    result = np.clip(signed + noise + 0.5, 0, 1)

    # Fehlstellen: organische Flecken aus geglättetem Rauschen, nur in der Tinte. Am Rand mehr davon.
    deep = ndimage.distance_transform_edt(inside)
    grain = ndimage.gaussian_filter(rng.standard_normal(signed.shape), VOID_GRAIN)
    grain /= grain.std()
    band = np.clip(1 - deep / 14, 0, 1)
    inner_cut = np.quantile(grain[deep > 3], 1 - VOID_COVERAGE)
    edge_cut = np.quantile(grain[(deep > 0) & (deep <= 6)], 1 - EDGE_BITES)
    voids = (grain > np.where(band > 0, inner_cut + (edge_cut - inner_cut) * band, inner_cut)) & (deep > 1.5)
    result[voids] = 0.0

    return Image.fromarray((np.clip(result, 0, 1) * 255).astype(np.uint8))


def render(variant, mark):
    colors = VARIANTS[variant]
    background = Image.new("RGB", (SIZE, SIZE), colors["background"])
    flame = Image.new("RGB", (SIZE, SIZE), colors["flame"])
    return Image.composite(flame, background, mark)


if __name__ == "__main__":
    mark = roughened(placed_mark(flame_alpha()))
    mark.save(BRANDING / "flame-mark.png")
    for variant in VARIANTS:
        render(variant, mark).save(ICONSET / f"AppIcon-{variant}.png")
