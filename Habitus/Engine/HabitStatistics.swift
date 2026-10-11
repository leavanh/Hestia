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

        return HabitStatistics(currentStreak: current, longestStreak: longest, rate30: rate)
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
    /// - Ein heute nicht erfüllter Tag ist noch offen und wird nicht bewertet.
    private func evaluatedDays(_ habit: HabitSnapshot, through today: Date) -> [(day: Date, outcome: Outcome)] {
        let created = startOfDay(habit.createdAt)
        let values = cappedValues(habit)
        let target = dailyTarget(habit)
        let windowTarget = max(habit.targetCount, 1)
        let length = windowLength(habit.rhythm)

        var result: [(day: Date, outcome: Outcome)] = []
        var day = created
        while day <= today {
            defer { day = calendar.date(byAdding: .day, value: 1, to: day).map(startOfDay) ?? today.addingTimeInterval(1) }

            let outcome: Outcome?
            switch habit.rhythm {
            case .daily:
                outcome = (values[day] ?? 0) >= target ? .met : .missed
            case .weekdays, .monthDay:
                outcome = isDue(habit, on: day) ? ((values[day] ?? 0) > 0 ? .met : .missed) : nil
            case .weekly, .monthly:
                guard let length else { continue }
                if windowSum(values, endingOn: day, length: length) >= windowTarget {
                    outcome = .met
                } else {
                    let age = calendar.dateComponents([.day], from: created, to: day).day ?? 0
                    outcome = age < length ? nil : .missed
                }
            }

            guard let outcome else { continue }
            if outcome == .missed, day == today { continue }
            result.append((day, outcome))
        }
        return result
    }
}
