import Foundation

extension PauseRange {
    /// Zeitraum als Text: "8. Okt." bei einem Tag, sonst "8. Okt. – 10. Okt." (englisch "Oct 8 – Oct 10"). Das Jahr steht nur dabei, wenn es
    /// nicht das von `today` ist.
    func text(today: Date, calendar: Calendar, locale: Locale = .current) -> String {
        let thisYear = calendar.component(.year, from: today)
        let showsYear = [start, end].contains { calendar.component(.year, from: $0) != thisYear }
        let format: Date.FormatStyle = showsYear
            ? .dateTime.day().month(.abbreviated).year().locale(locale)
            : .dateTime.day().month(.abbreviated).locale(locale)

        let first = start.formatted(format)
        guard calendar.startOfDay(for: start) != calendar.startOfDay(for: end) else { return first }
        return "\(first) – \(end.formatted(format))"
    }
}
