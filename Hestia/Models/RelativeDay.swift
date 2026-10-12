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
    private static let locale = Locale(identifier: "de_DE")

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        return calendar
    }()

    /// Die Symbole von `Calendar` beginnen am Sonntag, die Wochentage der App am Montag (1 = Montag bis 7 = Sonntag).
    private static func symbol(_ symbols: [String], _ weekday: Int) -> String {
        symbols[HabitEngine.calendarWeekday(weekday) - 1]
    }

    /// Kurzname eines Wochentags der App: "Mo", "Di" und so weiter.
    static func weekdayName(_ weekday: Int) -> String {
        symbol(calendar.shortStandaloneWeekdaySymbols, weekday)
    }

    /// Anfangsbuchstabe eines Wochentags der App: "M", "D" und so weiter.
    static func weekdayInitial(_ weekday: Int) -> String {
        symbol(calendar.veryShortStandaloneWeekdaySymbols, weekday)
    }

    /// Voller Name eines Wochentags der App: "Montag", "Dienstag" und so weiter.
    static func weekdayFullName(_ weekday: Int) -> String {
        symbol(calendar.standaloneWeekdaySymbols, weekday)
    }

    /// Die 7 Wochentage der App ab dem Wochenbeginn (1 = Montag bis 7 = Sonntag).
    static func weekdays(startingAt firstWeekday: Int) -> [Int] {
        (0..<7).map { (firstWeekday - 1 + $0) % 7 + 1 }
    }

    /// Kurznamen der Wochentage ab dem Wochenbeginn.
    static func weekdayNames(startingAt firstWeekday: Int) -> [String] {
        weekdays(startingAt: firstWeekday).map { weekdayName($0) }
    }

    /// Datumszeile ohne Kalenderwoche: "So · 11. Okt".
    static func dateLine(_ day: Date, engine: HabitEngine) -> String {
        "\(weekdayName(engine.weekday(of: day))) · \(shortDate(day, engine: engine))"
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
    static func weekNumber(_ day: Date, engine: HabitEngine, firstWeekday: Int = 1) -> String {
        "KW \(engine.weekOfYear(day, firstWeekday: firstWeekday))"
    }

    /// Vollständiges Datum für VoiceOver: "Sonntag, 11. Oktober".
    static func fullDate(_ day: Date) -> String {
        day.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(locale))
    }
}
