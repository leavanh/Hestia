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
    func rhythmText(window: WindowProgress?) -> String {
        let base = baseRhythmText(window: window)
        let extra = HabitDetail.normalized(detail)
        return extra.isEmpty ? base : "\(extra) · \(base)"
    }

    private func baseRhythmText(window: WindowProgress?) -> String {
        switch rhythm {
        case .daily:
            return targetCount > 1 ? "\(targetCount) pro Tag" : "Täglich"
        case .weekly:
            return "\(window?.done ?? 0) von \(max(targetCount, 1)) diese Woche"
        case .monthly:
            return "\(window?.done ?? 0) von \(max(targetCount, 1)) diesen Monat"
        case .weekdays:
            return Set(weekdays).sorted().compactMap { (1...7).contains($0) ? DayText.weekdayNames[$0 - 1] : nil }
                .joined(separator: " · ")
        case .monthDay:
            return "Am \(monthDay ?? 1). des Monats"
        }
    }
}
