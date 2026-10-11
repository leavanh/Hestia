import Foundation

/// Beschriftung des angezeigten Tags im Verhältnis zu heute (Spezifikation 5.2).
enum RelativeDay {
    /// "Heute", "Gestern", "Vorgestern", sonst "Vor n Tagen". `daysAgo` ist 0 für heute.
    static func text(daysAgo: Int) -> String {
        switch daysAgo {
        case ...0: "Heute"
        case 1: "Gestern"
        case 2: "Vorgestern"
        default: "Vor \(daysAgo) Tagen"
        }
    }
}

/// Datumstexte im Kopfband von Heute (Spezifikation 5.2).
enum DayText {
    /// Kurznamen der Wochentage, Index 0 = Montag.
    static let weekdayNames = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    private static let locale = Locale(identifier: "de_DE")

    /// Datumszeile ohne Kalenderwoche: "So · 11. Okt".
    static func dateLine(_ day: Date, engine: HabitEngine) -> String {
        "\(weekdayNames[engine.weekday(of: day) - 1]) · \(shortDate(day, engine: engine))"
    }

    /// Tag und Monat: "11. Okt".
    static func shortDate(_ day: Date, engine: HabitEngine) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = engine.calendar
        formatter.timeZone = engine.calendar.timeZone
        formatter.dateFormat = "d. LLL"
        return formatter.string(from: day).replacingOccurrences(of: ".", with: "", options: [.anchored, .backwards])
    }

    /// Datum mit Jahr: "11. Okt 2026".
    static func dateWithYear(_ day: Date, engine: HabitEngine) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = engine.calendar
        formatter.timeZone = engine.calendar.timeZone
        formatter.dateFormat = "d. LLL"
        let date = formatter.string(from: day).replacingOccurrences(of: ".", with: "", options: [.anchored, .backwards])
        return "\(date) \(engine.calendar.component(.year, from: day))"
    }

    /// Kalenderwoche: "KW 41".
    static func weekNumber(_ day: Date, engine: HabitEngine) -> String {
        "KW \(engine.isoWeek(day))"
    }

    /// Vollständiges Datum für VoiceOver: "Sonntag, 11. Oktober".
    static func fullDate(_ day: Date) -> String {
        day.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(locale))
    }
}
