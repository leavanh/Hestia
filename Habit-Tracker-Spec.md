# Habit Tracker: Spezifikation

## Hinweise für die KI beim Entwickeln

- Arbeite immer nur an **einer Phase**. Beginne erst mit der nächsten Phase, wenn ich das sage.
- Jede Phase endet mit einer lauffähigen App. Alle Punkte der Definition of Done müssen erfüllt sein.
- Halte dich an das Designsystem (Abschnitt 4). Erfinde keine neuen Stile, Farben oder Dialogformen.
- Die gesamte Rechenlogik (Status, Zählung, Streaks) liegt in einem eigenen Teil ohne Oberfläche (`HabitEngine`) und wird mit Unit Tests geprüft.
- Erkläre mir nach jeder Phase kurz, wie ich die Punkte der Definition of Done selbst prüfen kann.
- Keine Funktionen bauen, die hier nicht beschrieben sind.
- **Tests schlank halten.** Rechenlogik wird mit Unit Tests geprüft (Test Plan "Schnell", läuft in Sekunden). UI Tests gibt es nur für wenige zentrale Abläufe, jeder kostet 10 bis 30 Sekunden. Pro Phase höchstens 2 neue UI Tests, und nur die, die unter "Pflicht Testfälle" stehen. Lieber einen bestehenden UI Test anpassen als einen neuen schreiben. Was sich als Unit Test prüfen lässt, wird kein UI Test.
- **Wann welche Tests laufen.** Während der Arbeit nur "Schnell" und gezielt die betroffenen UI Tests (`-only-testing:HestiaUITests/<Klasse>/<Test>`). Den Test Plan "Komplett" nur einmal am Ende der Phase. Schlägt dort ein UI Test fehl, nach der Korrektur nur diesen erneut laufen lassen, nicht wieder alles.
- **Accessibility wird nicht getestet.** Keine Tests und keine eigenen Prüfläufe für VoiceOver, Dynamic Type, Large Content Viewer oder Reduce Motion, auch keine Prüfung mit größter Schrift im Simulator. Was es schon gibt, bleibt, aber dafür wird kein zusätzlicher Aufwand betrieben. Ältere Punkte dazu in dieser Spezifikation gelten als erledigt.

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
| Sprache der App | Deutsch. Ab Phase 16 Deutsch und Englisch, Wahl über die Sprachwahl von iOS (5.5) |
| Darstellung | Hell und Dunkel (folgt der Systemeinstellung). Ab Phase 14 in den Einstellungen wählbar: System, Hell oder Dunkel (5.5) |

**Bewusst nicht enthalten:** Erinnerungen, Notizen, Messwerte, negative Habits, Überspringen von Tagen, Widgets, Export, Haptik, Animationen über Standard hinaus, jährliche Habits.

*Ausnahme ab Phase 10:* ein kurzer **Zusatz** am Habit (höchstens 24 Zeichen, z.B. "20 Min"). Das ist eine Beschriftung, kein Notizfeld und kein Messwert. Es wird nichts damit gerechnet.

---

## 2. Begriffe

- **Habit:** Eine Gewohnheit, z.B. "Sport" oder "Wasser trinken".
- **Erledigung:** Ein Eintrag "an Tag X habe ich Habit Y n mal gemacht".
- **Tag:** Kalendertag, lokale Zeitzone, Wechsel um Mitternacht.
- **Fenster:** Rollierender Zeitraum, der heute endet. Woche = heute plus 6 Tage davor (7 Tage). Monat = heute plus 29 Tage davor (30 Tage).
- **Kalenderzeitraum** (ab Phase 15, wenn in den Einstellungen Zeiträume "Kalender" gewählt ist): Woche = die Kalenderwoche des Tags, beginnend am Wochenbeginn (5.5). Monat = der Kalendermonat des Tags. Gezählt wird vom ersten Tag des Zeitraums bis zum Tag selbst.
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
- **Ab Phase 13** teilt Heute die aktiven Habits in die **Hauptliste** und **Weitere** (5.2). Für den angezeigten Tag gilt:
  - Täglich: Hauptliste.
  - Feste Wochentage, fester Monatstag: fällig in der Hauptliste, sonst in Weitere.
  - Pro Woche, pro Monat: in Weitere, wenn das Ziel im Fenster (ab Phase 15 bzw. im Zeitraum) schon erfüllt ist und der Status grün ist, sonst in der Hauptliste. Beides wird dafür **ohne die Erledigung des angezeigten Tags** berechnet. So wechselt ein Habit beim Abhaken nie die Liste: Wer am Montag den 1x pro Woche Habit abhakt, sieht ihn am Montag unten bei den erledigten in der Hauptliste und ab Dienstag in Weitere. Ein gelber Habit (Ziel erfüllt, fällt aber bald heraus) bleibt in der Hauptliste.
  - Pausiert: in Weitere, am Ende.
  - Beendet: nirgends (wie bisher).

### 3.3 Abhaken

- **Täglich mit Anzahl größer 1:** Counter mit Minus und Plus. Wert von 0 bis Zielanzahl.
- **Alle anderen:** Ein Feld zum Abhaken (bis Phase 7 ein Kreis, ab Phase 8 ein Quadrat, `CheckBox`). Wert 0 oder 1 pro Tag. Erneutes Tippen hebt das Abhaken auf.
- Abgehakt wird immer für den angezeigten Tag (5.2).

### 3.4 Tagesfortschritt ("5 von 16 · 31 %")

Gezählt werden alle am angezeigten Tag fälligen Habits (siehe 3.2). **Ab Phase 13** zählen nur die Habits der Hauptliste. Habits in Weitere zählen nie mit, auch nicht, wenn sie am Tag abgehakt werden.

| Rhythmus | Punkte | Erledigte Punkte |
|---|---|---|
| Täglich | Zielanzahl (3x täglich = 3) | Heutiger Wert, höchstens Zielanzahl |
| Feste Wochentage, fester Monatstag | 1 | 1, wenn heute abgehakt |
| Pro Woche, pro Monat | 1 | 1, wenn heute abgehakt **oder** Ziel im Fenster schon erfüllt |

Prozent = erledigte Punkte geteilt durch Punkte, gerundet auf ganze Zahl. Bei 0 Punkten wird "Nichts fällig" angezeigt (bis Phase 15 "Heute nichts fällig", auch an vergangenen Tagen).

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

**Pro Woche / pro Monat mit Kalenderzeiträumen (ab Phase 15)**

Gilt statt des Abschnitts davor, wenn Zeiträume "Kalender" gewählt ist.
- **Erledigt:** Summe der Erledigungen vom Beginn des Zeitraums bis heute, nur nicht pausierte Tage (wie rollierend).
- **Ziel:** die Zielanzahl, höchstens die Anzahl der Tage im Zeitraum (z.B. 30x pro Monat im Februar: 28).
- **Noch nötig:** Ziel minus erledigt. **Noch möglich:** nicht pausierte Tage von heute (eingeschlossen) bis zum Ende des Zeitraums.
- Grün: Ziel erreicht, **oder** noch möglich ist größer als noch nötig.
- Gelb: noch möglich ist gleich noch nötig (jeder verbleibende Tag wird gebraucht).
- Rot: noch möglich ist kleiner als noch nötig (nicht mehr zu schaffen).
- Ein neuer Zeitraum beginnt ohne Altlast: Am ersten Tag einer Woche ist der Status grün, auch wenn die Woche davor verpasst wurde.
- **Zeiträume, die nur gewertet werden, wenn das Ziel erreicht ist:** der angebrochene Zeitraum, in dem der Habit erstellt wurde, ein Zeitraum mit mindestens einem Pausentag und der Zeitraum, in dem der Habit beendet wurde. In ihnen gibt es kein Rot, statt Rot gilt Gelb.

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
- **Pro Woche / pro Monat mit Kalenderzeiträumen (ab Phase 15):** Ein Tag übernimmt das Ergebnis seines Zeitraums. Ist ein abgeschlossener Zeitraum erfüllt, zählen alle seine nicht pausierten Tage ab Erstellung als erfüllt, sonst als verpasst. Zeiträume, die nur bei erreichtem Ziel gewertet werden (3.5), sind sonst weder erfüllt noch verpasst. Im laufenden Zeitraum zählen die Tage bis heute als erfüllt, sobald das Ziel erreicht ist, vorher sind sie noch offen (wie "Heute noch offen").
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
| `progress` (ab Phase 8.1, Einfärbung des Kalenders im Tab) | `brand` | `#7979F2` (Leuchtfarbe Blau) |

`progress` sorgt dafür, dass der Kalender im Tab auch im dunklen Modus blau ist und nicht grau wie `ink`. Die 70 % bzw. 80 % sind bewusst höher als in den Mockups (60 %), damit kleine Schrift den Kontrast 4,5 : 1 erreicht.

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
- **Einbinden:** Die Schriftdateien (`.ttf`) liegen in `Hestia/Design/Fonts/` und werden beim Start registriert (`CTFontManagerRegisterFontsForURL`, einmalig, z.B. in `FontRegistry.registerAll()` beim App Start und in Previews). Das Projekt erzeugt seine Info.plist selbst (`GENERATE_INFOPLIST_FILE`), deshalb kein `UIAppFonts` Eintrag. Fehlt eine Schrift, meldet ein Debug Assert das sofort.
- Die Systemschrift bleibt nur dort, wo das System sie selbst setzt (Systemleisten in Sheets, Alerts). Bis Phase 8.1 gehört auch die Tab Bar dazu, bis Phase 9.1 die Datumsauswahl im Sheet "Neue Pause".

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

Systemleisten in Sheets (Abbrechen, Sichern, Fertig) bleiben Systembuttons, getönt in `ink`. Ihr Liquid Glass Aussehen wird akzeptiert, weil Sheets nur kurz zu sehen sind. Eigene Glasflächen gibt es nicht.

**Ab Phase 8.1 kein Liquid Glass außerhalb von Sheets:** Die Tab Bar ist eine eigene flache Leiste (`PaperTabBar`, 4.5). Buttons in der Navigationsleiste eines Tabs (z.B. Plus und Sortieren in Heute) haben keine Glasfläche (`sharedBackgroundVisibility(.hidden)`) und nutzen `HermesButtonStyle`.

### 4.5 Bausteine (einmal bauen, überall nutzen)

| Baustein | Inhalt |
|---|---|
| `PaperBackground` | Fläche `background` für alle Bildschirme und Sheets. Ersetzt `GlassBackground`. |
| `PaperTabBar` (ab Phase 8.1) | Eigene Tab Bar statt der des Systems (5.1). Volle Breite bis zum unteren Rand, Fläche `background`, oben eine Haarlinie. Drei gleich breite Felder mit SF Symbol (Schnitt regular, 20 pt) und Label in Rolle `label`. Gewählter Tab in `ink` mit einem 2 pt Strich in `ink` an der Oberkante des Felds, die anderen in `inkSecondary`. Keine Fläche, kein Glas, kein Schatten. |
| `PaperSection` | Abschnitt mit Überschrift in Rolle `meta` und darunter dem Inhalt, oben eine Haarlinie. Keine Karte. Ersetzt `GlassSection` und `glassCard()`. |
| `HabitCard` | Flache Zeile ohne Karte, oben eine Haarlinie. Links `HabitIconView`, daneben Name (Rolle `title`), darunter die Rhythmus Zeile (4.5.1) und in derselben Zeile rechts daneben die 7 Tage Punkte (ab Phase 9, wie im Mockup; reicht der Platz bei großer Schrift nicht, stehen die Punkte darunter), rechts `CheckBox` oder `CounterControl`. Kein weiterer Text. Langes Drücken, Einsinken und VoiceOver Aktion wie bisher. |
| `CheckBox` | Quadrat 36 pt mit 1 pt Rand in Habitfarbe. Abgehakt: gefüllt mit Habitfarbe, Häkchen in `onColor`. Ersetzt `CheckCircle`. |
| `CounterControl` | Taste "−" (Quadrat 26 pt), Wert als "5/8" (Rolle `meta` in Medium, gleich breite Ziffern), Taste "+". Kein Ring mehr. Gesperrte Taste mit `disabledOpacity`. Gesamthöhe wie `CheckBox`. |
| `WeekDots` | 7 Quadrate (6 pt). Füllung wie 3.6 (Deckkraft nach Anteil), 0 = Habitfarbe mit 22 %. Der angezeigte Tag hat einen äußeren quadratischen Rahmen in Habitfarbe mit verringerter Deckkraft. Ab Phase 9.1 steht vor dem angezeigten Tag mehr Abstand, sodass zwischen Rahmen und Nachbarquadrat mindestens `Theme.dotSpacing` frei bleibt (Wert in `Theme`, z.B. `dotRingClearance`). Der Rahmen berührt nichts. Pausierte Tage: kurzer waagrechter Strich in `ink` mit Pausen Deckkraft. |
| `HabitIconView` | Quadratische Kachel (36 pt), Fläche `tint`, Symbol in `color`. Bei Status gelb oder rot oben rechts eine quadratische Statusmarke in Statusfarbe, mit schmalem freiem Rand in `background`. Bei grün keine Marke. |
| `Chip` | Kleine Kapsel mit 2 pt Ecken, Rolle `label` in klein (11 pt), Fläche `ink` mit 14 %. Für "Pausiert". Ersetzt `DayBadge`. |
| `DayHeader` | Das Kopfband in Heute (5.2): Datumszeile, Titel, Fortschritt, `SegmentBar`, `WeekStrip`. Ersetzt `ProgressHeader` und den bisherigen Kopf. |
| `SegmentBar` | Fortschritt als Reihe kurzer Balken (3 pt hoch, 3 pt Abstand), ein Balken pro Punkt (3.4), erledigte Punkte voll, offene mit 25 %. Bei mehr als 12 Punkten ein durchgehender Balken mit Füllung nach Prozent. Ersetzt `ProgressRing`. **Ab Phase 9.1 immer ein durchgehender Balken** (3 pt hoch, offener Teil mit 25 %, gefüllter Teil nach Prozent), unabhängig von der Anzahl der Punkte. Ändert sich der Fortschritt, wächst bzw. schrumpft die Füllung kurz animiert. |
| `WeekStrip` | 7 Felder Mo bis So der Woche des angezeigten Tags (Rolle `label`). Der angezeigte Tag invertiert (Fläche `onBand`, Schrift `band`). Tage nach heute mit `calendarFutureOpacity` und nicht antippbar. Antippen eines anderen Tags wechselt dorthin (5.2). |
| `MonthCalendar` | Wie bisher (Monat mit Pfeilen, Grenzen, Wochentagszeile), aber jeder Tag ist ein Quadrat mit der Tageszahl (Rolle `meta`, ohne Versalien). Monatsname in Rolle `meta`. Heute mit äußerem quadratischem Rahmen. Einfärbung, Pausen, Zukunft, Tippen wie bisher. Im Tab in `progress`, im Habit Detail in Habitfarbe. Ab Phase 11 gibt es im Habit Detail eine kompakte Darstellung wie im Mockup: Quadrate ohne Tageszahl mit 3 pt Abstand, heute mit Rahmen, pausierte Tage als kurzer waagrechter Strich wie in `WeekDots`. VoiceOver liest jeden Tag weiter mit Datum und Erledigung. |
| `HabitStatRow` | Flache Zeile mit Haarlinie: `HabitIconView` ohne Statusmarke, Name, Rhythmus Zeile, rechts der aktuelle Streak als Zahl (Rolle `stat`, kleiner: 32 pt) mit "Tage" darunter (Rolle `meta`). Kein Flammensymbol. Antippen öffnet das Habit Detail. |
| `StatValue` | Eine Kennzahl: großer Wert (Rolle `stat`), darunter die Beschriftung (Rolle `meta`). Ab Phase 11 steht im großen Wert nur die Zahl bzw. Prozentzahl, die Einheit gehört in die Beschriftung ("4" über "Längster Streak · Tage", nicht "4 Tage"). |
| `StepperControl` (ab Phase 8.1) | Ersetzt den System `Stepper` und das Menü für den Monatstag im Sheet: Text links (Rolle `body`), rechts Taste "−", Wert, Taste "+" mit denselben Quadraten wie `CounterControl`, in `ink`. Gesperrte Taste an der Grenze mit `disabledOpacity`. VoiceOver als einstellbarer Wert (`accessibilityAdjustableAction`). Ab Phase 9.1 nicht mehr für den Monatstag (siehe `MonthDayPicker`). |
| `MonthDayPicker` (ab Phase 9.1) | Auswahl des Monatstags im Sheet (5.3): Raster 1 bis 31 in 7 Spalten aus Quadraten wie im `MonthCalendar` (Tageszahl in Rolle `meta`, ohne Versalien). Der gewählte Tag ist gefüllt in `ink`, Zahl in `background`, die anderen ohne Fläche. Ein Tippen wählt den Tag, mit leichtem haptischem Signal. Unter dem Raster in Rolle `meta` der Hinweis "Fehlt der Tag im Monat, gilt der letzte Tag" (3.1), nur wenn 29, 30 oder 31 gewählt ist. VoiceOver liest jedes Feld als "n. des Monats", das gewählte als ausgewählt. |
| `DateRow` (ab Phase 9.1) | Zeile für ein Datum: Beschriftung links (Rolle `body`), Datum rechts (Rolle `body`, z.B. "11. Okt 2026") in Appschrift. Tippen klappt darunter einen `MonthCalendar` zur Auswahl auf (Farbe `progress`, gewählter Tag gefüllt, Pfeile wie bisher, Grenzen vom Aufrufer), ein zweites Tippen oder die Wahl eines Tags klappt ihn wieder zu. Es ist immer höchstens eine Zeile aufgeklappt. |
| `SegmentedChoice` | Segmentfeld mit 0,5 pt Rahmen in `ink`, Segmente in Rolle `label`, gewähltes Segment invertiert (Fläche `ink`, Schrift `background`). |
| `WeekdayPicker` | 7 Quadrate M D M D F S S, gewählt invertiert. |
| `ColorPicker` (Farbauswahl im Sheet) | 8 Quadrate (28 pt) in Habitfarbe, gewählt mit äußerem Rahmen in `ink`. |
| `EmptyState` | Titel in Rolle `display` (kleiner: 40 pt), Erklärung in `body`, Button `primary`. Ab Phase 12 optional ein Stich (`EngravingImage`, dekorativ) über dem Titel, nur in Heute und Kalender (siehe Phase 12). |
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

