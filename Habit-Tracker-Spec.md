# Habit Tracker: Spezifikation

## Hinweise für die KI beim Entwickeln

- Arbeite immer nur an **einer Phase**. Beginne erst mit der nächsten Phase, wenn ich das sage.
- Jede Phase endet mit einer lauffähigen App. Alle Punkte der Definition of Done müssen erfüllt sein.
- Halte dich an das Designsystem (Abschnitt 4). Erfinde keine neuen Stile, Farben oder Dialogformen.
- Die gesamte Rechenlogik (Status, Zählung, Streaks) liegt in einem eigenen Teil ohne Oberfläche (`HabitEngine`) und wird mit Unit Tests geprüft.
- Erkläre mir nach jeder Phase kurz, wie ich die Punkte der Definition of Done selbst prüfen kann.
- Keine Funktionen bauen, die hier nicht beschrieben sind.

---

## 1. Überblick

Ein persönlicher Habit Tracker für das iPhone. Ab Phase 8 im Stil von Hermes Agent (Nous Research): flach, Blau auf Papier, schmale dünne Schrift, Großbuchstaben für alles Funktionale. *(Bis Phase 7: clean, modern, minimalistisch, mit dezentem Glassmorphism.)*

| Punkt | Festlegung |
|---|---|
| Gerät | iPhone (getestet auf iPhone 16 Pro) |
| Mindestversion | iOS 26 (neueste Version, Liquid Glass verfügbar) |
| Technik | Xcode, Swift, SwiftUI, SwiftData |
| Nutzer | Nur ich, kein Login |
| Daten | Nur lokal auf dem Gerät, kein Sync, kein Export |
| Sprache der App | Deutsch |
| Darstellung | Hell und Dunkel (folgt der Systemeinstellung) |

**Bewusst nicht enthalten:** Erinnerungen, Notizen, Messwerte, negative Habits, Überspringen von Tagen, Widgets, Export, Haptik, Animationen über Standard hinaus, jährliche Habits.

*Ausnahme ab Phase 10:* ein kurzer **Zusatz** am Habit (höchstens 24 Zeichen, z.B. "20 Min"). Das ist eine Beschriftung, kein Notizfeld und kein Messwert. Es wird nichts damit gerechnet.

---

## 2. Begriffe

- **Habit:** Eine Gewohnheit, z.B. "Sport" oder "Wasser trinken".
- **Erledigung:** Ein Eintrag "an Tag X habe ich Habit Y n mal gemacht".
- **Tag:** Kalendertag, lokale Zeitzone, Wechsel um Mitternacht.
- **Fenster:** Rollierender Zeitraum, der heute endet. Woche = heute plus 6 Tage davor (7 Tage). Monat = heute plus 29 Tage davor (30 Tage).
- **Angezeigter Tag:** Der Tag, den die Heute Ansicht gerade zeigt. Standard ist heute, per Wischen kann ich auf vergangene Tage wechseln (5.2).

---

## 3. Fachliche Regeln

### 3.1 Rhythmen

| Rhythmus | Einstellung | Beispiel |
|---|---|---|
| Täglich | Anzahl pro Tag (1 bis 10) | 3x täglich Wasser |
| Pro Woche | Anzahl im 7 Tage Fenster (1 bis 7) | 2x pro Woche Sport |
| Pro Monat | Anzahl im 30 Tage Fenster (1 bis 30) | 1x pro Monat Pflanzen düngen |
| Feste Wochentage | Ein oder mehrere Wochentage | Montag und Donnerstag Yoga |
| Fester Monatstag | Tag 1 bis 31 | Jeden 1. Rechnungen prüfen |

Im Sheet gibt es dafür nur drei Rhythmen: **Täglich**, **Woche** und **Monat**. Feste Wochentage sind eine Variante von Woche, fester Monatstag eine Variante von Monat (siehe 5.3). Fachlich bleiben es die fünf Rhythmen aus der Tabelle.

Beim festen Monatstag gilt: Hat ein Monat weniger Tage (z.B. 31. im Februar), ist der letzte Tag des Monats fällig.

### 3.2 Fälligkeit (wann erscheint ein Habit in "Heute")

- Täglich, pro Woche, pro Monat: jeden Tag.
- Feste Wochentage und fester Monatstag: nur an den fälligen Tagen.
- Nie, wenn der Habit heute pausiert oder beendet ist. Ein pausierter Habit, der sonst fällig wäre, steht trotzdem in der Liste (5.2), zählt aber nicht als fällig.

### 3.3 Abhaken

- **Täglich mit Anzahl größer 1:** Counter mit Minus und Plus. Wert von 0 bis Zielanzahl.
- **Alle anderen:** Ein Feld zum Abhaken (bis Phase 7 ein Kreis, ab Phase 8 ein Quadrat, `CheckBox`). Wert 0 oder 1 pro Tag. Erneutes Tippen hebt das Abhaken auf.
- Abgehakt wird immer für den angezeigten Tag (5.2).

### 3.4 Tagesfortschritt ("5 von 16 · 31 %")

Gezählt werden alle am angezeigten Tag fälligen Habits (siehe 3.2).

| Rhythmus | Punkte | Erledigte Punkte |
|---|---|---|
| Täglich | Zielanzahl (3x täglich = 3) | Heutiger Wert, höchstens Zielanzahl |
| Feste Wochentage, fester Monatstag | 1 | 1, wenn heute abgehakt |
| Pro Woche, pro Monat | 1 | 1, wenn heute abgehakt **oder** Ziel im Fenster schon erfüllt |

Prozent = erledigte Punkte geteilt durch Punkte, gerundet auf ganze Zahl. Bei 0 Punkten wird "Heute nichts fällig" angezeigt.

### 3.5 Status (grün, gelb, rot)

**Pausentage** werden in allen Berechnungen übersprungen. Ein Fenster von 7 Tagen sind also die letzten 7 nicht pausierten Tage.

**Täglich**
- Grün: Ziel heute erreicht **oder** Ziel am letzten nicht pausierten Tag vor heute erreicht.
- Rot: sonst.
- Neu angelegt (heute erstellt): grün.
- Kein Gelb.

**Pro Woche / pro Monat**
- Grün: Summe der Erledigungen im Fenster ist mindestens die Zielanzahl.
- Gelb: Ziel ist erfüllt, würde aber ohne neue Erledigungen in den nächsten **2 Tagen** (Woche) bzw. **5 Tagen** (Monat) nicht mehr erfüllt sein, weil alte Erledigungen aus dem Fenster fallen.
- Rot: Ziel im Fenster nicht erfüllt.
- Neu angelegt: Das erste Fenster beginnt am Erstelltag. Bis es zu Ende ist, gibt es kein Rot. Ist das Ziel noch nicht erfüllt, gilt grün, in den letzten 2 bzw. 5 Tagen des ersten Fensters gelb.

**Feste Wochentage / fester Monatstag**
- Rot: Der letzte fällige Tag vor heute (nicht pausiert, nach Erstellung) wurde nicht abgehakt.
- Grün: sonst.
- Kein Gelb.

### 3.6 7 Tage Punkte

- Unter jedem Habit immer 7 kleine Punkte: die letzten 7 Tage, links der älteste, rechts der angezeigte Tag.
- Füllung: Wert des Tages geteilt durch Tagesziel (bei nicht täglichen Habits ist das Tagesziel 1). 0 = nur Umriss, Zwischenwerte = Habitfarbe mit steigender Deckkraft, 100 % = voll gefüllt.
- Tage vor der Erstellung: leerer Umriss wie ein Tag ohne Erledigung. Es sind also auch am Erstelltag alle 7 Punkte zu sehen. Status, Streaks und Statistik ändern sich dadurch nicht.
- Pausierte Tage: kleiner grauer Strich statt Punkt.
- Der angezeigte Tag (der Punkt ganz rechts) ist immer gut erkennbar: Er hat zusätzlich einen äußeren Ring (ab Phase 8 ein quadratischer Rahmen) in Habitfarbe mit verringerter Deckkraft und etwas Abstand zum Punkt. Das gilt für jede Füllung und auch für einen pausierten Tag. Der Ring bzw. Rahmen verändert Abstände und Ausrichtung der Punkte nicht.

### 3.7 Streaks und Statistik

- **Aktueller Streak:** Anzahl Tage am Stück bis heute, an denen der Status grün oder gelb war. Pausierte Tage werden übersprungen (unterbrechen nicht, zählen nicht mit). Bei festen Wochentagen und Monatstag zählen nur die fälligen Tage.
- **Längster Streak:** Größter Streak seit Erstellung.
- **Quote 30 Tage:** Anteil der letzten 30 Tage (ohne Pausen, ab Erstellung), an denen der Status grün oder gelb war. Bei festen Tagen nur fällige Tage.
- Alle Werte werden aus den Erledigungen berechnet, nicht gespeichert.

Präzisierung (Phase 5), wann ein Tag als erfüllt oder verpasst zählt:

- **Täglich:** erfüllt, wenn das Tagesziel erreicht ist. Sonst verpasst.
- **Pro Woche / pro Monat:** erfüllt, wenn das Fenster des Tages das Ziel erreicht (Status grün oder gelb). Im ersten Fenster nach der Erstellung ist ein unerfülltes Ziel weder erfüllt noch verpasst, der Tag wird nicht gewertet (wie "kein Rot" in 3.5).
- **Feste Wochentage / fester Monatstag:** nur fällige Tage werden gewertet, andere Tage unterbrechen den Streak nicht.
- **Heute noch offen:** Ein heute nicht erfüllter Tag ist noch nicht vorbei. Er unterbricht den Streak nicht und zählt erst mit, wenn er erreicht ist. Er geht auch nicht in die Quote ein.
- Tage vor der Erstellung werden nicht gewertet. Wenn es keinen gewerteten Tag gibt, ist der Streak 0 und die Quote leer ("–").
- **Beendete Habits:** Streaks und Quote werden bis zum Tag des Beendens gerechnet.
- **Längster Streak** ist die größte Folge erfüllter Tage seit Erstellung und damit nie kleiner als der aktuelle.
- **Pausentage** (Phase 6) werden übersprungen: sie unterbrechen keinen Streak, zählen nicht mit und gehören nicht zur Quote. Fenster und das erste Fenster nach der Erstellung zählen nur nicht pausierte Tage (3.5). Die Quote bleibt auf 30 Kalendertage bezogen, pausierte Tage darin entfallen.
- **Erledigungen** (ab Phase 11): Summe aller Erledigungen (`count`) des Habits von der Erstellung bis zum Statistiktag (heute bzw. Tag des Beendens), auch an Tagen, die später rückwirkend pausiert wurden. Ein 3x täglich Habit mit 3 vollen Tagen hat also 9.
- **Pausen** (ab Phase 11): Anzahl der Pausen dieses Habits, die am Statistiktag schon begonnen haben (laufende und vergangene). Geplante Pausen zählen nicht.
- **Beenden mit Historie** (Phase 6): Ab dem Tag des Beendens ist der Habit nicht mehr fällig. Tage davor bleiben mit ihrer Historie in Kalender, Statistik und in Heute an vergangenen Tagen.

### 3.8 Pausen

- Eine Pause hat einen Zeitraum (von, bis, beide Tage eingeschlossen) und gilt für einen oder mehrere ausgewählte Habits. Der Zeitraum darf auch in der Vergangenheit liegen: Die Tage werden dann rückwirkend nicht mehr gewertet.
- Während der Pause: steht der Habit ausgegraut mit der Kapsel "Pausiert" am Ende der Liste in "Heute" (5.2), lässt sich nicht abhaken, zählt nicht im Tagesfortschritt, Tage zählen nicht in Status und Statistik.
- Eine laufende Pause kann vorzeitig beendet werden (Enddatum = gestern). Bleibt dadurch kein Tag übrig (die Pause beginnt heute oder später), wird sie entfernt. Eine geplante Pause lässt sich so ebenfalls entfernen.
- Im Kalender im Tab ist ein Tag grau, wenn alle Habits, die es an dem Tag gibt, pausiert sind. Im Habit Detail ist jeder pausierte Tag des Habits grau.

### 3.9 Beenden

