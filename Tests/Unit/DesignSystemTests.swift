import Testing
import UIKit
@testable import Habitus

/// Schriften (Spezifikation 4.3) und das Modell der `SegmentBar` (4.5, ab Phase 9.1 immer ein durchgehender Balken).
struct DesignSystemTests {
    @Test func registeredFontsExist() {
        FontRegistry.registerAll()
        #expect(FontRegistry.allFontNames.count == 6)
        for name in FontRegistry.allFontNames {
            #expect(UIFont(name: name, size: 14) != nil, "\(name)")
        }
    }

    @Test func fourOfSixPointsGiveOneContinuousBarAtSixtySevenPercent() {
        #expect(SegmentBarModel(done: 4, total: 6) == .continuous(percent: 67))
    }

    @Test func fiveOfSixteenGiveOneContinuousBarAtThirtyOnePercent() {
        #expect(SegmentBarModel(done: 5, total: 16) == .continuous(percent: 31))
    }

    @Test func zeroPointsGiveNoBar() {
        #expect(SegmentBarModel(done: 0, total: 0) == .none)
    }

    @Test func fewPointsAreContinuousToo() {
        #expect(SegmentBarModel(done: 3, total: 12) == .continuous(percent: 25))
        #expect(SegmentBarModel(done: 13, total: 13) == .continuous(percent: 100))
    }
}