**Ab Phase 15** hängen die Texte bei Woche und Monat mit Anzahl von den Zeiträumen ab (5.5). Die Zahl "erledigt" ist dabei der Stand im jeweiligen Fenster bzw. Zeitraum:

| Rhythmus | Rollierend | Kalender |
|---|---|---|
| Woche, Anzahl | 1 VON 3 IN 7 TAGEN | 1 VON 3 DIESE WOCHE |
| Monat, Anzahl | 1 VON 1 IN 30 TAGEN | 1 VON 1 DIESEN MONAT |

Ab Phase 14 folgt die Reihenfolge fester Wochentage dem Wochenbeginn (5.5).

### 4.6 Icons

Auswahl aus ca. 30 kuratierten SF Symbols wie bisher (z.B. figure.run, drop.fill, book.fill, bed.double.fill, leaf.fill, dumbbell.fill, brain.head.profile, pills.fill, cup.and.saucer.fill, figure.walk, music.note, pencil, house.fill, cart.fill, heart.fill). Sie stehen in `color` auf der Kachel aus 4.5. Schnitt der Symbole: `.regular`, damit sie zur dünnen Schrift passen.

**Ab Phase 14.1:** 36 Symbole in 6 Zeilen zu je 6, jede Zeile ein Thema. Alle gibt es seit spätestens iOS 17.

| Zeile | Symbole (VoiceOver Name) |
|---|---|
| Bewegung | `figure.run` (Laufen), `figure.walk` (Gehen), `figure.hiking` (Wandern), `dumbbell.fill` (Hantel), `figure.yoga` (Yoga), `bicycle` (Fahrrad) |
| Pflege | `sparkles` (Hautpflege), `bubbles.and.sparkles.fill` (Reinigung), `face.smiling.fill` (Gesicht), `mouth.fill` (Zähne), `comb.fill` (Haare), `shower.fill` (Dusche) |
| Essen und Gesundheit | `drop.fill` (Wasser), `cup.and.saucer.fill` (Tasse), `fork.knife` (Essen), `carrot.fill` (Gemüse), `pills.fill` (Tabletten), `heart.fill` (Herz) |
| Ruhe | `bed.double.fill` (Bett), `moon.fill` (Mond), `sun.max.fill` (Sonne), `brain.head.profile` (Kopf), `figure.mind.and.body` (Meditation), `leaf.fill` (Blatt) |
| Lernen und Kreatives | `book.fill` (Buch), `pencil` (Schreiben), `character.bubble.fill` (Sprache), `music.note` (Musik), `paintbrush.fill` (Malen), `camera.fill` (Kamera) |
| Alltag | `house.fill` (Haushalt), `washer.fill` (Wäsche), `cart.fill` (Einkauf), `banknote.fill` (Geld), `iphone.slash` (Weniger Handy), `pawprint.fill` (Haustier) |

Entfallen: `figure.pool.swim`, `tree.fill`, `graduationcap.fill`, `creditcard.fill`, `phone.fill`, `envelope.fill`. Kein vorhandener Habit trägt eines davon, eine Sonderbehandlung gibt es nicht.

### 4.7 Bewegung

Unverändert: Tageswechsel, Einsinken beim langen Drücken, Rutschen erledigter Habits, Reduce Motion nur Überblenden. Neue Übergänge (z.B. Einblenden der kleinen Leiste in Heute) sind kurz (ca. 0,1 bis 0,2 s) und bei Reduce Motion ohne Bewegung.

### 4.8 Glossar und Texte (ab Phase 16)

Die App gibt es auf Deutsch (Entwicklungssprache) und Englisch, alle Texte stehen in `Localizable.xcstrings`. Die Sprache wählt man in iOS (Einstellungen › Hestia › Sprache), die Zeile "Sprache" in den Einstellungen springt dorthin (5.5).

| Begriff | Deutsch | Englisch |
|---|---|---|
| Habit | Habit, Habits | habit, habits |
| Erledigung | Erledigung, Erledigungen; Zustand "Erledigt" / "Offen" | completion, completions; "Done" / "Not done" |
| Rhythmus | Rhythmus | Repeat ("3x per week") |
| Zeiträume (Einstellung) | Zeiträume · Rollierend · Kalender | Periods · Rolling · Calendar |
| Fenster | kommt in keinem Text vor, nur "in 7 Tagen" / "in 30 Tagen" | "in 7 days" / "in 30 days" |
| Pause | Pause, Pausiert | pause, Paused |
| Datum der Pause | Zeitraum (im Sheet "Neue Pause") | Dates |
| Zusatz | Zusatz | Detail |
| Streak | Streak, Tage in Folge | streak, days in a row |
| Quote | Quote | Rate |
| Kalenderwoche | KW 41 | W41 |
| Weitere | Weitere | Others |
| Beenden | Habit beenden, Historie | End habit, history |

**Regeln**
- **Versalien:** Im Code und im Katalog steht jeder Text normal geschrieben, die Versalien entstehen in der Ansicht (Rollen `label` und `meta`, 4.3).
- **Englisch:** Satzschreibweise ("New habit", "Keep history"), nicht Title Case. Überschriften und Buttons ohne Schlusspunkt, ganze Sätze mit.
- **Ansprache:** neutral, ohne "du" und "Sie", im Englischen ohne "you", wo es natürlich geht. Anweisungen im Infinitiv ("Ersten Habit anlegen") bzw. Imperativ ("Add first habit").
- **Nicht übersetzt:** Wortmarke `HESTIA / HABITS`, App Name, Namen und Zusätze der Habits, Schriftnamen, Autoren und Lizenznamen im Sheet "Über", der Abschnitt "Entwickler" und Fehlermeldungen für Entwickler.
- **Datum und Zahlen:** folgen der Sprache der App und der Region (`Locale.current`), kein festes Gebietsschema. Prozent als "67 %" (mit geschütztem Leerzeichen) auf Deutsch, "67%" auf Englisch. Beispiele Datumszeile: "So · 11. Okt · KW 41" / "Sun · Oct 11 · W41".
- **Technik:** Texte in Hilfsfunktionen kommen über `localized(_:locale:)` (`Localization.swift`), das wegen der Tests auch eine andere Sprache als die der App liefern kann. Text in Ansichten steht als Literal in `Text(...)`, Buttons usw. und wird so automatisch aus dem Katalog gelesen. Der Katalog ist von Hand gepflegt (`extractionState: manual`), die Erzeugung von Symbolen ist aus (`STRING_CATALOG_GENERATE_SYMBOLS = NO`).

Die vollständige Zuordnung Deutsch zu Englisch steht im Katalog selbst.

---

## 5. Bildschirme

### 5.1 Tab Bar (3 Tabs)

1. **Heute** (Symbol: checkmark.circle)
2. **Kalender** (Symbol: calendar)
3. **Einstellungen** (Symbol: gearshape)

Ab Phase 8: Die Tab Bar bleibt die des Systems, getönt in `ink`. Hintergrund der Bildschirme ist `PaperBackground`. *(Ab Phase 8.1 ersetzt durch den nächsten Absatz.)*

**Ab Phase 8.1:** Die Tab Bar ist `PaperTabBar` (4.5), die System Tab Bar ist ausgeblendet.
- Reihenfolge, Namen und Symbole wie oben. Jeder Tab behält beim Wechsel seinen Zustand (Scrollposition, angezeigter Tag, Monat im Kalender), wie bisher mit `TabView`.
- Der Inhalt jedes Tabs scrollt vollständig über der Leiste, die letzte Zeile wird nicht verdeckt. Sheets liegen über der Leiste.
- Tippen auf den gerade gewählten Tab scrollt dessen Inhalt nach oben.
- Die Labels wachsen mit Dynamic Type höchstens bis `Theme.maxCircleTypeSize` und brechen nie um. Bei Barrierefreiheitsgrößen zeigt langes Drücken auf einen Tab das Label groß an (Large Content Viewer), wie bei der System Tab Bar.
- VoiceOver liest jeden Tab als Tab mit Namen, der gewählte ist als ausgewählt markiert, die Leiste meldet "Tab 1 von 3" usw.
- Identifier: `tab-today`, `tab-calendar`, `tab-settings`.
- **Wechsel animiert (ab Phase 9.1):** Der 2 pt Strich in der `PaperTabBar` gleitet zum neuen Tab, Symbol und Label wechseln die Farbe weich mit. Der neue Inhalt blendet ein und gleitet dabei ein kleines Stück (ca. 12 pt) aus der Richtung des Tabs herein (Tab weiter rechts: von rechts, weiter links: von links). Kurz (ca. 0,25 s) und weich, ohne Federn. Der Zustand jedes Tabs bleibt wie bisher erhalten. Tippen auf den gewählten Tab scrollt nur nach oben, ohne Übergang. Bei Reduce Motion nur Überblenden.

### 5.2 Heute

- **Kopfband (ab Phase 9, ersetzt den nächsten Punkt):** Oben ein Band in Markenblau (`band`, hell und dunkel gleich), randlos bis unter die Statusleiste. Es gibt in Heute keine Navigationsleiste mehr. Das Band (`DayHeader`) enthält von oben nach unten:
  1. **Datumszeile** (Rolle `meta`, `onBandSecondary`): links Wochentag kurz, Datum und Kalenderwoche ("So · 11. Okt · KW 41"), rechts der Plus Button (Variante `onBand`, Quadrat mit Plus Symbol, VoiceOver "Neuer Habit"). Die Kalenderwoche ist die ISO Kalenderwoche des angezeigten Tags.
  2. **Titel** (Rolle `display`): der angezeigte Tag relativ zu heute: "Heute", "Gestern", "Vorgestern", sonst "Vor n Tagen" (wie bisher `RelativeDay`). Die bisherige Kapsel neben dem Datum entfällt, weil der Titel das schon sagt. An vergangenen Tagen steht rechts auf Höhe des Titels der Button "Heute ›" (Variante `onBand`), der wie bisher animiert zu heute springt.
  3. **Fortschritt:** links groß "erledigte Punkte/Punkte" (Rolle `numeral`, z.B. "4/6"), daneben klein untereinander "Erledigt" und die Prozent ("67 %") in Rolle `meta`. Zählung wie 3.4, nur die Darstellung ist neu. Bei 0 Punkten steht statt Zahl und Balken "Nichts fällig" (Rolle `title`; bis Phase 15 "Heute nichts fällig"). Darunter die `SegmentBar`.
  4. **Wochenstreifen** (`WeekStrip`): Mo bis So der ISO Woche des angezeigten Tags, der angezeigte Tag invertiert. Antippen eines vergangenen Tags oder von heute wechselt dorthin, mit derselben Animation wie Wischen (Richtung nach Datum). Tage nach heute sind blass und nicht antippbar. Wischen über eine Wochengrenze zeigt im Streifen die neue Woche. Ab Phase 9.1 gleitet der Streifen ohne Verzögerung und genauso schnell wie Datumszeile und Titel (nicht als letztes Glied der Kaskade, kein Nachfedern). Wandert nur die Markierung innerhalb der Woche, geschieht das sofort mit dem Wischen, ebenso kurz. VoiceOver liest jeden Tag als vollständiges Datum, der angezeigte Tag ist als ausgewählt markiert.
