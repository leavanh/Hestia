import Foundation

/// Kennzahlen eines Habits (Spezifikation 3.7).
nonisolated struct HabitStatistics: Equatable, Sendable {
    /// Tage am Stück bis heute, an denen der Habit erfüllt war.
    var currentStreak: Int
    /// Größter Streak seit Erstellung, nie kleiner als der aktuelle.
    var longestStreak: Int
    /// Anteil von 0 bis 1 der erfüllten unter den bewerteten Tagen der letzten 30 Tage. `nil`, wenn es
    /// keinen bewerteten Tag gibt (z.B. heute erstellt und noch nichts erledigt).
    var rate30: Double?
    /// Summe aller Erledigungen von der Erstellung bis zum Statistiktag (Spezifikation 3.7), auch an Tagen, die
    /// später rückwirkend pausiert wurden.
    var totalCompletions: Int
    /// Pausen, die am Statistiktag schon begonnen haben (laufende und vergangene), geplante nicht.
    var pauseCount: Int

    /// Quote 30 Tage als ganze Prozent, gerundet. `nil`, wenn es noch keine Quote gibt.
    var ratePercent: Int? {
        rate30.map { Int(($0 * 100).rounded()) }
    }
}

extension HabitEngine {
    /// Länge des Zeitraums der Quote in Tagen.
    static let rateDays = 30

    /// Ergebnis eines bewerteten Tages. Tage ohne Wertung (nicht fällig, vor der Erstellung, noch offen)
    /// kommen gar nicht erst vor: sie unterbrechen einen Streak nicht und zählen nicht mit.
    private enum Outcome {
        case met
        case missed
    }

    /// Aktueller Streak: Tage am Stück bis `today`, an denen der Habit erfüllt war. Bei festen Wochentagen
    /// und festem Monatstag zählen nur die fälligen Tage. Ein heute noch offener Tag unterbricht den
    /// Streak nicht (der Tag ist noch nicht vorbei) und zählt erst mit, wenn er erreicht ist.
    func currentStreak(_ habit: HabitSnapshot, on today: Date) -> Int {
        statistics(habit, on: today).currentStreak
    }

    /// Längster Streak seit Erstellung.
    func longestStreak(_ habit: HabitSnapshot, on today: Date) -> Int {
        statistics(habit, on: today).longestStreak
    }

    /// Quote 30 Tage als Anteil von 0 bis 1, `nil` ohne bewerteten Tag.
    func rate30(_ habit: HabitSnapshot, on today: Date) -> Double? {
        statistics(habit, on: today).rate30
    }

    /// Alle Kennzahlen in einem Durchgang.
    func statistics(_ habit: HabitSnapshot, on today: Date) -> HabitStatistics {
        let today = startOfDay(today)
        let outcomes = evaluatedDays(habit, through: today)

        var current = 0
        var longest = 0
        for entry in outcomes {
            switch entry.outcome {
            case .met:
                current += 1
                longest = max(longest, current)
            case .missed:
                current = 0
            }
        }

        let recent = outcomes.filter { isInRateWindow($0.day, today: today) }
        let rate = recent.isEmpty
            ? nil
            : Double(recent.filter { $0.outcome == .met }.count) / Double(recent.count)

        return HabitStatistics(
            currentStreak: current,
            longestStreak: longest,
            rate30: rate,
            totalCompletions: totalCompletions(habit, through: today),
            pauseCount: pauseCount(habit, through: today)
        )
    }

    /// Letzter Tag, der in die Statistik eingeht: `today`, bei einem beendeten Habit der Tag des Beendens.
    private func lastStatisticsDay(_ habit: HabitSnapshot, today: Date) -> Date {
        guard let endedAt = habit.endedAt else { return today }
        return min(today, startOfDay(endedAt))
    }

    /// Summe aller Erledigungen (`count`) von der Erstellung bis zum Statistiktag, Pausen und Streaks unbeachtet.
    func totalCompletions(_ habit: HabitSnapshot, through today: Date) -> Int {
        let first = startOfDay(habit.createdAt)
        let last = lastStatisticsDay(habit, today: startOfDay(today))
        return habit.counts
            .filter { first <= startOfDay($0.day) && startOfDay($0.day) <= last }
            .reduce(0) { $0 + $1.count }
    }

    /// Anzahl der Pausen, die am Statistiktag schon begonnen haben.
    func pauseCount(_ habit: HabitSnapshot, through today: Date) -> Int {
        let last = lastStatisticsDay(habit, today: startOfDay(today))
        return habit.pauses.filter { startOfDay($0.start) <= last }.count
    }