- Ein Habit wird im Bearbeiten Sheet beendet ("Habit beenden"). Ein Dialog fragt dann genau eins: **Historie behalten** oder **Historie löschen** (oder Abbrechen). Es gibt keine weitere Entscheidung und nichts dazu in den Einstellungen.
- **Historie behalten:** Der Habit erscheint ab diesem Tag nicht mehr in "Heute" (`endedAt` ist der Tag des Beendens). Im Kalender und in der Statistik bleibt er mit seiner Historie sichtbar. Ein Wiederaktivieren gibt es nicht.
- **Historie löschen:** Der Habit, alle seine Erledigungen und seine Zuordnung zu Pausen werden entfernt. Eine Pause, die dadurch keinen Habit mehr hat, wird ebenfalls entfernt. Das ist unwiderruflich, der Dialog sagt das.

### 3.10 Ändern eines Habits

Änderungen (z.B. Rhythmus) gelten für die gesamte Historie. Der Status wird immer mit den aktuellen Einstellungen neu berechnet.

---

## 4. Design

*Ab Phase 8 gilt dieses Designsystem. Die Nummern der Unterabschnitte haben sich dabei geändert (Bausteine jetzt 4.5, Rhythmus Zeile 4.5.1, Icons 4.6). Verweise in den Phasen 1 bis 7 beziehen sich auf die alte Nummerierung. Es ersetzt das frühere Glas Design (Farbverlauf, Liquid Glass Karten, SF Pro, Kreise, gedämpfte Icon Farben). Die Phasen 1 bis 7 beschreiben den damaligen Stand. Vorbild ist die Website von Hermes Agent (hermes-agent.nousresearch.com). Die Referenz Skizze mit den Mockups liegt unter https://claude.ai/artifact/6ZK2dXDRfcRrSLCJ6eBmKh.*

### 4.1 Grundprinzipien

1. **Blau ist die Marke.** Text, Linien und Bedienelemente sind blau (hell) bzw. Papier (dunkel), nie Schwarz oder Systemgrau. Abstufungen entstehen über Deckkraft derselben Farbe.
2. **Flach mit Haarlinien.** Keine Glaskarten, kein Farbverlauf, keine Schatten, keine Karte in der Karte. Zeilen und Abschnitte werden durch Weißraum und eine Haarlinie (0,5 pt) getrennt.
3. **Fast keine Rundung.** Ecken 0 bis 2 pt. Was bisher ein Kreis war, wird ein Quadrat: Abhaken, Counter Tasten, 7 Tage Punkte, Icon Fläche, Kalendertage, Statusmarke, Farbauswahl.
4. **Großer Größenkontrast.** Riesige, dünne Zahlen und Titel neben kleinen Labels. Mittlere Größen möglichst vermeiden.
5. **Großbuchstaben für Funktion.** Buttons, Labels, Rubriken und Meta Zeilen stehen in Versalien mit Laufweite. Inhalte (Habit Namen, Titel) stehen in normaler Schreibweise. Die Versalien entstehen in der Ansicht (`.textCase(.uppercase)`), die Texte im Code bleiben normal geschrieben, damit VoiceOver sie normal vorliest und Tests stabil bleiben.
6. **Umkehrung statt Grau.** Das Wichtigste steht invertiert, also Papier auf Blau: das Kopfband in Heute, der angezeigte Tag im Wochenstreifen, das erledigte Häkchen, das gewählte Segment.
7. **Habitfarbe nur als Tinte.** Sie färbt Icon, Häkchen, Counter Tasten, 7 Tage Punkte und Kalendertage, nie eine ganze Zeile. Nur das Habit Detail nutzt sie als Fläche (Band, 5.4).
8. **Ein Muster für alles:** Jede Eingabe öffnet ein Sheet von unten. Keine Alerts außer für Bestätigungen (z.B. "Habit beenden?").
9. **Dynamic Type bleibt.** Alle Schriften skalieren mit (4.3). Bei großer Schrift gelten weiter die Regeln aus Phase 7 (`AdaptiveStack`, nichts abgeschnitten).

### 4.2 Farben

Alle Farben stehen zentral in `Theme` bzw. `HabitColor`. In den Ansichten stehen keine Farbwerte.

**Marke**

| Name | Wert | Verwendung |
|---|---|---|
| `brand` | `#0000F2` | Markenblau. Kopfband in Heute (hell und dunkel), Tinte im hellen Modus |
| `paper` | `#F2F2F2` | Fläche im hellen Modus, Schrift auf Blau |
| `night` | `#000030` | Fläche im dunklen Modus (Blau, 80 % abgedunkelt) |
| `frame` | `#000091` | Blau, 40 % abgedunkelt. Kopfband in der kleinen Leiste beim Scrollen im dunklen Modus, falls nötig |

**Rollen** (hell / dunkel)

| Rolle | Hell | Dunkel |
|---|---|---|
| `background` | `paper` | `night` |
| `ink` (Text, Linien, Bedienelemente) | `brand` | `paper` |
| `inkSecondary` | `ink` mit 70 % | `ink` mit 70 % |
| `hairline` | `ink` mit 25 % | `ink` mit 20 % |
| `band` (Kopfband Heute) | `brand` | `brand` |
| `onBand` | `paper` | `paper` |
| `onBandSecondary` | `paper` mit 80 % | `paper` mit 80 % |

Die 70 % bzw. 80 % sind bewusst höher als in den Mockups (60 %), damit kleine Schrift den Kontrast 4,5 : 1 erreicht.

**Habitfarben**

Weiterhin 8 Farben mit denselben Schlüsseln wie bisher, damit gespeicherte Habits ihre Farbe behalten. Die Farbtöne folgen dem Farbkreis von Hermes (30 Grad Schritte). Im hellen Modus ist jede Farbe eine dunkle **Tinte** auf Papier (Kontrast mindestens 4,4 : 1), im dunklen Modus eine helle **Leuchtfarbe** auf Nachtblau (Kanalwerte nur 79, B5, F2).

| Schlüssel | Name (VoiceOver) | Tinte (hell) | Leuchtfarbe (dunkel) |
|---|---|---|---|
| `blue` | Blau | `#0000F2` | `#7979F2` |
| `violet` | Indigo | `#5C00D6` | `#B079F2` |
| `pink` | Pink | `#D1005F` | `#F279B5` |
| `red` | Rot | `#D10000` | `#F27979` |
| `orange` | Orange | `#B35500` | `#F2B579` |
| `yellow` | Ocker | `#806B00` | `#F2F279` |
| `green` | Grün | `#00804C` | `#79F2B5` |
| `teal` | Cyan | `#007A80` | `#79F2F2` |

- `HabitColor.color`: Tinte bzw. Leuchtfarbe, je nach Modus.
- `HabitColor.tint`: `color` mit 14 % Deckkraft, für die Icon Fläche.
- `HabitColor.onColor`: Vordergrund auf voller Habitfarbe (Häkchen, Text im Band des Detail) = `Theme.background`.
- Es gibt keine gedämpfte Variante mehr (`mutedColor` entfällt). Symbol und Kreisfläche von `HabitIconView` nutzen `color` und `tint`.
- Die Reihenfolge in der Farbauswahl folgt dem Farbkreis: Blau, Indigo, Pink, Rot, Orange, Ocker, Grün, Cyan.

**Statusfarben** (nur für die Statusmarke am Icon, 4.5)

| Status | Hell | Dunkel |
|---|---|---|
| Gelb | `#A88000` | `#F2C200` |
| Rot | `#E00000` | `#F27979` |

Für grün gibt es weiter keine Anzeige und keine Farbe. Die Werte erreichen als Grafik mindestens 3 : 1 gegen die Fläche.

**Grau für Pausen:** Pausierte Tage und pausierte Habits nutzen `ink` mit verringerter Deckkraft (Werte wie bisher in `Theme`), kein Systemgrau.

### 4.3 Schrift

Drei freie Schriften (SIL Open Font License 1.1, dürfen in die App eingebettet werden). Die Lizenzdateien liegen neben den Schriftdateien im Projekt.

| Schrift | Quelle | Schnitte | Ersetzt bei Hermes |
|---|---|---|---|
| Barlow Condensed | Google Fonts | ExtraLight (200), Regular (400), Medium (500) | Rules Gothic Condensed, Rules Condensed |
| Antonio | Google Fonts | Thin (100) | Rules Gothic Compressed |
| Geist Mono | Vercel (github.com/vercel/geist-font) bzw. Google Fonts | Regular (400), Medium (500) | Aeonik Fono |

**Rollen** in `Theme.Typography` (Größe in pt bei Standard Schriftgröße, `relativeTo` für Dynamic Type):

| Rolle | Schrift | Größe | `relativeTo` | Stil | Verwendung |
|---|---|---|---|---|---|
| `display` | Barlow Condensed ExtraLight | 58 | `.largeTitle` | Laufweite −2 %, Zeilenhöhe eng | Titel im Kopfband ("Heute"), Habit Name im Detail, Titel der Leerzustände |
| `numeral` | Antonio Thin | 76 | `.largeTitle` | Ziffern gleich breit (`monospacedDigit`) | Fortschritt "4/6", Streak im Detail |
| `stat` | Antonio Thin | 52 | `.title` | gleich breite Ziffern | Kennzahlen im Detail (`StatValue`), Streak in `HabitStatRow` |
| `title` | Barlow Condensed Regular | 21 | `.headline` | normal | Habit Name auf Karten und Zeilen, Sheet Titel |
| `label` | Barlow Condensed Medium | 14 | `.subheadline` | Versalien, Laufweite +10 % | Buttons, Segmente, Wochentage, Chips |
| `body` | Geist Mono Regular | 14 | `.body` | normal | Fließtext, Eingabefelder, Erklärungen in Leerzuständen |
| `meta` | Geist Mono Regular | 11 | `.caption` | Versalien, Laufweite +4 % | Rhythmus Zeile, Datum im Band, Abschnittsüberschriften, Beschriftungen unter Kennzahlen |

- Alle Rollen nutzen `Font.custom(_:size:relativeTo:)`, damit Dynamic Type wirkt. In Ansichten wird nur noch `Theme.Typography` verwendet, keine `.font(.headline)` usw. mehr.
- Laufweite und Versalien sind als Modifier gebündelt (z.B. `.labelStyle()` / `.metaStyle()` als View Extension), damit sie nicht an jeder Stelle einzeln stehen.
- **Einbinden:** Die Schriftdateien (`.ttf`) liegen in `Habitus/Design/Fonts/` und werden beim Start registriert (`CTFontManagerRegisterFontsForURL`, einmalig, z.B. in `FontRegistry.registerAll()` beim App Start und in Previews). Das Projekt erzeugt seine Info.plist selbst (`GENERATE_INFOPLIST_FILE`), deshalb kein `UIAppFonts` Eintrag. Fehlt eine Schrift, meldet ein Debug Assert das sofort.
- Die Systemschrift bleibt nur dort, wo das System sie selbst setzt (Tab Bar, Systemleisten in Sheets, Datumsauswahl, Alerts).

### 4.4 Formen, Linien, Abstände

| Wert | Festlegung |
|---|---|
| `cornerRadius` | 2 pt (Buttons, Chips, Segmentfeld). Quadrate (Häkchen, Punkte, Kacheln, Kalendertage) haben 0 pt. |
| `hairlineWidth` | 0,5 pt in `hairline` Farbe |
| `controlSize` | 36 pt (Häkchen, Icon Kachel, unverändert) |
| Counter Tasten | 26 pt Quadrat, 1 pt Rand in Habitfarbe |
| 7 Tage Punkte | 6 pt Quadrat, Abstand 3 pt |
| Abstände | `spacing`, `sectionSpacing`, `cardPadding` bleiben wie bisher |

Werte, die nur zum Glas Design gehörten (z.B. `cornerRadius` 24, `iconBackgroundOpacity`, `backgroundTop`, `backgroundBottom`), entfallen in Phase 8.

**Buttons** (`HermesButtonStyle`, ein Stil mit Varianten):

| Variante | Aussehen | Beispiel |
|---|---|---|
| `primary` | Fläche `ink`, Schrift `background`, Rolle `label` | "Ersten Habit anlegen", "Neue Pause" |
| `secondary` | Fläche `ink` mit 14 %, Schrift `ink` | "Pause beenden" |
| `onBand` | Fläche `onBand` mit 20 %, Schrift `onBand` | Plus im Kopfband, "Heute ›" |
| `text` | ohne Fläche, Schrift `ink`, Rolle `label` | "Sortieren", "Fertig" in Heute |
| `destructive` | wie `secondary`, Schrift und Fläche in Statusrot | "Habit beenden" |

