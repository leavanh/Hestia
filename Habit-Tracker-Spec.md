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
- Der angezeigte Tag (der Punkt ganz rechts) ist immer gut erkennbar: Er hat zusätzlich einen äußeren Ring in Habitfarbe mit verringerter Deckkraft und etwas Abstand zum Punkt. Das gilt für jede Füllung und auch für einen pausierten Tag. Der Ring verändert Abstände und Ausrichtung der Punkte nicht.

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
- Pausentage kommen erst mit Phase 6 hinzu.

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
- **Karten und Tab Bar:** Liquid Glass (`.glassEffect()`), damit der Verlauf leicht durchscheint.
- **Habitfarben:** Feste Palette mit 8 Farben (Blau, Türkis, Grün, Gelb, Orange, Rot, Pink, Violett). Nur für Icon, Ring im Counter, Abhakkreis und 7 Tage Punkte.
- **Gedämpfte Habitfarben für Icons:** Zu jeder Habitfarbe gibt es eine gedämpfte Variante (weniger Sättigung, hell und dunkel abgestimmt auf den Hintergrundverlauf). Symbol und Kreisfläche von `HabitIconView` nutzen nur diese gedämpfte Variante, auch in der Icon Vorschau im Sheet. Abhakkreis, Counter und 7 Tage Punkte bleiben in der normalen Habitfarbe.
- **Statusfarben:** Systemgelb und Systemrot. Nur für die Statusmarke am Icon (4.3). Für grün gibt es keine Anzeige und keine Farbe.
- Alle Farben als zentrale Definition im Designsystem, nirgendwo Farbwerte direkt im Code der Ansichten.

### 4.3 Bausteine (einmal bauen, überall nutzen)

| Baustein | Inhalt |
|---|---|
| `HabitCard` | Links `HabitIconView` mit Statusmarke, daneben der Name, darunter eine kleine Zeile mit dem Rhythmus (siehe 4.3.1), darunter 7 Tage Punkte. Rechts Abhakkreis oder Counter. Kein weiterer Text. |
| `CheckCircle` | Kreis mit Umriss in Habitfarbe, abgehakt gefüllt mit Häkchen. |
| `CounterControl` | Minus im Kreis, Ring mit Zahl in der Mitte (Ring füllt sich mit Fortschritt), Plus im Kreis. Gleiche Kreisgröße wie `CheckCircle`, alles auf einer Linie. |
| `WeekDots` | Die 7 Punkte aus 3.6, der angezeigte Tag mit äußerem Ring. |
| `HabitIconView` | Icon in gedämpfter Habitfarbe auf zarter Kreisfläche derselben Farbe. Bei Status gelb oder rot oben rechts eine kleine runde Statusmarke in Statusfarbe, die den Kreis leicht überlappt und durch einen schmalen freien Rand von ihm abgesetzt ist. Bei grün keine Marke. |
| `ProgressHeader` | Fortschrittsring und Text "5 von 16 · 31 %". Ohne Karte, direkt auf dem Hintergrund. |
| `MonthCalendar` | Ein Monat, Monatsname mit Pfeil links und rechts, darunter die Wochentagszeile Mo bis So und die Tage, ohne Karte. Der Wechsel zwischen den Monaten (Grenzen, deaktivierte Pfeile) gehört zum Baustein. Jeder Tag ist ein Kreis, nach Tagesfortschritt in einer Tönung eingefärbt (keine Farbe bei 0 %, bis 100 % zunehmend kräftiger), heute mit Ring, zukünftige Tage blass und gesperrt. Im Tab Akzentfarbe und antippbar, im Habit Detail Habitfarbe und nicht antippbar (5.4). Werte in `Theme`. |
| `HabitStatRow` | Zeile der Habit Liste unter dem Kalender (5.4): `HabitIconView` ohne Statusmarke, Name, Rhythmus Zeile (4.3.1) und rechts der aktuelle Streak mit Flammensymbol ("5 Tage"). In einer Glaskarte, antippen öffnet das Habit Detail. |
| `StatValue` | Eine Kennzahl im Habit Detail: großer Wert, darunter eine kleine Beschriftung ("12 Tage" / "Längster Streak"). |
| `GlassBackground` | Farbverlauf für alle Bildschirme. |
| `SegmentedChoice` | Segmentfeld im Glas Stil, z.B. für den Rhythmus und seine Variante. |

#### 4.3.1 Rhythmus Zeile auf der `HabitCard`

Kleine Zeile (`.caption`, sekundäre Farbe) unter dem Namen, vor den 7 Tage Punkten. Sie sagt, wie oft der Habit wiederholt werden soll. Bei Woche und Monat steht davor, wie viele Erledigungen im Fenster des angezeigten Tags schon da sind (`windowProgress`).

