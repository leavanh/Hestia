import Testing
import UIKit
@testable import Hestia

/// VoiceOver Namen in der Icon und Farbauswahl (Phase 7).
struct AccessibilityTextTests {
    @Test(arguments: HabitIcons.all)
    func everyIconHasAGermanName(icon: String) {
        let title = HabitIcons.title(for: icon)
        #expect(title != icon, "\(icon) hat einen eigenen Namen")
        #expect(!title.isEmpty)
    }

    /// Phase 14.1: 36 Symbole ohne Doppelte, jedes lässt sich laden.
    @Test func iconListHasThirtySixLoadableSymbols() {
        #expect(HabitIcons.all.count == 36)
        #expect(Set(HabitIcons.all).count == 36)
        for icon in HabitIcons.all {
            #expect(UIImage(systemName: icon) != nil, "\(icon) lässt sich laden")
        }
    }

    @Test func iconNamesAreDistinct() {
        let titles = HabitIcons.all.map { HabitIcons.title(for: $0) }
        #expect(Set(titles).count == titles.count)
    }

    @MainActor
    @Test func colorNamesAreDistinct() {
        let titles = HabitColor.allCases.map(\.title)
        #expect(Set(titles).count == HabitColor.allCases.count)
        #expect(HabitColor.teal.title == "Cyan")
    }
}