Systemleisten in Sheets (Abbrechen, Sichern, Fertig) bleiben Systembuttons, getönt in `ink`. Ihr Liquid Glass Aussehen wird akzeptiert, eigene Glasflächen gibt es nicht.

### 4.5 Bausteine (einmal bauen, überall nutzen)

| Baustein | Inhalt |
|---|---|
| `PaperBackground` | Fläche `background` für alle Bildschirme und Sheets. Ersetzt `GlassBackground`. |
| `PaperSection` | Abschnitt mit Überschrift in Rolle `meta` und darunter dem Inhalt, oben eine Haarlinie. Keine Karte. Ersetzt `GlassSection` und `glassCard()`. |
| `HabitCard` | Flache Zeile ohne Karte, oben eine Haarlinie. Links `HabitIconView`, daneben Name (Rolle `title`), darunter die Rhythmus Zeile (4.5.1) und daneben die 7 Tage Punkte, rechts `CheckBox` oder `CounterControl`. Kein weiterer Text. Langes Drücken, Einsinken und VoiceOver Aktion wie bisher. |
| `CheckBox` | Quadrat 36 pt mit 1 pt Rand in Habitfarbe. Abgehakt: gefüllt mit Habitfarbe, Häkchen in `onColor`. Ersetzt `CheckCircle`. |
| `CounterControl` | Taste "−" (Quadrat 26 pt), Wert als "5/8" (Rolle `meta` in Medium, gleich breite Ziffern), Taste "+". Kein Ring mehr. Gesperrte Taste mit `disabledOpacity`. Gesamthöhe wie `CheckBox`. |
| `WeekDots` | 7 Quadrate (6 pt). Füllung wie 3.6 (Deckkraft nach Anteil), 0 = Habitfarbe mit 22 %. Der angezeigte Tag hat einen äußeren quadratischen Rahmen in Habitfarbe mit verringerter Deckkraft. Pausierte Tage: kurzer waagrechter Strich in `ink` mit Pausen Deckkraft. |
| `HabitIconView` | Quadratische Kachel (36 pt), Fläche `tint`, Symbol in `color`. Bei Status gelb oder rot oben rechts eine quadratische Statusmarke in Statusfarbe, mit schmalem freiem Rand in `background`. Bei grün keine Marke. |
| `Chip` | Kleine Kapsel mit 2 pt Ecken, Rolle `label` in klein (11 pt), Fläche `ink` mit 14 %. Für "Pausiert". Ersetzt `DayBadge`. |
| `DayHeader` | Das Kopfband in Heute (5.2): Datumszeile, Titel, Fortschritt, `SegmentBar`, `WeekStrip`. Ersetzt `ProgressHeader` und den bisherigen Kopf. |
| `SegmentBar` | Fortschritt als Reihe kurzer Balken (3 pt hoch, 3 pt Abstand), ein Balken pro Punkt (3.4), erledigte Punkte voll, offene mit 25 %. Bei mehr als 12 Punkten ein durchgehender Balken mit Füllung nach Prozent. Ersetzt `ProgressRing`. |
| `WeekStrip` | 7 Felder Mo bis So der Woche des angezeigten Tags (Rolle `label`). Der angezeigte Tag invertiert (Fläche `onBand`, Schrift `band`). Tage nach heute mit `calendarFutureOpacity` und nicht antippbar. Antippen eines anderen Tags wechselt dorthin (5.2). |
| `MonthCalendar` | Wie bisher (Monat mit Pfeilen, Grenzen, Wochentagszeile), aber jeder Tag ist ein Quadrat mit der Tageszahl (Rolle `meta`, ohne Versalien). Monatsname in Rolle `meta`. Heute mit äußerem quadratischem Rahmen. Einfärbung, Pausen, Zukunft, Tippen wie bisher. |
| `HabitStatRow` | Flache Zeile mit Haarlinie: `HabitIconView` ohne Statusmarke, Name, Rhythmus Zeile, rechts der aktuelle Streak als Zahl (Rolle `stat`, kleiner: 32 pt) mit "Tage" darunter (Rolle `meta`). Kein Flammensymbol. Antippen öffnet das Habit Detail. |
| `StatValue` | Eine Kennzahl: großer Wert (Rolle `stat`), darunter die Beschriftung (Rolle `meta`). |
| `SegmentedChoice` | Segmentfeld mit 0,5 pt Rahmen in `ink`, Segmente in Rolle `label`, gewähltes Segment invertiert (Fläche `ink`, Schrift `background`). |
| `WeekdayPicker` | 7 Quadrate M D M D F S S, gewählt invertiert. |
| `ColorPicker` (Farbauswahl im Sheet) | 8 Quadrate (28 pt) in Habitfarbe, gewählt mit äußerem Rahmen in `ink`. |
| `EmptyState` | Titel in Rolle `display` (kleiner: 40 pt), Erklärung in `body`, Button `primary`. |
| `PauseRow` | Flache Zeile mit Haarlinie, Zeitraum in `title`, Habits in `meta`, Button rechts. |

#### 4.5.1 Rhythmus Zeile

Kleine Zeile in Rolle `meta` (Versalien) und Farbe `inkSecondary` unter dem Namen. Inhalt wie bisher, mit drei Änderungen:

- Steht ein **Zusatz** am Habit (ab Phase 10), steht er vorne, getrennt mit " · ".
- Wochentage werden mit " · " statt ", " getrennt.
- Die Texte im Code bleiben normal geschrieben, die Versalien entstehen in der Ansicht.

| Rhythmus | Text (im Code) | Anzeige |
|---|---|---|
| Täglich, Anzahl 1 | "Täglich" | TÄGLICH |
| Täglich, Anzahl n größer 1 | "n pro Tag" | 8 PRO TAG |
| Woche, Anzahl | "erledigt von Ziel diese Woche" | 1 VON 3 DIESE WOCHE |
| Monat, Anzahl | "erledigt von Ziel diesen Monat" | 1 VON 1 DIESEN MONAT |
| Feste Wochentage | Kurznamen der Tage | MO · MI · FR |
| Fester Monatstag | "Am n. des Monats" | AM 15. DES MONATS |
| Mit Zusatz | "Zusatz · Rhythmus" | 20 MIN · TÄGLICH |

### 4.6 Icons

Auswahl aus ca. 30 kuratierten SF Symbols wie bisher (z.B. figure.run, drop.fill, book.fill, bed.double.fill, leaf.fill, dumbbell.fill, brain.head.profile, pills.fill, cup.and.saucer.fill, figure.walk, music.note, pencil, house.fill, cart.fill, heart.fill). Sie stehen in `color` auf der Kachel aus 4.5. Schnitt der Symbole: `.regular`, damit sie zur dünnen Schrift passen.

### 4.7 Bewegung

Unverändert: Tageswechsel, Einsinken beim langen Drücken, Rutschen erledigter Habits, Reduce Motion nur Überblenden. Neue Übergänge (z.B. Einblenden der kleinen Leiste in Heute) sind kurz (ca. 0,1 bis 0,2 s) und bei Reduce Motion ohne Bewegung.

---

## 5. Bildschirme

### 5.1 Tab Bar (3 Tabs)

1. **Heute** (Symbol: checkmark.circle)
2. **Kalender** (Symbol: calendar)
3. **Einstellungen** (Symbol: gearshape)

Ab Phase 8: Die Tab Bar bleibt die des Systems, getönt in `ink`. Hintergrund der Bildschirme ist `PaperBackground`.

### 5.2 Heute

- **Kopfband (ab Phase 9, ersetzt den nächsten Punkt):** Oben ein Band in Markenblau (`band`, hell und dunkel gleich), randlos bis unter die Statusleiste. Es gibt in Heute keine Navigationsleiste mehr. Das Band (`DayHeader`) enthält von oben nach unten:
  1. **Datumszeile** (Rolle `meta`, `onBandSecondary`): links Wochentag kurz, Datum und Kalenderwoche ("So · 11. Okt · KW 41"), rechts der Plus Button (Variante `onBand`, Quadrat mit Plus Symbol, VoiceOver "Neuer Habit"). Die Kalenderwoche ist die ISO Kalenderwoche des angezeigten Tags.
  2. **Titel** (Rolle `display`): der angezeigte Tag relativ zu heute: "Heute", "Gestern", "Vorgestern", sonst "Vor n Tagen" (wie bisher `RelativeDay`). Die bisherige Kapsel neben dem Datum entfällt, weil der Titel das schon sagt. An vergangenen Tagen steht rechts auf Höhe des Titels der Button "Heute ›" (Variante `onBand`), der wie bisher animiert zu heute springt.
  3. **Fortschritt:** links groß "erledigte Punkte/Punkte" (Rolle `numeral`, z.B. "4/6"), daneben klein untereinander "Erledigt" und die Prozent ("67 %") in Rolle `meta`. Zählung wie 3.4, nur die Darstellung ist neu. Bei 0 Punkten steht statt Zahl und Balken "Heute nichts fällig" (Rolle `title`). Darunter die `SegmentBar`.
  4. **Wochenstreifen** (`WeekStrip`): Mo bis So der ISO Woche des angezeigten Tags, der angezeigte Tag invertiert. Antippen eines vergangenen Tags oder von heute wechselt dorthin, mit derselben Animation wie Wischen (Richtung nach Datum). Tage nach heute sind blass und nicht antippbar. Wischen über eine Wochengrenze zeigt im Streifen die neue Woche. VoiceOver liest jeden Tag als vollständiges Datum, der angezeigte Tag ist als ausgewählt markiert.
