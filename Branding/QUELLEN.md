# Bildquellen

Alle Bilder in der App stammen aus eigenen Quellen oder sind gemeinfrei. Die Lizenz wurde vor dem Einsatz
über die Open Access Schnittstelle der Met geprüft (`isPublicDomain: true`, 11.10.2026).

| Einsatz | Werk | Objekt | Lizenz | Datei |
| --- | --- | --- | --- | --- |
| Heute ohne Habits | Man with Torch between Flaming Altar and Statuette, aus "Ex Antiquis Cameorum et Gemmae Delineata", Anonym, Italien, 16. Jh., Kupferstich, veröffentlicht ca. 1599–1622 | The Met 371844 (49.97.407), https://www.metmuseum.org/art/collection/search/371844 | Public Domain, CC0 (Met Open Access) | `engravings-source/met-371844-torch.jpg` (Bild DP819663, Version web-large) |
| Kalender ohne Daten | A Vestal Virgin (?), aus "Speculum Romanae Magnificentiae", Anonym, 16. Jh., Radierung | The Met 402697 (41.72(2.94)), https://www.metmuseum.org/art/collection/search/402697 | Public Domain, CC0 (Met Open Access) | `engravings-source/met-402697-vestal.jpg` (Bild DP870222, Version web-large) |
| App Icon, Startbildschirm | Flamme als Linolschnitt | eigene Quelle, KI erzeugt | keine Lizenz nötig | `flame-linocut-source.webp` |

Die fertigen Bilder im Asset Katalog erzeugen Skripte, nichts ist von Hand bearbeitet:

- `render_flame_icon.py`: App Icon (hell, dunkel, getönt) und `flame-mark.png`
- `render_launch_flame.py`: Flamme und Hintergrundfarbe für den Startbildschirm
- `render_engravings.py`: die beiden Stiche, hell Blau und dunkel Papier