| Rhythmus | Text | Beispiel |
|---|---|---|
| Täglich, Anzahl 1 | "Täglich" | Täglich |
| Täglich, Anzahl n größer 1 | "n pro Tag" | 2 pro Tag |
| Woche, Anzahl | "erledigt von Ziel diese Woche" | 1 von 3 diese Woche |
| Monat, Anzahl | "erledigt von Ziel diesen Monat" | 1 von 1 diesen Monat |
| Feste Wochentage | Kurzname der Tage | Mo, Do |
| Fester Monatstag | "Am n. des Monats" | Am 15. des Monats |

*Ersetzt nach Phase 3.1 die dort entfernte Anzeige "x/y im Fenster". Das Format ist neu und steht jetzt in der Zeile unter dem Namen, nicht mehr neben den Punkten.*

### 4.4 Icons

Auswahl aus ca. 30 kuratierten SF Symbols (z.B. figure.run, drop.fill, book.fill, bed.double.fill, leaf.fill, dumbbell.fill, brain.head.profile, pills.fill, cup.and.saucer.fill, figure.walk, music.note, pencil, house.fill, cart.fill, heart.fill).

---

## 5. Bildschirme

### 5.1 Tab Bar (3 Tabs)

1. **Heute** (Symbol: checkmark.circle)
2. **Kalender** (Symbol: calendar)
3. **Einstellungen** (Symbol: gearshape)

### 5.2 Heute

- **Kopfbereich ohne Karte:** Oben steht das Datum des angezeigten Tags im Stil eines großen Navigationstitels (Large Title einer `NavigationStack`: Schrift, Gewicht, Einzug links). Titel ist der Wochentag ("Donnerstag"), darunter als Untertitel das Datum ("8. Oktober"). Beim Scrollen verhält sich der Titel wie ein Large Title und wird klein in der Leiste angezeigt. Darunter der `ProgressHeader`, ebenfalls ohne Karte und ohne Glas direkt auf dem Hintergrund. Neben dem Datum steht eine kleine Kapsel: "Heute" in Akzentfarbe, an vergangenen Tagen neutral "Gestern", "Vorgestern" oder "Vor n Tagen". In der kleinen Leiste steht sie hinter dem Datum.
- **Tag wechseln:** Waagrechtes Wischen im Inhalt von Heute (Kopfbereich und Liste) nach rechts zeigt den vorherigen Tag, nach links den nächsten Tag. Senkrechtes Scrollen, Abhakkreis und Counter funktionieren weiter wie bisher. Weiter als bis heute geht es nicht, zukünftige Tage sind nicht erreichbar. Beim Start der App, beim Zurückkehren in die App und beim Tageswechsel um Mitternacht zeigt die Ansicht wieder heute.
- **Animation beim Tageswechsel:** Titel, Untertitel, Fortschritt und Liste gleiten in Wischrichtung heraus und der neue Tag gleitet von der anderen Seite herein (zurück in die Vergangenheit: Inhalt kommt von links, vorwärts: von rechts), kurz und weich (ca. 0,3 s). Wird nicht gewechselt, weil heute schon erreicht ist, federt der Inhalt nur kurz zurück. Der neue Tag federt dabei Kopf und Karten nacheinander (leicht versetzt) herein. Bei "Bewegung reduzieren" (Reduce Motion) nur Überblenden. Das Zurückspringen auf heute (Start, Rückkehr, Mitternacht) ist nicht animiert.
- Für den angezeigten Tag gelten Fälligkeit, Fortschritt, Abhaken, Status und 7 Tage Punkte so, als wäre dieser Tag heute. Tage vor der Erstellung eines Habits und pausierte Tage verhalten sich wie in Abschnitt 3 beschrieben.
- Oben rechts: Plus Button für neuen Habit. Zeigt die Ansicht einen vergangenen Tag, steht in der Datumszeile rechts (auf einer Ebene mit Datum und Kapsel, nicht in der Leiste) ein Button "Heute >" mit kleinem Chevron, der (animiert, wie ein Wischen nach vorn) zu heute zurückspringt. Auf heute ist er nicht zu sehen. Oben links: Button "Sortieren".
- Darunter eine einzige Liste mit `HabitCard`s, ohne Abschnitte und ohne Überschriften.
- **Reihenfolge:** Oben die offenen Habits, darunter die erledigten. Innerhalb beider Teile gilt die gespeicherte Reihenfolge (`sortOrder`, dann `createdAt`). Erledigt heißt: Am angezeigten Tag ist das Tagesziel erreicht, also Abhakkreis abgehakt bzw. Counter voll. Ein Wochen oder Monats Habit, dessen Fenster erfüllt ist, der am angezeigten Tag aber nicht abgehakt ist, bleibt oben. Wird ein Habit erledigt, rutscht er animiert nach unten, wird es wieder aufgehoben, rutscht er animiert zurück an seinen Platz.
- **Bearbeiten:** Festes Drücken (ca. 0,6 s) auf die Karte (nicht auf Kreis/Counter) öffnet das Bearbeiten Sheet. Die Karte sinkt dabei ein und gibt ein haptisches Signal, beim Auslösen ein festeres. Einfaches Tippen auf die Karte tut nichts. Für VoiceOver gibt es auf der Karte die Aktion "Bearbeiten".
- **Sortieren:** Im Sortiermodus Habits per Drag and Drop verschieben. Es gibt eine Reihenfolge für alle Habits, sie wird gespeichert. Auch im Sortiermodus stehen erledigte Habits unten. Verschieben lassen sich nur die offenen Habits, die erledigten sind im Sortiermodus nicht verschiebbar. Nach dem Verschieben bekommen die offenen Habits in ihrer neuen Reihenfolge die vorderen Plätze in `sortOrder`, die erledigten folgen dahinter in ihrer bisherigen Reihenfolge.

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