- **Listenkopf (ab Phase 9):** Direkt unter dem Band eine Zeile in Rolle `meta`: links die Anzahl der Zeilen in der Liste ("6 Habits", Einzahl "1 Habit", pausierte zählen mit; ab Phase 13 nur die Zeilen der Hauptliste), rechts der Button "Sortieren" bzw. im Sortiermodus "Fertig" (Variante `text`). Er ersetzt den Button oben links.
- **Scrollen (ab Phase 9):** Das Band scrollt mit dem Inhalt weg. Ist es aus dem Bild gescrollt (Schwelle `Theme.compactBarScrollOffset`: vom Band ist weniger als diese Höhe zu sehen), erscheint oben eine schmale Leiste in `band` mit "Heute · 4/6" (Titel und Fortschritt, Rolle `label`) links und dem Plus Button rechts. Sie ersetzt den kleinen Navigationstitel. Wischen und Tageswechsel funktionieren in beiden Zuständen. Ab Phase 9.1 hat die Leiste oben und unten so viel Innenabstand, dass der Plus Button mit Luft darin steht (mindestens `Theme.spacing` bzw. 8 pt über und unter dem Button, Wert in `Theme`, z.B. `compactBarPadding`). Er reicht nicht bis an die Unterkante.
- *Bis Phase 8:* **Kopfbereich ohne Karte:** Oben steht das Datum des angezeigten Tags im Stil eines großen Navigationstitels (Large Title einer `NavigationStack`: Schrift, Gewicht, Einzug links). Titel ist der Wochentag ("Donnerstag"), darunter als Untertitel das Datum ("8. Oktober"). Beim Scrollen verhält sich der Titel wie ein Large Title und wird klein in der Leiste angezeigt. Darunter der `ProgressHeader`, ebenfalls ohne Karte und ohne Glas direkt auf dem Hintergrund. Neben dem Datum steht eine kleine Kapsel: "Heute" in Akzentfarbe, an vergangenen Tagen neutral "Gestern", "Vorgestern" oder "Vor n Tagen". In der kleinen Leiste steht sie hinter dem Datum.
- **Tag wechseln:** Waagrechtes Wischen im Inhalt von Heute (Kopfbereich und Liste) nach rechts zeigt den vorherigen Tag, nach links den nächsten Tag. Senkrechtes Scrollen, Abhakkreis und Counter funktionieren weiter wie bisher. Weiter als bis heute geht es nicht, zukünftige Tage sind nicht erreichbar. Beim Start der App, beim Zurückkehren in die App und beim Tageswechsel um Mitternacht zeigt die Ansicht wieder heute.
- **Animation beim Tageswechsel:** Titel, Untertitel, Fortschritt und Liste gleiten in Wischrichtung heraus und der neue Tag gleitet von der anderen Seite herein (zurück in die Vergangenheit: Inhalt kommt von links, vorwärts: von rechts), kurz und weich (ca. 0,3 s). Wird nicht gewechselt, weil heute schon erreicht ist, federt der Inhalt nur kurz zurück. Der neue Tag federt dabei Kopf und Karten nacheinander (leicht versetzt) herein. Bei "Bewegung reduzieren" (Reduce Motion) nur Überblenden. Das Zurückspringen auf heute (Start, Rückkehr, Mitternacht) ist nicht animiert.
- Für den angezeigten Tag gelten Fälligkeit, Fortschritt, Abhaken, Status und 7 Tage Punkte so, als wäre dieser Tag heute. Tage vor der Erstellung eines Habits und pausierte Tage verhalten sich wie in Abschnitt 3 beschrieben.
- *Bis Phase 8:* Oben rechts: Plus Button für neuen Habit. Zeigt die Ansicht einen vergangenen Tag, steht in der Datumszeile rechts (auf einer Ebene mit Datum und Kapsel, nicht in der Leiste) ein Button "Heute >" mit kleinem Chevron, der (animiert, wie ein Wischen nach vorn) zu heute zurückspringt. Auf heute ist er nicht zu sehen. Oben links: Button "Sortieren".
- Darunter eine einzige Liste mit `HabitCard`s, ohne Abschnitte und ohne Überschriften.
- **Pausierte Habits** (3.8) stehen am Ende der Liste (ab Phase 13 am Ende von Weitere), nach den erledigten, in der gespeicherten Reihenfolge: Icon und Name ausgegraut, daneben die Kapsel "Pausiert" (wie im Sheet "Neue Pause"), Abhakkreis bzw. Counter ausgegraut und nicht bedienbar. Langes Drücken öffnet weiter das Bearbeiten Sheet. Sie zählen nicht im Fortschritt. Dasselbe gilt im Sheet "Tag bearbeiten" für den gewählten Tag.
- **Weitere (ab Phase 13):** Unter der Hauptliste steht der Abschnitt **Weitere** mit den Habits, die am angezeigten Tag nicht dran oder schon erfüllt sind (Zuordnung 3.2).
  - Kopfzeile mit Haarlinie oben, Rolle `meta`: links "Weitere · 3" (Anzahl der Habits darin), rechts ein Chevron (zu: nach rechts, offen: nach unten). Tippen auf die ganze Zeile klappt auf und zu, kurz animiert, bei Reduce Motion ohne Bewegung. **Voreinstellung zugeklappt.** Der Zustand bleibt gespeichert (UserDefaults, Schlüssel `HestiaOtherExpanded`) und gilt für jeden Tag.
  - Aufgeklappt stehen darunter `HabitCard`s wie in der Hauptliste, in der gespeicherten Reihenfolge (`sortOrder`, dann `createdAt`), pausierte am Ende. Erledigte rutschen hier nicht nach unten, die Reihenfolge bleibt fest.
  - Abhaken, Counter, 7 Tage Punkte, Status und langes Drücken zum Bearbeiten funktionieren wie in der Hauptliste. Pausierte sind ausgegraut und nicht abhakbar (wie bisher).
  - Ist Weitere leer, fehlt der Abschnitt ganz. Ist die Hauptliste leer, aber Weitere nicht, zeigt das Band "Nichts fällig" und darunter steht nur Weitere.
  - Gilt genauso für vergangene Tage und im Sheet "Tag bearbeiten". Im Sortiermodus ist Weitere ausgeblendet, der Sortiermodus zeigt wie bisher alle aktiven Habits.
  - VoiceOver: Die Kopfzeile ist ein Button "Weitere, 3 Habits" mit Zustand auf- bzw. zugeklappt. Identifier `other-habits-toggle`, die Karten behalten ihre Identifier.
- **Reihenfolge:** Oben die offenen Habits, darunter die erledigten. Innerhalb beider Teile gilt die gespeicherte Reihenfolge (`sortOrder`, dann `createdAt`). Erledigt heißt: Am angezeigten Tag ist das Tagesziel erreicht, also Abhakkreis abgehakt bzw. Counter voll. Ein Wochen oder Monats Habit, dessen Fenster erfüllt ist, der am angezeigten Tag aber nicht abgehakt ist, bleibt oben. Wird ein Habit erledigt, rutscht er animiert nach unten, wird es wieder aufgehoben, rutscht er animiert zurück an seinen Platz.
- **Bearbeiten:** Festes Drücken (ca. 0,6 s) auf die Karte (nicht auf Kreis/Counter) öffnet das Bearbeiten Sheet. Die Karte sinkt dabei ein und gibt ein haptisches Signal, beim Auslösen ein festeres. Einfaches Tippen auf die Karte tut nichts. Für VoiceOver gibt es auf der Karte die Aktion "Bearbeiten".
- **Sortieren:** Im Sortiermodus Habits per Drag and Drop verschieben. Es gibt eine Reihenfolge für alle Habits, sie wird gespeichert. Auch im Sortiermodus stehen erledigte Habits unten. Verschieben lassen sich nur die offenen Habits, die erledigten sind im Sortiermodus nicht verschiebbar. Nach dem Verschieben bekommen die offenen Habits in ihrer neuen Reihenfolge die vorderen Plätze in `sortOrder`, die erledigten folgen dahinter in ihrer bisherigen Reihenfolge. *(Ab Phase 9.1 ersetzt durch den nächsten Punkt.)*
- **Sortieren (ab Phase 9.1):** Der Sortiermodus zeigt alle aktiven Habits (nicht beendet) in der gespeicherten Reihenfolge (`sortOrder`, dann `createdAt`), unabhängig davon, ob sie am angezeigten Tag fällig, erledigt oder pausiert sind. Alle lassen sich per Drag and Drop verschieben. Die Reihenfolge gilt für alle Tage. Erledigt oder pausiert sind im Sortiermodus nur leise markiert (z.B. Häkchen bzw. Kapsel "Pausiert" ausgegraut), sie verändern die Position nicht. Nach "Fertig" gilt in Heute wieder die Reihenfolge von oben: offene oben, erledigte darunter, pausierte am Ende, jeweils in der neuen gespeicherten Reihenfolge.

### 5.3 Sheet "Habit anlegen / bearbeiten"

Felder in dieser Reihenfolge:
1. Name
2. **Zusatz** (ab Phase 10): einzeiliges Textfeld unter dem Namen, optional, Platzhalter "z.B. 20 Min", höchstens 24 Zeichen (weitere Eingaben werden nicht angenommen). Leerzeichen am Anfang und Ende werden beim Speichern entfernt, ein leerer Zusatz wird nicht angezeigt.
3. Icon (Raster)
4. Farbe (8 Kreise, ab Phase 8 8 Quadrate in der Reihenfolge des Farbkreises, 4.2)
5. Rhythmus (Segmente: Täglich, Woche, Monat) und passende Einstellung darunter:
   - **Täglich:** Anzahl pro Tag als Stepper (ab Phase 8.1 `StepperControl`, ebenso Anzahl bei Woche und Monat und der Monatstag).
   - **Woche:** zweites Segmentfeld "Anzahl" / "Wochentage". Bei Anzahl ein Stepper ("2x pro Woche"), bei Wochentage 7 Kreise M D M D F S S.
   - **Monat:** zweites Segmentfeld "Anzahl" / "Monatstag". Bei Anzahl ein Stepper ("1x pro Monat"), bei Monatstag die Auswahl 1 bis 31 (ab Phase 9.1 `MonthDayPicker` statt `StepperControl`).
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
  1. Oben rechts in der Leiste der **runde Haken** "Fertig" (Systembutton, `role: .confirm`, getönt in `onColor`), der das Sheet schließt. Die Leiste hat keinen Titel und keinen Hintergrund, das Band reicht darunter bis zum oberen Rand des Sheets. *(Phase 11 hatte "Fertig" und "Bearbeiten" als eckige Buttons im Band, ab Phase 11.2 ersetzt: sie passten nicht zu den runden Ecken des Sheets. Bearbeitet wird im Detail nicht, sondern wie bisher über langes Drücken in Heute.)* Nach "Historie behalten" im Bearbeiten Sheet (aus Heute) zeigt das Detail den beendeten Habit.
  2. Meta Zeile (Rolle `meta`): die Rhythmus Zeile (4.5.1, mit Zusatz). Bei beendeten Habits stattdessen "Beendet am 3. Okt".
  3. Name in Rolle `display`.
  4. Aktueller Streak groß (Rolle `numeral`), daneben "Tage in Folge" (Einzahl "Tag in Folge") in Rolle `meta`.
  
  Darunter auf `background` ein Raster aus 2 × 2 Kennzahlen (`StatValue`), getrennt durch Haarlinien: **Quote 30 Tage** ("86 %" bzw. "–"), **Längster Streak**, **Erledigungen** (Summe aller Erledigungen, 3.7) und **Pausen** (Anzahl der Pausen, 3.7). Darunter der `MonthCalendar` in Habitfarbe in der kompakten Darstellung (4.5). **Ab Phase 11.1 stehen unter dem Band alle Texte, Haarlinien, Pfeile und Tageszahlen in der Habitfarbe** (`color`, Beschriftungen mit 70 %, Haarlinien mit 25 % bzw. 20 %) statt in `ink`; die Fläche bleibt `background`. Technisch überschreibt `inkOverride` (Environment) die Tinte von `StatValue`, `Hairline` und `MonthCalendar`. Pausierte Tage zeigen im kompakten Kalender wie `WeekDots` einen kurzen waagrechten Strich in der Tinte mit Pausen Deckkraft statt einer Fläche (ab Phase 11.2). Kein Icon im Detail, keine Leiste mit Titel, nur der runde Haken.
- *Bis Phase 10:* Habit antippen öffnet als Sheet das **Habit Detail**: Icon, Name, Rhythmus, eigener Monatskalender (nur dieser Habit, Tage mit Erledigung in Habitfarbe, bei Tagesziel größer 1 mit Teilfüllung), aktueller Streak, längster Streak, Quote 30 Tage (3.7). Der Monatskalender ist derselbe wie im Tab (siehe oben).
- Unter dem Monatskalender im Tab steht die Habit Liste. Der ganze Tab scrollt senkrecht, der Kalender selbst wird nur mit den Pfeilen gewechselt.

### 5.5 Einstellungen

- **Pausen:** Liste der laufenden und geplanten Pausen ("Läuft", "Geplant"), vergangene stehen nicht darin. Button "Neue Pause": Sheet mit Zeitraum (Startdatum, Enddatum, auch in der Vergangenheit) und Mehrfachauswahl der aktiven Habits. Habits, die im gewählten Zeitraum schon pausiert sind, sind deutlich markiert (Kapsel "Pausiert", ausgegraut, mit dem Zeitraum darunter), lassen sich aber trotzdem auswählen. Laufende Pause kann beendet werden ("Pause beenden"), geplante entfernt ("Pause entfernen").
  - **Ab Phase 9.1:** Start und Enddatum als `DateRow` ("Von", "Bis") in Appschrift statt System Datumsauswahl. "Bis" lässt keinen Tag vor "Von" zu. Wird "Von" hinter "Bis" gelegt, rückt "Bis" auf denselben Tag.
  - **Ab Phase 9.1:** Über der Liste der Habits steht eine Zeile "Alle auswählen" (Variante `text`). Sind schon alle ausgewählt, heißt sie "Alle abwählen" und hebt die Auswahl auf. Einzelne Habits lassen sich danach wie bisher an und abwählen.
