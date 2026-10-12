import SwiftUI
import UIKit

/// Feste Palette mit 8 Habitfarben (Spezifikation 4.2). Gespeichert wird der `rawValue` in `Habit.colorKey`.
/// Im hellen Modus ist jede Farbe eine dunkle Tinte auf Papier, im dunklen eine helle Leuchtfarbe auf Nachtblau.
/// Die Reihenfolge folgt dem Farbkreis.
enum HabitColor: String, CaseIterable, Identifiable {
    case blue, violet, pink, red, orange, yellow, green, teal

    var id: String { rawValue }

    init(key: String) {
        self = HabitColor(rawValue: key) ?? .blue
    }

    /// Tinte bzw. Leuchtfarbe, je nach Modus.
    var color: Color { Color(uiColor: uiColor) }

    /// `color` mit 14 % Deckkraft, für die Fläche von `HabitIconView`.
    var tint: Color { color.opacity(Theme.fillOpacity) }

    /// Vordergrund auf voller Habitfarbe (Häkchen, Text im Band des Details).
    var onColor: Color { Theme.background }

    /// Name für VoiceOver in der Farbauswahl.
    var title: String {
        switch self {
        case .blue: localized("Blau")
        case .violet: localized("Indigo")
        case .pink: localized("Pink")
        case .red: localized("Rot")
        case .orange: localized("Orange")
        case .yellow: localized("Ocker")
        case .green: localized("Grün")
        case .teal: localized("Cyan")
        }
    }

    var uiColor: UIColor {
        Theme.dynamicUIColor(light: hex.ink, dark: hex.glow)
    }

    /// Hex Werte (`0xRRGGBB`) der Tinte (hell) und der Leuchtfarbe (dunkel).
    var hex: (ink: UInt32, glow: UInt32) {
        switch self {
        case .blue: (0x0000F2, 0x7979F2)
        case .violet: (0x5C00D6, 0xB079F2)
        case .pink: (0xD1005F, 0xF279B5)
        case .red: (0xD10000, 0xF27979)
        case .orange: (0xB35500, 0xF2B579)
        case .yellow: (0x806B00, 0xF2F279)
        case .green: (0x00804C, 0x79F2B5)
        case .teal: (0x007A80, 0x79F2F2)
        }
    }
}