- **Listenkopf (ab Phase 9):** Direkt unter dem Band eine Zeile in Rolle `meta`: links die Anzahl der Zeilen in der Liste ("6 Habits", Einzahl "1 Habit", pausierte zählen mit), rechts der Button "Sortieren" bzw. im Sortiermodus "Fertig" (Variante `text`). Er ersetzt den Button oben links.
- **Scrollen (ab Phase 9):** Das Band scrollt mit dem Inhalt weg. Ist es aus dem Bild gescrollt (Schwelle `Theme.barTitleScrollOffset`), erscheint oben eine schmale Leiste in `band` mit "Heute · 4/6" (Titel und Fortschritt, Rolle `label`) links und dem Plus Button rechts. Sie ersetzt den kleinen Navigationstitel. Wischen und Tageswechsel funktionieren in beiden Zuständen.
- *Bis Phase 8:* **Kopfbereich ohne Karte:** Oben steht das Datum des angezeigten Tags im Stil eines großen Navigationstitels (Large Title einer `NavigationStack`: Schrift, Gewicht, Einzug links). Titel ist der Wochentag ("Donnerstag"), darunter als Untertitel das Datum ("8. Oktober"). Beim Scrollen verhält sich der Titel wie ein Large Title und wird klein in der Leiste angezeigt. Darunter der `ProgressHeader`, ebenfalls ohne Karte und ohne Glas direkt auf dem Hintergrund. Neben dem Datum steht eine kleine Kapsel: "Heute" in Akzentfarbe, an vergangenen Tagen neutral "Gestern", "Vorgestern" oder "Vor n Tagen". In der kleinen Leiste steht sie hinter dem Datum.
- **Tag wechseln:** Waagrechtes Wischen im Inhalt von Heute (Kopfbereich und Liste) nach rechts zeigt den vorherigen Tag, nach links den nächsten Tag. Senkrechtes Scrollen, Abhakkreis und Counter funktionieren weiter wie bisher. Weiter als bis heute geht es nicht, zukünftige Tage sind nicht erreichbar. Beim Start der App, beim Zurückkehren in die App und beim Tageswechsel um Mitternacht zeigt die Ansicht wieder heute.
- **Animation beim Tageswechsel:** Titel, Untertitel, Fortschritt und Liste gleiten in Wischrichtung heraus und der neue Tag gleitet von der anderen Seite herein (zurück in die Vergangenheit: Inhalt kommt von links, vorwärts: von rechts), kurz und weich (ca. 0,3 s). Wird nicht gewechselt, weil heute schon erreicht ist, federt der Inhalt nur kurz zurück. Der neue Tag federt dabei Kopf und Karten nacheinander (leicht versetzt) herein. Bei "Bewegung reduzieren" (Reduce Motion) nur Überblenden. Das Zurückspringen auf heute (Start, Rückkehr, Mitternacht) ist nicht animiert.
- Für den angezeigten Tag gelten Fälligkeit, Fortschritt, Abhaken, Status und 7 Tage Punkte so, als wäre dieser Tag heute. Tage vor der Erstellung eines Habits und pausierte Tage verhalten sich wie in Abschnitt 3 beschrieben.
- *Bis Phase 8:* Oben rechts: Plus Button für neuen Habit. Zeigt die Ansicht einen vergangenen Tag, steht in der Datumszeile rechts (auf einer Ebene mit Datum und Kapsel, nicht in der Leiste) ein Button "Heute >" mit kleinem Chevron, der (animiert, wie ein Wischen nach vorn) zu heute zurückspringt. Auf heute ist er nicht zu sehen. Oben links: Button "Sortieren".
- Darunter eine einzige Liste mit `HabitCard`s, ohne Abschnitte und ohne Überschriften.
- **Pausierte Habits** (3.8) stehen am Ende der Liste, nach den erledigten, in der gespeicherten Reihenfolge: Icon und Name ausgegraut, daneben die Kapsel "Pausiert" (wie im Sheet "Neue Pause"), Abhakkreis bzw. Counter ausgegraut und nicht bedienbar. Langes Drücken öffnet weiter das Bearbeiten Sheet. Sie zählen nicht im Fortschritt. Dasselbe gilt im Sheet "Tag bearbeiten" für den gewählten Tag.
- **Reihenfolge:** Oben die offenen Habits, darunter die erledigten. Innerhalb beider Teile gilt die gespeicherte Reihenfolge (`sortOrder`, dann `createdAt`). Erledigt heißt: Am angezeigten Tag ist das Tagesziel erreicht, also Abhakkreis abgehakt bzw. Counter voll. Ein Wochen oder Monats Habit, dessen Fenster erfüllt ist, der am angezeigten Tag aber nicht abgehakt ist, bleibt oben. Wird ein Habit erledigt, rutscht er animiert nach unten, wird es wieder aufgehoben, rutscht er animiert zurück an seinen Platz.
- **Bearbeiten:** Festes Drücken (ca. 0,6 s) auf die Karte (nicht auf Kreis/Counter) öffnet das Bearbeiten Sheet. Die Karte sinkt dabei ein und gibt ein haptisches Signal, beim Auslösen ein festeres. Einfaches Tippen auf die Karte tut nichts. Für VoiceOver gibt es auf der Karte die Aktion "Bearbeiten".
- **Sortieren:** Im Sortiermodus Habits per Drag and Drop verschieben. Es gibt eine Reihenfolge für alle Habits, sie wird gespeichert. Auch im Sortiermodus stehen erledigte Habits unten. Verschieben lassen sich nur die offenen Habits, die erledigten sind im Sortiermodus nicht verschiebbar. Nach dem Verschieben bekommen die offenen Habits in ihrer neuen Reihenfolge die vorderen Plätze in `sortOrder`, die erledigten folgen dahinter in ihrer bisherigen Reihenfolge.

### 5.3 Sheet "Habit anlegen / bearbeiten"

Felder in dieser Reihenfolge:
1. Name
2. **Zusatz** (ab Phase 10): einzeiliges Textfeld unter dem Namen, optional, Platzhalter "z.B. 20 Min", höchstens 24 Zeichen (weitere Eingaben werden nicht angenommen). Leerzeichen am Anfang und Ende werden beim Speichern entfernt, ein leerer Zusatz wird nicht angezeigt.
3. Icon (Raster)
4. Farbe (8 Kreise, ab Phase 8 8 Quadrate in der Reihenfolge des Farbkreises, 4.2)
5. Rhythmus (Segmente: Täglich, Woche, Monat) und passende Einstellung darunter:
   - **Täglich:** Anzahl pro Tag als Stepper.
   - **Woche:** zweites Segmentfeld "Anzahl" / "Wochentage". Bei Anzahl ein Stepper ("2x pro Woche"), bei Wochentage 7 Kreise M D M D F S S.
   - **Monat:** zweites Segmentfeld "Anzahl" / "Monatstag". Bei Anzahl ein Stepper ("1x pro Monat"), bei Monatstag die Auswahl 1 bis 31.
   - Beim Bearbeiten eines bestehenden Habits sind Rhythmus und Variante passend vorausgewählt (z.B. Wochentage Habit: Woche + Wochentage).
6. Nur beim Bearbeiten, ganz unten: "Habit beenden" (Dialog: Historie behalten oder löschen, siehe 3.9)

Es gibt keine Auswahl von Tagesgruppen (Morgens, Mittags, Abends). Alle Habits gelten ganztägig.

Speichern nur möglich, wenn Name nicht leer.

### 5.4 Kalender

- Monatskalender mit Pfeilen: Der Kalender zeigt einen Monat, mit Pfeil links (voriger Monat) und Pfeil rechts (nächster Monat) rechts neben dem Monatsnamen. Er beginnt beim aktuellen Monat, einen späteren Monat gibt es nicht (Pfeil rechts ist dort deaktiviert). Er reicht mindestens 3 Monate zurück, sonst bis zum Monat des ältesten Habits (dort ist der Pfeil links deaktiviert). Unter dem Monatsnamen steht die Wochentagszeile Mo bis So. *(Ersetzt nach Phase 5.1 den durchgehend scrollbaren Kalender aus Phase 4.)*
- **Gleicher Kalender überall:** Der Kalender im Tab und der Kalender im Habit Detail sind derselbe Baustein mit demselben Aussehen und denselben Pfeilen. Unterschiede nur: Farbe (Akzentfarbe bzw. Habitfarbe), Tippen (im Tab öffnet ein Tag das Sheet, im Detail sind die Tage nicht antippbar) und die Grenzen (im Tab siehe oben, im Detail Erstellmonat bis aktueller Monat, bei beendeten Habits bis Monat des Beendens).
- Jeder Tag eingefärbt nach Tagesfortschritt (3.4) an diesem Tag: keine Farbe bei 0 %, dann zunehmend kräftigere Akzentfarbe bis 100 %. Zukünftige Tage blass.
- Tag antippen öffnet Sheet "Tag bearbeiten": dieselbe Liste wie "Heute" für diesen Tag, mit Abhaken und Counter. Zukünftige Tage sind nicht antippbar.
- Darunter Liste aller Habits (aktive zuerst, dann beendete) mit aktuellem Streak.
- **Habit Detail ab Phase 11** (ersetzt den nächsten Punkt): Habit antippen öffnet das Detail als Sheet. Oben ein randloses **Band in Habitfarbe** (Fläche `color`, Schrift `onColor`), wie das Kopfband in Heute, nur in der Farbe des Habits:
  1. Zeile oben: links "Fertig" (schließt), rechts "Bearbeiten" (Variante `onBand` bzw. `text` in `onColor`). "Bearbeiten" öffnet das Sheet "Habit bearbeiten" (5.3) über dem Detail. Nach dem Sichern zeigt das Detail die neuen Werte. Nach "Historie löschen" schließen sich beide Sheets. Nach "Historie behalten" bleibt das Detail offen und zeigt den beendeten Habit. Bei einem beendeten Habit gibt es "Bearbeiten" nicht.
  2. Meta Zeile (Rolle `meta`): die Rhythmus Zeile (4.5.1, mit Zusatz). Bei beendeten Habits stattdessen "Beendet am 3. Okt".
  3. Name in Rolle `display`.
  4. Aktueller Streak groß (Rolle `numeral`), daneben "Tage in Folge" (Einzahl "Tag in Folge") in Rolle `meta`.
  
  Darunter auf `background` ein Raster aus 2 × 2 Kennzahlen (`StatValue`), getrennt durch Haarlinien: **Quote 30 Tage** ("86 %" bzw. "–"), **Längster Streak**, **Erledigungen** (Summe aller Erledigungen, 3.7) und **Pausen** (Anzahl der Pausen, 3.7). Darunter der `MonthCalendar` in Habitfarbe wie bisher. Kein Icon im Detail, kein Titel "Habit Detail" in einer Leiste.
- *Bis Phase 10:* Habit antippen öffnet als Sheet das **Habit Detail**: Icon, Name, Rhythmus, eigener Monatskalender (nur dieser Habit, Tage mit Erledigung in Habitfarbe, bei Tagesziel größer 1 mit Teilfüllung), aktueller Streak, längster Streak, Quote 30 Tage (3.7). Der Monatskalender ist derselbe wie im Tab (siehe oben).
- Unter dem Monatskalender im Tab steht die Habit Liste. Der ganze Tab scrollt senkrecht, der Kalender selbst wird nur mit den Pfeilen gewechselt.

### 5.5 Einstellungen

- **Pausen:** Liste der laufenden und geplanten Pausen ("Läuft", "Geplant"), vergangene stehen nicht darin. Button "Neue Pause": Sheet mit Zeitraum (Startdatum, Enddatum, auch in der Vergangenheit) und Mehrfachauswahl der aktiven Habits. Habits, die im gewählten Zeitraum schon pausiert sind, sind deutlich markiert (Kapsel "Pausiert", ausgegraut, mit dem Zeitraum darunter), lassen sich aber trotzdem auswählen. Laufende Pause kann beendet werden ("Pause beenden"), geplante entfernt ("Pause entfernen").
- Beendete Habits haben keinen Platz in den Einstellungen (3.9).
- **Entwickler** (nur in Debug Builds sichtbar): "Testdaten erzeugen" und "Alle Daten zurücksetzen". Startargumente für Vorschauen und UI Tests: `-HabitusSampleData` und dazu `-HabitusSamplePauses` (Lesen war vorgestern und gestern pausiert, Sport hat eine geplante Pause ab übermorgen).

---

## 6. Datenmodell (SwiftData)

Das Modell wurde in Phase 1 vollständig angelegt. In Phase 10 kommt `detail` an `Habit` dazu (leichte Migration, Feld mit Standardwert). In Phase 3.1 entfallen `timeSlots` und `sortIndex`, neu ist `sortOrder`. Das ist eine leichte Migration (Feld entfernt, Feld mit Standardwert hinzugefügt), vorhandene Habits und Erledigungen bleiben erhalten.

**Habit**
- `id: UUID`
- `name: String`
- `iconName: String`
- `colorKey: String` (Schlüssel aus der Palette)
- `rhythm: Rhythm` (enum: daily, weekly, monthly, weekdays, monthDay)
- `targetCount: Int` (pro Tag bei daily, pro Fenster bei weekly/monthly, sonst 1)
- `weekdays: [Int]` (1 = Montag bis 7 = Sonntag)
- `monthDay: Int?`
- `detail: String` (Zusatz, ab Phase 10, Standard "", höchstens 24 Zeichen, 5.3)
- `sortOrder: Int` (Reihenfolge in der Heute Ansicht, Standard 0, bei Gleichstand nach `createdAt`)
- `createdAt: Date`
- `endedAt: Date?`
- Beziehung: `completions: [Completion]`

**Completion**
- `id: UUID`
- `day: Date` (Tagesbeginn)
- `count: Int`
- Beziehung: `habit: Habit`
- Pro Habit und Tag höchstens ein Eintrag. Bei count 0 wird der Eintrag gelöscht.

**Pause**
- `id: UUID`
- `startDay: Date`
- `endDay: Date`
- Beziehung: `habits: [Habit]`

**HabitEngine** (reiner Swift Code, keine SwiftUI, keine SwiftData Abhängigkeit in den Berechnungen)
- `isDue(habit, day)`
- `points(habit, day)` und `donePoints(habit, day)`
- `dayProgress(habits, day)`
- `status(habit, day)`
- `weekDots(habit, day)` (immer 7 Punkte, siehe 3.6)
- `currentStreak`, `longestStreak`, `rate30`
- ab Phase 9: `isoWeek(day)` (Kalenderwoche nach ISO 8601) und `weekStrip(day, today)` (7 Tage Mo bis So der Woche von `day`, je mit Datum und Zustand: angezeigt, antippbar, Zukunft)
- ab Phase 11: `totalCompletions` und `pauseCount` (3.7), als Teil von `statistics`
- Nimmt das "heutige" Datum immer als Parameter entgegen, damit Tests mit festen Daten möglich sind.

---

## 7. Phasen

