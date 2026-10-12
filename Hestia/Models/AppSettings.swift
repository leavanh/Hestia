import SwiftUI

/// Schlüssel der Einstellungen in UserDefaults (Spezifikation 6).
enum SettingsKey {
    static let appearance = "HestiaAppearance"
    static let firstWeekday = "HestiaFirstWeekday"
    static let periods = "HestiaPeriods"
}

extension Periods {
    var title: String {
        switch self {
        case .rolling: localized("Rollierend")
        case .calendar: localized("Kalender")
        }
    }

    /// Erklärzeile unter der Auswahl (Spezifikation 5.5).
    var explanation: String {
        switch self {
        case .rolling: localized("Die letzten 7 bzw. 30 Tage")
        case .calendar: localized("Die laufende Woche bzw. der laufende Monat")
        }
    }
}

/// Darstellung der App (Spezifikation 5.5). Gespeichert wird `rawValue`.
enum AppearanceSetting: String, CaseIterable {
    case system
    case light
    case dark

    var title: String {
        switch self {
        case .system: localized("System")
        case .light: localized("Hell")
        case .dark: localized("Dunkel")
        }
    }

    /// Farbschema für `.preferredColorScheme`. `nil` heißt: dem System folgen.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Wochenbeginn (Spezifikation 5.5). Gespeichert wird `rawValue`.
enum FirstWeekdaySetting: String, CaseIterable {
    case automatic
    case monday
    case sunday

    var title: String {
        switch self {
        case .automatic: localized("Automatisch")
        case .monday: localized("Montag")
        case .sunday: localized("Sonntag")
        }
    }

    /// Wochenbeginn als Wochentag der App (1 = Montag bis 7 = Sonntag). "Automatisch" folgt dem ersten Wochentag der
    /// Region bzw. der Einstellung in iOS.
    func start(locale: Locale = .current) -> Int {
        switch self {
        case .monday:
            return 1
        case .sunday:
            return 7
        case .automatic:
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = locale
            // `Calendar` zählt 1 = Sonntag bis 7 = Samstag, die App 1 = Montag bis 7 = Sonntag.
            return (calendar.firstWeekday + 5) % 7 + 1
        }
    }
}

private struct FirstWeekdayKey: EnvironmentKey {
    static let defaultValue = 1
}

extension EnvironmentValues {
    /// Wochenbeginn als Wochentag der App (1 = Montag bis 7 = Sonntag), gesetzt an der Wurzel der App.
    var firstWeekday: Int {
        get { self[FirstWeekdayKey.self] }
        set { self[FirstWeekdayKey.self] = newValue }
    }
}

private struct HabitEngineKey: EnvironmentKey {
    static let defaultValue = HabitEngine()
}

extension EnvironmentValues {
    /// Die `HabitEngine` mit den aktuellen Einstellungen (Zeiträume, Wochenbeginn), gesetzt an der Wurzel der App.
    /// Ändert sich eine Einstellung, rechnen die Ansichten damit neu (Spezifikation 6).
    var habitEngine: HabitEngine {
        get { self[HabitEngineKey.self] }
        set { self[HabitEngineKey.self] = newValue }
    }
}

/// Setzt Darstellung, Wochenbeginn und die `HabitEngine` aus den Einstellungen für die ganze App samt Sheets.
struct AppSettingsModifier: ViewModifier {
    @AppStorage(SettingsKey.appearance) private var appearance = AppearanceSetting.system
    @AppStorage(SettingsKey.firstWeekday) private var firstWeekday = FirstWeekdaySetting.automatic
    @AppStorage(SettingsKey.periods) private var periods = Periods.rolling

    func body(content: Content) -> some View {
        content
            .environment(\.firstWeekday, firstWeekday.start())
            .environment(\.habitEngine, HabitEngine(periods: periods, firstWeekday: firstWeekday.start()))
            .preferredColorScheme(appearance.colorScheme)
    }
}
