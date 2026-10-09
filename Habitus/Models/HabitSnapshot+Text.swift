import Foundation

extension HabitSnapshot {
    /// Rhythmus Zeile auf der `HabitCard` (Spezifikation 4.3.1). Bei Woche und Monat steht davor
    /// der Stand im Fenster, `window` kommt aus `HabitEngine.windowProgress`.
    func rhythmText(window: WindowProgress?) -> String {
        switch rhythm {
        case .daily:
            return targetCount > 1 ? "\(targetCount) pro Tag" : "Täglich"
        case .weekly:
            return "\(window?.done ?? 0) von \(max(targetCount, 1)) diese Woche"
        case .monthly:
            return "\(window?.done ?? 0) von \(max(targetCount, 1)) diesen Monat"
        case .weekdays:
            let names = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
            return Set(weekdays).sorted().compactMap { (1...7).contains($0) ? names[$0 - 1] : nil }
                .joined(separator: ", ")
        case .monthDay:
            return "Am \(monthDay ?? 1). des Monats"
        }
    }
}
