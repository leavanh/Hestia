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
    /// Feste Wochentage folgen dem Wochenbeginn `firstWeekday` (1 = Montag bis 7 = Sonntag). Bei Woche und Monat
    /// hängt der Text von den Zeiträumen ab: "in 7 Tagen" bzw. "in 30 Tagen" rollierend, "diese Woche" bzw.
    /// "diesen Monat" nach Kalender (ab Phase 15).
    func rhythmText(
        window: WindowProgress?, firstWeekday: Int = 1, periods: Periods = .rolling, locale: Locale = .current
    ) -> String {
        let base = baseRhythmText(window: window, firstWeekday: firstWeekday, periods: periods, locale: locale)
        let extra = HabitDetail.normalized(detail)
        return extra.isEmpty ? base : "\(extra) · \(base)"
    }

    private func baseRhythmText(window: WindowProgress?, firstWeekday: Int, periods: Periods, locale: Locale) -> String {
        switch rhythm {
        case .daily:
            return targetCount > 1 ? localized("\(targetCount) pro Tag", locale: locale) : localized("Täglich", locale: locale)
        case .weekly:
            let done = window?.done ?? 0
            let target = window?.target ?? max(targetCount, 1)
            return periods == .calendar
                ? localized("\(done) von \(target) diese Woche", locale: locale)
                : localized("\(done) von \(target) in 7 Tagen", locale: locale)
        case .monthly:
            let done = window?.done ?? 0
            let target = window?.target ?? max(targetCount, 1)
            return periods == .calendar
                ? localized("\(done) von \(target) diesen Monat", locale: locale)
                : localized("\(done) von \(target) in 30 Tagen", locale: locale)
        case .weekdays:
            // Die Tage stehen in der Reihenfolge der Woche, die am Wochenbeginn anfängt.
            let chosen = Set(weekdays)
            return DayText.weekdays(startingAt: firstWeekday).filter { chosen.contains($0) }
                .map { DayText.weekdayName($0, locale: locale) }
                .joined(separator: " · ")
        case .monthDay:
            return localized("Am \(monthDay ?? 1). des Monats", locale: locale)
        }
    }
}