Jede Phase baut auf der vorherigen auf und ergibt eine App, die auf dem iPhone läuft.

**Für alle Phasen gilt zusätzlich als Definition of Done:**
- [ ] Projekt baut in Xcode ohne Fehler und ohne Warnungen.
- [ ] App startet auf dem iPhone 16 Pro (oder Simulator) ohne Absturz.
- [ ] Alle Unit Tests sind grün.
- [ ] Hell und Dunkel sehen korrekt aus.
- [ ] Nur Bausteine aus dem Designsystem verwendet.
- [ ] Die KI hat eine kurze Testanleitung für mich geschrieben.

---

### Phase 1: Grundgerüst und erster Habit

**Ziel:** Ich kann einfache tägliche Habits anlegen und abhaken. Die App sieht schon aus wie die fertige App.

**Umfang**
- Xcode Projekt (SwiftUI, SwiftData, iOS 26) mit Ordnern: Models, Engine, Design, Views, Tests.
- Vollständiges Datenmodell (Abschnitt 6).
- Designsystem: Farben, `GlassBackground`, `HabitCard` (vorerst ohne Statuspunkt und Punkte), `CheckCircle`.
- Tab Bar mit 3 Tabs. Kalender und Einstellungen zeigen vorerst nur einen Platzhalter.
- Heute Ansicht: Datum, einfache Liste aller Habits (noch ohne Gruppen).
- Sheet "Habit anlegen" mit Name, Icon, Farbe. Rhythmus ist fest "1x täglich".
- Abhaken mit `CheckCircle`, Wert wird gespeichert.

**Definition of Done**
- [ ] Ich kann einen Habit mit Name, Icon und Farbe anlegen.
- [ ] Ich kann ihn abhaken und wieder aufheben.
- [ ] Nach Beenden und Neustart der App sind Habits und Häkchen noch da.
- [ ] Am nächsten Tag sind alle Häkchen leer.
- [ ] Hintergrundverlauf und Glaskarten sind sichtbar.

---

### Phase 2: Mehrfach täglich, Tagesgruppen, Fortschritt

**Ziel:** Die Heute Ansicht ist für tägliche Habits komplett.

**Umfang**
- Zielanzahl pro Tag (1 bis 10) im Sheet.
- `CounterControl` für Habits mit Ziel größer 1.
- Tagesgruppen im Sheet (Mehrfachauswahl) und Abschnitte in Heute. *(In Phase 3.1 wieder entfernt.)*
- Gleicher Wert in allen Gruppen eines Habits. *(In Phase 3.1 wieder entfernt.)*
- `ProgressHeader` mit Tagesfortschritt (3.4) für tägliche Habits.
- `WeekDots` (3.6).
- Karte antippen öffnet Bearbeiten Sheet. *(Ab Phase 3.2 langes Drücken.)*
- Erste `HabitEngine` Funktionen mit Unit Tests: `points`, `donePoints`, `dayProgress`, `weekDots`.

**Definition of Done**
- [ ] Ein 3x täglich Habit zeigt den Counter, Minus geht nicht unter 0, Plus nicht über 3.
- [ ] Der Ring im Counter füllt sich mit jedem Plus.
- [ ] Ein Habit in Morgens und Abends zeigt in beiden Abschnitten denselben Wert. *(In Phase 3.1 entfallen.)*
- [ ] Bei 2 Habits (1x und 3x täglich) und 2 Erledigungen steht "2 von 4 · 50 %".
- [ ] Die 7 Punkte werden bei Teilerledigung heller, bei Ziel voll gefüllt.
- [ ] Leere Abschnitte sind ausgeblendet. *(In Phase 3.1 entfallen.)*
- [ ] Unit Tests für Fortschritt und Punkte vorhanden und grün.

---

### Phase 3: Rhythmen und Status

**Ziel:** Alle Rhythmen funktionieren, inklusive rollierender Fenster und Ampelstatus. Das ist die wichtigste Logik der App.

**Umfang**
- Rhythmen Woche, Monat, Wochentage, Monatstag im Sheet (5.3).
- Fälligkeit (3.2), Zählung im Fortschritt (3.4).
- Status (3.5) als `StatusDot` auf der Karte. *(Ab Phase 3.2 Ring um das Icon.)*
- Text "x/y im Fenster" bei Woche und Monat. *(In Phase 3.1 wieder entfernt.)*
- Einstellungen > Entwickler: "Testdaten erzeugen" (legt Beispielhabits mit 60 Tagen Historie an) und "Alle Daten zurücksetzen".
- Umfangreiche Unit Tests für `isDue` und `status` mit festen Daten.

**Pflicht Testfälle (als Unit Tests)**
- 1x pro Woche, erledigt Freitag, heute Montag: grün.
- 1x pro Woche, erledigt vor 5 Tagen: gelb (fällt in 2 Tagen raus).
- 1x pro Woche, erledigt vor 7 Tagen: rot.
- 3x pro Woche, 1x erledigt: 1 Punkt im Fortschritt, offen.
- 2x pro Woche, im Fenster erfüllt, heute nicht abgehakt: Punkt zählt als erledigt.
- 1x pro Monat, erledigt vor 26 Tagen: gelb.
- Montag fest, heute Dienstag, Montag nicht abgehakt: rot.
- Montag fest, heute Mittwoch: Habit erscheint nicht in Heute.
- Monatstag 31, Februar: am letzten Februartag fällig.
- Täglich, gestern erreicht, heute noch nicht: grün.
- Täglich, gestern verpasst, heute noch nicht: rot.
- Neu angelegter Wochen Habit, Tag 3: grün; Tag 6 ohne Erledigung: gelb.

**Definition of Done**
- [ ] Alle Rhythmen lassen sich anlegen und bearbeiten.
- [ ] Alle Pflicht Testfälle als Unit Tests vorhanden und grün.
- [ ] Mit Testdaten zeigt die Heute Ansicht grüne, gelbe und rote Habits.
- [ ] Habits an festen Tagen erscheinen nur an ihren Tagen.

---

### Phase 3.1: Vereinfachung Heute und Sheet

**Ziel:** Die Heute Ansicht und das Sheet werden einfacher, und ich kann in Heute zwischen Tagen wechseln. Alles, was dadurch wegfällt, ist vollständig aus Code, Tests und Daten entfernt.

**Umfang**
- **Tagesgruppen entfernen:** Kein Morgens, Mittags, Abends, Ganztägig mehr, weder im Sheet noch in Heute. Heute zeigt eine einzige Liste ohne Abschnitte (5.2, 5.3).
- **Datenmodell:** `timeSlots` und `sortIndex` aus `Habit` entfernen, `sortOrder: Int` (Standard 0) hinzufügen (6). Heute sortiert nach `sortOrder`, dann `createdAt`. Vorhandene Daten bleiben bei der Migration erhalten.
- **7 Tage Punkte:** Tage vor der Erstellung als leerer Umriss statt unsichtbar, also immer 7 Punkte (3.6).
- **Tag wechseln per Wischen** auf der Datumskarte in Heute, nur zwischen vergangenen Tagen und heute (5.2). *(Ab Phase 3.2 ohne Karte, Wischen im ganzen Inhalt.)*
- **Rhythmus im Sheet:** Nur noch Täglich, Woche, Monat. Wochentage und Monatstag als Variante unter Woche bzw. Monat (5.3). Das Datenmodell (`Rhythm` mit fünf Fällen) und die `HabitEngine` bleiben unverändert.
- **"x/y im Fenster" entfernen** aus `HabitCard` und Heute (4.3). `windowProgress` in der `HabitEngine` bleibt, weil der Tagesfortschritt es braucht (3.4).
- Testdaten (Einstellungen > Entwickler) ohne Tagesgruppen.

**Aufräumen (Pflicht, keine Überbleibsel)**
- Löschen: enum `TimeSlot`, `TodaySection` (Datei), `TodaySectionTests` (Datei), die Tagesgruppen Auswahl im Sheet (`slotList`, `toggle`, State `timeSlots`), `windowText` in `HabitCard` samt Preview Wert, `WeekDot.hidden` (Fall und Darstellung in `WeekDots`).
- `SectionTitle` und `GlassSection` nur behalten, wenn sie danach noch verwendet werden, sonst löschen.
- `Rhythm.title` so anpassen, dass es zu den drei Segmenten bzw. Varianten passt. Keine ungenutzten Beschriftungen zurücklassen.
- Tests anpassen oder löschen, die Tagesgruppen, Abschnitte, "im Fenster" Texte oder unsichtbare Punkte prüfen (u.a. `TodayPhase2UITests`, `TodayPhase3UITests`, `HabitEngineTests`, `CompletionStorageTests`, `SampleDataTests`). Unit Tests für `windowProgress` bleiben.
- Entfernte Dateien auch aus `Habitus.xcodeproj` entfernen.
- Kommentare und Accessibility Identifier, die sich auf Tagesgruppen, Abschnitte oder "im Fenster" beziehen, entfernen oder anpassen.
- Abschluss: Eine Suche im Projekt nach `TimeSlot`, `timeSlots`, `sortIndex`, `TodaySection`, `Morgens`, `Mittags`, `Abends`, `Ganztägig`, `windowText`, `window-` (Accessibility Identifier) und `.hidden` (bei `WeekDot`) findet nichts mehr, ebenso keine Anzeige im Format "x/y im Fenster". Ausnahme ist nur diese Spezifikation. Fachliche Kommentare zum Fenster (z.B. "Ziel im Fenster erfüllt") dürfen bleiben.

**Pflicht Testfälle**
- Unit Test: Habit heute erstellt, `weekDots` liefert 7 Punkte, die 6 Tage davor mit Füllung 0.
- Unit Test: Heute Liste sortiert nach `sortOrder`, bei Gleichstand nach `createdAt`.
- UI Test: Wischen nach rechts auf der Datumskarte zeigt das Datum von gestern, Wischen nach links wieder heute, ein weiteres Wischen nach links bleibt bei heute.
- UI Test: An einem vergangenen Tag abhaken ändert den Wert dieses Tags, nicht den von heute.
- UI Test: Sheet zeigt genau die Segmente Täglich, Woche, Monat. Unter Woche lassen sich Anzahl und Wochentage wählen, unter Monat Anzahl und Monatstag. Speichern ergibt den richtigen Rhythmus.
- UI Test: Bearbeiten eines Wochentage Habits öffnet mit Woche + Wochentage, eines Monatstag Habits mit Monat + Monatstag.
- UI Test: Ein Wochen Habit zeigt keinen "im Fenster" Text.

**Definition of Done**
- [ ] Im Sheet gibt es keine Tagesgruppen mehr, in Heute keine Abschnitte und Überschriften.
- [ ] Ein neu angelegter Habit zeigt sofort alle 7 Punkte (6 leer, heute je nach Wert).
- [ ] Wischen auf der Datumskarte wechselt die Tage. Datum, Fortschritt, Liste, Häkchen, Status und Punkte passen zum angezeigten Tag. Über heute hinaus geht es nicht.
- [ ] Nach Verlassen und Zurückkehren in die App zeigt Heute wieder heute.
- [ ] Im Sheet gibt es nur Täglich, Woche, Monat. Wochentage und Monatstag sind unter Woche bzw. Monat auswählbar. Bestehende Habits aller fünf Rhythmen lassen sich korrekt bearbeiten.
- [ ] Auf keiner Karte steht "x/y im Fenster". Der Tagesfortschritt zählt Wochen und Monats Habits weiterhin wie in 3.4.
- [ ] Nach dem Update sind vorhandene Habits und Erledigungen noch da (kein Absturz bei der Migration).
- [ ] Die Suche aus "Aufräumen" findet nichts mehr, es gibt keine ungenutzten Dateien, Typen oder Funktionen.

---

### Phase 3.2: Heute aufräumen und lebendiger machen

**Ziel:** Heute wirkt ruhiger und klarer: kein Kartenkopf mehr, Status direkt am Icon, erledigte Habits rutschen weg, und ich sehe beim Wischen sofort, dass sich der Tag geändert hat. Alles, was dadurch wegfällt, ist vollständig aus Code und Tests entfernt.

