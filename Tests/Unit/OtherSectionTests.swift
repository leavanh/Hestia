import Foundation
import Testing
@testable import Hestia

/// Hauptliste und Weitere (Spezifikation 3.2 und 3.4) in der Woche vom Mo 12.10. bis So 18.10.2026, rollierend.
struct OtherSectionTests {
    let engine: HabitEngine = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return HabitEngine(calendar: calendar)
    }()

    /// Tag im Oktober 2026.
    func day(_ day: Int) -> Date {
        engine.calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: 12))!
    }

    func make(
        _ rhythm: Rhythm, target: Int = 1, weekdays: [Int] = [], done: [Int] = [], pauses: [PauseRange] = []
    ) -> HabitSnapshot {
        HabitSnapshot(
            rhythm: rhythm, targetCount: target, weekdays: weekdays,
            createdAt: engine.calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!,
            counts: done.map { DayCount(day: engine.startOfDay(day($0)), count: 1) },
            pauses: pauses
        )
    }

    @Test func fixedWeekdaysAreOtherOnDaysTheyAreNotDue() {
        let habit = make(.weekdays, weekdays: [1, 4]) // Montag und Donnerstag
        #expect(engine.section(habit, on: day(14)) == .other)
        #expect(engine.section(habit, on: day(15)) == .main)
        #expect(engine.section(habit, on: day(12)) == .main)
    }

    @Test func dailyIsAlwaysMain() {
        #expect(engine.section(make(.daily), on: day(14)) == .main)
    }

    @Test func weeklyDoneOnMondayMovesToOtherFromTuesdayAndStaysThereWhenCheckedAgain() {
        let habit = make(.weekly, done: [12])
        #expect(engine.section(habit, on: day(12)) == .main, "Am Tag des Abhakens bleibt er in der Hauptliste")
        #expect(engine.section(habit, on: day(13)) == .other)

        let checkedTwice = make(.weekly, done: [12, 13])
        #expect(engine.section(checkedTwice, on: day(13)) == .other)
        #expect(
            engine.dayProgress([habit], on: day(13)) == engine.dayProgress([checkedTwice], on: day(13)),
            "Der Tagesfortschritt ändert sich nicht"
        )
        #expect(engine.dayProgress([checkedTwice], on: day(13)) == DayProgress(done: 0, total: 0))
    }

    @Test func weeklyTurnsBackToMainWhenItTurnsYellow() {
        let habit = make(.weekly, done: [12])
        #expect(engine.status(habit, on: day(16)) == .green)
        #expect(engine.section(habit, on: day(16)) == .other)
        #expect(engine.status(habit, on: day(17)) == .yellow)
        #expect(engine.section(habit, on: day(17)) == .main)
    }

    @Test func weeklyWithTwoTargetsAndOneDoneIsMain() {
        #expect(engine.section(make(.weekly, target: 2, done: [12]), on: day(13)) == .main)
    }

    @Test func notFulfilledMonthlyIsMainAndFulfilledIsOther() {
        #expect(engine.section(make(.monthly), on: day(14)) == .main)
        #expect(engine.section(make(.monthly, done: [5]), on: day(14)) == .other)
    }

    @Test func pausedHabitIsOtherAndDoesNotCount() {
        let pause = PauseRange(start: engine.startOfDay(day(12)), end: engine.startOfDay(day(14)))
        let paused = make(.daily, pauses: [pause])
        #expect(engine.section(paused, on: day(13)) == .other)
        #expect(engine.dayProgress([paused], on: day(13)) == DayProgress(done: 0, total: 0))
        #expect(engine.section(paused, on: day(15)) == .main)
    }

    @Test func endedAndNotYetCreatedHabitsAreNowhere() {
        var ended = make(.daily)
        ended.endedAt = engine.startOfDay(day(13))
        #expect(engine.section(ended, on: day(13)) == nil)
        #expect(engine.section(ended, on: day(12)) == .main)

        var fresh = make(.daily)
        fresh.createdAt = day(14)
        #expect(engine.section(fresh, on: day(13)) == nil)
    }

    @Test func threeDailyHabitsAndAnOtherWeeklyGiveThreePoints() {
        let habits = [make(.daily), make(.daily), make(.daily), make(.weekly, done: [12])]
        #expect(engine.section(habits[3], on: day(13)) == .other)
        #expect(engine.dayProgress(habits, on: day(13)) == DayProgress(done: 0, total: 3))
    }
}
