import SwiftUI
import UIKit

/// Navigationstitel in den Schriften des Designsystems (Spezifikation 4.3): klein in Rolle `label`. Große Titel
/// stehen als `ScreenTitle` in Rolle `display` im Inhalt, weil UIKit sie mit dieser Schrift nicht darstellt.
/// Die Leisten haben keinen eigenen Hintergrund, sondern stehen auf `background`.
enum NavigationAppearance {
    static func apply() {
        FontRegistry.registerAll()

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.background)
        appearance.shadowColor = nil

        let ink = UIColor(Theme.ink)
        appearance.titleTextAttributes = [
            .font: scaled(FontRegistry.barlowMedium, size: 14, style: .subheadline),
            .foregroundColor: ink,
            .kern: 1.4,
        ]

        let bar = UINavigationBar.appearance()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
        bar.compactScrollEdgeAppearance = appearance
        bar.tintColor = ink
    }

    private static func scaled(_ name: String, size: CGFloat, style: UIFont.TextStyle) -> UIFont {
        let font = UIFont(name: name, size: size) ?? .systemFont(ofSize: size)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: font)
    }
}
