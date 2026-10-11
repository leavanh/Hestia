import Foundation
import SwiftData

extension Habit {
    /// Ob der Habit noch in der Datenbank steht. Nach dem Löschen zeichnet sich eine Ansicht, die
    /// im Hintergrund liegt (z.B. Heute hinter den Einstellungen), kurz noch mit dem alten Objekt
    /// neu. Dessen Eigenschaften zu lesen stürzt ab.
    var isAlive: Bool {
        !isDeleted && modelContext != nil
    }

    /// Erledigungen als reine Werte für die `HabitEngine`.
    var dayCounts: [DayCount] {
        completions.map { DayCount(day: $0.day, count: $0.count) }
    }

    /// Alles, was die `HabitEngine` braucht, als reiner Wert.
    var snapshot: HabitSnapshot {
        HabitSnapshot(
            rhythm: rhythm,
            targetCount: targetCount,
            weekdays: weekdays,
            monthDay: monthDay,
            createdAt: createdAt,
            counts: dayCounts,
            pauses: pauses.map(\.range),
            endedAt: endedAt
        )
    }

    /// Setzt den Wert eines Tages und speichert sofort. Bei 0 wird der Eintrag gelöscht (Spezifikation 6).
    func setCount(_ count: Int, on day: Date, engine: HabitEngine, in context: ModelContext) {
        let day = engine.startOfDay(day)
        let existing = completions.first { $0.day == day }

        if count <= 0 {
            if let existing {
                completions.removeAll { $0.id == existing.id }
                context.delete(existing)
            }
        } else if let existing {
            existing.count = count
        } else {
            let completion = Completion(day: day, count: count)
            context.insert(completion)
            completions.append(completion)
        }
        try? context.save()
    }
}

extension Habit {
    /// Tag, bis zu dem Streaks und Quote gerechnet werden: heute, bei einem beendeten Habit sein letzter Tag.
    func statisticsDay(today: Date, engine: HabitEngine) -> Date {
        let today = engine.startOfDay(today)
        guard let endedAt else { return today }
        return min(today, engine.startOfDay(endedAt))
    }
}
