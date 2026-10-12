import Foundation
import SwiftData

extension Habit {
    /// Beendet den Habit ab `today`: Er erscheint ab diesem Tag nicht mehr in Heute, seine Historie bleibt
    /// in Kalender und Statistik (Spezifikation 3.9).
    func end(on today: Date, engine: HabitEngine, in context: ModelContext) {
        endedAt = engine.startOfDay(today)
        try? context.save()
    }

    /// Löscht den Habit mit allen Erledigungen und seiner Zuordnung zu Pausen. Eine Pause, die dadurch keinen
    /// Habit mehr hat, wird ebenfalls entfernt. Das ist die Antwort "Historie löschen" beim Beenden (Spezifikation 3.9).
    func deleteWithHistory(in context: ModelContext) {
        let id = self.id
        let affectedPauses = pauses
        for pause in affectedPauses {
            pause.habits.removeAll { $0.id == id }
            if pause.habits.isEmpty { context.delete(pause) }
        }
        // Die Erledigungen löscht die Beziehung (`deleteRule: .cascade`).
        context.delete(self)
        try? context.save()
    }

    /// Die Habits in der gespeicherten Reihenfolge: `sortOrder`, bei Gleichstand `createdAt`.
    static func inSavedOrder(_ habits: [Habit]) -> [Habit] {
        habits.sorted {
            $0.sortOrder != $1.sortOrder ? $0.sortOrder < $1.sortOrder : $0.createdAt < $1.createdAt
        }
    }

    /// Speichert die Reihenfolge nach dem Verschieben im Sortiermodus (`HabitOrder.reordered`). `shown` sind die
    /// gezeigten Habits in ihrer neuen Reihenfolge, alle Habits bekommen danach fortlaufende Plätze.
    static func saveOrder(all habits: [Habit], shown: [Habit], in context: ModelContext) {
        let merged = HabitOrder.reordered(all: inSavedOrder(habits).map(\.id), shown: shown.map(\.id))
        let byID = Dictionary(uniqueKeysWithValues: habits.map { ($0.id, $0) })
        for (index, id) in merged.enumerated() {
            byID[id]?.sortOrder = index
        }
        try? context.save()
    }
}

extension Habit {
    /// Beendet die heute laufende Pause nur für diesen Habit (Phase 18.5): Er ist ab heute nicht mehr pausiert.
    /// Gilt die Pause nur für ihn, endet sie gestern bzw. entfällt (`Pause.endEarly`). Gilt sie auch für andere,
    /// bleibt sie für diese, und dieser Habit bekommt eine eigene Pause vom Beginn bis gestern, sofern ein Tag übrig ist.
    func endRunningPause(today: Date, engine: HabitEngine, in context: ModelContext) {
        for pause in pauses where engine.phase(of: pause.range, today: today) == .running {
            if pause.habits.count <= 1 {
                pause.endEarly(today: today, engine: engine, in: context)
                continue
            }
            pause.habits.removeAll { $0.id == id }
            if let shortened = engine.endedEarly(pause.range, today: today) {
                let own = Pause(startDay: shortened.start, endDay: shortened.end)
                context.insert(own)
                own.habits = [self]
            }
        }
        try? context.save()
    }
}

extension Pause {
    var range: PauseRange {
        PauseRange(start: startDay, end: endDay)
    }

    /// Beendet die Pause vorzeitig: Enddatum gestern. Bleibt kein Tag übrig (geplant oder heute begonnen),
    /// wird die Pause entfernt (Spezifikation 3.8).
    func endEarly(today: Date, engine: HabitEngine, in context: ModelContext) {
        if let shortened = engine.endedEarly(range, today: today) {
            endDay = shortened.end
        } else {
            context.delete(self)
        }
        try? context.save()
    }
}
