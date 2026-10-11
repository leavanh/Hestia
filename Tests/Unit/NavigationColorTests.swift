import Testing
import UIKit
@testable import Hestia

/// Die Farben für die Navigationsleiste (Spezifikation 8.1) lösen sich erst beim Zeichnen auf und folgen dem Modus.
struct NavigationColorTests {
    private let light = UITraitCollection(userInterfaceStyle: .light)
    private let dark = UITraitCollection(userInterfaceStyle: .dark)

    @Test func backgroundIsPaperInLightAndNightInDark() {
        #expect(Theme.backgroundUIColor.resolvedColor(with: light) == UIColor(hex: 0xF2F2F2))
        #expect(Theme.backgroundUIColor.resolvedColor(with: dark) == UIColor(hex: 0x000030))
    }

    @Test func inkIsBrandInLightAndPaperInDark() {
        #expect(Theme.inkUIColor.resolvedColor(with: light) == UIColor(hex: 0x0000F2))
        #expect(Theme.inkUIColor.resolvedColor(with: dark) == UIColor(hex: 0xF2F2F2))
    }
}