- Beendete Habits haben keinen Platz in den Einstellungen (3.9).
- **Entwickler** (nur in Debug Builds sichtbar): "Testdaten erzeugen" und "Alle Daten zurücksetzen". Startargumente für Vorschauen und UI Tests: `-HestiaSampleData` und dazu `-HestiaSamplePauses` (Lesen war vorgestern und gestern pausiert, Sport hat eine geplante Pause ab übermorgen).
- **Fuß (ab Phase 12):** Ganz unten steht linksbündig die Wortmarke `HESTIA / HABITS` (zweizeilig, Barlow Condensed Regular, 56 pt, Versalien, Farbe `inkSecondary`) und darunter die Version in Rolle `meta`. Sie ist der einzige Ort der Wortmarke in der App und kein Button. **Ab Phase 14:** Rechts neben der Wortmarke steht klein dieselbe Figur wie in Heute ohne Habits (die Vestalin, 5.2), 80 pt hoch und damit etwas niedriger als die zwei Zeilen der Wortmarke, mit der Grundlinie von "HABITS" ausgerichtet. Sie ist dekorativ und für VoiceOver ausgeblendet.
- **Aufbau ab Phase 14** (von oben nach unten): Titel "Einstellungen", Abschnitt **Pausen** (wie bisher), Abschnitt **Kalender** (Wochenbeginn, ab Phase 15 Zeiträume), Abschnitt **Anzeige** (Darstellung, ab Phase 16 Sprache), Abschnitt **Über**, in Debug Builds **Entwickler**, ganz unten der Fuß. Alle Abschnitte sind `PaperSection`, es gibt keine neuen Bausteine.
- **Darstellung (ab Phase 14):** `SegmentedChoice` mit "System", "Hell", "Dunkel", Voreinstellung "System". Die Wahl gilt sofort für die ganze App samt Sheets (`.preferredColorScheme` an der Wurzel, `nil` bei System). Gespeichert in UserDefaults (`@AppStorage`, Schlüssel `HestiaAppearance`). Der Startbildschirm folgt weiter dem System, das lässt iOS nicht anders zu.
- **Wochenbeginn (ab Phase 14):** `SegmentedChoice` mit "Automatisch", "Montag", "Sonntag", Voreinstellung "Automatisch". Automatisch übernimmt den ersten Wochentag aus den Systemeinstellungen (`Locale.current`, iOS: Allgemein › Sprache & Region › Erster Wochentag). Gespeichert in UserDefaults (Schlüssel `HestiaFirstWeekday`).
  - Bei rollierenden Zeiträumen ändert der Wochenbeginn **nur die Anzeige**, nie die Rechnung. Status, Streaks und Quoten bleiben gleich. Ab Phase 15 legt er bei Zeiträumen "Kalender" auch fest, wann eine Woche für die Rechnung beginnt (3.5).
  - Er gilt für: Wochenstreifen in Heute (5.2), Wochentagszeile und Raster im `MonthCalendar` (Tab, Detail, `DateRow`), Reihenfolge der 7 Quadrate im `WeekdayPicker` (5.3), Reihenfolge der Tage in der Rhythmus Zeile (4.5.1, z.B. "SO · MI" statt "MI · SO"). Gespeichert bleibt `weekdays` unverändert (1 = Montag bis 7 = Sonntag).
  - **Kalenderwoche:** Bei Montag ist sie wie bisher die ISO Kalenderwoche. Bei einem anderen Wochenbeginn zählt sie Wochen ab diesem Tag mit der ISO Regel für die erste Woche (mindestens 4 Tage im neuen Jahr). So gehört jeder Tag im Wochenstreifen zur selben KW wie die Datumszeile.
- **Über (ab Phase 14):** Zeile "Über Hestia" im Abschnitt Über, Tippen öffnet ein Sheet (Titel "Über", Systembutton "Fertig"). Inhalt:
  - **Schriften:** je eine Zeile für Barlow Condensed, Antonio und Geist Mono mit Urheber und "SIL Open Font License 1.1". Tippen auf eine Zeile zeigt im Sheet den vollen Lizenztext aus der mitgelieferten Datei (`OFL-*.txt`, Rolle `body`, scrollbar).
  - **Bilder** (nur wenn die Stiche aus Phase 12 in der App sind): je eine Zeile mit Titel des Stichs, "The Metropolitan Museum of Art", "CC0".
  - Version und Wortmarke stehen nicht im Sheet, sondern weiter im Fuß.
- **Zeiträume (ab Phase 15):** `SegmentedChoice` mit "Rollierend" und "Kalender", Voreinstellung "Rollierend" (wie bisher). Darunter in Rolle `meta` eine Zeile, die die gewählte Variante erklärt: "Die letzten 7 bzw. 30 Tage" oder "Die laufende Woche bzw. der laufende Monat". Gilt für alle Habits mit Rhythmus pro Woche und pro Monat (3.5). Gespeichert in UserDefaults (Schlüssel `HestiaPeriods`). Ein Wechsel rechnet Status, Streaks und Quoten auch für die Vergangenheit neu (wie 3.10), gespeicherte Erledigungen ändern sich nicht.
- **Sprache (ab Phase 16):** Zeile "Sprache" im Abschnitt Anzeige, rechts die aktuelle Sprache der App in ihrem eigenen Namen ("Deutsch", "English"), dahinter ein Pfeil nach außen. Tippen öffnet die Seite der App in den iOS Einstellungen (`UIApplication.openSettingsURLString`), dort wählt man die Sprache. Es gibt keinen eigenen Umschalter in der App. iOS zeigt die Sprachwahl erst, wenn die App mehr als eine Sprache mitbringt.

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
- ab Phase 13: `section(habit, day)` liefert Hauptliste oder Weitere (3.2). `dayProgress` zählt nur Habits der Hauptliste.
- ab Phase 14: `weekStrip` und die Kalenderwoche bekommen den Wochenbeginn als Parameter (5.5). Bei Montag ist das Ergebnis wie bisher. Die Rechnung (Fenster, Status, Streaks, Quoten) kennt keinen Wochenbeginn.
- ab Phase 15: Die `HabitEngine` bekommt Zeiträume (rollierend, Kalender) und Wochenbeginn als Eigenschaften, wie den Kalender. Alle Fensterberechnungen (`windowProgress`, `donePoints`, `status`, Streaks, Quote) gehen über eine Stelle, die je nach Zeitraum das rollierende Fenster oder den Kalenderzeitraum liefert. Ansichten erzeugen die Engine mit den aktuellen Einstellungen, ändert sich eine, rechnen sie neu.
- Nimmt das "heutige" Datum immer als Parameter entgegen, damit Tests mit festen Daten möglich sind.

**Einstellungen (ab Phase 14)** liegen nicht in SwiftData, sondern in UserDefaults (`@AppStorage`): `HestiaAppearance` (system, light, dark), `HestiaFirstWeekday` (automatic, monday, sunday) und ab Phase 15 `HestiaPeriods` (rolling, calendar). Fehlt ein Wert, gilt die Voreinstellung. Die Sprache speichert iOS selbst.

---

## 7. Phasen

Jede Phase baut auf der vorherigen auf und ergibt eine App, die auf dem iPhone läuft.

**Für alle Phasen gilt zusätzlich als Definition of Done:**
- [ ] Projekt baut in Xcode ohne Fehler und ohne Warnungen.
- [ ] App startet auf dem iPhone 16 Pro (oder Simulator) ohne Absturz.
- [ ] Alle Unit Tests sind grün. Die UI Tests aus "Komplett" sind grün (ein Lauf am Ende der Phase).
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
- Leerzustände: Heute ohne Habits ("Ersten Habit anlegen" mit Button, bis Phase 15 "Lege deinen ersten Habit an"), Kalender ohne Daten, keine Pausen.
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

### Phase 8.1: Eigene Tab Bar und Nacharbeiten aus Phase 8

**Ziel:** Außerhalb von Sheets gibt es kein Liquid Glass mehr. Unten steht eine flache Leiste im Hermes Stil, und Plus und Sortieren in Heute haben keine Glasfläche. Dazu werden die Stellen behoben, die bei der Durchsicht der Screenshots nach Phase 8 aufgefallen sind.

**Umfang**
- **`PaperTabBar`** (4.5, 5.1): eigene flache Tab Bar mit Haarlinie oben und 2 pt Strich über dem gewählten Tab. Die System Tab Bar wird ausgeblendet, `TabView` bleibt für den Zustand der Tabs. Die Auswahl liegt in einem kleinen Enum (z.B. `AppTab`).
- Inhalt, Sheets, Scrollen nach oben beim erneuten Tippen, Dynamic Type, Large Content Viewer und VoiceOver wie in 5.1.
- **Plus und Sortieren in Heute:** Die Toolbar Einträge bekommen keine Glasfläche mehr (`sharedBackgroundVisibility(.hidden)`) und nutzen `HermesButtonStyle`:
  - Sortieren als Text "Sortieren" bzw. im Sortiermodus "Fertig" (Variante `text`, Rolle `label`), ohne Symbol.
  - Plus als Quadrat (Variante `secondary`, Fläche `ink` mit 14 %, Plus Symbol in `ink`), VoiceOver "Neuer Habit".
  - Identifier (`sort-toggle` usw.) bleiben gleich.
  - Abweichung: Beide stehen nicht mehr in der Navigationsleiste, sondern im Inhalt von Heute, Sortieren links und Plus rechts über dem Kopfbereich. Grund: Die Leiste behielt nach einem Wechsel zwischen Hell und Dunkel bei laufender App ihre Farben nicht. Im Sortiermodus steht "Fertig" oben links in der Liste. In Phase 9 ziehen beide in Kopfband und Listenkopf um (5.2).
- **Scrollkante in Heute:** Die harte Scrollkante aus Phase 3.2 (`scrollEdgeEffectStyle(.hard)`) entfällt, Heute nutzt die Standardkante. Grund: Mit der harten Kante aktualisierte sich die Statusleiste beim Wechsel zwischen Hell und Dunkel bei laufender App nicht.
- Dasselbe gilt für alle anderen Buttons in der Navigationsleiste eines Tabs, falls vorhanden (Kalender, Einstellungen). Sheets behalten ihre Systemleisten (4.4).
- **Fehler: Navigationsleiste im falschen Modus.** Nach dem Wechsel zwischen Hell und Dunkel bleibt die Leiste in Heute in der Farbe des Modus beim Start (z.B. hell im dunklen Modus). Ursache ist vermutlich `UIColor(Theme.background)` in `NavigationAppearance`, das die Farbe beim Start fest auflöst. Die Farben für UIKit (Hintergrund, Titel, Tönung) müssen als dynamische `UIColor` aus `Theme` kommen, damit sie dem Modus folgen.
- **`StepperControl`** (4.5) statt System `Stepper` (Anzahl bei Täglich, Woche, Monat) und statt Menü für den Monatstag im Sheet (5.3). Identifier `target-stepper` und `monthday-picker` bleiben am Baustein, die Tasten bekommen `<Identifier>-minus` und `<Identifier>-plus`.
- **Kalender im Tab in Blau:** Die Einfärbung der Tage nutzt `progress` (4.2) statt `ink`, damit sie im dunklen Modus blau und nicht grau ist. Die Tageszahl auf kräftiger Fläche steht in `background`.

**Aufräumen (Pflicht, keine Überbleibsel)**
- Die Tönung der System Tab Bar aus Phase 8 entfernen, falls sie danach nicht mehr wirkt.
- UI Tests, die den System Stepper oder das Monatstag Menü bedienen, auf die neuen Tasten umstellen.
- Eine Suche in `Habitus/` nach `Stepper(`, `pickerStyle(.menu)` und `UIColor(Theme.` findet nichts mehr.
- UI Tests, die Tabs über `app.tabBars` ansteuern, auf die Identifier `tab-today`, `tab-calendar`, `tab-settings` umstellen. Am besten eine gemeinsame Hilfsfunktion in den UI Tests (z.B. `app.openTab(.calendar)`), damit das nur an einer Stelle steht.
- Abschluss: Eine Suche in `Tests/` nach `tabBars` findet nichts mehr. Eine Suche in `Habitus/` findet keinen Button in einer Tab Navigationsleiste ohne `sharedBackgroundVisibility(.hidden)`.

**Pflicht Testfälle**
- UI Test: Tippen auf `tab-calendar` zeigt den Kalender, `tab-settings` die Einstellungen, `tab-today` wieder Heute. Der gewählte Tab ist jeweils als ausgewählt markiert (`isSelected`).
- UI Test: Heute an einem vergangenen Tag öffnen, zum Kalender und zurück wechseln: Heute zeigt noch denselben Tag (Zustand bleibt erhalten).
- UI Test: Mit Testdaten in Heute ganz nach unten scrollen: die letzte Karte ist vollständig sichtbar und bedienbar, nicht von der Leiste verdeckt.
- UI Test: Plus öffnet das Sheet "Neuer Habit", "Sortieren" startet den Sortiermodus und heißt dann "Fertig".
- UI Test: Im Sheet "Neuer Habit" erhöht `target-stepper-plus` die Anzahl, an der oberen Grenze ist die Taste gesperrt. Monat + Monatstag: `monthday-picker-plus` stellt vom 1. auf den 2.
- Unit Test: Die Farben für die Navigationsleiste ergeben aufgelöst mit hellem bzw. dunklem `UITraitCollection` `paper` bzw. `night`.
- Alle bestehenden UI Tests sind nach der Umstellung auf die neuen Identifier weiter grün.

**Definition of Done**
- [x] Unten steht eine flache Leiste mit Haarlinie, ohne Glas und ohne Schweben. Der gewählte Tab hat oben einen Strich.
- [x] Plus und Sortieren in Heute haben keine Glasfläche mehr.
- [x] Außerhalb von Sheets ist nirgends Liquid Glass zu sehen.
- [x] Wechsel zwischen Hell und Dunkel bei laufender App: Leisten und Hintergründe wechseln sofort mit, nirgends bleibt eine helle Fläche im dunklen Modus.
- [x] Im Sheet gibt es keinen System Stepper und kein Menü mehr, Anzahl und Monatstag haben quadratische Tasten.
- [x] Der Kalender im Tab ist in Hell und Dunkel blau eingefärbt.
- [x] Beim Tabwechsel bleibt der Zustand jedes Tabs erhalten.
- [x] Die letzte Zeile jeder Liste ist über der Leiste erreichbar.
- [x] Bei größter Schriftgröße bricht kein Tab Label um, mit VoiceOver sind die drei Tabs und der gewählte Tab klar erkennbar. *Einschränkung: Der VoiceOver Teil wurde nicht mit VoiceOver selbst geprüft. Der Accessibility Baum zeigt die ausgeblendete System Tab Bar weiterhin, und "Tab 1 von 3" ist nicht bestätigt. Die Einschränkung hat die Nutzerin akzeptiert.*
- [x] Die Suche aus "Aufräumen" findet nichts mehr.

