import SwiftUI
import Testing
import UIKit
@testable import Hestia

/// Habitfarben (Spezifikation 4.2): Tinte im hellen, Leuchtfarbe im dunklen Modus, Schlüssel und Kontrast.
struct HabitColorTests {
    private static let expected: [HabitColor: (ink: UInt32, glow: UInt32)] = [
        .blue: (0x0000F2, 0x7979F2), .violet: (0x5C00D6, 0xB079F2), .pink: (0xD1005F, 0xF279B5),
        .red: (0xD10000, 0xF27979), .orange: (0xB35500, 0xF2B579), .yellow: (0x806B00, 0xF2F279),
        .green: (0x00804C, 0x79F2B5), .teal: (0x007A80, 0x79F2F2),
    ]

    @Test(arguments: HabitColor.allCases)
    func everyColorResolvesToTheValuesFromTheSpecInLightAndDark(_ habitColor: HabitColor) throws {
        let expectedValues = try #require(Self.expected[habitColor])
        #expect(DesignColors.hex(habitColor.color, .light) == expectedValues.ink, "\(habitColor) hell")
        #expect(DesignColors.hex(habitColor.color, .dark) == expectedValues.glow, "\(habitColor) dunkel")
    }

    @Test func allEightKeysStayAndFollowTheColorWheel() {
        #expect(HabitColor.allCases.map(\.rawValue) == ["blue", "violet", "pink", "red", "orange", "yellow", "green", "teal"])
    }

    @Test func titlesAreTheNewNames() {
        #expect(HabitColor.allCases.map(\.title) == ["Blau", "Indigo", "Pink", "Rot", "Orange", "Ocker", "Grün", "Cyan"])
    }

    @Test(arguments: ["blue", "teal", "green", "yellow", "orange", "red", "pink", "violet"])
    func knownKeysGiveTheMatchingCase(_ key: String) {
        #expect(HabitColor(key: key).rawValue == key)
    }

    @Test func unknownKeyBecomesBlue() {
        #expect(HabitColor(key: "magenta") == .blue)
        #expect(HabitColor(key: "") == .blue)
    }

    @Test func onColorIsTheBackgroundAndTintIsFourteenPercent() {
        for habitColor in HabitColor.allCases {
            for style in [UIUserInterfaceStyle.light, .dark] {
                #expect(DesignColors.hex(habitColor.onColor, style) == DesignColors.hex(Theme.background, style))
                let tint = DesignColors.rgba(habitColor.tint, style)
                #expect(abs(tint.a - 0.14) < 0.001)
            }
        }
    }

    // MARK: Kontrast

    @Test(arguments: HabitColor.allCases)
    func inkOnPaperHasAtLeastFourPointFour(_ habitColor: HabitColor) {
        let ratio = DesignColors.contrast(habitColor.color, .light, against: Theme.background)
        #expect(ratio >= 4.4, "\(habitColor) \(ratio)")
    }

    @Test(arguments: HabitColor.allCases)
    func glowOnNightHasAtLeastFourPointFive(_ habitColor: HabitColor) {
        let ratio = DesignColors.contrast(habitColor.color, .dark, against: Theme.background)
        #expect(ratio >= 4.5, "\(habitColor) \(ratio)")
    }

    @Test(arguments: [UIUserInterfaceStyle.light, .dark])
    func secondaryInkHasAtLeastFourPointFiveOnBackground(_ style: UIUserInterfaceStyle) {
        #expect(DesignColors.contrast(Theme.inkSecondary, style, against: Theme.background) >= 4.5)
        #expect(DesignColors.contrast(Theme.ink, style, against: Theme.background) >= 4.5)
    }

    @Test(arguments: [UIUserInterfaceStyle.light, .dark])
    func statusColorsHaveAtLeastThreeOnBackground(_ style: UIUserInterfaceStyle) {
        #expect(DesignColors.contrast(Theme.statusYellow, style, against: Theme.background) >= 3)
        #expect(DesignColors.contrast(Theme.statusRed, style, against: Theme.background) >= 3)
    }

    @Test func onBandTextIsReadableOnTheBand() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            #expect(DesignColors.contrast(Theme.onBand, style, against: Theme.band) >= 4.5)
            #expect(DesignColors.contrast(Theme.onBandSecondary, style, against: Theme.band) >= 4.5)
        }
    }

    // MARK: Rollen

    @Test func rolesResolveToTheValuesFromTheSpec() {
        #expect(DesignColors.hex(Theme.background, .light) == 0xF2F2F2)
        #expect(DesignColors.hex(Theme.background, .dark) == 0x000030)
        #expect(DesignColors.hex(Theme.ink, .light) == 0x0000F2)
        #expect(DesignColors.hex(Theme.ink, .dark) == 0xF2F2F2)
        #expect(DesignColors.hex(Theme.band, .light) == 0x0000F2)
        #expect(DesignColors.hex(Theme.band, .dark) == 0x0000F2)
        #expect(DesignColors.hex(Theme.onBand, .dark) == 0xF2F2F2)
        #expect(DesignColors.hex(Theme.frame, .light) == 0x000091)
        #expect(abs(DesignColors.rgba(Theme.hairline, .light).a - 0.25) < 0.001)
        #expect(abs(DesignColors.rgba(Theme.hairline, .dark).a - 0.20) < 0.001)
    }
}

/// Hilfsfunktionen für Farbtests: Auflösen mit `UITraitCollection`, Hex Werte und die WCAG Kontrastformel.
enum DesignColors {
    static func rgba(_ color: Color, _ style: UIUserInterfaceStyle) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }

    static func hex(_ color: Color, _ style: UIUserInterfaceStyle) -> UInt32 {
        let c = rgba(color, style)
        func byte(_ value: CGFloat) -> UInt32 { UInt32((value * 255).rounded()) }
        return byte(c.r) << 16 | byte(c.g) << 8 | byte(c.b)
    }

    /// Relative Luminanz nach WCAG. Eine Farbe mit Deckkraft wird zuerst auf `base` gelegt.
    private static func luminance(_ color: Color, _ style: UIUserInterfaceStyle, over base: Color?) -> Double {
        var c = rgba(color, style)
        if let base, c.a < 1 {
            let b = rgba(base, style)
            c = (c.r * c.a + b.r * (1 - c.a), c.g * c.a + b.g * (1 - c.a), c.b * c.a + b.b * (1 - c.a), 1)
        }
        func linear(_ value: CGFloat) -> Double {
            let v = Double(value)
            return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b)
    }

    static func contrast(_ foreground: Color, _ style: UIUserInterfaceStyle, against background: Color) -> Double {
        let f = luminance(foreground, style, over: background)
        let b = luminance(background, style, over: nil)
        return (max(f, b) + 0.05) / (min(f, b) + 0.05)
    }
}
