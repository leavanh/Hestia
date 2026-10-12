import SwiftUI

/// Die drei Tabs der App (Spezifikation 5.1).
enum AppTab: String, CaseIterable, Identifiable {
    case today, calendar, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: localized("Heute")
        case .calendar: localized("Kalender")
        case .settings: localized("Einstellungen")
        }
    }

    var systemImage: String {
        switch self {
        case .today: "checkmark.circle"
        case .calendar: "calendar"
        case .settings: "gearshape"
        }
    }

    var identifier: String { "tab-\(rawValue)" }
}