---

### Phase 9: Heute mit Kopfband und Wochenstreifen

**Ziel:** Heute sieht aus wie der erste Mockup: ein blaues Band oben mit großem Titel, großem Fortschritt und Wochenstreifen, darunter die flache Liste. Ich kann einen Tag der Woche direkt antippen.

**Umfang**
- `DayHeader` (4.5, 5.2) mit Datumszeile inklusive Kalenderwoche, Titel relativ zu heute, Fortschritt "erledigt/Punkte" mit Prozent, `SegmentBar` und `WeekStrip`. Das Band ist in Hell und Dunkel Markenblau und reicht bis unter die Statusleiste. Die Statusleiste ist auf dem Band lesbar (helle Schrift, auch im hellen Modus), auf welchem Weg ist frei.
- In Heute gibt es keine Navigationsleiste mehr. Der Plus Button sitzt in der Datumszeile, "Heute ›" auf Höhe des Titels, "Sortieren" / "Fertig" im Listenkopf (5.2).
- **Listenkopf** mit Anzahl der Habits ("6 Habits" / "1 Habit").
- **Kleine Leiste beim Scrollen** in `band` mit "Heute · 4/6" und Plus Button (5.2).
- **Wochenstreifen antippen** wechselt den Tag mit derselben Animation wie Wischen. Zukünftige Tage sind blass und nicht antippbar.
- **Animation:** Datumszeile, Titel, Fortschritt und Liste gleiten wie bisher (5.2). Der Wochenstreifen gleitet nur, wenn sich die Woche ändert. Sonst wandert nur die Markierung des angezeigten Tags (kurz).
- `HabitEngine`: `isoWeek(day)` und `weekStrip(day, today)` (6), ohne SwiftUI, mit Unit Tests.
- Das Sheet "Tag bearbeiten" behält seinen einfachen Kopf (Navigationstitel mit Datum), zeigt aber dieselbe Liste.
- **`HabitCard` wie im Mockup:** Die 7 Tage Punkte stehen in derselben Zeile rechts neben der Rhythmus Zeile (4.5). Gilt auch für "Tag bearbeiten".

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
- UI Test (bestehenden Wisch Test anpassen): Mit Testdaten zeigt der Titel "Heute", nach Wischen nach rechts "Gestern". Die Datumszeile passt jeweils zum Tag.
- UI Test: Tippen auf einen früheren Tag im Wochenstreifen zeigt diesen Tag (Titel und Datumszeile). Tippen auf einen zukünftigen Tag ändert nichts.
- Plus und Sortieren: den bestehenden Test `testPlusAndSortInTheBar` an die neuen Orte anpassen, kein neuer Test.

**Definition of Done**
- [x] Oben in Heute steht ein blaues Band mit Datum und Kalenderwoche, großem Titel, großem Fortschritt, Balken und Wochenstreifen, in Hell und Dunkel.
- [x] Der Fortschritt zählt genau wie vorher (3.4), nur die Darstellung ist neu.
- [x] Auf den Karten stehen die 7 Tage Punkte neben der Rhythmus Zeile.
- [x] Ich kann einen Tag der aktuellen Woche antippen und lande dort. Zukünftige Tage lassen sich nicht antippen. Wischen funktioniert weiter, auch über Wochengrenzen.
- [x] Beim Scrollen erscheint oben die schmale blaue Leiste mit Titel und Fortschritt, der Plus Button ist immer erreichbar.
- [x] Die Statusleiste ist auf dem Band gut lesbar. *Umsetzung: iOS passt die Schrift der Statusleiste selbst an den Inhalt darunter an (hell auf dem Band, dunkel im Sortiermodus auf Papier), dafür war kein eigener Code nötig.*
- [x] Die Suche aus "Aufräumen" findet nichts mehr.

---

### Phase 9.1: Nacharbeiten nach Phase 9

**Ziel:** Kleine Stellen, die beim Benutzen nach Phase 9 aufgefallen sind: ein durchgehender Fortschrittsbalken, Luft um den Rahmen der 7 Tage Punkte, eine schnelle Auswahl des Monatstags, eine Datumsauswahl in Appschrift mit "Alle auswählen" bei Pausen, Sortieren aller Habits und ein schöner Übergang zwischen den Tabs.

**Umfang**
- **`SegmentBar` immer durchgehend** (4.5): Bisher war der Balken bis 12 Punkte in einzelne Stücke geteilt und sah deshalb an manchen Tagen gestrichelt aus. Jetzt ist er immer ein durchgehender Balken mit Füllung nach Prozent, im Kopfband und in der kleinen Leiste. Die Füllung ändert sich kurz animiert. Die Zählung (3.4) bleibt gleich.
- **Rahmen der 7 Tage Punkte** (4.5 `WeekDots`): Der Rahmen um den angezeigten Tag stößt nicht mehr an das Nachbarquadrat. Vor dem angezeigten Tag steht mehr Abstand, die übrigen 6 Quadrate behalten ihre Abstände. Gilt überall, wo `WeekDots` steht (Heute, Tag bearbeiten).
- **Monatstag mit Raster** (4.5 `MonthDayPicker`, 5.3): Unter Monat + Monatstag wählt man den Tag mit einem Tippen in einem Raster 1 bis 31 statt mit Plus und Minus. Anzahl bei Täglich, Woche und Monat bleibt `StepperControl`.
- **Pause: Datum in Appschrift** (4.5 `DateRow`, 5.5): "Von" und "Bis" sind eigene Zeilen in Appschrift, die Auswahl erfolgt im aufklappenden `MonthCalendar`. Keine System Datumsauswahl mehr in der App.
- **Pause: "Alle auswählen"** (5.5) über der Liste der Habits, umschaltbar auf "Alle abwählen".
- **Alle Habits sortieren** (5.2): Im Sortiermodus stehen alle aktiven Habits, auch erledigte, pausierte und am Tag nicht fällige, und alle lassen sich verschieben. Außerhalb des Sortiermodus bleiben erledigte unten und pausierte am Ende. Die Reihenfolge wird wie bisher in `sortOrder` gespeichert. Die Logik für die neue Reihenfolge liegt ohne Oberfläche (z.B. in `Habit.saveOrder` bzw. einer reinen Funktion daneben) und wird mit Unit Tests geprüft.
- **Wochenstreifen ohne Verzögerung** (5.2): Beim Wischen durch die Tage erschien der Wochenstreifen bisher spürbar später als der Rest, weil er als drittes Glied der Kaskade (`dayEntrance` mit `index` 2) verzögert hereinfedert. Er gleitet jetzt gleichzeitig und gleich schnell wie Datumszeile und Titel, ohne Kaskade. Die Markierung des Tags wandert ebenso ohne Verzögerung. Datumszeile, Titel, Fortschritt und Liste behalten ihre Animation.
- **Kleine Leiste beim Scrollen höher** (5.2): Bisher endete der Plus Button fast mit der Unterkante der Leiste und wirkte abgeschnitten. Die Leiste bekommt oben und unten mehr Innenabstand, Titel und Plus Button stehen mittig mit Luft.
- **Übergang zwischen den Tabs** (5.1): Strich in der `PaperTabBar` gleitet zum neuen Tab, der Inhalt blendet mit kleinem Versatz aus der Richtung des Tabs ein (4.7).

**Aufräumen (Pflicht, keine Überbleibsel)**
- Löschen: Fall `segments` in `SegmentBarModel` samt Darstellung, `Theme.segmentBarMaxSegments` und `Theme.segmentBarSpacing`, falls danach unbenutzt. Kommentare in `SegmentBar.swift` anpassen.
- Löschen: `StepperControl` für den Monatstag im Sheet. Der Identifier `monthday-picker` sitzt am `MonthDayPicker`, die Felder heißen `monthday-<n>` (z.B. `monthday-15`). `monthday-picker-minus` und `monthday-picker-plus` gibt es nicht mehr.
- Löschen: `DatePicker` in `PauseEditorSheet`. Identifier `pause-start` und `pause-end` sitzen an den `DateRow`s. Neu: `pause-select-all`.
- Löschen: im Sortiermodus die Trennung in verschiebbare und nicht verschiebbare Habits (`moveDisabled` an Habit Zeilen, Filter nach offen und erledigt in `HabitSortList`). Der Listenkopf bleibt nicht verschiebbar.
- UI Tests anpassen, die `monthday-picker-plus`, `monthday-picker-minus`, `DatePicker` (z.B. `datePickers`) oder das Nicht Verschieben erledigter Habits nutzen.
- Abschluss: Eine Suche in `Habitus/` nach `DatePicker(`, `segmentBarMaxSegments` und `monthday-picker-plus` findet nichts mehr, eine Suche in `Tests/` nach `datePickers` und `monthday-picker-plus` ebenfalls. Ausnahme ist nur diese Spezifikation.

**Pflicht Testfälle**
- Unit Test: `SegmentBarModel` ergibt für 4 von 6 Punkten einen durchgehenden Balken mit 67 %, für 5 von 16 mit 31 %, für 0 Punkte keinen Balken.
- Unit Test: Neue Reihenfolge beim Sortieren: Wird ein erledigter Habit vor einen offenen geschoben, steht er danach auch in `sortOrder` davor. Pausierte und am Tag nicht fällige Habits behalten ihre Plätze relativ zueinander, wenn sie nicht bewegt werden.
- Unit Test: Die Reihenfolge in Heute (offen, erledigt, pausiert) folgt nach dem Sortieren innerhalb jeder Gruppe der neuen `sortOrder`.
- UI Test (bestehenden Monatstag Test anpassen, kein neuer): Monat + Monatstag, `monthday-15` antippen, sichern: die Rhythmus Zeile zeigt "Am 15. des Monats". Bearbeiten zeigt `monthday-15` ausgewählt.
- UI Test (bestehenden Pausen Test anpassen, kein neuer): Im Sheet "Neue Pause" wählt `pause-select-all` alle Habits aus, ein zweites Tippen keinen. "Von" über `pause-start` auf einen früheren Tag setzen und sichern: die Pause steht in der Liste.
- Tabwechsel, Rahmen der Punkte und Balken werden nicht mit UI Tests geprüft, sondern beim Durchsehen.

**Definition of Done**
- [x] Der Fortschrittsbalken im Kopfband ist an jedem Tag durchgehend, egal wie viele Habits fällig sind.
- [x] Der Rahmen um den angezeigten Tag in den 7 Tage Punkten hat sichtbar Luft zum Nachbarquadrat.
- [x] Den Monatstag stelle ich mit einem Tippen ein, auch den 31.
- [x] Im Sheet "Neue Pause" stehen die Daten in der Schrift der App, und ich kann mit einem Tippen alle Habits auswählen.
- [x] Im Sortiermodus kann ich alle Habits verschieben, auch erledigte. Die neue Reihenfolge sehe ich auch an den nächsten Tagen, erledigte stehen in Heute weiter unten.
- [x] Beim Wischen durch die Tage ist der Wochenstreifen genauso schnell da wie Datum und Titel, auch über Wochengrenzen.
- [x] In der kleinen Leiste beim Scrollen steht der Plus Button mit Luft nach oben und unten, nichts wirkt abgeschnitten.
- [x] Beim Wechsel zwischen Heute, Kalender und Einstellungen gleitet der Strich in der Leiste mit, und der Inhalt erscheint weich statt hart. *Einschränkung: Die Bewegung selbst wurde nicht Bild für Bild angesehen, nur der Endzustand nach dem Wechsel im Screenshot. Das Durchsehen bleibt bei der Nutzerin.*
- [x] Die Suche aus "Aufräumen" findet nichts mehr.

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
- [x] Ich kann einen Zusatz eingeben, ändern und löschen. Mehr als 24 Zeichen gehen nicht.
- [x] Der Zusatz steht vorne in der Rhythmus Zeile in Heute, im Kalender und im Detail.
- [x] Habits ohne Zusatz sehen aus wie vorher.
- [x] Nach dem Update sind alle Habits und Erledigungen noch da.

*Geprüft im Simulator: Eine Version vor Phase 10 legte die Testdaten an, die neue Version darüber installiert zeigt dieselben 13 Habits und 6/15 erledigt, Habits ohne Zusatz unverändert. Zusatz in Hell und Dunkel im Screenshot gesehen. Anlegen, Bearbeiten und Löschen prüft der UI Test.*

---

### Phase 11: Habit Detail als eigene Seite

**Ziel:** Das Habit Detail sieht aus wie der dritte Mockup: ein Band in der Farbe des Habits mit Name und großem Streak, darunter vier Kennzahlen und der Kalender. Ich kann den Habit von dort aus bearbeiten.

**Umfang**
- Detail mit Band in Habitfarbe, Kennzahlen Raster und Kalender (5.4). Die Statusleiste ist auf dem Band lesbar.
- Das Sheet "Habit bearbeiten" öffnet sich nicht aus dem Detail *(ab Phase 11.2: gestrichen)*. Bei beendeten Habits steht "Beendet am …" in der Meta Zeile.
- **Leiste ohne Titel und Hintergrund** im Detail, nur der runde Haken "Fertig" oben rechts (5.4).
- **`StatValue`** zeigt nur die Zahl, die Einheit steht in der Beschriftung (4.5). Gilt auch für `HabitStatRow`.
- **Kompakter Kalender** im Detail: Quadrate ohne Tageszahl wie im Mockup (4.5). Der Kalender im Tab behält die Tageszahlen.
- Neue Kennzahlen **Erledigungen** und **Pausen** (3.7): `HabitStatistics` bekommt `totalCompletions` und `pauseCount`, berechnet in der `HabitEngine`, mit Unit Tests.

**Aufräumen (Pflicht, keine Überbleibsel)**
- Löschen: Kopf mit Icon im Detail, Navigationstitel "Habit Detail", der Abschnitt "Statistik" als Überschrift.
- Identifier: `detail-name`, `detail-rhythm`, `stat-current-streak`, `stat-longest-streak`, `stat-rate-30` bleiben gleich. Neu: `stat-total`, `stat-pauses`, `detail-done`.
- UI Tests anpassen, die den Kopf mit Icon oder den Titel "Habit Detail" erwarten (u.a. `CalendarPhase5UITests`, `CalendarPhase51UITests`).

