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

Ein persönlicher Habit Tracker für das iPhone. Clean, modern, minimalistisch, mit dezentem Glassmorphism.

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
- Nie, wenn der Habit heute pausiert oder beendet ist.

### 3.3 Abhaken

- **Täglich mit Anzahl größer 1:** Counter mit Minus und Plus. Wert von 0 bis Zielanzahl.
- **Alle anderen:** Ein Kreis zum Abhaken. Wert 0 oder 1 pro Tag. Erneutes Tippen hebt das Abhaken auf.
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

### 3.7 Streaks und Statistik

- **Aktueller Streak:** Anzahl Tage am Stück bis heute, an denen der Status grün oder gelb war. Pausierte Tage werden übersprungen (unterbrechen nicht, zählen nicht mit). Bei festen Wochentagen und Monatstag zählen nur die fälligen Tage.
- **Längster Streak:** Größter Streak seit Erstellung.
- **Quote 30 Tage:** Anteil der letzten 30 Tage (ohne Pausen, ab Erstellung), an denen der Status grün oder gelb war. Bei festen Tagen nur fällige Tage.
- Alle Werte werden aus den Erledigungen berechnet, nicht gespeichert.

### 3.8 Pausen

- Eine Pause hat einen Zeitraum (von, bis, beide Tage eingeschlossen) und gilt für einen oder mehrere ausgewählte Habits.
- Während der Pause: nicht in "Heute", zählt nicht im Tagesfortschritt, Tage zählen nicht in Status und Statistik.
- Eine laufende Pause kann vorzeitig beendet werden (Enddatum = gestern).

### 3.9 Beenden

- Ein Habit kann beendet werden. Ab dann erscheint er nicht mehr in "Heute".
- Im Kalender und in der Statistik bleibt er mit seiner Historie sichtbar.
- Beendete Habits können wieder aktiviert werden.
- Löschen ist nur bei **beendeten** Habits möglich (Einstellungen > Beendete Habits), nie bei aktiven. Es gibt vorher einen Bestätigungsdialog, der warnt, dass die Historie unwiderruflich gelöscht wird.
- Beim Löschen werden der Habit, alle seine Erledigungen und seine Zuordnung zu Pausen entfernt. Eine Pause, die dadurch keinen Habit mehr hat, wird ebenfalls entfernt.

### 3.10 Ändern eines Habits

Änderungen (z.B. Rhythmus) gelten für die gesamte Historie. Der Status wird immer mit den aktuellen Einstellungen neu berechnet.

---

## 4. Design

### 4.1 Grundprinzipien

- Minimalistisch: viel Abstand, wenig Text, keine Rahmenlinien, keine Schatten außer dem Glas Effekt.
- Ein Muster für alles: Jede Eingabe öffnet ein Sheet von unten. Keine Alerts außer für Bestätigungen (z.B. "Habit beenden?").
- Eine Schrift: SF Pro (Systemschrift), Dynamic Type unterstützen.

### 4.2 Farben

- **Hintergrund:** Ruhiger Farbverlauf. Hell: sehr helles Blau zu hellem Flieder. Dunkel: tiefes Marineblau zu dunklem Violett.
- **Karten, Tab Bar, Header:** Liquid Glass (`.glassEffect()`), damit der Verlauf leicht durchscheint.
- **Habitfarben:** Feste Palette mit 8 Farben (Blau, Türkis, Grün, Gelb, Orange, Rot, Pink, Violett). Nur für Icon, Ring, Abhakkreis und 7 Tage Punkte.
- **Statusfarben:** Systemgrün, Systemgelb, Systemrot. Nur für den Statuspunkt.
- Alle Farben als zentrale Definition im Designsystem, nirgendwo Farbwerte direkt im Code der Ansichten.

### 4.3 Bausteine (einmal bauen, überall nutzen)

| Baustein | Inhalt |
|---|---|
| `HabitCard` | Links Icon in Habitfarbe, daneben Name und kleiner Statuspunkt, darunter 7 Tage Punkte. Rechts Abhakkreis oder Counter. Kein weiterer Text (kein "2/3 im Fenster"). |
| `CheckCircle` | Kreis mit Umriss in Habitfarbe, abgehakt gefüllt mit Häkchen. |
| `CounterControl` | Minus im Kreis, Ring mit Zahl in der Mitte (Ring füllt sich mit Fortschritt), Plus im Kreis. Gleiche Kreisgröße wie `CheckCircle`, alles auf einer Linie. |
| `WeekDots` | Die 7 Punkte aus 3.6. |
| `StatusDot` | Kleiner Punkt in Statusfarbe. |
| `ProgressHeader` | Fortschrittsring und Text "5 von 16 · 31 %". |
| `GlassBackground` | Farbverlauf für alle Bildschirme. |
| `SegmentedChoice` | Segmentfeld im Glas Stil, z.B. für den Rhythmus und seine Variante. |

