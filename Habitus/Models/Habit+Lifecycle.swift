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

    /// Speichert die Reihenfolge nach dem Verschieben in Heute (`HabitOrder.merged`). Alle Habits bekommen
    /// danach fortlaufende Plätze.
    static func saveOrder(all habits: [Habit], open: [Habit], done: [Habit], in context: ModelContext) {
        let ordered = habits.sorted {
            $0.sortOrder != $1.sortOrder ? $0.sortOrder < $1.sortOrder : $0.createdAt < $1.createdAt
        }
        let merged = HabitOrder.merged(all: ordered.map(\.id), open: open.map(\.id), done: done.map(\.id))
        let byID = Dictionary(uniqueKeysWithValues: habits.map { ($0.id, $0) })
        for (index, id) in merged.enumerated() {
            byID[id]?.sortOrder = index
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
