import Foundation

/// Die Tage eines Monats für den Kalender (Spezifikation 5.4), ohne Oberfläche.
nonisolated struct MonthGrid: Equatable, Sendable {
    /// Tagesbeginn des ersten Tags im Monat.
    var firstDay: Date
    /// Tagesbeginn aller Tage des Monats, aufsteigend.
    var days: [Date]
    /// Leere Felder vor dem 1., weil die Woche am Montag beginnt (Montag 0, Sonntag 6).
    var leadingBlanks: Int
}

extension HabitEngine {
    /// Der Monat, der `date` enthält. Die Woche beginnt am Montag, unabhängig von der Region des Geräts.
    func monthGrid(containing date: Date) -> MonthGrid {
        let first = firstOfMonth(containing: date)
        let count = calendar.range(of: .day, in: .month, for: first)?.count ?? 30
        let days = (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: first) }
        return MonthGrid(firstDay: first, days: days, leadingBlanks: weekday(of: first) - 1)
    }

    /// Tagesbeginn des 1. des Monats, der `date` enthält.
    func firstOfMonth(containing date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components).map(startOfDay) ?? startOfDay(date)
    }

    /// Die Anfänge aller Monate von dem, der `first` enthält, bis zu dem, der `last` enthält, aufsteigend.
    func monthStarts(from first: Date, through last: Date) -> [Date] {
        let end = firstOfMonth(containing: last)
        var months: [Date] = []
        var month = firstOfMonth(containing: first)
        while month <= end {
            months.append(month)
            guard let next = calendar.date(byAdding: .month, value: 1, to: month) else { break }
            month = startOfDay(next)
        }
        return months
    }

    /// Ob `day` nach `today` liegt. Zukünftige Tage sind im Kalender gesperrt (Spezifikation 5.4).
    func isFuture(_ day: Date, today: Date) -> Bool {
        startOfDay(day) > startOfDay(today)
    }

    /// Der Monat `months` Monate nach `month` (negativ: davor), begrenzt auf den Bereich vom Monat, der `first`
    /// enthält, bis zu dem, der `last` enthält. Gibt den Anfang des Monats zurück (Spezifikation 5.4).
    func steppedMonth(_ month: Date, by months: Int, from first: Date, through last: Date) -> Date {
        let lower = firstOfMonth(containing: first)
        let upper = max(firstOfMonth(containing: last), lower)
        guard let moved = calendar.date(byAdding: .month, value: months, to: firstOfMonth(containing: month)) else {
            return min(max(firstOfMonth(containing: month), lower), upper)
        }
        return min(max(firstOfMonth(containing: moved), lower), upper)
    }
}