**Umfang**
- **Animation beim Tageswechsel** in Heute: Inhalt gleitet in Wischrichtung, Reduce Motion nur Überblenden, kein Wechsel über heute hinaus mit kurzem Zurückfedern (5.2).
- **Kopfbereich ohne Karte:** Datum als Large Title (Wochentag als Titel, Datum als Untertitel) wie bei einer `NavigationStack`, beim Scrollen klein in der Leiste. `ProgressHeader` ohne Glaskarte darunter (4.2, 4.3, 5.2). Ob dafür der echte Navigationstitel oder ein eigener Kopf im selben Stil genutzt wird, ist frei, solange Optik, Scrollverhalten und Animation stimmen.
- **Wischen** wechselt den Tag im ganzen Inhalt von Heute statt nur auf der früheren Datumskarte (5.2).
- **Bearbeiten per langem Drücken** auf die Karte statt per Tippen, plus VoiceOver Aktion "Bearbeiten" (5.2).
- **Erledigte Habits nach unten**, animiert, wieder aufgehoben zurück an ihren Platz (5.2). Die Reihenfolge wird ohne Oberfläche berechnet (offene zuerst, dann erledigte, jeweils `sortOrder`, dann `createdAt`) und ist per Unit Test prüfbar. `sortOrder` wird dabei nicht verändert.
- **Status als Ring um das Icon** statt Statuspunkt neben dem Namen (4.2, 4.3). *(In Phase 3.3 ersetzt durch die Statusmarke.)* Der Ring liegt außen um die Kreisfläche von `HabitIconView`, Strichstärke und Abstand als Werte in `Theme`. Statuslogik (3.5) bleibt unverändert.
- **Angezeigter Tag in den 7 Punkten** mit äußerem, leicht durchsichtigem Ring in Habitfarbe (3.6). Ringstärke, Abstand und Deckkraft als Werte in `Theme`.

**Aufräumen (Pflicht, keine Überbleibsel)**
- Löschen: `StatusDot` (Datei, auch aus `Habitus.xcodeproj`), `Theme.statusDotSize`, die Glaskarte um den Kopfbereich in `TodayView`, `onTap` in `HabitCard` (ersetzt durch langes Drücken).
- Accessibility Identifier `date-card` ersetzen (z.B. `today-header`), `status-<Name>` sitzt jetzt am Icon und liefert weiter den Wert Grün, Gelb oder Rot.
- Kommentare anpassen, die von Datumskarte, Statuspunkt oder Tippen zum Bearbeiten sprechen.
- Tests anpassen, die die Datumskarte, den Statuspunkt oder Tippen zum Bearbeiten nutzen (u.a. `TodayPhase2UITests`, `TodayPhase3UITests`, `TodayPhase31UITests`).
- Abschluss: Eine Suche im Projekt nach `StatusDot`, `statusDotSize`, `date-card`, `Datumskarte` und `Statuspunkt` findet nichts mehr. Ausnahme ist nur diese Spezifikation.

**Pflicht Testfälle**
- Unit Test: Reihenfolge mit drei Habits (sortOrder 0, 1, 2), der erste ist erledigt: Ergebnis 1, 2, 0. Wieder aufgehoben: 0, 1, 2.
- Unit Test: Ein Counter Habit mit Ziel 3 und Wert 2 gilt als offen, mit Wert 3 als erledigt.
- Unit Test: Ein Wochen Habit mit erfülltem Fenster, am angezeigten Tag nicht abgehakt, gilt als offen.
- UI Test: Abhaken des obersten Habits schiebt ihn ans Ende der Liste, Aufheben bringt ihn zurück nach oben.
- UI Test: Tippen auf die Karte öffnet kein Sheet, langes Drücken öffnet das Bearbeiten Sheet mit diesem Habit.
- UI Test: Wischen nach rechts auf der Liste zeigt gestern (Titel und Untertitel passen), Wischen nach links wieder heute, ein weiteres Wischen nach links bleibt bei heute.
- UI Test: Mit Testdaten liefert `status-<Name>` die Werte Grün, Gelb und Rot, und es gibt keinen Statuspunkt mehr neben dem Namen.

**Definition of Done**
- [ ] Beim Wischen sehe ich deutlich, dass der Tag wechselt, und in welche Richtung. Mit Reduce Motion wird nur überblendet.
- [ ] Oben ist keine Karte mehr. Das Datum sieht aus wie ein großer Navigationstitel und wird beim Scrollen klein in der Leiste angezeigt. Der Fortschritt steht ohne Karte darunter.
- [ ] Tippen auf eine Karte macht nichts, langes Drücken öffnet das Bearbeiten Sheet. Abhakkreis und Counter reagieren weiter auf einfaches Tippen.
- [ ] Erledigte Habits rutschen sichtbar nach unten, aufgehobene zurück an ihren Platz. Nach Neustart ist die gespeicherte Reihenfolge unverändert.
- [ ] Der Status ist als farbiger Ring um das Icon zu sehen, neben dem Namen steht kein Punkt mehr.
- [ ] In den 7 Punkten ist der angezeigte Tag (ganz rechts) bei jeder Füllung gut erkennbar, auch an vergangenen Tagen.
- [ ] Die Suche aus "Aufräumen" findet nichts mehr, es gibt keine ungenutzten Dateien, Typen oder Funktionen.

---

### Phase 3.3: Ruhigere Farben am Icon

**Ziel:** Auf der Karte ist im Normalfall nur noch die Habitfarbe zu sehen. Statusfarbe taucht nur auf, wenn ich etwas tun sollte, und die Icons wirken ruhiger.

**Umfang**
- **Statusmarke statt Statusring** (4.2, 4.3): Der Ring in Statusfarbe um das Icon entfällt. Bei Status gelb oder rot sitzt oben rechts am Icon eine kleine runde Marke in Systemgelb bzw. Systemrot, bei grün ist nichts zu sehen. Größe der Marke und Breite des freien Rands als Werte in `Theme`. Die Statuslogik (3.5) bleibt unverändert.
- **Gedämpfte Icon Farben** (4.2): Jede der 8 Habitfarben bekommt eine gedämpfte Variante, zentral in `HabitColor` (keine Farbwerte in den Ansichten). `HabitIconView` nutzt für Symbol und Kreisfläche nur diese Variante, überall wo es vorkommt (Karte, Icon Vorschau im Sheet). Die gedämpften Farben sind in Hell und Dunkel gut lesbar und passen zum Verlauf. Abhakkreis, Counter und 7 Tage Punkte behalten die normale Habitfarbe.
- **Accessibility:** `status-<Name>` sitzt weiter am Icon und liefert Grün, Gelb oder Rot, auch wenn bei grün keine Marke zu sehen ist. Die Marke selbst hat den Identifier `status-badge-<Name>` und existiert nur bei gelb und rot.

**Aufräumen (Pflicht, keine Überbleibsel)**
- Löschen: `Theme.statusRingWidth`, `Theme.statusRingGap`, `Theme.statusGreen` und die Ring Darstellung in `HabitIconView`.
- Kommentare anpassen, die vom Statusring sprechen.
- Abschluss: Eine Suche im Projekt nach `statusRing`, `statusGreen` und `Statusring` findet nichts mehr. Ausnahme ist nur diese Spezifikation.

**Pflicht Testfälle**
- Unit Test: Jede der 8 Habitfarben hat eine gedämpfte Variante, die sich von der normalen Farbe unterscheidet.
- UI Test: Mit Testdaten hat ein grüner Habit keine `status-badge-<Name>`, ein gelber und ein roter Habit haben eine. `status-<Name>` liefert in allen drei Fällen den richtigen Wert.

**Definition of Done**
- [ ] Grüne Habits zeigen am Icon keine Statusfarbe, gelbe und rote eine kleine Marke oben rechts.
- [ ] Um das Icon gibt es keinen Ring mehr.
- [ ] Die Icons wirken in Hell und Dunkel sichtbar gedämpfter als Abhakkreis und Punkte, alle 8 Farben sind noch gut voneinander zu unterscheiden.
- [ ] Die Suche aus "Aufräumen" findet nichts mehr, es gibt keine ungenutzten Werte oder Funktionen.

---

### Phase 4: Kalender und Nachtragen

**Ziel:** Ich sehe meine Vergangenheit und kann alte Tage korrigieren.

**Umfang**
- Durchgehender, scrollbarer Kalender mit Einfärbung nach Tagesfortschritt (5.4). *(In Phase 5.1 ersetzt durch den Monatskalender mit Pfeilen.)*
- Sheet "Tag bearbeiten" mit derselben Liste wie Heute für den gewählten Tag.
- Zukünftige Tage gesperrt.

**Definition of Done**
- [ ] Mit Testdaten sind Tage unterschiedlich stark eingefärbt.
- [ ] Ich kann einen Tag von letzter Woche öffnen, etwas abhaken, und Kalenderfarbe, 7 Tage Punkte und Status in Heute ändern sich passend.
- [ ] An einem vergangenen Tag erscheinen nur die Habits, die damals fällig waren.
- [ ] Zukünftige Tage lassen sich nicht öffnen.

---

### Phase 5: Statistik und Streaks

**Ziel:** Ich sehe, wie gut ich pro Habit bin.

**Umfang**
- Liste der Habits unter dem Kalender mit aktuellem Streak.
- Habit Detail mit eigenem Monatskalender, aktuellem Streak, längstem Streak, Quote 30 Tage (3.7).
- Unit Tests für Streaks und Quote.

**Definition of Done**
- [x] Streak täglicher Habit: 5 Tage in Folge erreicht ergibt 5; ein verpasster Tag setzt auf 0 (bzw. Zählung ab heute).
- [x] Streak Wochen Habit läuft weiter, solange das Fenster erfüllt ist.
- [x] Längster Streak ist nie kleiner als der aktuelle.
- [x] Quote 30 Tage stimmt mit einem von Hand nachgerechneten Testfall überein.
- [x] Unit Tests für Streaks und Quote grün.

---

### Phase 5.1: Ein Kalender mit Pfeilen

**Ziel:** Der Kalender im Tab und im Habit Detail sehen gleich aus und bedienen sich gleich: ein Monat, Pfeile links und rechts.

**Umfang**
- `MonthCalendar` bekommt den Monatswechsel (Pfeile, Grenzen) selbst (4.3). Der Wechsel wird in der `HabitEngine` berechnet und mit Unit Tests geprüft: ein Monat vor und zurück, Begrenzung auf erster und letzter Monat, Sprung über Jahresgrenzen.
- Der Tab Kalender zeigt einen Monat statt der untereinander stehenden Monate. Start beim aktuellen Monat, mindestens 3 Monate zurück, sonst bis zum Monat des ältesten Habits (5.4). Darunter die Habit Liste, der Tab scrollt senkrecht.
- Das Habit Detail benutzt denselben Baustein (Habitfarbe, nicht antippbar, Grenzen Erstellmonat bis aktueller Monat).
- Der Wechsel des Monats ändert nichts an Tagesfortschritt, Einfärbung oder Sheet "Tag bearbeiten".
- Aufräumen: Die Wochentagszeile über dem Scrollbereich, die Scrollposition auf den aktuellen Monat und die Monatsliste im Tab entfallen. Tests, die in den Monaten scrollen (u.a. `CalendarPhase4UITests`), werden auf die Pfeile umgestellt.

**Definition of Done**
- [x] Im Tab Kalender sehe ich einen Monat mit Pfeil links und rechts neben dem Monatsnamen, im Habit Detail dasselbe Aussehen.
- [x] Pfeil rechts ist im aktuellen Monat deaktiviert, Pfeil links im ersten Monat (Tab: mindestens 3 Monate zurück).
- [x] Ich kann im Tab einen Tag von letzter Woche öffnen, auch wenn er im Vormonat liegt.
- [x] Der Monat im Habit Detail wechselt unabhängig vom Monat im Tab.
- [x] Unit Tests für den Monatswechsel grün, alle anderen Tests weiter grün.

---

### Phase 6: Pausen, Beenden, Sortieren

**Ziel:** Ich kann meine Habits verwalten.