### 4.4 Icons

Auswahl aus ca. 30 kuratierten SF Symbols (z.B. figure.run, drop.fill, book.fill, bed.double.fill, leaf.fill, dumbbell.fill, brain.head.profile, pills.fill, cup.and.saucer.fill, figure.walk, music.note, pencil, house.fill, cart.fill, heart.fill).

---

## 5. Bildschirme

### 5.1 Tab Bar (3 Tabs)

1. **Heute** (Symbol: checkmark.circle)
2. **Kalender** (Symbol: calendar)
3. **Einstellungen** (Symbol: gearshape)

### 5.2 Heute

- Oben: Datum des angezeigten Tags (z.B. "Donnerstag, 8. Oktober") und `ProgressHeader`.
- **Tag wechseln:** Wischen auf der Datumskarte nach rechts zeigt den vorherigen Tag, nach links den nächsten Tag. Weiter als bis heute geht es nicht, zukünftige Tage sind nicht erreichbar. Beim Start der App, beim Zurückkehren in die App und beim Tageswechsel um Mitternacht zeigt die Ansicht wieder heute.
- Für den angezeigten Tag gelten Fälligkeit, Fortschritt, Abhaken, Status und 7 Tage Punkte so, als wäre dieser Tag heute. Tage vor der Erstellung eines Habits und pausierte Tage verhalten sich wie in Abschnitt 3 beschrieben.
- Oben rechts: Plus Button für neuen Habit. Oben links: Button "Sortieren".
- Darunter eine einzige Liste mit `HabitCard`s, ohne Abschnitte und ohne Überschriften.
- Tippen auf die Karte (nicht auf Kreis/Counter) öffnet das Bearbeiten Sheet.
- **Sortieren:** Im Sortiermodus Habits per Drag and Drop verschieben. Es gibt eine Reihenfolge für alle Habits, sie wird gespeichert.

### 5.3 Sheet "Habit anlegen / bearbeiten"

Felder in dieser Reihenfolge:
1. Name
2. Icon (Raster)
3. Farbe (8 Kreise)
4. Rhythmus (Segmente: Täglich, Woche, Monat) und passende Einstellung darunter:
   - **Täglich:** Anzahl pro Tag als Stepper.
   - **Woche:** zweites Segmentfeld "Anzahl" / "Wochentage". Bei Anzahl ein Stepper ("2x pro Woche"), bei Wochentage 7 Kreise M D M D F S S.
   - **Monat:** zweites Segmentfeld "Anzahl" / "Monatstag". Bei Anzahl ein Stepper ("1x pro Monat"), bei Monatstag die Auswahl 1 bis 31.
   - Beim Bearbeiten eines bestehenden Habits sind Rhythmus und Variante passend vorausgewählt (z.B. Wochentage Habit: Woche + Wochentage).
5. Nur beim Bearbeiten, ganz unten: "Habit beenden" (mit Bestätigung)

Es gibt keine Auswahl von Tagesgruppen (Morgens, Mittags, Abends). Alle Habits gelten ganztägig.

Speichern nur möglich, wenn Name nicht leer.

### 5.4 Kalender

- Oben Monatsansicht mit Wechsel zum vorherigen/nächsten Monat.
- Jeder Tag eingefärbt nach Tagesfortschritt (3.4) an diesem Tag: keine Farbe bei 0 %, dann zunehmend kräftigere Akzentfarbe bis 100 %. Zukünftige Tage blass.
- Tag antippen öffnet Sheet "Tag bearbeiten": dieselbe Liste wie "Heute" für diesen Tag, mit Abhaken und Counter. Zukünftige Tage sind nicht antippbar.
- Darunter Liste aller Habits (aktive zuerst, dann beendete) mit aktuellem Streak.
- Habit antippen öffnet **Habit Detail**: Icon, Name, Rhythmus, eigener Monatskalender (nur dieser Habit, Tage mit Erledigung in Habitfarbe), aktueller Streak, längster Streak, Quote 30 Tage.

### 5.5 Einstellungen

- **Pausen:** Liste laufender und geplanter Pausen. Button "Neue Pause": Sheet mit Mehrfachauswahl der Habits, Startdatum, Enddatum. Laufende Pause kann beendet werden.
- **Beendete Habits:** Liste mit Optionen "Wieder aktivieren" und "Löschen" (mit Bestätigung, siehe 3.9).
- **Entwickler** (nur in Debug Builds sichtbar): "Testdaten erzeugen" und "Alle Daten zurücksetzen".

---