**Pflicht Testfälle**
- Unit Test: 3x täglich, an 3 Tagen voll erledigt, an einem Tag 1: `totalCompletions` ist 10.
- Unit Test: Beendeter Habit: Erledigungen nach dem Tag des Beendens zählen nicht.
- Unit Test: Eine vergangene, eine laufende und eine geplante Pause: `pauseCount` ist 2. Ohne Pausen 0.
- UI Test (bestehenden Test `testDetailShowsStreaksAndRate` erweitern): Detail eines Habits aus den Testdaten zeigt alle fünf Kennzahlen (Streak im Band, vier im Raster).
- *(Ab Phase 11.2 entfällt:)* "Bearbeiten" im Detail.

**Definition of Done**
- [x] Das Detail hat oben ein Band in der Farbe des Habits mit Name und großem Streak, in Hell und Dunkel gut lesbar.
- [x] Darunter stehen Quote 30 Tage, Längster Streak, Erledigungen und Pausen als große Zahlen ohne Einheit, darunter der kompakte Kalender in Habitfarbe.
- [x] Im Detail gibt es keine Leiste mit Titel, nur den runden Haken oben rechts *(Phase 11.2)*.
- [x] Ich kann einen aktiven Habit aus dem Detail heraus bearbeiten und beenden. Ein beendeter Habit lässt sich dort nicht bearbeiten.
- [x] Die Kennzahlen stimmen mit einem von Hand nachgerechneten Beispiel aus den Testdaten überein.

*Geprüft im Simulator: Band in Habitfarbe in Hell und Dunkel gut lesbar, Kennzahlen von Hand nachgerechnet ("Lesen": 48 Erledigungen, 0 Pausen, 79 %; mit Beispielpausen 1 Pause und 81 %). Komplett-Lauf grün. Ab Phase 11.1 und 11.2: durchgehend Habitfarbe unter dem Band, runder Haken statt Buttons im Band, Pausentage als Strich.*

---

### Phase 12: Name, Logo und App Icon

**Ziel:** Die App heißt Hestia und hat Wortmarke, App Icon, Startbildschirm und zwei Stiche in den Leerzuständen, alles im Hermes Stil.

**Entschieden:**
- **Name:** Hestia (Herdfeuer, das täglich gepflegt wird). Es gibt noch keine echten Daten, deshalb wird alles umbenannt, nicht nur der Anzeigename:
  - Bundle Identifier `de.vanheyden.Hestia`, `de.vanheyden.HestiaTests`, `de.vanheyden.HestiaUITests`. iOS behandelt das als neue App mit eigenem Datencontainer, Habits aus der alten App kommen nicht mit. Die alte App "Habitus" wird vom Gerät und aus dem Simulator gelöscht.
  - Modul, Targets, Scheme, Testpläne, Projekt (`Hestia.xcodeproj`) und Ordner (`Hestia/`, Tests bleiben in `Tests/`) heißen `Hestia`, `HestiaTests`, `HestiaUITests`, die App Struktur `HestiaApp`.
  - Startargumente `-HestiaResetData`, `-HestiaSampleData`, `-HestiaSamplePauses`, UserDefaults Schlüssel `HestiaDayOffset`. Alle UI Tests und Kommentare ziehen mit.
  - Ältere Phasen in dieser Spezifikation nennen weiter `Habitus` (Verlauf), sie werden nicht umgeschrieben.
- **Bildmarke:** eine Flamme als Linolschnitt, Blau auf Papier. Quelle ist `Branding/flame-linocut-source.webp` (KI erzeugt, keine Lizenz nötig), `Branding/render_flame_icon.py` liest daraus die Maske und baut die drei Icons. Hell ist Blau auf Papier, dunkel Papier auf Nachtblau, getönt Weiß auf Schwarz. Die Flamme füllt etwa 86 % der Höhe (`FLAME_HEIGHT` 880, oben 46 px und unten 96 px Rand) und ist leicht aufgeraut (wellige Kante, kleine Fehlstellen, feste Seed). Das ersetzt die frühere Idee mit Markenblau Fläche, weil die Schnitte als helle Linien auf Blau klein besser lesbar sind. **Größe und Proportionen des Icons bleiben, wie sie sind.**
- **Wortmarke:** `HESTIA / HABITS`, zweizeilig wie "HERMES / AGENT" bei Hermes, in Barlow Condensed Regular, Versalien. In der App steht sie nur an einer Stelle: ganz unten in den Einstellungen (5.5).
- **Startbildschirm:** Hintergrund in der Farbe `background`, mittig nur die Flamme (`Branding/flame-mark.png`, fast bildschirmfüllend: 560 pt hoch, etwa 345 pt breit; nach der Sichtung von 120 pt vergrößert), kein Text. Hell Blau auf Papier, dunkel Papier auf Nachtblau, wie das Icon. Das ersetzt den generierten leeren Startbildschirm.
- **Bildwelt:** zwei gemeinfreie Stiche (Met Open Access, CC0), blau gerastert, je einer in einem Leerzustand:
  - **Heute ohne Habits:** Vestalin (Met 402697).
  - **Kalender ohne Daten:** Fackel zwischen Altar und Statuette (Met 371844).
  - *(Nach der Sichtung getauscht, ursprünglich stand die Fackel in Heute.)*
  - Die Leerzustände in Einstellungen ("Keine Pausen") und im Sheet "Tag bearbeiten" bekommen kein Bild. Höchstens ein Bild pro Leerzustand.
  - Das Bild steht über dem Titel, auf Inhaltsbreite im Seitenverhältnis des Stichs, höchstens etwa 200 pt hoch (Startwert, nach der ersten Sichtung anpassen). Es ist dekorativ und für VoiceOver ausgeblendet. *(Umgesetzt: beide Stiche sind hochkant und stehen deshalb 200 pt hoch, linksbündig wie der Text, `Theme.engravingMaxHeight`.)*
  - Quelle sind die Versionen "web-large" der Met (ca. 550 × 625 px), nicht die Originale. Das reicht für 200 pt Höhe.
  - Der Stich wird nicht in Punkte zerlegt, sondern aus dem Rotkanal als Tinte gelesen: Papier, Flecken und Bleistiftnotizen fallen weg, die Linien des Stichs bleiben. Hell Markenblau, dunkel Papier, jeweils auf transparentem Grund.
  - Passt ein Stich nach der Sichtung nicht zum Hermes Stil (neben dem Linolschnitt der Flamme), entscheiden wir für diesen Stich einzeln, ob er bleibt.

**Später (nicht in Phase 12):** Feuer als Zustand. Aus der eigenen Flammenmaske werden Stufen abgeleitet (Funke für einen neuen Habit, Glut für eine Pause, volle Flamme für einen langen Streak). Das widerspricht der Regel "Kein Flammensymbol" an den Streak Zahlen (4.5 `HabitStatRow`) und müsste dort neu entschieden werden.

**Umfang**
- **Umbenennung** wie oben (ein Schritt, mechanisch: Ordner und Projekt mit `git mv`, Targets, Scheme, Testpläne, Bundle Identifier, Startargumente, `@testable import Hestia`). `INFOPLIST_KEY_CFBundleDisplayName` bleibt `Hestia`. *(Anzeigename erledigt.)*
- **App Icon:** Flamme in Markenblau `#0000F2` auf Papier `#F2F2F2`, Varianten hell, dunkel und getönt (`AppIcon-light/-dark/-tinted`). `Branding/render_flame_icon.py` erzeugt alle Varianten, der Pfad zum Asset Katalog dort wird auf `Hestia/` angepasst. *(Icons erledigt.)* `Branding/render_icon.py` und `habitus-mark.svg` gehören zum alten Wochenkreis Icon.
- **Wortmarke:** Fuß der Einstellungen (5.5) als Text in Barlow Condensed Regular, kein Bild. Eine Vektorvorlage in `Branding/` ist optional. *(Umgesetzt: Schriftrolle `wordmark` in `Theme.Typography`, 56 pt, 4 % Laufweite, linksbündig. Version als "Version 1.0 (1)" aus `CFBundleShortVersionString` und `CFBundleVersion`.)*
- **Startbildschirm:** Eintrag `UILaunchScreen` mit Bild und Hintergrundfarbe aus dem Asset Katalog (je hell und dunkel) statt `INFOPLIST_KEY_UILaunchScreen_Generation`. *(Umgesetzt: `Hestia/Info.plist` enthält nur `UILaunchScreen` und wird mit der erzeugten Info.plist zusammengeführt. Bild `LaunchFlame` und Farbe `LaunchBackground` erzeugt `Branding/render_launch_flame.py` aus `flame-mark.png`.)*
- **Bildwelt:** Quellen mit Objektnummer, Link und Lizenz in `Branding/QUELLEN.md` (die Lizenz wird vor dem Einsatz auf der Seite der Met geprüft). Rasterung und Einfärbung per Skript `Branding/render_engravings.py`, keine Bilder von Hand bearbeitet. Die fertigen Bilder (hell und dunkel) liegen in `Assets.xcassets`, `EngravingImage` zeigt sie in `EmptyState`.

**Definition of Done**
- [x] Das App Icon ist auf dem Homescreen sichtbar, in Hell, Dunkel und getönt, in unveränderter Größe.
- [x] Unter dem Icon steht "Hestia".
- [x] Bundle Identifier, Projekt, Targets, Scheme, Testpläne, Ordner und Startargumente heißen Hestia. Eine Suche nach `Habitus` im Projekt (außer in dieser Spezifikation und den alten Dateien in `Branding/`) findet nichts mehr.
- [x] Die neue App startet auf einem Gerät ohne die alte App leer und ohne Absturz. Angelegte Habits sind nach einem Neustart noch da.
- [x] Der Startbildschirm zeigt die Flamme, in Hell und Dunkel, ohne weißen Blitz.
- [x] Ganz unten in den Einstellungen stehen `HESTIA / HABITS` und die Version, in Hell und Dunkel gut lesbar.
- [x] Heute ohne Habits zeigt die Vestalin, der Kalender ohne Daten die Fackel, in Hell und Dunkel. Andere Leerzustände haben kein Bild.
- [x] Alle Bildquellen sind mit Lizenz in `Branding/QUELLEN.md` dokumentiert.
- [x] Unit Tests und die UI Tests aus "Komplett" laufen mit den neuen Startargumenten grün.

*Geprüft im Simulator (iPhone 18 Pro): Homescreen zeigt "Hestia" mit der Flamme, Icons unverändert. Startbildschirm hell Blau auf Papier, dunkel Papier auf Nachtblau, ohne weißen Blitz. Vestalin in Heute und Fackel im Kalender in Hell und Dunkel (nach der Sichtung getauscht), "Keine Pausen" und "Nichts fällig" ohne Bild. Wortmarke und "Version 1.0 (1)" unten in den Einstellungen. Alte App und alter UI Test Runner aus beiden Simulatoren gelöscht. Unit Tests (250) grün. Komplett-Lauf auf dem Endstand (große Flamme, Wortmarke links, Stiche getauscht) vollständig grün, alle 20 UI Tests. Im ersten Lauf war `testCreateCheckUncheckAndPersist` einmal fehlgeschlagen (wackelt beim schnellen Abhaken und Aufheben). Auf dem iPhone 16 Pro: "Habitus" ist nicht mehr installiert. Hestia gelöscht und neu installiert, startet leer (0 Habits) und ohne Absturz. Danach die vorher gesicherten Daten (16 Habits, 5 Erledigungen) zurückgespielt, nach dem Neustart vollständig da.*

---

### Phase 13: Weitere Habits in Heute

**Ziel:** In Heute sehe ich oben nur, was am Tag wirklich zu tun ist. Darunter, eingeklappt, stehen unter "Weitere" alle anderen aktiven Habits, die ich trotzdem abhaken kann.

**Entschieden:**
- In Weitere stehen: Habits mit festen Wochentagen oder festem Monatstag, die am Tag nicht fällig sind, Wochen und Monats Habits, deren Ziel schon erfüllt und deren Status grün ist, und pausierte Habits (3.2).
- Die Zuordnung rechnet ohne die Erledigung des angezeigten Tags. Ein Habit wechselt beim Abhaken also nie die Liste (3.2).
- Habits in Weitere zählen nie im Tagesfortschritt (3.4), auch abgehakt nicht. Ihre Erledigungen zählen sonst ganz normal (Fenster, 7 Tage Punkte, Streaks, Kalender).
- Weitere ist einklappbar, Voreinstellung zu, der Zustand bleibt gespeichert (5.2).
- Folge für den Kalender: Die Einfärbung der Tage nutzt den Tagesfortschritt. Tage, an denen ein erfüllter Wochen oder Monats Habit bisher als erledigter Punkt zählte, ändern dadurch leicht ihre Einfärbung. Das ist gewollt.

**Umfang**
- **Engine:** `section(habit, day)` (Hauptliste oder Weitere) und `dayProgress` nur über die Hauptliste (6), mit Unit Tests.
- **Heute und Sheet "Tag bearbeiten":** Abschnitt Weitere unter der Liste (5.2), Listenkopf zählt nur die Hauptliste, pausierte Habits wandern ans Ende von Weitere.
- **Testdaten:** ein zusätzlicher Habit mit festem Wochentag, der heute nie fällig ist (z.B. der Wochentag von übermorgen), damit Weitere in Vorschauen und UI Tests sicher nicht leer ist.

**Pflicht Testfälle** (Rollierend, Woche vom Mo 12.10. bis So 18.10.2026)
- Unit Test: Wochentage Mo und Do: am Mi 14.10. Weitere, am Do 15.10. Hauptliste.
- Unit Test: 1x pro Woche, abgehakt am Mo 12.10.: am Mo Hauptliste (erledigt), am Di 13.10. Weitere. Wird er am Di zusätzlich abgehakt, bleibt er in Weitere und der Tagesfortschritt ändert sich nicht.
- Unit Test: 1x pro Woche, abgehakt am Mo 12.10.: am Fr 16.10. Weitere (grün), am Sa 17.10. Hauptliste (gelb).
- Unit Test: 2x pro Woche mit einer Erledigung im Fenster: Hauptliste.
- Unit Test: Pausierter Habit: Weitere, zählt nicht im Tagesfortschritt.
- Unit Test: drei tägliche Habits und ein 1x pro Woche Habit in Weitere: der Tagesfortschritt hat 3 Punkte.
- UI Test (einer): Mit Testdaten ist Weitere zugeklappt, Tippen auf `other-habits-toggle` klappt auf, der Habit mit festem Wochentag ist zu sehen. Ihn abhaken ändert den Fortschritt im Band nicht.

