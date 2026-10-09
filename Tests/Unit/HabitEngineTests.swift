import Foundation
import Testing
@testable import Habitus

struct HabitEngineTests {
    let engine: HabitEngine = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return HabitEngine(calendar: calendar)
    }()

    func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        engine.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    @Test func startOfDayIsMidnight() {
        let start = engine.startOfDay(date(2026, 10, 8, 23, 59))
        #expect(start == date(2026, 10, 8, 0, 0))
    }

    @Test func countForDayWithEntry() {
        let counts = [DayCount(day: date(2026, 10, 8, 0), count: 1)]
        #expect(engine.count(on: date(2026, 10, 8, 18), in: counts) == 1)
    }

    @Test func countIsZeroWithoutEntry() {
        #expect(engine.count(on: date(2026, 10, 8), in: []) == 0)
    }

    @Test func nextDayStartsEmpty() {
        let counts = [DayCount(day: date(2026, 10, 8, 0), count: 1)]
        #expect(engine.count(on: date(2026, 10, 8, 23, 59), in: counts) == 1)
        #expect(engine.count(on: date(2026, 10, 9, 0, 0), in: counts) == 0)
    }

    @Test func toggleChecksAndUnchecks() {
        #expect(engine.toggledCount(0) == 1)
        #expect(engine.toggledCount(1) == 0)
    }

    // MARK: Hilfen

    func daily(
        target: Int = 1,
        created: Date? = nil,
        _ counts: [(Date, Int)] = []
    ) -> HabitSnapshot {
        HabitSnapshot(
            rhythm: .daily,
            targetCount: target,
            createdAt: created ?? date(2026, 1, 1),
            counts: counts.map { DayCount(day: engine.startOfDay($0.0), count: $0.1) }
        )
    }

    var day: Date { date(2026, 10, 8, 14) }

    // MARK: Counter (Spezifikation 3.3)

    @Test func counterIsUsedOnlyForDailyAboveOne() {
        #expect(engine.usesCounter(daily(target: 3)))
        #expect(!engine.usesCounter(daily(target: 1)))
        var weekly = daily(target: 3)
        weekly.rhythm = .weekly
        #expect(!engine.usesCounter(weekly))
    }

    @Test func plusStopsAtTarget() {
        #expect(engine.incrementedCount(0, target: 3) == 1)
        #expect(engine.incrementedCount(2, target: 3) == 3)
        #expect(engine.incrementedCount(3, target: 3) == 3)
    }

    @Test func minusStopsAtZero() {
        #expect(engine.decrementedCount(3) == 2)
        #expect(engine.decrementedCount(1) == 0)
        #expect(engine.decrementedCount(0) == 0)
    }

    // MARK: Punkte (Spezifikation 3.4)

    @Test func pointsEqualDailyTarget() {
        #expect(engine.points(daily(target: 1), on: day) == 1)
        #expect(engine.points(daily(target: 3), on: day) == 3)
        #expect(engine.points(daily(target: 10), on: day) == 10)
    }

    @Test func donePointsAreTodaysValue() {
        let habit = daily(target: 3, [(day, 2)])
        #expect(engine.donePoints(habit, on: day) == 2)
    }

    @Test func donePointsAreZeroWithoutEntry() {
        #expect(engine.donePoints(daily(target: 3), on: day) == 0)
    }

    @Test func donePointsOnlyCountTheGivenDay() {
        let habit = daily(target: 3, [(date(2026, 10, 7), 3)])
        #expect(engine.donePoints(habit, on: day) == 0)
    }

    @Test func donePointsAreCappedAtTarget() {
        // z.B. nachdem das Ziel von 5 auf 2 gesenkt wurde
        let habit = daily(target: 2, [(day, 5)])
        #expect(engine.donePoints(habit, on: day) == 2)
    }

    // MARK: Tagesfortschritt (Spezifikation 3.4)

    @Test func progressOfOnceAndThreeTimesDailyWithTwoCompletions() {
        // Definition of Done Phase 2: "2 von 4 · 50 %"
        let once = daily(target: 1, [(day, 1)])
        let thrice = daily(target: 3, [(day, 1)])
        let progress = engine.dayProgress([once, thrice], on: day)
        #expect(progress == DayProgress(done: 2, total: 4))
        #expect(progress.percent == 50)
    }

    @Test func progressRoundsToWholePercent() {
        #expect(DayProgress(done: 5, total: 16).percent == 31) // 31,25
        #expect(DayProgress(done: 1, total: 3).percent == 33)
        #expect(DayProgress(done: 2, total: 3).percent == 67)
        #expect(DayProgress(done: 16, total: 16).percent == 100)
        #expect(DayProgress(done: 0, total: 4).percent == 0)
    }

    @Test func progressWithoutHabitsHasNoPoints() {
        let progress = engine.dayProgress([], on: day)
        #expect(progress.total == 0)
        #expect(progress.percent == 0)
        #expect(progress.fraction == 0)
    }

    @Test func progressFractionForRing() {
        #expect(DayProgress(done: 1, total: 4).fraction == 0.25)
    }

    @Test func progressCapsEachHabitAtItsTarget() {
        let habit = daily(target: 2, [(day, 9)])
        #expect(engine.dayProgress([habit], on: day) == DayProgress(done: 2, total: 2))
    }

    @Test func progressStartsEmptyOnTheNextDay() {
        let habit = daily(target: 3, [(day, 3)])
        let tomorrow = date(2026, 10, 9, 8)
        #expect(engine.dayProgress([habit], on: tomorrow) == DayProgress(done: 0, total: 3))
    }

    // MARK: 7 Tage Punkte (Spezifikation 3.6)

    @Test func weekDotsAreSevenOldestFirst() {
        let habit = daily(target: 1, [
            (date(2026, 10, 2), 1), // vor 6 Tagen: links
            (date(2026, 10, 8), 1), // heute: rechts
        ])
        let dots = engine.weekDots(habit, on: day)
        #expect(dots.count == 7)
        #expect(dots.first == .fill(1))
        #expect(dots.last == .fill(1))
        #expect(dots[1...5].allSatisfy { $0 == .fill(0) })
    }

    @Test func weekDotsAreEmptyOutlineWithoutValue() {
        let dots = engine.weekDots(daily(target: 3), on: day)
        #expect(dots == Array(repeating: .fill(0), count: 7))
    }

    @Test func weekDotsFillByValueOverDailyTarget() {
        let habit = daily(target: 3, [
            (date(2026, 10, 6), 1),
            (date(2026, 10, 7), 2),
            (date(2026, 10, 8), 3),
        ])
        let dots = engine.weekDots(habit, on: day)
        #expect(dots[4] == .fill(1.0 / 3.0))
        #expect(dots[5] == .fill(2.0 / 3.0))
        #expect(dots[6] == .fill(1))
    }

    @Test func weekDotsNeverExceedFull() {
        let habit = daily(target: 2, [(day, 7)])
        #expect(engine.weekDots(habit, on: day).last == .fill(1))
    }

    @Test func weekDotsBeforeCreationAreEmptyOutlines() {
        // Erstellt vor 2 Tagen (6. Oktober): die 4 Tage davor haben Füllung 0, es bleiben 7 Punkte.
        let habit = daily(target: 1, created: date(2026, 10, 6, 17), [(date(2026, 10, 6), 1)])
        let dots = engine.weekDots(habit, on: day)
        #expect(dots.count == 7)
        #expect(dots[0...3].allSatisfy { $0 == .fill(0) })
        #expect(dots[4] == .fill(1))
        #expect(dots[5] == .fill(0))
        #expect(dots[6] == .fill(0))
    }

    @Test func weekDotsOfHabitCreatedTodayShowSixEmptyDaysBefore() {
        let habit = daily(target: 1, created: date(2026, 10, 8, 9))
        let dots = engine.weekDots(habit, on: day)
        #expect(dots.count == 7)
        #expect(dots[0...5].allSatisfy { $0 == .fill(0) })
        #expect(dots[6] == .fill(0))

        let checked = daily(target: 1, created: date(2026, 10, 8, 9), [(day, 1)])
        #expect(engine.weekDots(checked, on: day) == Array(repeating: .fill(0), count: 6) + [.fill(1)])
    }

    @Test func weekDotsShiftWithTheDay() {
        let habit = daily(target: 1, [(date(2026, 10, 8), 1)])
        let tomorrow = engine.weekDots(habit, on: date(2026, 10, 9))
        #expect(tomorrow[5] == .fill(1))
        #expect(tomorrow[6] == .fill(0))
    }
}
