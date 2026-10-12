import Foundation
import Testing
@testable import Hestia

/// Rhythmus Zeile auf der `HabitCard` (Spezifikation 4.3.1).
struct RhythmTextTests {
    func snapshot(
        _ rhythm: Rhythm, target: Int = 1, weekdays: [Int] = [], monthDay: Int? = nil, detail: String = ""
    ) -> HabitSnapshot {
        HabitSnapshot(rhythm: rhythm, targetCount: target, weekdays: weekdays, monthDay: monthDay,
                      createdAt: Date(timeIntervalSince1970: 0), counts: [], detail: detail)
    }

    @Test func dailyOnceSaysDaily() {
        #expect(snapshot(.daily).rhythmText(window: nil) == "Täglich")
    }

    @Test func dailyManyTimesSaysPerDay() {
        #expect(snapshot(.daily, target: 2).rhythmText(window: nil) == "2 pro Tag")
        #expect(snapshot(.daily, target: 10).rhythmText(window: nil) == "10 pro Tag")
    }

    @Test func weeklyShowsDoneOfTargetThisWeek() {
        let habit = snapshot(.weekly, target: 3)
        #expect(habit.rhythmText(window: WindowProgress(done: 1, target: 3), periods: .calendar) == "1 von 3 diese Woche")
        #expect(habit.rhythmText(window: WindowProgress(done: 0, target: 3), periods: .calendar) == "0 von 3 diese Woche")
    }

    @Test func monthlyShowsDoneOfTargetThisMonth() {
        let habit = snapshot(.monthly)
        #expect(habit.rhythmText(window: WindowProgress(done: 1, target: 1), periods: .calendar) == "1 von 1 diesen Monat")
    }

    // MARK: Zeiträume (Phase 15)

    @Test func rollingPeriodsSayInSevenOrThirtyDays() {
        let window = WindowProgress(done: 1, target: 3)
        #expect(snapshot(.weekly, target: 3).rhythmText(window: window, periods: .rolling) == "1 von 3 in 7 Tagen")
        #expect(snapshot(.weekly, target: 3).rhythmText(window: window, periods: .calendar) == "1 von 3 diese Woche")
        #expect(snapshot(.monthly, target: 3).rhythmText(window: window, periods: .rolling) == "1 von 3 in 30 Tagen")
        #expect(snapshot(.monthly, target: 3).rhythmText(window: window, periods: .calendar) == "1 von 3 diesen Monat")
    }

    @Test func rollingIsTheDefault() {
        let window = WindowProgress(done: 1, target: 3)
        #expect(snapshot(.weekly, target: 3).rhythmText(window: window) == "1 von 3 in 7 Tagen")
    }

    @Test func weeklyFallsBackToZeroWithoutWindow() {
        #expect(snapshot(.weekly, target: 2).rhythmText(window: nil, periods: .calendar) == "0 von 2 diese Woche")
    }

    @Test func weekdaysListShortNamesInOrder() {
        #expect(snapshot(.weekdays, weekdays: [4, 1]).rhythmText(window: nil) == "Mo · Do")
        #expect(snapshot(.weekdays, weekdays: [7]).rhythmText(window: nil) == "So")
    }

    @Test func monthDayNamesTheDay() {
        #expect(snapshot(.monthDay, monthDay: 15).rhythmText(window: nil) == "Am 15. des Monats")
    }

    // MARK: Zusatz (Phase 10, ab Phase 18.4 hinten)

    @Test func detailStandsBehindTheFrequency() {
        #expect(snapshot(.daily, detail: "20 Min").rhythmText(window: nil) == "Täglich · 20 Min")
        #expect(snapshot(.weekdays, weekdays: [1, 4], detail: "Yoga").rhythmText(window: nil) == "Mo · Do · Yoga")
    }

    @Test func frequencyTextLeavesOutTheDetail() {
        #expect(snapshot(.daily, detail: "20 Min").frequencyText(window: nil) == "Täglich")
    }

    @Test func blankDetailIsNotShown() {
        #expect(snapshot(.daily, detail: "   ").rhythmText(window: nil) == "Täglich")
    }

    @Test func detailIsTrimmedAndLimitedTo24Characters() {
        #expect(HabitDetail.normalized("  20 Min  ") == "20 Min")
        #expect(HabitDetail.normalized(String(repeating: "a", count: 40)).count == 24)
        let habit = Habit(name: "Lesen", iconName: "book.fill", colorKey: "blue", detail: "  " + String(repeating: "b", count: 30))
        #expect(habit.detail == String(repeating: "b", count: 24))
    }

    @Test func habitWithoutDetailKeepsTheOldLine() {
        let habit = Habit(name: "Lesen", iconName: "book.fill", colorKey: "blue")
        #expect(habit.detail == "")
        #expect(habit.snapshot.rhythmText(window: nil) == "Täglich")
    }
}