## 6. Datenmodell (SwiftData)

Das Modell wurde in Phase 1 vollständig angelegt. In Phase 3.1 entfallen `timeSlots` und `sortIndex`, neu ist `sortOrder`. Das ist eine leichte Migration (Feld entfernt, Feld mit Standardwert hinzugefügt), vorhandene Habits und Erledigungen bleiben erhalten.

**Habit**
- `id: UUID`
- `name: String`
- `iconName: String`
- `colorKey: String` (Schlüssel aus der Palette)
- `rhythm: Rhythm` (enum: daily, weekly, monthly, weekdays, monthDay)
- `targetCount: Int` (pro Tag bei daily, pro Fenster bei weekly/monthly, sonst 1)
- `weekdays: [Int]` (1 = Montag bis 7 = Sonntag)
- `monthDay: Int?`
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
- Karte antippen öffnet Bearbeiten Sheet.
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
- Status (3.5) als `StatusDot` auf der Karte.
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
- **Tag wechseln per Wischen** auf der Datumskarte in Heute, nur zwischen vergangenen Tagen und heute (5.2).
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

### Phase 4: Kalender und Nachtragen

**Ziel:** Ich sehe meine Vergangenheit und kann alte Tage korrigieren.

**Umfang**
- Monatsansicht mit Einfärbung nach Tagesfortschritt (5.4).
- Monatswechsel.
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
- [ ] Streak täglicher Habit: 5 Tage in Folge erreicht ergibt 5; ein verpasster Tag setzt auf 0 (bzw. Zählung ab heute).
- [ ] Streak Wochen Habit läuft weiter, solange das Fenster erfüllt ist.
- [ ] Längster Streak ist nie kleiner als der aktuelle.
- [ ] Quote 30 Tage stimmt mit einem von Hand nachgerechneten Testfall überein.
- [ ] Unit Tests für Streaks und Quote grün.

---

### Phase 6: Pausen, Beenden, Sortieren

**Ziel:** Ich kann meine Habits verwalten.

**Umfang**
- Einstellungen > Pausen (3.8, 5.5).
- Pausentage in Status, Fortschritt, Punkten (grauer Strich), Kalender (grau) und Statistik berücksichtigen.
- Habit beenden im Bearbeiten Sheet, Einstellungen > Beendete Habits mit "Wieder aktivieren" und "Löschen" (3.9).
- Sortiermodus in Heute mit Drag and Drop, eine Reihenfolge für alle Habits über `sortOrder` (5.2).
- Unit Tests: Fenster überspringen Pausentage, Streak wird durch Pause nicht unterbrochen, Löschen entfernt Habit, Erledigungen und Pausenzuordnung (leere Pausen verschwinden).

**Definition of Done**
- [ ] Ich kann 2 Habits für 3 Tage pausieren, sie verschwinden aus Heute und aus dem Fortschritt.
- [ ] Nach der Pause ist ein vorher grüner Wochen Habit weiterhin grün, wenn die Pause das Fenster sonst gesprengt hätte.
- [ ] Eine laufende Pause lässt sich beenden.
- [ ] Ein beendeter Habit ist weg aus Heute, aber im Kalender und Detail mit Historie da.
- [ ] Wieder aktivieren funktioniert.
- [ ] Ein beendeter Habit lässt sich nach Bestätigung löschen und ist danach auch in Kalender und Detail weg. Aktive Habits lassen sich nicht löschen.
- [ ] Abbrechen im Bestätigungsdialog lässt den Habit unverändert.
- [ ] Nach dem Löschen eines pausierten Habits ist die Pause ohne ihn weiter vorhanden, bzw. weg, wenn er der einzige war.
- [ ] Neue Sortierung bleibt nach Neustart erhalten.

---

### Phase 7: Feinschliff

**Ziel:** Die App fühlt sich fertig und stimmig an.

**Umfang**
- Leerzustände: Heute ohne Habits ("Lege deinen ersten Habit an" mit Button), Kalender ohne Daten, keine Pausen.
- App Icon (minimalistisch, passend zum Farbverlauf).
- VoiceOver Beschriftungen für Abhakkreis, Counter und Statuspunkt.
- Prüfung mit großer Schrift (Dynamic Type) und Korrektur von Umbrüchen.
- Durchsicht aller Bildschirme auf einheitliche Abstände, Schriftgrößen und Farben.

**Definition of Done**
- [ ] Jeder Bildschirm hat einen sinnvollen Leerzustand.
- [ ] App Icon ist auf dem Homescreen sichtbar.
- [ ] Bei größter Schriftgröße ist nichts abgeschnitten.
- [ ] Abstände, Ecken und Schriftgrößen sind auf allen Bildschirmen gleich.
