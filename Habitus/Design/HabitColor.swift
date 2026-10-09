import SwiftUI

/// Feste Palette mit 8 Habitfarben. Gespeichert wird der `rawValue` in `Habit.colorKey`.
enum HabitColor: String, CaseIterable, Identifiable {
    case blue, teal, green, yellow, orange, red, pink, violet

    var id: String { rawValue }

    init(key: String) {
        self = HabitColor(rawValue: key) ?? .blue
    }

    var color: Color {
        switch self {
        case .blue: Color(uiColor: .systemBlue)
        case .teal: Color(uiColor: .systemTeal)
        case .green: Color(uiColor: .systemGreen)
        case .yellow: Color(uiColor: .systemYellow)
        case .orange: Color(uiColor: .systemOrange)
        case .red: Color(uiColor: .systemRed)
        case .pink: Color(uiColor: .systemPink)
        case .violet: Color(uiColor: .systemPurple)
        }
    }
}
