import Foundation

/// Wo eine Pause zeitlich steht (Spezifikation 5.5: laufende und geplante Pausen werden aufgelistet).
nonisolated enum PausePhase: Equatable, Sendable {
    /// Beginnt nach heute.
    case upcoming
    /// Heute ist ein Tag der Pause.
    case running
    /// Endet vor heute.
    case over
}

extension HabitEngine {
    func phase(of pause: PauseRange, today: Date) -> PausePhase {
        let today = startOfDay(today)
        if startOfDay(pause.end) < today { return .over }
        return startOfDay(pause.start) > today ? .upcoming : .running
    }

    /// Ob sich die beiden Zeiträume an mindestens einem Tag überschneiden.
    func overlaps(_ first: PauseRange, _ second: PauseRange) -> Bool {
        startOfDay(first.start) <= startOfDay(second.end) && startOfDay(second.start) <= startOfDay(first.end)
    }

    /// Eine Pause vorzeitig beenden: Enddatum ist gestern (Spezifikation 3.8). `nil`, wenn dann kein Tag
    /// mehr übrig ist (geplant, oder heute begonnen). Eine solche Pause wird entfernt.
    func endedEarly(_ pause: PauseRange, today: Date) -> PauseRange? {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfDay(today)) else { return nil }
        guard startOfDay(pause.start) <= startOfDay(yesterday) else { return nil }
        return PauseRange(start: pause.start, end: min(pause.end, startOfDay(yesterday)))
    }
}

/// Reihenfolge aller Habits (`sortOrder`), ohne Oberfläche (Spezifikation 5.2, Sortieren).
nonisolated enum HabitOrder {
    /// Die neue Gesamtreihenfolge nach dem Verschieben in Heute.
    ///
    /// Die offenen Habits des Tages bekommen in ihrer neuen Reihenfolge die vorderen Plätze unter allen sichtbaren
    /// Habits, die erledigten folgen dahinter in ihrer bisherigen Reihenfolge. Habits, die am Tag nicht in der
    /// Liste stehen (nicht fällig, pausiert, beendet), behalten ihren Platz.
    static func merged<ID: Hashable>(all: [ID], open: [ID], done: [ID]) -> [ID] {
        let visible = open + done
        let visibleSet = Set(visible)
        var queue = visible[...]
        return all.map { id in
            guard visibleSet.contains(id), let next = queue.popFirst() else { return id }
            return next
        }
    }
}
