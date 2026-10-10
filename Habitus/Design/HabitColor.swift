import SwiftUI
import UIKit

/// Feste Palette mit 8 Habitfarben. Gespeichert wird der `rawValue` in `Habit.colorKey`.
enum HabitColor: String, CaseIterable, Identifiable {
    case blue, teal, green, yellow, orange, red, pink, violet

    var id: String { rawValue }

    init(key: String) {
        self = HabitColor(rawValue: key) ?? .blue
    }

    var color: Color { Color(uiColor: uiColor) }

    /// Gedämpfte Variante für Symbol und Kreisfläche von `HabitIconView`: weniger Sättigung, in Hell etwas
    /// dunkler, in Dunkel etwas heller, damit sie auf dem Verlauf lesbar bleibt. Der Farbton bleibt erhalten.
    var mutedColor: Color {
        Color(uiColor: Self.muted(uiColor))
    }

    var uiColor: UIColor {
        switch self {
        case .blue: .systemBlue
        case .teal: .systemTeal
        case .green: .systemGreen
        case .yellow: .systemYellow
        case .orange: .systemOrange
        case .red: .systemRed
        case .pink: .systemPink
        case .violet: .systemPurple
        }
    }

    private static let mutedSaturation: CGFloat = 0.6
    private static let mutedBrightnessLight: CGFloat = 0.9
    private static let mutedBrightnessDark: CGFloat = 0.95

    private static func muted(_ base: UIColor) -> UIColor {
        UIColor { traits in
            var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
            base.resolvedColor(with: traits).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            let isDark = traits.userInterfaceStyle == .dark
            return UIColor(
                hue: hue,
                saturation: saturation * mutedSaturation,
                brightness: brightness * (isDark ? mutedBrightnessDark : mutedBrightnessLight),
                alpha: alpha
            )
        }
    }
}