**Umfang**
- Einstellungen > Pausen (3.8, 5.5), auch mit Startdatum in der Vergangenheit. Pausierte Habits stehen ausgegraut mit "Pausiert" am Ende von Heute.
- Pausentage in Status, Fortschritt, Punkten (grauer Strich), Kalender (grau) und Statistik berücksichtigen.
- Habit beenden im Bearbeiten Sheet mit der Wahl "Historie behalten" oder "Historie löschen" (3.9). Keine Liste beendeter Habits in den Einstellungen.
- Sortiermodus in Heute mit Drag and Drop, eine Reihenfolge für alle Habits über `sortOrder` (5.2). Nur offene Habits sind verschiebbar, erledigte bleiben unten (Phase 3.2).
- Unit Tests: Fenster überspringen Pausentage, Streak wird durch Pause nicht unterbrochen, Historie löschen entfernt Habit, Erledigungen und Pausenzuordnung (leere Pausen verschwinden).

**Definition of Done**
- [x] Ich kann 2 Habits für 3 Tage pausieren. Sie stehen ausgegraut mit "Pausiert" am Ende von Heute und zählen nicht im Fortschritt.
- [x] Nach der Pause ist ein vorher grüner Wochen Habit weiterhin grün, wenn die Pause das Fenster sonst gesprengt hätte.
- [x] Eine laufende Pause lässt sich beenden.
- [x] Beenden mit "Historie behalten": Der Habit ist weg aus Heute, aber im Kalender und Detail mit Historie da.
- [x] Beenden mit "Historie löschen": Der Habit ist danach auch in Kalender und Detail weg.
- [x] Abbrechen im Dialog lässt den Habit unverändert.
- [x] In den Einstellungen gibt es keine Liste beendeter Habits.
- [x] Ein Pausenzeitraum mit Startdatum in der Vergangenheit lässt sich anlegen. Schon pausierte Habits sind im Sheet deutlich markiert, aber auswählbar.
- [x] Nach dem Löschen (Historie löschen) eines pausierten Habits ist die Pause ohne ihn weiter vorhanden, bzw. weg, wenn er der einzige war.
- [x] Neue Sortierung bleibt nach Neustart erhalten.

---

### Phase 7: Feinschliff

**Ziel:** Die App fühlt sich fertig und stimmig an.

**Umfang**
- Leerzustände: Heute ohne Habits ("Lege deinen ersten Habit an" mit Button), Kalender ohne Daten, keine Pausen.
- App Icon (minimalistisch, passend zum Farbverlauf).
- VoiceOver Beschriftungen für Abhakkreis, Counter und Statusmarke.
- Prüfung mit großer Schrift (Dynamic Type) und Korrektur von Umbrüchen.
- Durchsicht aller Bildschirme auf einheitliche Abstände, Schriftgrößen und Farben.

**Definition of Done**
- [x] Jeder Bildschirm hat einen sinnvollen Leerzustand.
- [x] App Icon ist auf dem Homescreen sichtbar.
- [x] Bei größter Schriftgröße ist nichts abgeschnitten.
- [x] Abstände, Ecken und Schriftgrößen sind auf allen Bildschirmen gleich.

---

### Phase 8: Designsystem im Hermes Stil

**Ziel:** Die ganze App sieht aus wie Hermes Agent: Blau auf Papier, flach, schmale Schrift, Quadrate statt Kreise. Aufbau und Verhalten aller Bildschirme bleiben gleich, es gibt keine neuen Funktionen. Alles, was zum Glas Design gehörte, ist vollständig entfernt.

**Umfang**
- **Schriften** (4.3): Barlow Condensed (ExtraLight, Regular, Medium), Antonio (Thin) und Geist Mono (Regular, Medium) als `.ttf` mit ihren `OFL.txt` in `Habitus/Design/Fonts/`. `FontRegistry` registriert sie einmalig beim App Start und in Previews. `Theme.Typography` mit den 7 Rollen `display`, `numeral`, `stat`, `title`, `label`, `body`, `meta`, alle mit `relativeTo` für Dynamic Type. View Extensions für Versalien und Laufweite (`label`, `meta`).
- **Farben** (4.2): `Theme` bekommt Marke (`brand`, `paper`, `night`, `frame`) und Rollen (`background`, `ink`, `inkSecondary`, `hairline`, `band`, `onBand`, `onBandSecondary`) sowie die neuen Statusfarben. Die Hex Werte stehen nur in `Theme` und `HabitColor` (Hilfsfunktion z.B. `Color(hex:)` bzw. `dynamic(light:dark:)` mit Hex). Das Asset `AccentColor` wird auf `#0000F2` (hell) und `#F2F2F2` (dunkel) gesetzt, damit Systemelemente (Toggle, Datumsauswahl, Tab Bar) passen.
- **Habitfarben** (4.2): `HabitColor` mit Tinte und Leuchtfarbe pro Modus, `tint`, `onColor`, neue VoiceOver Namen (Indigo, Ocker, Cyan), Reihenfolge des Farbkreises. Die Schlüssel (`rawValue`) bleiben unverändert, gespeicherte Habits behalten ihre Farbe.
- **Formen** (4.4): `cornerRadius` 2, `hairlineWidth` 0,5, Maße für Counter Tasten und 7 Tage Punkte in `Theme`. `HermesButtonStyle` mit den Varianten aus 4.4.
- **Bausteine umbauen** (4.5), Identifier bleiben gleich:
  - `GlassBackground` → `PaperBackground`, `GlassSection` und `glassCard()` → `PaperSection`, `CheckCircle` → `CheckBox`, `DayBadge` → `Chip`.
  - `HabitCard`, `CounterControl`, `WeekDots`, `HabitIconView`, `MonthCalendar`, `HabitStatRow`, `StatValue`, `SegmentedChoice`, `WeekdayPicker`, Farbauswahl, `EmptyState`, `PauseRow` im neuen Stil.
  - `ProgressRing` → `SegmentBar`. `ProgressHeader` zeigt bis Phase 9 die `SegmentBar` und darüber "5 von 16 · 31 %" in Rolle `meta`.
- **Bildschirme** auf die neuen Bausteine umstellen: Heute, Sheet "Tag bearbeiten", Sheet "Habit anlegen / bearbeiten", Sortiermodus, Kalender, Habit Detail, Einstellungen, Sheet "Neue Pause", alle Leerzustände.
  - Navigationstitel (Inline) in Rolle `label` über `UINavigationBarAppearance`, Leisten ohne eigenen Hintergrund auf `background`. Große Titel (Kalender, Einstellungen) stehen als `ScreenTitle` in Rolle `display` im Inhalt, weil UIKit sie mit der Schrift nicht darstellt. Die Variante `secondary` von `HermesButtonStyle` heißt im Code `quiet` (die Suche unten findet sonst `.secondary`), die Versalien im Button setzt `HermesButton`, damit der Name für VoiceOver normal bleibt.
  - Heute behält bis Phase 9 seinen Aufbau (Large Title mit Wochentag, Untertitel, Kapsel, Fortschritt, Liste). Die Kapsel "Heute" ist ein invertierter `Chip`, "Gestern" usw. neutral.
  - Die Tab Bar bleibt die des Systems, getönt in `ink` (5.1).
- **Rhythmus Zeile** (4.5.1) in Rolle `meta` und `inkSecondary`. Wochentage werden mit " · " statt ", " getrennt (`RhythmTextTests` anpassen).
- **App Icon** bleibt bis Phase 12 unverändert.

**Aufräumen (Pflicht, keine Überbleibsel)**
- Löschen: `GlassBackground`, `GlassSection`, `glassCard()`, `CheckCircle`, `DayBadge`, `ProgressRing` (Dateien und Typen), `HabitColor.mutedColor` samt Hilfsfunktion und Konstanten.
- Aus `Theme` löschen: `backgroundTop`, `backgroundBottom`, `accent` (ersetzt durch `ink` bzw. `brand`), `paused` (Systemgrau), `statusYellow`/`statusRed` als Systemfarben, `segmentTrack`, `segmentSelected`, `onHabitColor`, `onAccent`, `iconBackgroundOpacity`, `ringTrackOpacity`, `ringWidth`, `progressRingSize`, der alte `cornerRadius` 24 und alle weiteren Werte, die danach nicht mehr verwendet werden.
- In Ansichten keine Systemschriften mehr (`.font(.headline)` usw.), keine `.foregroundStyle(.secondary)` bzw. `Color.secondary` / `Color.primary`, keine Systemfarben (`.systemGray`, `.systemYellow` …), kein `.glassEffect`.
- Tests anpassen, die gedämpfte Farben, Kreise oder alte Typnamen prüfen (u.a. `HabitColorTests`). Kommentare, die von Glas, Verlauf, Kreis oder gedämpften Farben sprechen, anpassen.
- Abschluss: Eine Suche in `Habitus/` nach `glassEffect`, `glassCard`, `GlassBackground`, `GlassSection`, `CheckCircle`, `DayBadge`, `ProgressRing`, `mutedColor`, `accentColor` (außer im Asset), `systemGray`, `systemYellow`, `systemRed`, `.secondary`, `.font(.` (außer in `Theme`/`FontRegistry`) und `Verlauf` findet nichts mehr. Ausnahme ist nur diese Spezifikation.

**Pflicht Testfälle**
- Unit Test: Jede der 8 Habitfarben liefert in Hell und Dunkel genau die Werte aus 4.2 (aufgelöst mit `UITraitCollection`).
- Unit Test: Kontrast (WCAG Formel, Hilfsfunktion im Test): jede Tinte mindestens 4,4 : 1 gegen `paper`, jede Leuchtfarbe mindestens 4,5 : 1 gegen `night`, `inkSecondary` mindestens 4,5 : 1 gegen `background` in beiden Modi, Statusfarben mindestens 3 : 1.
- Unit Test: `HabitColor(key:)` liefert für alle 8 bisherigen Schlüssel den passenden Fall, ein unbekannter Schlüssel ergibt `blue`.
- Unit Test: Nach `FontRegistry.registerAll()` liefert `UIFont(name:size:)` für alle 6 Schnitte eine Schrift.
- Unit Test: `SegmentBar` Modell (ohne Oberfläche): 4 von 6 Punkten ergibt 6 Segmente, davon 4 voll. 5 von 16 ergibt einen durchgehenden Balken mit 31 %. 0 Punkte ergibt keinen Balken.
- Alle bestehenden UI Tests sind weiter grün (Identifier unverändert).

**Definition of Done**
- [x] Auf keinem Bildschirm gibt es noch Farbverlauf, Glaskarte oder Schatten. Glas gibt es nur noch in Tab Bar und Systemleisten.
- [x] Hell: Papier mit blauer Schrift. Dunkel: Nachtblau mit Schrift in Papier. Nirgends Schwarz oder Systemgrau als Schrift.
- [x] Alle Texte stehen in Barlow Condensed, Antonio oder Geist Mono, außer Tab Bar, Systemleisten, Datumsauswahl und Alerts.
- [x] Abhaken, Counter Tasten, 7 Tage Punkte, Icon Fläche, Statusmarke, Kalendertage und Farbauswahl sind Quadrate.
- [x] Vorhandene Habits haben nach dem Update dieselbe Farbfamilie wie vorher.
- [x] Bei größter Schriftgröße ist nichts abgeschnitten (wie Phase 7).
- [x] Die Suche aus "Aufräumen" findet nichts mehr, es gibt keine ungenutzten Dateien, Typen oder Werte.

---

### Phase 9: Heute mit Kopfband und Wochenstreifen

**Ziel:** Heute sieht aus wie der erste Mockup: ein blaues Band oben mit großem Titel, großem Fortschritt und Wochenstreifen, darunter die flache Liste. Ich kann einen Tag der Woche direkt antippen.

**Umfang**
- `DayHeader` (4.5, 5.2) mit Datumszeile inklusive Kalenderwoche, Titel relativ zu heute, Fortschritt "erledigt/Punkte" mit Prozent, `SegmentBar` und `WeekStrip`. Das Band ist in Hell und Dunkel Markenblau und reicht bis unter die Statusleiste. Die Statusleiste ist auf dem Band lesbar (helle Schrift, auch im hellen Modus), auf welchem Weg ist frei.
- In Heute gibt es keine Navigationsleiste mehr. Der Plus Button sitzt in der Datumszeile, "Heute ›" auf Höhe des Titels, "Sortieren" / "Fertig" im Listenkopf (5.2).
- **Listenkopf** mit Anzahl der Habits ("6 Habits" / "1 Habit").
- **Kleine Leiste beim Scrollen** in `band` mit "Heute · 4/6" und Plus Button (5.2).
- **Wochenstreifen antippen** wechselt den Tag mit derselben Animation wie Wischen. Zukünftige Tage sind blass und nicht antippbar.
- **Animation:** Datumszeile, Titel, Fortschritt und Liste gleiten wie bisher (5.2). Der Wochenstreifen gleitet nur, wenn sich die Woche ändert. Sonst wandert nur die Markierung des angezeigten Tags (kurz, bei Reduce Motion sofort).
- `HabitEngine`: `isoWeek(day)` und `weekStrip(day, today)` (6), ohne SwiftUI, mit Unit Tests.
- Das Sheet "Tag bearbeiten" behält seinen einfachen Kopf (Navigationstitel mit Datum), zeigt aber dieselbe Liste.

