import Foundation

/// Regeln für den Zusatz am Habit (Spezifikation 5.3).
enum HabitDetail {
    static let maxLength = 24

    /// Ohne Leerzeichen am Anfang und Ende, auf `maxLength` Zeichen begrenzt.
    static func normalized(_ text: String) -> String {
        String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxLength)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension HabitSnapshot {
    /// Rhythmus Zeile (Spezifikation 4.5.1): ein vorhandener Zusatz steht vorne, getrennt mit " · ".
    /// Bei Woche und Monat steht im Rhythmus der Stand im Fenster, `window` kommt aus `HabitEngine.windowProgress`.
    /// Feste Wochentage folgen dem Wochenbeginn `firstWeekday` (1 = Montag bis 7 = Sonntag).
    func rhythmText(window: WindowProgress?, firstWeekday: Int = 1) -> String {
        let base = baseRhythmText(window: window, firstWeekday: firstWeekday)
        let extra = HabitDetail.normalized(detail)
        return extra.isEmpty ? base : "\(extra) · \(base)"
    }

    private func baseRhythmText(window: WindowProgress?, firstWeekday: Int) -> String {
        switch rhythm {
        case .daily:
            return targetCount > 1 ? "\(targetCount) pro Tag" : "Täglich"
        case .weekly:
            return "\(window?.done ?? 0) von \(max(targetCount, 1)) diese Woche"
        case .monthly:
            return "\(window?.done ?? 0) von \(max(targetCount, 1)) diesen Monat"
        case .weekdays:
            // Die Tage stehen in der Reihenfolge der Woche, die am Wochenbeginn anfängt.
            let chosen = Set(weekdays)
            return DayText.weekdays(startingAt: firstWeekday).filter { chosen.contains($0) }.map { DayText.weekdayName($0) }
                .joined(separator: " · ")
        case .monthDay:
            return "Am \(monthDay ?? 1). des Monats"
        }
    }
}