- Monatskalender mit Pfeilen: Der Kalender zeigt einen Monat, mit Pfeil links (voriger Monat) und Pfeil rechts (nächster Monat) rechts neben dem Monatsnamen. Er beginnt beim aktuellen Monat, einen späteren Monat gibt es nicht (Pfeil rechts ist dort deaktiviert). Er reicht mindestens 3 Monate zurück, sonst bis zum Monat des ältesten Habits (dort ist der Pfeil links deaktiviert). Unter dem Monatsnamen steht die Wochentagszeile Mo bis So. *(Ersetzt nach Phase 5.1 den durchgehend scrollbaren Kalender aus Phase 4.)*
- **Gleicher Kalender überall:** Der Kalender im Tab und der Kalender im Habit Detail sind derselbe Baustein mit demselben Aussehen und denselben Pfeilen. Unterschiede nur: Farbe (Akzentfarbe bzw. Habitfarbe), Tippen (im Tab öffnet ein Tag das Sheet, im Detail sind die Tage nicht antippbar) und die Grenzen (im Tab siehe oben, im Detail Erstellmonat bis aktueller Monat, bei beendeten Habits bis Monat des Beendens).
- Jeder Tag eingefärbt nach Tagesfortschritt (3.4) an diesem Tag: keine Farbe bei 0 %, dann zunehmend kräftigere Akzentfarbe bis 100 %. Zukünftige Tage blass.
- Tag antippen öffnet Sheet "Tag bearbeiten": dieselbe Liste wie "Heute" für diesen Tag, mit Abhaken und Counter. Zukünftige Tage sind nicht antippbar.
- Darunter Liste aller Habits (aktive zuerst, dann beendete) mit aktuellem Streak.
- Habit antippen öffnet als Sheet das **Habit Detail**: Icon, Name, Rhythmus, eigener Monatskalender (nur dieser Habit, Tage mit Erledigung in Habitfarbe, bei Tagesziel größer 1 mit Teilfüllung), aktueller Streak, längster Streak, Quote 30 Tage (3.7). Der Monatskalender ist derselbe wie im Tab (siehe oben).
- Unter dem Monatskalender im Tab steht die Habit Liste. Der ganze Tab scrollt senkrecht, der Kalender selbst wird nur mit den Pfeilen gewechselt.

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
- Einstellungen > Pausen (3.8, 5.5).
- Pausentage in Status, Fortschritt, Punkten (grauer Strich), Kalender (grau) und Statistik berücksichtigen.
- Habit beenden im Bearbeiten Sheet, Einstellungen > Beendete Habits mit "Wieder aktivieren" und "Löschen" (3.9).
- Sortiermodus in Heute mit Drag and Drop, eine Reihenfolge für alle Habits über `sortOrder` (5.2). Nur offene Habits sind verschiebbar, erledigte bleiben unten (Phase 3.2).
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
- VoiceOver Beschriftungen für Abhakkreis, Counter und Statusmarke.
- Prüfung mit großer Schrift (Dynamic Type) und Korrektur von Umbrüchen.
- Durchsicht aller Bildschirme auf einheitliche Abstände, Schriftgrößen und Farben.

**Definition of Done**
- [ ] Jeder Bildschirm hat einen sinnvollen Leerzustand.
- [ ] App Icon ist auf dem Homescreen sichtbar.
- [ ] Bei größter Schriftgröße ist nichts abgeschnitten.
- [ ] Abstände, Ecken und Schriftgrößen sind auf allen Bildschirmen gleich.