**Aufräumen (Pflicht, keine Überbleibsel)**
- Löschen: `ProgressHeader`, die Toolbar Einträge von `TodayView` (Plus, Sortieren, kleiner Titel `barTitle`), die Kapsel neben dem Datum in Heute, den bisherigen Untertitel mit dem Datum.
- Identifier: `today-header` sitzt am `DayHeader`. Bestehende Identifier für Plus, Sortieren und "Heute" Button bleiben gleich. Neu: `week-number`, `week-strip-<yyyy-MM-dd>`, `habit-count`, `compact-bar`.
- UI Tests anpassen, die den Wochentag als Titel oder die Kapsel erwarten (u.a. `TodayPhase31UITests`, `TodayPhase32UITests`, `TodayUITests`): Der Titel ist jetzt "Heute", "Gestern" usw., das Datum steht in der Datumszeile.
- Abschluss: Eine Suche nach `ProgressHeader` und `barTitle` findet nichts mehr. Ausnahme ist nur diese Spezifikation.

**Pflicht Testfälle**
- Unit Test: `isoWeek` ergibt für den 11.10.2026 die Woche 41, für den 29.12.2025 die Woche 1, für den 1.1.2027 die Woche 53.
- Unit Test: `weekStrip` für Sonntag 11.10.2026 (heute) liefert Mo 5.10. bis So 11.10., der 11. ist angezeigt, alle sind antippbar.
- Unit Test: `weekStrip` für Mittwoch 14.10.2026 (heute) liefert Do 15. bis So 18. als Zukunft und nicht antippbar.
- Unit Test: Anzahl Text: 1 ergibt "1 Habit", 6 ergibt "6 Habits".
- UI Test: Mit Testdaten zeigt der Titel "Heute", nach Wischen nach rechts "Gestern". Die Datumszeile passt jeweils zum Tag.
- UI Test: Tippen auf einen früheren Tag im Wochenstreifen zeigt diesen Tag (Titel und Datumszeile). Tippen auf einen zukünftigen Tag ändert nichts.
- UI Test: Der Plus Button im Band öffnet das Sheet "Neuer Habit". "Sortieren" im Listenkopf startet den Sortiermodus, "Fertig" beendet ihn.
- UI Test: Nach dem Scrollen nach unten erscheint `compact-bar` mit dem Fortschritt, nach dem Zurückscrollen verschwindet sie.

**Definition of Done**
- [ ] Oben in Heute steht ein blaues Band mit Datum und Kalenderwoche, großem Titel, großem Fortschritt, Balken und Wochenstreifen, in Hell und Dunkel.
- [ ] Der Fortschritt zählt genau wie vorher (3.4), nur die Darstellung ist neu.
- [ ] Ich kann einen Tag der aktuellen Woche antippen und lande dort. Zukünftige Tage lassen sich nicht antippen. Wischen funktioniert weiter, auch über Wochengrenzen.
- [ ] Beim Scrollen erscheint oben die schmale blaue Leiste mit Titel und Fortschritt, der Plus Button ist immer erreichbar.
- [ ] Die Statusleiste ist auf dem Band gut lesbar.
- [ ] Mit Reduce Motion wird nur überblendet.
- [ ] Die Suche aus "Aufräumen" findet nichts mehr.

---

### Phase 10: Zusatz am Habit

**Ziel:** Ich kann einem Habit eine kurze Angabe mitgeben, z.B. "20 Min", und sehe sie überall in der Rhythmus Zeile.

**Umfang**
- Datenmodell: `detail: String` an `Habit`, Standard "" (6). Leichte Migration, vorhandene Daten bleiben erhalten. `HabitSnapshot` bekommt das Feld ebenfalls.
- Sheet "Habit anlegen / bearbeiten": Feld "Zusatz" unter dem Namen (5.3), höchstens 24 Zeichen, beim Speichern ohne Leerzeichen am Anfang und Ende.
- Rhythmus Zeile mit Zusatz vorne (4.5.1) überall, wo sie steht: `HabitCard` (Heute, Tag bearbeiten), `HabitStatRow` (Kalender), Habit Detail. Die Textlogik liegt ohne Oberfläche bei `HabitSnapshot+Text`.
- Testdaten (Einstellungen > Entwickler): "Lesen" bekommt den Zusatz "20 Min", ein weiterer Habit einen Zusatz, die übrigen keinen.

**Pflicht Testfälle**
- Unit Test: Täglich mit Zusatz "20 Min" ergibt "20 Min · Täglich". Wochentage Mo und Do mit Zusatz "Yoga" ergibt "Yoga · Mo · Do".
- Unit Test: Zusatz nur aus Leerzeichen ergibt nur den Rhythmus. Zusatz mit Leerzeichen außen wird gekürzt gespeichert. Mehr als 24 Zeichen werden auf 24 begrenzt.
- Unit Test: Ein vorhandener Habit ohne Zusatz (Migration bzw. Standardwert) ergibt dieselbe Rhythmus Zeile wie vorher.
- UI Test: Habit mit Zusatz "20 Min" anlegen: `repeat-<Name>` enthält "20 Min" (Groß und Kleinschreibung beim Vergleich ignorieren, weil die Anzeige in Versalien ist). Bearbeiten zeigt den Zusatz im Feld.

**Definition of Done**
- [ ] Ich kann einen Zusatz eingeben, ändern und löschen. Mehr als 24 Zeichen gehen nicht.
- [ ] Der Zusatz steht vorne in der Rhythmus Zeile in Heute, im Kalender und im Detail.
- [ ] Habits ohne Zusatz sehen aus wie vorher.
- [ ] Nach dem Update sind alle Habits und Erledigungen noch da.

---

### Phase 11: Habit Detail als eigene Seite

**Ziel:** Das Habit Detail sieht aus wie der dritte Mockup: ein Band in der Farbe des Habits mit Name und großem Streak, darunter vier Kennzahlen und der Kalender. Ich kann den Habit von dort aus bearbeiten.

**Umfang**
- Detail mit Band in Habitfarbe, Kennzahlen Raster und Kalender (5.4). Die Statusleiste ist auf dem Band lesbar.
- "Bearbeiten" im Band öffnet das Sheet "Habit bearbeiten" über dem Detail, mit den Folgen aus 5.4 (Sichern, Historie behalten, Historie löschen). Bei beendeten Habits kein "Bearbeiten", stattdessen "Beendet am …" in der Meta Zeile.
- Neue Kennzahlen **Erledigungen** und **Pausen** (3.7): `HabitStatistics` bekommt `totalCompletions` und `pauseCount`, berechnet in der `HabitEngine`, mit Unit Tests.

**Aufräumen (Pflicht, keine Überbleibsel)**
- Löschen: Kopf mit Icon im Detail, Navigationstitel "Habit Detail", der Abschnitt "Statistik" als Überschrift.
- Identifier: `detail-name`, `detail-rhythm`, `stat-current-streak`, `stat-longest-streak`, `stat-rate-30` bleiben gleich. Neu: `stat-total`, `stat-pauses`, `detail-edit`.
- UI Tests anpassen, die den Kopf mit Icon oder den Titel "Habit Detail" erwarten (u.a. `CalendarPhase5UITests`, `CalendarPhase51UITests`).

**Pflicht Testfälle**
- Unit Test: 3x täglich, an 3 Tagen voll erledigt, an einem Tag 1: `totalCompletions` ist 10.
- Unit Test: Beendeter Habit: Erledigungen nach dem Tag des Beendens zählen nicht.
- Unit Test: Eine vergangene, eine laufende und eine geplante Pause: `pauseCount` ist 2. Ohne Pausen 0.
- UI Test: Detail eines Habits aus den Testdaten zeigt alle fünf Kennzahlen (Streak im Band, vier im Raster).
- UI Test: "Bearbeiten" im Detail öffnet das Sheet. Name ändern und sichern zeigt den neuen Namen im Detail.
- UI Test: Nach "Habit beenden" mit "Historie löschen" aus dem Detail ist das Detail geschlossen und der Habit nicht mehr in der Liste.
- UI Test: Ein beendeter Habit (Testdaten) hat kein `detail-edit` und zeigt "Beendet am".

**Definition of Done**
- [ ] Das Detail hat oben ein Band in der Farbe des Habits mit Name und großem Streak, in Hell und Dunkel gut lesbar.
- [ ] Darunter stehen Quote 30 Tage, Längster Streak, Erledigungen und Pausen, darunter der Kalender wie bisher.
- [ ] Ich kann einen aktiven Habit aus dem Detail heraus bearbeiten und beenden. Ein beendeter Habit lässt sich dort nicht bearbeiten.
- [ ] Die Kennzahlen stimmen mit einem von Hand nachgerechneten Beispiel aus den Testdaten überein.

---

### Phase 12: Name, Logo und App Icon

**Ziel:** Die App hat einen Namen, eine Wortmarke und ein App Icon im Hermes Stil.

**Entschieden:**
- **Name:** Hestia (Herdfeuer, das täglich gepflegt wird). Nur der Anzeigename ändert sich, Bundle Identifier, Modulname `Habitus` und Startargumente (`-HabitusResetData` usw.) bleiben.
- **Bildmarke:** eine Flamme als Linolschnitt, Blau auf Papier. Quelle ist `Branding/flame-linocut-source.webp` (KI erzeugt, keine Lizenz nötig), `Branding/render_flame_icon.py` liest daraus die Maske und baut die drei Icons. Hell ist Blau auf Papier, dunkel Papier auf Nachtblau, getönt Weiß auf Schwarz. Die Flamme füllt etwa 86 % der Höhe (`FLAME_HEIGHT` 880, oben 46 px und unten 96 px Rand) und ist leicht aufgeraut (wellige Kante, kleine Fehlstellen, feste Seed), damit sie wie ein echter Abzug wirkt. Das ersetzt die frühere Idee mit Markenblau Fläche, weil die Schnitte als helle Linien auf Blau klein besser lesbar sind.
- **Bildwelt:** noch offen. Ob gemeinfreie Stiche (z.B. Met Open Access, CC0) blau gerastert eingesetzt werden, und wenn ja, wo (z.B. in den Leerzuständen). Kandidaten: Met 371844 (Fackel zwischen Altar und Statuette), 402697 (Vestalin).

**Umfang (nach der Entscheidung)**
- **Wortmarke:** Name in Barlow Condensed Regular, Versalien, zweizeilig gesetzt wie "HERMES / AGENT" bei Hermes. Als Vektor in `Branding/`. In der App höchstens an einer Stelle (z.B. Leerzustand Heute oder Einstellungen unten).
- **App Icon:** Flamme in Markenblau `#0000F2` auf Papier `#F2F2F2`, Varianten hell, dunkel und getönt (`AppIcon-light/-dark/-tinted`). `Branding/render_flame_icon.py` erzeugt alle Varianten. *(Erledigt.)* `Branding/render_icon.py` und `habitus-mark.svg` gehören zum alten Wochenkreis Icon.
- **Anzeigename:** `INFOPLIST_KEY_CFBundleDisplayName`. Bundle Identifier und Datenbank bleiben gleich, damit keine Daten verloren gehen.
- **Bildwelt (falls gewählt):** Quellen mit Lizenz in `Branding/QUELLEN.md`. Rasterung und Einfärbung per Skript in `Branding/`, keine Bilder von Hand bearbeitet. Höchstens ein Bild pro Leerzustand, in `Assets.xcassets`.

**Definition of Done**
- [ ] Das neue App Icon ist auf dem Homescreen sichtbar, in Hell, Dunkel und getönt.
- [ ] Unter dem Icon steht der gewählte Name.
- [ ] Nach dem Update sind alle Habits und Erledigungen noch da.
- [ ] Alle Bildquellen sind mit Lizenz dokumentiert.
