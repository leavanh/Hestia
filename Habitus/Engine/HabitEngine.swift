import Foundation

/// Wert eines Habits an einem Tag, unabhängig von SwiftData.
nonisolated struct DayCount: Equatable, Sendable {
    var day: Date
    var count: Int
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

    /// Anteil von 0 bis 1 für den Fortschrittsring.
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

    /// Täglich mit Anzahl größer 1 zeigt einen Counter, alle anderen einen Kreis.
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
    /// existierte der Habit noch nicht.
    func isDue(_ habit: HabitSnapshot, on day: Date) -> Bool {
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
    private func cappedValues(_ habit: HabitSnapshot) -> [Date: Int] {
        let target = dailyTarget(habit)
        return habit.counts.reduce(into: [:]) { values, entry in
            values[startOfDay(entry.day), default: 0] += min(max(entry.count, 0), target)
        }
    }

    /// Summe der Erledigungen in den letzten `length` Tagen, die an `day` enden.
    private func windowSum(_ values: [Date: Int], endingOn day: Date, length: Int) -> Int {
        (0..<max(length, 0)).reduce(0) { sum, offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: day) else { return sum }
            return sum + (values[startOfDay(date)] ?? 0)
        }
    }

    /// Stand im Fenster. `nil`, wenn der Rhythmus kein Fenster hat.
    func windowProgress(_ habit: HabitSnapshot, on day: Date) -> WindowProgress? {
        guard let length = windowLength(habit.rhythm) else { return nil }
        let done = windowSum(cappedValues(habit), endingOn: startOfDay(day), length: length)
        return WindowProgress(done: done, target: max(habit.targetCount, 1))
    }

    // MARK: Tagesfortschritt (Spezifikation 3.4)

    /// Zielanzahl pro Tag: bei täglichen Habits die Anzahl, sonst 1.
    func dailyTarget(_ habit: HabitSnapshot) -> Int {
        habit.rhythm == .daily ? max(habit.targetCount, 1) : 1
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

    /// Täglich: grün, wenn das Ziel heute oder am Tag davor erreicht ist. Kein Gelb.
    private func dailyStatus(_ habit: HabitSnapshot, on day: Date) -> HabitStatus {
        let target = dailyTarget(habit)
        if count(on: day, in: habit.counts) >= target { return .green }

        // Heute erstellt: es gibt keinen Tag davor, der verpasst sein könnte.
        guard let previous = calendar.date(byAdding: .day, value: -1, to: day),
              previous >= startOfDay(habit.createdAt) else { return .green }
        return count(on: previous, in: habit.counts) >= target ? .green : .red
    }

    /// Pro Woche / pro Monat: grün, solange das Fenster erfüllt bleibt. Gelb, wenn es ohne neue
    /// Erledigungen in den nächsten 2 bzw. 5 Tagen nicht mehr erfüllt wäre. Rot, wenn es nicht
    /// erfüllt ist. Im ersten Fenster nach dem Erstellen gibt es kein Rot.
    private func windowStatus(_ habit: HabitSnapshot, on day: Date) -> HabitStatus {
        guard let length = windowLength(habit.rhythm) else { return .green }
        let warning = warningDays(habit.rhythm)
        let target = max(habit.targetCount, 1)
        let values = cappedValues(habit)

        if windowSum(values, endingOn: day, length: length) >= target {
            // Dasselbe Fenster, um `warning` Tage nach vorn geschoben: ohne neue Erledigungen
            // zählt nur noch, was in den letzten `length - warning` Tagen bis heute liegt.
            let later = windowSum(values, endingOn: day, length: length - warning)
            return later >= target ? .green : .yellow
        }

        let created = startOfDay(habit.createdAt)
        let daysSinceCreation = calendar.dateComponents([.day], from: created, to: day).day ?? 0
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

    /// Der letzte fällige Tag vor `day`, nicht vor dem Erstelltag. Zwischen zwei fälligen Tagen
    /// liegen höchstens 31 Tage.
    private func lastDueDay(_ habit: HabitSnapshot, before day: Date) -> Date? {
        for offset in 1...62 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: day) else { return nil }
            if isDue(habit, on: date) { return date }
        }
        return nil
    }

    // MARK: 7 Tage Punkte (Spezifikation 3.6)

    /// Die letzten 7 Tage, links der älteste, rechts `day`. Tage vor der Erstellung haben keine
    /// Erledigung und damit die Füllung 0.
    func weekDots(_ habit: HabitSnapshot, on day: Date) -> [WeekDot] {
        let today = startOfDay(day)
        let target = Double(dailyTarget(habit))

        return (-6...0).map { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return .fill(0) }
            let value = Double(count(on: date, in: habit.counts))
            return .fill(min(max(value / target, 0), 1))
        }
    }
}
