import Testing
@testable import Habitus

/// VoiceOver Namen in der Icon und Farbauswahl (Phase 7).
struct AccessibilityTextTests {
    @Test(arguments: HabitIcons.all)
    func everyIconHasAGermanName(icon: String) {
        let title = HabitIcons.title(for: icon)
        #expect(title != icon, "\(icon) hat einen eigenen Namen")
        #expect(!title.isEmpty)
    }

    @Test func iconNamesAreDistinct() {
        let titles = HabitIcons.all.map(HabitIcons.title(for:))
        #expect(Set(titles).count == titles.count)
    }

    @MainActor
    @Test func colorNamesAreDistinct() {
        let titles = HabitColor.allCases.map(\.title)
        #expect(Set(titles).count == HabitColor.allCases.count)
        #expect(HabitColor.teal.title == "Cyan")
    }
}
