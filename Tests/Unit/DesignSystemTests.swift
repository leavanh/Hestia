import Testing
import UIKit
@testable import Habitus

/// Schriften (Spezifikation 4.3) und das Modell der `SegmentBar` (4.5).
struct DesignSystemTests {
    @Test func registeredFontsExist() {
        FontRegistry.registerAll()
        #expect(FontRegistry.allFontNames.count == 6)
        for name in FontRegistry.allFontNames {
            #expect(UIFont(name: name, size: 14) != nil, "\(name)")
        }
    }

    @Test func fourOfSixPointsGiveSixSegmentsWithFourFull() {
        #expect(SegmentBarModel(done: 4, total: 6) == .segments(total: 6, done: 4))
    }

    @Test func fiveOfSixteenGiveOneContinuousBarAtThirtyOnePercent() {
        #expect(SegmentBarModel(done: 5, total: 16) == .continuous(percent: 31))
    }

    @Test func zeroPointsGiveNoBar() {
        #expect(SegmentBarModel(done: 0, total: 0) == .none)
    }

    @Test func twelvePointsStillGetSegmentsAndThirteenDoNot() {
        #expect(SegmentBarModel(done: 3, total: 12) == .segments(total: 12, done: 3))
        #expect(SegmentBarModel(done: 13, total: 13) == .continuous(percent: 100))
    }
}