    private func isInRateWindow(_ day: Date, today: Date) -> Bool {
        guard let first = calendar.date(byAdding: .day, value: -(Self.rateDays - 1), to: today) else { return false }
        return day >= first
    }

    /// Die bewerteten Tage von der Erstellung bis `today`, aufsteigend.
    ///
    /// - Täglich: erfüllt, wenn das Tagesziel erreicht ist.
    /// - Feste Wochentage / fester Monatstag: nur fällige Tage, erfüllt, wenn abgehakt.
    /// - Pro Woche / pro Monat: erfüllt, solange das Fenster des Tages das Ziel erreicht (Status grün oder
    ///   gelb). Im ersten Fenster nach der Erstellung ist ein unerfülltes Ziel noch nicht verpasst (3.5).
    /// - Pro Woche / pro Monat mit Kalenderzeiträumen (ab Phase 15): ein Tag übernimmt das Ergebnis seines Zeitraums
    ///   (`calendarOutcome`).
    /// - Ein heute nicht erfüllter Tag ist noch offen und wird nicht bewertet.
    /// - Pausierte Tage und Tage ab dem Beenden werden übersprungen: sie unterbrechen keinen Streak, zählen nicht
    ///   mit und gehören nicht zur Quote. Fenster überspringen Pausentage ebenfalls.
    private func evaluatedDays(_ habit: HabitSnapshot, through today: Date) -> [(day: Date, outcome: Outcome)] {
        let created = startOfDay(habit.createdAt)
        let values = cappedValues(habit)
        let target = dailyTarget(habit)
        let windowTarget = max(habit.targetCount, 1)
        let length = windowLength(habit.rhythm)

        var result: [(day: Date, outcome: Outcome)] = []
        var day = created
        /// Nicht pausierte Tage seit der Erstellung vor dem aktuellen Tag: so alt ist der Habit in Tagen,
        /// die zählen (Pausentage zählen nicht mit).
        var activeAge = 0
        /// Kalenderzeiträume und ihr Stand, nach Beginn des Zeitraums (nur bei Zeiträumen "Kalender").
        var periodCache: [Date: (period: CalendarPeriod, target: Int, done: Int)] = [:]
        while day <= today {
            defer { day = calendar.date(byAdding: .day, value: 1, to: day).map(startOfDay) ?? today.addingTimeInterval(1) }

            // Pausierte Tage zählen nicht, ebenso Tage ab dem Beenden (Spezifikation 3.7, 3.8, 3.9).
            if isPaused(habit, on: day) { continue }
            let age = activeAge
            activeAge += 1
            if isEnded(habit, on: day) { continue }

            let outcome: Outcome?
            switch habit.rhythm {
            case .daily:
                outcome = (values[day] ?? 0) >= target ? .met : .missed
            case .weekdays, .monthDay:
                outcome = isDue(habit, on: day) ? ((values[day] ?? 0) > 0 ? .met : .missed) : nil
            case .weekly, .monthly:
                if periods == .calendar {
                    outcome = calendarOutcome(habit, values: values, day: day, today: today, cache: &periodCache)
                    break
                }
                guard let length else { continue }
                if windowSum(values, endingOn: day, length: length, skipping: { isPaused(habit, on: $0) }) >= windowTarget {
                    outcome = .met
                } else {
                    outcome = age < length ? nil : .missed
                }
            }

            guard let outcome else { continue }
            if outcome == .missed, day == today { continue }
            result.append((day, outcome))
        }
        return result
    }

    /// Ergebnis eines Tages bei Kalenderzeiträumen (Spezifikation 3.7): Ist das Ziel des Zeitraums erreicht, ist der
    /// Tag erfüllt, auch im laufenden Zeitraum (bis heute). Sonst verpasst, wenn der Zeitraum vorbei ist und nicht nur
    /// bei erreichtem Ziel zählt, und in allen anderen Fällen noch offen.
    private func calendarOutcome(
        _ habit: HabitSnapshot,
        values: [Date: Int],
        day: Date,
        today: Date,
        cache: inout [Date: (period: CalendarPeriod, target: Int, done: Int)]
    ) -> Outcome? {
        guard let first = period(for: habit, on: day) else { return nil }
        let entry: (period: CalendarPeriod, target: Int, done: Int)
        if let cached = cache[first.start] {
            entry = cached
        } else {
            entry = (first, periodTarget(habit, period: first), periodDone(values, habit: habit, period: first, through: min(first.end, today)))
            cache[first.start] = entry
        }
        if entry.done >= entry.target { return .met }
        return entry.period.end < today && !entry.period.countsOnlyIfReached ? .missed : nil
    }
}