**Definition of Done**
- [x] In Heute stehen oben nur die Habits, die am Tag zu tun sind. Ein 1x pro Woche Habit, den ich diese Woche schon gemacht habe, steht in Weitere.
- [x] Weitere ist beim ersten Start zu, lässt sich auf und zuklappen und merkt sich das.
- [x] Ich kann einen Habit in Weitere abhaken, er bleibt dort, und der Fortschritt im Band ändert sich nicht.
- [x] Ein Habit, den ich in der Hauptliste abhake, bleibt am selben Tag in der Hauptliste.
- [x] Pausierte Habits stehen ausgegraut am Ende von Weitere.
- [x] Im Sheet "Tag bearbeiten" ist es genauso.

*Geprüft im Simulator (iPhone 18 Pro) mit Testdaten an einem Montag, hell und dunkel: Heute zeigt 11 Habits in der Hauptliste und 4/13 im Band, "Weitere · 5" ist beim ersten Start zu, Tippen klappt auf (Chevron nach unten) und zeigt die Habits in gespeicherter Reihenfolge. Gestern: das pausierte "Lesen" steht ausgegraut mit Kapsel "Pausiert" am Ende von Weitere. Das Sheet "Tag bearbeiten" (Kalender, 11. Oktober) zeigt dieselbe Aufteilung ("6 von 9 · 67 %", Hauptliste, Weitere). Unit Tests (259) grün, darunter die Pflicht Testfälle in `OtherSectionTests`. Komplett-Lauf auf dem Endstand vollständig grün, alle 21 UI Tests. Der Build hat keine Warnungen mehr: die drei Warnungen in `RootView.swift` (Zugriff auf `reduceMotion`, `tabSlideOffset`, `direction` in der Closure des `keyframeAnimator`) gab es schon in Phase 12 und sind behoben, indem der Versatz vorab berechnet wird. Zwei Tests waren zeitabhängig und wurden robuster gemacht: `Phase9UITests` las an einem Montag die Position des Wochenstreifens noch während er hereinfederte, `testCreateCheckUncheckAndPersist` (wackelte schon in Phase 12) tippt jetzt erst, wenn die Karte nach dem Abhaken nicht mehr wandert. Bestehende Tests angepasst: erfüllte Wochen Habits stehen jetzt in Weitere (`HabitEngineStatusTests`, `TodayPhase33UITests`), `pausedInTodayOrder` ist durch `otherInSavedOrder` ersetzt.*

---

### Phase 14: Einstellungen

**Ziel:** In den Einstellungen wähle ich Darstellung und Wochenbeginn und finde unter "Über" die Lizenzen der Schriften und Bilder.

**Entschieden:**
- Nur Einstellungen, die Apple selbst so anbietet bzw. die dem System folgen können: Darstellung mit "System" als Voreinstellung, Wochenbeginn mit "Automatisch" als Voreinstellung (5.5).
- Der Wochenbeginn ändert in dieser Phase nur die Anzeige. Fenster bleiben rollierend, Status, Streaks und Quoten ändern sich nicht (2, 3.5).
- Die Kalenderwoche folgt dem Wochenbeginn (bei Montag ISO wie bisher), damit Datumszeile und Wochenstreifen nie verschiedene Wochen zeigen (5.5).
- Die Zeile "Sprache" kommt erst in Phase 16, weil iOS die Sprachwahl erst mit einer zweiten Sprache anzeigt.

**Umfang**
- Einstellungen neu aufgebaut wie in 5.5: Pausen, Kalender, Anzeige, Über, Entwickler, Fuß.
- **Darstellung:** `SegmentedChoice` System / Hell / Dunkel, `@AppStorage("HestiaAppearance")`, `.preferredColorScheme` an der Wurzel der App. Gilt auch für alle Sheets.
- **Wochenbeginn:** `SegmentedChoice` Automatisch / Montag / Sonntag, `@AppStorage("HestiaFirstWeekday")`. Wirkt auf `WeekStrip`, `MonthCalendar` (Wochentagszeile und Raster, auch kompakt und in `DateRow`), `WeekdayPicker` und die Reihenfolge der Tage in der Rhythmus Zeile (4.5.1). Die Wochentagskürzel kommen aus dem `Calendar`, nicht aus festen Listen.
- **Engine:** `weekStrip` und Kalenderwoche mit Wochenbeginn als Parameter (6). `isoWeek` wird dabei umbenannt (z.B. `weekOfYear`), weil sie nur bei Montag ISO ist. `MonthGrid` bekommt den Wochenbeginn für den Versatz am Monatsanfang.
- **Über:** Zeile "Über Hestia" öffnet das Sheet "Über" mit Schriften (Lizenztext aus den `OFL-*.txt` im Projekt) und, falls vorhanden, Bildquellen (5.5).
- Identifier: `settings-appearance`, `settings-first-weekday`, `settings-about`, `about-done`, im Sheet je Schrift `about-font-<Name>`.

**Pflicht Testfälle**
- Unit Test: Wochenbeginn Montag ergibt dieselben Werte wie bisher für `weekStrip` und die Kalenderwoche (bestehende Tests bleiben unverändert grün).
- Unit Test: Wochenbeginn Sonntag: Der Wochenstreifen für Mi 14.10.2026 beginnt am So 11.10. und endet am Sa 17.10. So 11.10. und Sa 17.10. haben dieselbe Kalenderwoche.
- Unit Test: `MonthGrid` für Oktober 2026 (1.10. ist ein Donnerstag): bei Montag 3 leere Felder vor dem 1., bei Sonntag 4.
- Unit Test: Rhythmus Zeile für Wochentage Mo und So: bei Montag "Mo · So", bei Sonntag "So · Mo".
- Unit Test: "Automatisch" ergibt bei Region Deutschland Montag, bei Region USA Sonntag.
- UI Test (einer): In den Einstellungen Wochenbeginn "Sonntag" wählen, in Heute ist das erste Feld des Wochenstreifens ein Sonntag. Danach "Über Hestia" öffnen, die Zeile für Barlow Condensed ist zu sehen, "Fertig" schließt das Sheet.

**Definition of Done**
- [x] Ich kann Hell oder Dunkel fest einstellen, die App samt Sheets folgt sofort. Mit "System" folgt sie wieder dem iPhone.
- [x] Mit Wochenbeginn Sonntag beginnen Wochenstreifen, Kalender und Wochentagsauswahl mit Sonntag. Datumszeile und Wochenstreifen zeigen dieselbe Woche.
- [x] Mit "Automatisch" folgt der Wochenbeginn der Einstellung "Erster Wochentag" in iOS.
- [x] Status, Streaks und Quoten sind nach dem Umstellen des Wochenbeginns genau wie vorher.
- [x] Unter "Über Hestia" stehen die drei Schriften mit Lizenz, der volle Lizenztext ist lesbar.
- [x] Die Einstellungen bleiben nach einem Neustart der App erhalten.

*Geprüft im Simulator (iPhone 18 Pro): Die Einstellungen zeigen die Abschnitte Pausen, Kalender (Wochenbeginn), Anzeige (Darstellung), Über, Entwickler und den Fuß. "Über Hestia" öffnet das Sheet mit den drei Schriften (Urheber, SIL Open Font License 1.1, Tippen zeigt den Lizenztext) und den beiden Stichen (The Metropolitan Museum of Art, CC0). Darstellung "Dunkel" bei hellem System gilt sofort für Einstellungen, Heute und das Sheet "Über" und bleibt nach Beenden und Neustart der App erhalten, ebenso der Wochenbeginn "Sonntag" (Streifen "SO MO …", Montag 12.10. in KW 41, die Datumszeile passt zum Streifen). Mit "Automatisch" beginnt der Streifen bei Region USA am Sonntag (`-AppleLocale en_US`) und bei Region Deutschland am Montag (KW 42). Unit Tests (268) grün, darunter die Pflicht Testfälle in `FirstWeekdayTests`. Komplett-Lauf vollständig grün (22 UI Tests, davon neu `Phase14UITests`), Build ohne Warnungen. `isoWeek` heißt jetzt `weekOfYear`, `-HestiaResetData` setzt auch die Einstellungen zurück.*

---

### Phase 14.1: Neue Habit Icons

**Ziel:** Die Icon Auswahl passt zu meinen Habits: mehr Symbole, nach Themen geordnet, unter anderem für Hautpflege, ohne die, die ich nicht brauche.

**Entschieden:**
- Liste, Reihenfolge und VoiceOver Namen wie in 4.6: 36 Symbole, 6 Zeilen zu je 6 Themen. Die Themen sind nur die Reihenfolge, das Raster bekommt keine Überschriften.
- Kein vorhandener Habit trägt ein entfallenes Symbol. Es gibt keine Migration, keine Sonderbehandlung und keine Änderung am Datenmodell.
- Die Phase liegt vor Phase 16, damit die neuen VoiceOver Namen in die Texttabelle kommen.

**Umfang**
- `HabitIcons.all` und die Namen für VoiceOver neu nach 4.6. `HabitIcons.default` bleibt `figure.run`.
- Raster im Sheet "Habit anlegen / bearbeiten" wie bisher mit 6 Spalten, jetzt 6 Zeilen.
- Testdaten: "Auto waschen" bekommt statt `cart.fill` ein passendes Symbol aus der neuen Liste (z.B. `bubbles.and.sparkles.fill`), ein Habit "Hautpflege" mit `sparkles` kommt dazu.

**Pflicht Testfälle**
- Unit Test: `HabitIcons.all` hat 36 Einträge ohne Doppelte, jeder hat einen VoiceOver Namen, und jedes Symbol lässt sich laden (`UIImage(systemName:)` ist nicht `nil`).
- Kein neuer UI Test.

**Definition of Done**
- [x] Im Sheet sehe ich 6 Zeilen Symbole in der Reihenfolge aus 4.6, Schwimmen ist nicht mehr dabei, Hautpflege schon.
- [x] Alle Symbole sehen im Schnitt `.regular` auf der Kachel in Hell und Dunkel ordentlich aus.

*Geprüft im Simulator (iPhone 18 Pro): Das Sheet zeigt 6 Zeilen zu je 6 Symbole in der Reihenfolge aus 4.6, ohne Schwimmen, mit Hautpflege (`sparkles`) vorn in Zeile 2. In Heute steht der neue Testhabit "Hautpflege" mit `sparkles`, "Auto waschen" trägt `bubbles.and.sparkles.fill`. Die Testdaten "Miete überweisen" und "Rechnungen prüfen" nutzten die entfallenen Symbole `creditcard.fill` und `envelope.fill` und tragen jetzt `banknote.fill` und `pencil`, damit im Sheet immer ein Symbol ausgewählt ist. Unit Tests (269) grün, darunter `iconListHasThirtySixLoadableSymbols`. Komplett-Lauf vollständig grün (22 UI Tests, keiner neu), Build ohne Warnungen.*

---

### Phase 15: Feste Zeiträume

**Ziel:** Ich kann in den Einstellungen wählen, ob "x pro Woche" und "x pro Monat" in rollierenden Fenstern (die letzten 7 bzw. 30 Tage) oder in Kalenderwochen und Kalendermonaten gezählt werden.

**Entschieden:**
- Eine Einstellung "Zeiträume" (Rollierend / Kalender) für Wochen und Monate zusammen, für alle Habits. Voreinstellung "Rollierend", also verhält sich die App ohne Umstellen wie bisher.
- Bei "Kalender" beginnt die Woche am Wochenbeginn aus Phase 14. Der Monat ist der Kalendermonat.
- **Ampel:** Rot erst, wenn das Ziel im Zeitraum nicht mehr zu schaffen ist. Gelb, wenn jeder verbleibende Tag gebraucht wird (3.5).
- **Pausen und angebrochene Zeiträume** (Erstellung, Beenden, Pausentage im Zeitraum): Sie zählen nur, wenn das Ziel erreicht ist, sonst sind sie weder erfüllt noch verpasst. Kein Rot darin (3.5, 3.7).
- Ein Wechsel der Einstellung rechnet auch die Vergangenheit neu. Gespeichert werden weiter nur Erledigungen.

**Umfang**
- **Einstellungen:** Zeile "Zeiträume" im Abschnitt Kalender mit Erklärzeile (5.5), `@AppStorage("HestiaPeriods")`.
- **Engine:** Zeitraum (rollierend oder Kalender) und Wochenbeginn als Eigenschaften der `HabitEngine` (6). Eine Stelle liefert für Habit und Tag den Zeitraum (Beginn, Ende, ob er nur bei erreichtem Ziel zählt). `windowProgress`, `donePoints`, `status` und die Bewertung der Tage für Streaks und Quote nutzen sie. Die rollierende Rechnung bleibt unverändert.
- **Weitere (Phase 13):** Ob ein Wochen oder Monats Habit in Weitere steht, richtet sich bei "Kalender" nach dem Zeitraum (3.2). Das ergibt sich aus der gemeinsamen Stelle in der Engine, braucht aber einen Unit Test.
- **Rhythmus Zeile:** "in 7 Tagen" / "in 30 Tagen" bei rollierend, "diese Woche" / "diesen Monat" bei Kalender (4.5.1).
- **Testdaten** bleiben gleich. Mit beiden Einstellungen ergeben sie sinnvolle, verschiedene Werte.
- Identifier: `settings-periods`.

