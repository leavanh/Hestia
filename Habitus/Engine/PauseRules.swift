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
    /// Die neue Gesamtreihenfolge nach dem Verschieben im Sortiermodus.
    ///
    /// `shown` sind die Habits, die der Sortiermodus zeigt, in ihrer neuen Reihenfolge. Sie belegen die Plätze, die sie
    /// vorher in `all` hatten, in dieser Reihenfolge. Habits, die nicht gezeigt werden (beendete), behalten ihren Platz.
    static func reordered<ID: Hashable>(all: [ID], shown: [ID]) -> [ID] {
        let shownSet = Set(shown)
        var queue = shown[...]
        return all.map { id in
            guard shownSet.contains(id), let next = queue.popFirst() else { return id }
            return next
        }
    }
}
