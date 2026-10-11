import Foundation

/// Wert eines Habits an einem Tag, unabhängig von SwiftData.
nonisolated struct DayCount: Equatable, Sendable {
    var day: Date
    var count: Int
}

/// Zeitraum einer Pause, beide Tage eingeschlossen (Spezifikation 3.8).
nonisolated struct PauseRange: Equatable, Sendable {
    var start: Date
    var end: Date
}

/// Alles, was die `HabitEngine` über einen Habit wissen muss, als reiner Wert.
nonisolated struct HabitSnapshot: Equatable, Sendable {
    var rhythm: Rhythm
    /// Pro Tag bei daily, pro Fenster bei weekly/monthly, sonst 1.
    var targetCount: Int
    /// 1 = Montag bis 7 = Sonntag. Nur bei `.weekdays`.
    var weekdays: [Int] = []
    /// Nur bei `.monthDay`.
    var monthDay: Int? = nil
    var createdAt: Date
    var counts: [DayCount]
    /// Pausen, die für diesen Habit gelten (Spezifikation 3.8).
    var pauses: [PauseRange] = []
    /// Tag, an dem der Habit beendet wurde. Ab diesem Tag ist er nicht mehr fällig (Spezifikation 3.9).
    var endedAt: Date? = nil
}

/// Ampelstatus eines Habits (Spezifikation 3.5).
nonisolated enum HabitStatus: Equatable, Sendable {
    case green
    case yellow
    case red
}

/// Stand im rollierenden Fenster bei pro Woche / pro Monat (2 von 3 Erledigungen).
nonisolated struct WindowProgress: Equatable, Sendable {
    var done: Int
    var target: Int
}

/// Ein Punkt der 7 Tage Anzeige (Spezifikation 3.6).
nonisolated enum WeekDot: Equatable, Sendable {
    /// Wert des Tages geteilt durch Tagesziel, 0 bis 1. Tage vor der Erstellung haben 0.
    case fill(Double)
    /// Pausierter Tag: kleiner grauer Strich statt Punkt.
    case paused
}

/// Tagesfortschritt "5 von 16 · 31 %" (Spezifikation 3.4).
nonisolated struct DayProgress: Equatable, Sendable {
    var done: Int
    var total: Int

    /// Erledigte Punkte geteilt durch Punkte, gerundet auf ganze Zahl. Bei 0 Punkten 0.
    var percent: Int {
        guard total > 0 else { return 0 }
        return Int((Double(done) * 100 / Double(total)).rounded())
    }

    /// Anteil von 0 bis 1.
    var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(done) / Double(total)
    }
}

