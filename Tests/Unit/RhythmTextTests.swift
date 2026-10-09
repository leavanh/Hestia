import Foundation
import Testing
@testable import Habitus

/// Rhythmus Zeile auf der `HabitCard` (Spezifikation 4.3.1).
struct RhythmTextTests {
    func snapshot(
        _ rhythm: Rhythm, target: Int = 1, weekdays: [Int] = [], monthDay: Int? = nil
    ) -> HabitSnapshot {
        HabitSnapshot(rhythm: rhythm, targetCount: target, weekdays: weekdays, monthDay: monthDay,
                      createdAt: Date(timeIntervalSince1970: 0), counts: [])
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
        #expect(habit.rhythmText(window: WindowProgress(done: 1, target: 3)) == "1 von 3 diese Woche")
        #expect(habit.rhythmText(window: WindowProgress(done: 0, target: 3)) == "0 von 3 diese Woche")
    }

    @Test func monthlyShowsDoneOfTargetThisMonth() {
        let habit = snapshot(.monthly)
        #expect(habit.rhythmText(window: WindowProgress(done: 1, target: 1)) == "1 von 1 diesen Monat")
    }

    @Test func weeklyFallsBackToZeroWithoutWindow() {
        #expect(snapshot(.weekly, target: 2).rhythmText(window: nil) == "0 von 2 diese Woche")
    }

    @Test func weekdaysListShortNamesInOrder() {
        #expect(snapshot(.weekdays, weekdays: [4, 1]).rhythmText(window: nil) == "Mo, Do")
        #expect(snapshot(.weekdays, weekdays: [7]).rhythmText(window: nil) == "So")
    }

    @Test func monthDayNamesTheDay() {
        #expect(snapshot(.monthDay, monthDay: 15).rhythmText(window: nil) == "Am 15. des Monats")
    }
}
