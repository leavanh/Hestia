import Foundation

/// Beschriftung des angezeigten Tags im Verhältnis zu heute (Spezifikation 5.2).
enum RelativeDay {
    /// "Heute", "Gestern", "Vorgestern", sonst "Vor n Tagen". `daysAgo` ist 0 für heute.
    static func text(daysAgo: Int, locale: Locale = .current) -> String {
        switch daysAgo {
        case ...0: localized("Heute", locale: locale)
        case 1: localized("Gestern", locale: locale)
        case 2: localized("Vorgestern", locale: locale)
        default: localized("Vor \(daysAgo) Tagen", locale: locale)
        }
    }
}

/// Datumstexte im Kopfband von Heute (Spezifikation 5.2). Sprache und Format folgen `locale`, in der App der Sprache
/// der App.
enum DayText {
    private static func calendar(_ locale: Locale) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        return calendar
    }

    /// Die Symbole von `Calendar` beginnen am Sonntag, die Wochentage der App am Montag (1 = Montag bis 7 = Sonntag).
    private static func symbol(_ symbols: [String], _ weekday: Int) -> String {
        symbols[HabitEngine.calendarWeekday(weekday) - 1]
    }

    /// Kurzname eines Wochentags der App: "Mo", "Di" und so weiter.
    static func weekdayName(_ weekday: Int, locale: Locale = .current) -> String {
        symbol(calendar(locale).shortStandaloneWeekdaySymbols, weekday)
    }

    /// Anfangsbuchstabe eines Wochentags der App: "M", "D" und so weiter.
    static func weekdayInitial(_ weekday: Int, locale: Locale = .current) -> String {
        symbol(calendar(locale).veryShortStandaloneWeekdaySymbols, weekday)
    }

    /// Voller Name eines Wochentags der App: "Montag", "Dienstag" und so weiter.
    static func weekdayFullName(_ weekday: Int, locale: Locale = .current) -> String {
        symbol(calendar(locale).standaloneWeekdaySymbols, weekday)
    }

    /// Die 7 Wochentage der App ab dem Wochenbeginn (1 = Montag bis 7 = Sonntag).
    static func weekdays(startingAt firstWeekday: Int) -> [Int] {
        (0..<7).map { (firstWeekday - 1 + $0) % 7 + 1 }
    }

    /// Kurznamen der Wochentage ab dem Wochenbeginn.
    static func weekdayNames(startingAt firstWeekday: Int, locale: Locale = .current) -> [String] {
        weekdays(startingAt: firstWeekday).map { weekdayName($0, locale: locale) }
    }

    /// Datumszeile ohne Kalenderwoche: "So · 11. Okt" bzw. "Sun · Oct 11".
    static func dateLine(_ day: Date, engine: HabitEngine, locale: Locale = .current) -> String {
        "\(weekdayName(engine.weekday(of: day), locale: locale)) · \(shortDate(day, engine: engine, locale: locale))"
    }

    /// Tag und Monat: "11. Okt" bzw. "Oct 11".
    static func shortDate(_ day: Date, engine: HabitEngine, locale: Locale = .current) -> String {
        format(day, template: "dLLL", engine: engine, locale: locale)
    }

    /// Datum mit Jahr: "11. Okt 2026" bzw. "Oct 11, 2026".
    static func dateWithYear(_ day: Date, engine: HabitEngine, locale: Locale = .current) -> String {
        format(day, template: "dLLLy", engine: engine, locale: locale)
    }

    /// Formatiert nach einer Vorlage der Sprache. Der Punkt hinter dem Monatsnamen ("Okt.") entfällt.
    private static func format(_ day: Date, template: String, engine: HabitEngine, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = engine.calendar
        formatter.timeZone = engine.calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: day).replacingOccurrences(of: #"(?<=\p{L})\."#, with: "", options: .regularExpression)
    }

    /// Kalenderwoche: "KW 41" bzw. "W41".
    static func weekNumber(_ day: Date, engine: HabitEngine, firstWeekday: Int = 1, locale: Locale = .current) -> String {
        localized("KW \(engine.weekOfYear(day, firstWeekday: firstWeekday))", locale: locale)
    }

    /// Kalenderwoche für VoiceOver: "Kalenderwoche 41" bzw. "Week 41".
    static func weekNumberSpoken(_ day: Date, engine: HabitEngine, firstWeekday: Int = 1, locale: Locale = .current) -> String {
        localized("Kalenderwoche \(engine.weekOfYear(day, firstWeekday: firstWeekday))", locale: locale)
    }

    /// Vollständiges Datum für VoiceOver: "Sonntag, 11. Oktober" bzw. "Sunday, October 11".
    static func fullDate(_ day: Date, locale: Locale = .current) -> String {
        day.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(locale))
    }
}