**Pflicht Testfälle** (Wochenbeginn Montag, Zeiträume Kalender, 3x pro Woche, erstellt vor der Woche vom Mo 12.10. bis So 18.10.2026, falls nicht anders genannt)
- Unit Test Ampel: Mi 14.10. ohne Erledigung grün (noch 5 Tage möglich, 3 nötig). Fr 16.10. ohne Erledigung gelb (3 und 3). Sa 17.10. ohne Erledigung rot (2 und 3). Sa 17.10. mit einer Erledigung am Mo gelb (2 und 2).
- Unit Test: Woche vom 12.10. verpasst, Mo 19.10. ohne Erledigung grün.
- Unit Test: drei Erledigungen bis Di 13.10.: `donePoints` ist an jedem Tag bis So 18.10. 1, am Mo 19.10. ohne Erledigung 0.
- Unit Test Wochenbeginn: Bei Sonntag zählt eine Erledigung am So 18.10. zur Woche vom 18.10. bis 24.10., bei Montag zur Woche vom 12.10.
- Unit Test Monat: 1x pro Monat ohne Erledigung im Oktober: am Sa 31.10. gelb, am So 1.11. grün. 30x pro Monat im Februar 2027: Ziel 28.
- Unit Test Pause: Pause am 14. und 15.10., eine Erledigung in der Woche: am So 18.10. gelb statt rot, die Woche ist weder erfüllt noch verpasst und unterbricht keinen Streak.
- Unit Test Erstellung: erstellt Do 15.10., 5x pro Woche, keine Erledigung: Sa 17.10. gelb statt rot, die Woche wird nicht gewertet.
- Unit Test Streak: erstellt Mo 5.10., Wochen vom 5.10. und 12.10. erfüllt, heute Mi 21.10. ohne Erledigung: aktueller Streak 14, die laufende Woche ist noch offen.
- Unit Test: Bei Zeiträumen "Rollierend" bleiben alle bestehenden Tests zu Status, Streaks und Quote unverändert grün.
- Unit Test Weitere: 1x pro Woche, abgehakt Mo 12.10.: bei "Kalender" am So 18.10. in Weitere, am Mo 19.10. in der Hauptliste.
- Unit Test Rhythmus Zeile: 1 von 3 ergibt "1 von 3 in 7 Tagen" bzw. "1 von 3 diese Woche".
- UI Test (einer, bestehenden erweitern, wenn möglich): Mit Testdaten Zeiträume "Kalender" wählen, die Rhythmus Zeile eines Wochen Habits enthält "diese Woche". Zurück auf "Rollierend": "in 7 Tagen".

**Definition of Done**
- [x] Ich kann zwischen rollierend und Kalender wählen, die Erklärzeile sagt, was gilt.
- [x] Bei "Kalender" ist ein Wochen Habit am Montag grün, auch wenn die letzte Woche verpasst war. Gelb und rot stimmen mit einem von Hand nachgerechneten Beispiel überein.
- [x] Wochen mit Pausen und die erste angebrochene Woche werden nie rot.
- [x] Streaks und Quote im Detail stimmen für beide Einstellungen mit einem von Hand nachgerechneten Beispiel aus den Testdaten überein.
- [x] Mit "Rollierend" ist alles wie vor dieser Phase.

*Geprüft per Unit und UI Tests (iPhone 18 Pro Simulator): Die Einstellung "Zeiträume" (Rollierend / Kalender) steht im Abschnitt Kalender, die Erklärzeile wechselt mit. Die Engine rechnet Status, Fortschritt, Streaks, Quote und Weitere über `period(for:on:)`, die Ansichten bekommen sie als `habitEngine` aus der Umgebung und rechnen bei einer Änderung neu. Die Pflicht Testfälle liegen in `CalendarPeriodTests` (Ampel Mo bis So, neue Woche grün, Wochenbeginn Sonntag, Monat inkl. Februar, Pause, Erstellung, Streak und Quote, Weitere), die Rhythmus Zeile in `RhythmTextTests`, der UI Test in `Phase15UITests` ("in 7 Tagen" und "diese Woche"). Mit "Rollierend" bleiben alle bestehenden Tests zu Status, Streaks und Quote unverändert grün, nur die Erwartung der Rhythmus Zeile ist an die neue Tabelle 4.5.1 angepasst ("in 7 Tagen" statt "diese Woche"). Unit Tests (288) grün, Komplett-Lauf vollständig grün (23 UI Tests, davon neu `Phase15UITests`), Build ohne Warnungen. Zusätzlich im Simulator (iPhone 18 Pro, Testdaten mit 60 Tagen Historie, Erstellung 13.8., heute Mo 12.10., Zeiträume "Kalender") angesehen und von Hand nachgerechnet: Die Einstellungen mit der Zeile "Zeiträume" und der Erklärzeile sehen in Hell und Dunkel korrekt aus. Gitarre üben (3x pro Woche, Erledigungen vor 2 Tagen und alle 2 Tage ab vor 9 Tagen): Am Montag ist der Habit grün, obwohl die Woche davor verpasst war. Woche 5.10. bis 11.10. hat nur 1 Erledigung und ist verpasst, daher aktueller Streak 0. Die sieben vollen Wochen vom 17.8. bis 4.10. sind erfüllt (je 3 bis 4), die angebrochene Erstellungswoche vom 10.8. nicht, daher längster Streak 49 (7 x 7). Quote 30 Tage: bewertet sind 13.9. bis 11.10., zusammen 29 Tage (der 12.10. ist offen), davon 22 erfüllt (13.9. und die Wochen 14.9., 21.9. und 28.9. mit je 7 Tagen) und 7 verpasst (Woche 5.10.), also 22 von 29 = 76 %. Erledigungen 27. Das Detail zeigt genau 0 Tage, 76 %, 49 und 27. Pflanzen düngen (1x pro Monat, erledigt am 17.8. und 16.9.): angebrochener August erfüllt (13.8. bis 31.8., 19 Tage) plus September (30 Tage) ist Streak 49, der Oktober ist noch offen und zählt mit 0, die Quote ist 18 von 18 (13.9. bis 30.9.). Fenster putzen (erledigt am 2.9. und 2.10.) hat Streak 42 (September 30 plus Oktober 1. bis 12. mit 12), Auto waschen (erledigt am 7.9.) Streak 30. Die Rhythmus Zeilen zeigen "0 von 1 diesen Monat" und "0 von 3 diese Woche". Dieselben Habits mit Zeiträumen "Rollierend" (7 bzw. 30 Tage Fenster, Rot erst nach dem ersten vollen Fenster, wie vor Phase 15), ebenfalls von Hand nachgerechnet und im Simulator verglichen: Gitarre üben: Die Fenster der Tage 6.10. bis 11.10. enthalten nur 1 bis 2 Erledigungen und sind verpasst (der 5.10. hat mit 3 Erledigungen im Fenster das Ziel), der 12.10. ist offen. Aktueller Streak 0, längster Streak 49, Quote 23 von 29 = 79 %, Erledigungen 27, Rhythmus Zeile "1 von 3 in 7 Tagen". Das Detail zeigt genau 0 Tage, 79 %, 49 und 27. Pflanzen düngen: erledigt am 17.8. und 16.9., das 30 Tage Fenster ist vom 17.8. bis heute erfüllt, die Tage 13.8. bis 16.8. sind im ersten Fenster noch offen: Streak 15 (August) + 30 (September) + 12 (Oktober) = 57, in der Liste so angezeigt, Quote 30 von 30 = 100 %. Fenster putzen 41 (2.9. bis 12.10.), Joggen 55. Die Zeilen zeigen "in 7 Tagen" und "in 30 Tagen".*

---

### Phase 16: Texte und Sprachen

**Ziel:** Alle Texte der App sind überarbeitet und einheitlich, und die App gibt es auf Deutsch und Englisch. Die Sprache wähle ich über iOS.

**Entschieden:**
- **Sprachen:** Deutsch (Basis, `developmentRegion = de`) und Englisch. Weitere Sprachen später nur, wenn ich sie gegenlesen kann.
- **Ansprache:** neutral, weder "du" noch "Sie". Beispiele: "Noch keine Habits" statt "Du hast noch keine Habits", "Ersten Habit anlegen" (Infinitiv) statt "Lege deinen ersten Habit an". Im Englischen ebenso ohne "you", wo es natürlich geht.
- **Sprachwahl** nur über iOS (Einstellungen › Hestia › Sprache), in der App eine Zeile "Sprache", die dorthin springt (5.5). Kein eigener Umschalter.
- **Technik nach Apple:** ein String Catalog `Localizable.xcstrings`. Nicht übersetzt werden die Wortmarke `HESTIA / HABITS`, der App Name und die Namen und Zusätze der Habits.

**Ablauf (Reihenfolge ist Pflicht)**
1. **Glossar:** Die KI schlägt die festen Begriffe auf Deutsch und Englisch vor (mindestens Habit, Erledigung, Rhythmus, Fenster/Zeitraum, Pause, Zusatz, Streak, Quote, Kalenderwoche) und die Regel für Versalien. Ich entscheide. Das Glossar steht danach als Abschnitt 4.8 in dieser Spezifikation.
2. **Texttabelle:** Die KI legt alle Texte der App als Tabelle vor: Ort (Datei bzw. Bildschirm), Text jetzt, Vorschlag Deutsch, Vorschlag Englisch, Bemerkung. Dazu gehören VoiceOver Texte und Hinweise. Ich entscheide Zeile für Zeile.
3. **Umsetzung:** erst danach Code und Katalog.

**Umfang**
- `Localizable.xcstrings` mit allen Texten auf Deutsch und Englisch. Texte in `Text(...)`, Buttons usw. landen automatisch im Katalog. Texte aus Hilfsfunktionen, die einen `String` liefern (z.B. `Rhythm`, `HabitCountText`, `HabitSnapshot+Text`, `PauseRange+Text`, `RelativeDay`), werden zu `String(localized:)` bzw. `LocalizedStringResource`.
- **Einzahl und Mehrzahl** über den Katalog ("Vary by Plural"), wo die Zahl im Text steht: "1 Habit" / "n Habits", "1 Tag" / "n Tage", "n Tage pausiert". Texte ohne Zahl ("Tag in Folge" / "Tage in Folge", "Tag" / "Tage" unter dem Streak) sind zwei eigene Schlüssel, weil Xcode Mehrzahlvarianten ohne Zahl im Text ablehnt; die Auswahl `== 1` steht in `StatValue`.
- **Datum und Zahlen:** kein festes `de_DE` mehr. Monatsnamen, Wochentage, Datumsangaben und Prozent folgen der Sprache der App. Wochentagskürzel aus dem `Calendar` (seit Phase 14).
- Die Datumszeile in Heute ("So · 11. Okt · KW 41") bekommt im Englischen eine passende Form, festgelegt in der Texttabelle.
- **Sprache:** Zeile im Abschnitt Anzeige (5.5), Identifier `settings-language`.
- Glossar als Abschnitt 4.8 in die Spezifikation, die überarbeiteten deutschen Texte in die betroffenen Abschnitte (z.B. 4.5.1).
- **Tests:** Die Testpläne "Schnell" und "Komplett" laufen fest auf Deutsch (Region Deutschland), damit bestehende Tests mit deutschen Texten stabil bleiben. Neue Texte in Tests nur, wo kein Identifier passt.

**Pflicht Testfälle**
- Unit Test: Für 1 und 3 Habits, 1 und 3 Tage Streak sowie jede Rhythmus Zeile gibt es den richtigen deutschen und englischen Text (Englisch über eine Ressource mit englischer Locale).
- Unit Test: Pausenzeitraum und relativer Tag ("Gestern" / "Yesterday") auf Deutsch und Englisch.
- Unit Test: Der Katalog hat für jeden Schlüssel eine englische Übersetzung (kein Eintrag "needs review" oder leer).
- Kein neuer UI Test.

**Definition of Done**
- [x] Glossar und Texttabelle sind von mir freigegeben, bevor Code geändert wurde.
- [x] Mit iPhone auf Englisch (oder Hestia in iOS auf Englisch gestellt) ist die ganze App englisch, auch Datum, Monatsnamen und VoiceOver. Kein deutsches Wort bleibt übrig außer Habit Namen.
- [x] Mit Deutsch sieht die App aus wie freigegeben.
- [x] Die Zeile "Sprache" in den Einstellungen öffnet die iOS Einstellungen der App, dort lässt sich die Sprache wechseln.
- [x] Keine Texte sprechen mich mit "du" oder "Sie" an.
- [x] Eine Suche nach `de_DE` im Code findet nichts mehr.

*Geprüft per Unit und UI Tests (iPhone 18 Pro Simulator, Testpläne fest auf Deutsch/Deutschland): Unit Tests (300) grün, darunter neu `LocalizationTests` (1 und 3 Habits, 1 und 3 Tage Streak, jede Rhythmus Zeile, Zielzahl, relativer Tag, Pausenzeitraum, Datum, KW, Icon Namen jeweils Deutsch und Englisch sowie der Katalog: jeder Schlüssel hat eine fertig übersetzte englische Zeile). Komplett-Lauf vollständig grün (23 UI Tests, keiner neu), Build ohne Warnungen. Die Texttabelle wurde im Chat freigegeben, vor dem ersten Code. Zusätzlich im Simulator mit englischer App Sprache (`-AppleLanguages (en)`) angesehen: Heute (Datumszeile "Mon · Oct 12 · W41", "Today", "Done 29%", "Reorder", "12 habits", "3 per day", "20 min · Daily"), Kalender ("October 2026", "1 day"), Einstellungen (alle Abschnitte, Zeile "Language / English"), Sheet "New pause" und Sheet "New habit". Kein deutsches Wort bleibt außer den Habit Namen der Testdaten. Die Anrede ist neutral (Katalog enthält weder "du" noch "Sie" noch "you"). In Tests und App steht kein `de_DE` mehr (Tests nutzen `de` bzw. `de_AT`). VoiceOver Texte stehen im Katalog und sind über die Unit Tests belegt, mit VoiceOver selbst wurde nicht gelesen.*

*Abweichungen von der Planung: Mehrzahl über den Katalog nur dort, wo die Zahl im Text steht (Xcode lehnt Mehrzahlvarianten ohne Zahl ab), "Tag in Folge" und "Tag" sind deshalb eigene Schlüssel (4.8). `STRING_CATALOG_GENERATE_SYMBOLS` ist aus, weil Schlüssel wie "Habit beenden" und "Habit beenden?" dasselbe Symbol ergeben. "Heute nichts fällig" heißt jetzt "Nichts fällig", weil es auch an vergangenen Tagen stand. HermesButton und Chip setzen den VoiceOver Text selbst, damit er nicht in Versalien gelesen wird.*

*Sprachzeile im Simulator geprüft: Tippen auf "Language / English" öffnet die iOS Einstellungen. Im Simulator landet der Sprung dort zuerst in der Suche der Einstellungs App; unter Apps › Hestia steht der Abschnitt "Preferred Language" mit "Language" (English, Deutsch zur Auswahl). Diesen Abschnitt zeigt iOS nur, weil die App seit dieser Phase zwei Sprachen mitbringt. Mit Deutsch (`-AppleLanguages (de)`) sieht Heute wie freigegeben aus ("Heute", "Erledigt 29 %", "Sortieren", "3 pro Tag", "20 Min · Täglich", "MO · 12. OKT · KW 42"). Ob der Sprung auf dem iPhone direkt bei Hestia landet, sieht man erst dort, die Sprachwahl selbst ist belegt.*
