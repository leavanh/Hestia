import SwiftUI
import Testing
import UIKit
@testable import Habitus

/// Gedämpfte Icon Farben (Spezifikation 4.2).
struct HabitColorTests {
    private func rgba(_ color: Color, _ style: UIUserInterfaceStyle) -> [CGFloat] {
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b, a]
    }

    @Test(arguments: HabitColor.allCases)
    func everyColorHasAMutedVariantInLightAndDark(_ habitColor: HabitColor) {
        for style in [UIUserInterfaceStyle.light, .dark] {
            #expect(rgba(habitColor.mutedColor, style) != rgba(habitColor.color, style), "\(habitColor) \(style)")
        }
    }

    @Test func mutedVariantsStayDistinguishable() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let all = HabitColor.allCases.map { rgba($0.mutedColor, style) }
            #expect(Set(all.map { $0.map { ($0 * 100).rounded() } }).count == HabitColor.allCases.count)
        }
    }
}