/// Rechenlogik ohne Oberfläche und ohne SwiftData.
/// "Heute" wird immer als Parameter übergeben, damit Tests mit festen Daten möglich sind.
nonisolated struct HabitEngine: Sendable {
    var calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// Tagesbeginn in der Zeitzone des Kalenders (Wechsel um Mitternacht).
    func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Wert eines Habits an einem Tag (0, wenn es keinen Eintrag gibt).
    func count(on day: Date, in counts: [DayCount]) -> Int {
        let day = startOfDay(day)
        return counts.first { startOfDay($0.day) == day }?.count ?? 0
    }

    // MARK: Abhaken (Spezifikation 3.3)

    /// Neuer Wert nach Tippen auf den Abhakkreis: 0 wird 1, sonst wieder 0.
    func toggledCount(_ current: Int) -> Int {
        current > 0 ? 0 : 1
    }

    /// Täglich mit Anzahl größer 1 zeigt einen Counter, alle anderen ein Quadrat zum Abhaken.
    func usesCounter(_ habit: HabitSnapshot) -> Bool {
        habit.rhythm == .daily && habit.targetCount > 1
    }

    /// Plus im Counter: höchstens bis zur Zielanzahl.
    func incrementedCount(_ current: Int, target: Int) -> Int {
        min(max(current, 0) + 1, max(target, 0))
    }

    /// Minus im Counter: nie unter 0.
    func decrementedCount(_ current: Int) -> Int {
        max(current - 1, 0)
    }

    // MARK: Fälligkeit (Spezifikation 3.2)

    /// Wochentag nach der Zählung der App: 1 = Montag bis 7 = Sonntag.
    func weekday(of day: Date) -> Int {
        // `Calendar` zählt 1 = Sonntag bis 7 = Samstag.
        (calendar.component(.weekday, from: day) + 5) % 7 + 1
    }

    /// Ob der Habit am Tag in "Heute" erscheint. Täglich, pro Woche und pro Monat sind jeden Tag
    /// fällig, feste Wochentage und fester Monatstag nur an ihren Tagen. Vor dem Erstelltag
    /// existierte der Habit noch nicht, an pausierten Tagen und ab dem Tag des Beendens ist er nie fällig.
    func isDue(_ habit: HabitSnapshot, on day: Date) -> Bool {
        isScheduled(habit, on: day) && !isPaused(habit, on: day) && !isEnded(habit, on: day)
    }

    /// Ob der Habit am Tag zwar fällig wäre, aber pausiert ist. Solche Habits stehen ausgegraut mit "Pausiert" am
    /// Ende der Liste, zählen aber nicht im Fortschritt (Spezifikation 3.8).
    func isShownAsPaused(_ habit: HabitSnapshot, on day: Date) -> Bool {
        isScheduled(habit, on: day) && isPaused(habit, on: day) && !isEnded(habit, on: day)
    }

    /// Ob der Habit am Tag pausiert (Spezifikation 3.8).
    func isPaused(_ habit: HabitSnapshot, on day: Date) -> Bool {
        let day = startOfDay(day)
        return habit.pauses.contains { startOfDay($0.start) <= day && day <= startOfDay($0.end) }
    }

    /// Ob der Habit am Tag schon beendet ist. Der Tag des Beendens selbst gilt als beendet, damit der Habit
    /// sofort aus "Heute" verschwindet (Spezifikation 3.9).
    func isEnded(_ habit: HabitSnapshot, on day: Date) -> Bool {
        guard let endedAt = habit.endedAt else { return false }
        return startOfDay(day) >= startOfDay(endedAt)
    }

    /// Ob der Rhythmus den Habit am Tag vorsieht, unabhängig von Pause und Beenden.
    private func isScheduled(_ habit: HabitSnapshot, on day: Date) -> Bool {
        let day = startOfDay(day)
        guard day >= startOfDay(habit.createdAt) else { return false }

        switch habit.rhythm {
        case .daily, .weekly, .monthly:
            return true
        case .weekdays:
            return habit.weekdays.contains(weekday(of: day))
        case .monthDay:
            guard let monthDay = habit.monthDay else { return false }
            // Hat der Monat weniger Tage (31. im Februar), ist sein letzter Tag fällig.
            let daysInMonth = calendar.range(of: .day, in: .month, for: day)?.count ?? 31
            return calendar.component(.day, from: day) == min(monthDay, daysInMonth)
        }
    }

    // MARK: Rollierende Fenster (Spezifikation 2 und 3.5)

    /// Länge des Fensters in Tagen: Woche 7, Monat 30. Andere Rhythmen haben keins.
    func windowLength(_ rhythm: Rhythm) -> Int? {
        switch rhythm {
        case .weekly: 7
        case .monthly: 30
        case .daily, .weekdays, .monthDay: nil
        }
    }

    /// So viele Tage vor Ablauf des Fensters wird ein erfülltes Ziel gelb.
    private func warningDays(_ rhythm: Rhythm) -> Int {
        rhythm == .monthly ? 5 : 2
    }

    /// Wert pro Tag, höchstens Tagesziel (bei nicht täglichen Habits also 0 oder 1).
    func cappedValues(_ habit: HabitSnapshot) -> [Date: Int] {
        let target = dailyTarget(habit)
        return habit.counts.reduce(into: [:]) { values, entry in
            values[startOfDay(entry.day), default: 0] += min(max(entry.count, 0), target)
        }
    }

    /// So weit zurück wird höchstens gesucht, wenn Pausentage übersprungen werden.
    private static let maxLookbackDays = 20_000

    /// Summe der Erledigungen in den letzten `length` Tagen, die an `day` enden. Tage, für die `isSkipped`
    /// wahr ist (Pausentage), werden übersprungen: das Fenster sind dann die letzten `length` übrigen Tage.
    func windowSum(
        _ values: [Date: Int], endingOn day: Date, length: Int, skipping isSkipped: (Date) -> Bool = { _ in false }
    ) -> Int {
        var sum = 0
        var counted = 0
        var date = startOfDay(day)
        var steps = 0
        while counted < length, steps < Self.maxLookbackDays {
            steps += 1
            if !isSkipped(date) {
                sum += values[date] ?? 0
                counted += 1
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = startOfDay(previous)
        }
        return sum
    }

    /// Stand im Fenster. `nil`, wenn der Rhythmus kein Fenster hat.
    func windowProgress(_ habit: HabitSnapshot, on day: Date) -> WindowProgress? {
        guard let length = windowLength(habit.rhythm) else { return nil }
        let done = windowSum(
            cappedValues(habit), endingOn: startOfDay(day), length: length, skipping: { isPaused(habit, on: $0) }
        )
        return WindowProgress(done: done, target: max(habit.targetCount, 1))
    }

    // MARK: Tagesfortschritt (Spezifikation 3.4)

    /// Zielanzahl pro Tag: bei täglichen Habits die Anzahl, sonst 1.
    func dailyTarget(_ habit: HabitSnapshot) -> Int {
        habit.rhythm == .daily ? max(habit.targetCount, 1) : 1
    }

    /// Erledigt heißt: das Tagesziel ist am Tag erreicht (Häkchen gesetzt, Counter voll). Ein Wochen
    /// oder Monats Habit mit erfülltem Fenster, der am Tag nicht abgehakt ist, bleibt offen.
    func isCompleted(_ habit: HabitSnapshot, on day: Date) -> Bool {
        count(on: day, in: habit.counts) >= dailyTarget(habit)
    }

    /// Punkte, die ein Habit am Tag wert ist (3x täglich = 3, alle anderen Rhythmen 1).
    func points(_ habit: HabitSnapshot, on day: Date) -> Int {
        dailyTarget(habit)
    }

    /// Erledigte Punkte. Täglich: heutiger Wert, höchstens Zielanzahl. Feste Tage: 1, wenn heute
    /// abgehakt. Pro Woche / pro Monat: 1, wenn heute abgehakt oder das Ziel im Fenster erfüllt ist.
    func donePoints(_ habit: HabitSnapshot, on day: Date) -> Int {
        let value = min(max(count(on: day, in: habit.counts), 0), dailyTarget(habit))
        switch habit.rhythm {
        case .daily, .weekdays, .monthDay:
            return value
        case .weekly, .monthly:
            if value > 0 { return 1 }
            guard let window = windowProgress(habit, on: day) else { return 0 }
            return window.done >= window.target ? 1 : 0
        }
    }

    /// Fortschritt über alle übergebenen Habits. Habits, die am Tag nicht fällig sind, zählen nicht mit.
    func dayProgress(_ habits: [HabitSnapshot], on day: Date) -> DayProgress {
        habits.filter { isDue($0, on: day) }.reduce(DayProgress(done: 0, total: 0)) { progress, habit in
            DayProgress(
                done: progress.done + donePoints(habit, on: day),
                total: progress.total + points(habit, on: day)
            )
        }
    }

    // MARK: Status (Spezifikation 3.5)

    /// Ampelstatus am Tag, berechnet aus den Erledigungen und den aktuellen Einstellungen.
    func status(_ habit: HabitSnapshot, on day: Date) -> HabitStatus {
        let day = startOfDay(day)
        switch habit.rhythm {
        case .daily:
            return dailyStatus(habit, on: day)
        case .weekly, .monthly:
            return windowStatus(habit, on: day)
        case .weekdays, .monthDay:
            return fixedDayStatus(habit, on: day)
        }
    }

    /// Täglich: grün, wenn das Ziel heute oder am letzten nicht pausierten Tag davor erreicht ist. Kein Gelb.
    private func dailyStatus(_ habit: HabitSnapshot, on day: Date) -> HabitStatus {
        let target = dailyTarget(habit)
        if count(on: day, in: habit.counts) >= target { return .green }

        // Heute erstellt (oder alle Tage davor pausiert): es gibt keinen Tag davor, der verpasst sein könnte.
        guard let previous = lastActiveDay(habit, before: day) else { return .green }
        return count(on: previous, in: habit.counts) >= target ? .green : .red
    }

    /// Der letzte nicht pausierte Tag vor `day`, nicht vor dem Erstelltag.
    private func lastActiveDay(_ habit: HabitSnapshot, before day: Date) -> Date? {
        let created = startOfDay(habit.createdAt)
        var date = startOfDay(day)
        for _ in 0..<Self.maxLookbackDays {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: date) else { return nil }
            date = startOfDay(previous)
            if date < created { return nil }
            if !isPaused(habit, on: date) { return date }
        }
        return nil
    }

    /// Pro Woche / pro Monat: grün, solange das Fenster erfüllt bleibt. Gelb, wenn es ohne neue
    /// Erledigungen in den nächsten 2 bzw. 5 Tagen nicht mehr erfüllt wäre. Rot, wenn es nicht
    /// erfüllt ist. Im ersten Fenster nach dem Erstellen gibt es kein Rot.
    private func windowStatus(_ habit: HabitSnapshot, on day: Date) -> HabitStatus {
        guard let length = windowLength(habit.rhythm) else { return .green }
        let warning = warningDays(habit.rhythm)
        let target = max(habit.targetCount, 1)
        let values = cappedValues(habit)
        let skipPaused = { (date: Date) in isPaused(habit, on: date) }

        if windowSum(values, endingOn: day, length: length, skipping: skipPaused) >= target {
            // Dasselbe Fenster, um `warning` Tage nach vorn geschoben: ohne neue Erledigungen
            // zählt nur noch, was in den letzten `length - warning` Tagen bis heute liegt.
            let later = windowSum(values, endingOn: day, length: length - warning, skipping: skipPaused)
            return later >= target ? .green : .yellow
        }

        // Das erste Fenster sind die ersten `length` nicht pausierten Tage ab dem Erstelltag.
        let daysSinceCreation = activeDays(habit, from: startOfDay(habit.createdAt), before: day, upTo: length)
        guard daysSinceCreation < length else { return .red }
        return daysSinceCreation >= length - warning ? .yellow : .green
    }

    /// Feste Wochentage / fester Monatstag: rot, wenn der letzte fällige Tag vor heute
    /// nicht abgehakt wurde. Kein Gelb. Ist der Habit heute fällig und schon abgehakt, ist er
    /// grün (wie bei täglich und pro Woche zählt die Erledigung von heute).
    private func fixedDayStatus(_ habit: HabitSnapshot, on day: Date) -> HabitStatus {
        if isDue(habit, on: day), count(on: day, in: habit.counts) > 0 { return .green }
        guard let last = lastDueDay(habit, before: day) else { return .green }
        return count(on: last, in: habit.counts) > 0 ? .green : .red
    }

    /// Der letzte fällige (also nicht pausierte) Tag vor `day`, nicht vor dem Erstelltag.
    private func lastDueDay(_ habit: HabitSnapshot, before day: Date) -> Date? {
        let created = startOfDay(habit.createdAt)
        var date = startOfDay(day)
        for _ in 0..<Self.maxLookbackDays {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: date) else { return nil }
            date = startOfDay(previous)
            if date < created { return nil }
            if isDue(habit, on: date) { return date }
        }
        return nil
    }

    /// Anzahl der nicht pausierten Tage von `start` bis vor `end`, gezählt höchstens bis `limit`.
    func activeDays(_ habit: HabitSnapshot, from start: Date, before end: Date, upTo limit: Int) -> Int {
        var count = 0
        var date = startOfDay(start)
        let end = startOfDay(end)
        while date < end, count < limit {
            if !isPaused(habit, on: date) { count += 1 }
            guard let next = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = startOfDay(next)
        }
        return count
    }

    // MARK: 7 Tage Punkte (Spezifikation 3.6)

    /// Die letzten 7 Tage, links der älteste, rechts `day`. Tage vor der Erstellung haben keine
    /// Erledigung und damit die Füllung 0, pausierte Tage sind ein grauer Strich.
    func weekDots(_ habit: HabitSnapshot, on day: Date) -> [WeekDot] {
        let today = startOfDay(day)
        let target = Double(dailyTarget(habit))
        let created = startOfDay(habit.createdAt)

        return (-6...0).map { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return .fill(0) }
            if startOfDay(date) >= created, isPaused(habit, on: date) { return .paused }
            let value = Double(count(on: date, in: habit.counts))
            return .fill(min(max(value / target, 0), 1))
        }
    }
}
