import Foundation
import Testing
@testable import Hestia

/// Feste Zeiträume (Kalenderwoche, Kalendermonat) in Status, Fortschritt, Streaks, Weitere und Rhythmus Zeile
/// (Spezifikation 3.5, 3.7, Phase 15). Wochenbeginn Montag, falls nicht anders genannt.
struct CalendarPeriodTests {
    static func makeEngine(periods: Periods = .calendar, firstWeekday: Int = 1) -> HabitEngine {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return HabitEngine(calendar: calendar, periods: periods, firstWeekday: firstWeekday)
    }

    let engine: HabitEngine

    init() {
        engine = Self.makeEngine()
    }

    func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        engine.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    /// Oktober 2026: Mo 12.10. bis So 18.10. ist die Testwoche.
    func october(_ day: Int) -> Date { date(2026, 10, day) }

    func make(
        _ rhythm: Rhythm = .weekly,
        target: Int = 3,
        created: Date? = nil,
        done: [Date] = [],
        pauses: [(Date, Date)] = [],
        ended: Date? = nil
    ) -> HabitSnapshot {
        HabitSnapshot(
            rhythm: rhythm,
            targetCount: target,
            createdAt: created ?? date(2026, 1, 1),
            counts: done.map { DayCount(day: engine.startOfDay($0), count: 1) },
            pauses: pauses.map { PauseRange(start: engine.startOfDay($0.0), end: engine.startOfDay($0.1)) },
            endedAt: ended
        )
    }

    // MARK: Ampel

    @Test func weeklyTrafficLightCountsTheDaysThatAreLeft() {
        let habit = make()
        #expect(engine.status(habit, on: october(14)) == .green) // noch 5 Tage möglich, 3 nötig
        #expect(engine.status(habit, on: october(16)) == .yellow) // 3 und 3
        #expect(engine.status(habit, on: october(17)) == .red) // 2 und 3
        let oneDone = make(done: [october(12)])
        #expect(engine.status(oneDone, on: october(17)) == .yellow) // 2 und 2
    }

    @Test func aNewWeekStartsWithoutOldBurden() {
        let habit = make()
        #expect(engine.status(habit, on: october(18)) == .red)
        #expect(engine.status(habit, on: october(19)) == .green)
    }

    @Test func reachedGoalStaysGreenForTheRestOfThePeriod() {
        let habit = make(done: [october(12), october(13), october(14)])
        for day in 14...18 { #expect(engine.status(habit, on: october(day)) == .green) }
    }

    @Test func monthlyGoalTurnsYellowOnTheLastDayAndGreenInTheNewMonth() {
        let habit = make(.monthly, target: 1, created: date(2026, 1, 1))
        #expect(engine.status(habit, on: october(30)) == .green)
        #expect(engine.status(habit, on: october(31)) == .yellow)
        #expect(engine.status(habit, on: date(2026, 11, 1)) == .green)
    }

    @Test func monthlyTargetIsCappedAtTheDaysOfTheMonth() {
        let habit = make(.monthly, target: 30)
        let period = engine.period(for: habit, on: date(2027, 2, 10))!
        #expect(period.dayCount == 28)
        #expect(engine.periodTarget(habit, period: period) == 28)
        #expect(engine.windowProgress(habit, on: date(2027, 2, 10))?.target == 28)
    }

    // MARK: Fortschritt

    @Test func donePointsStayOneUntilTheEndOfThePeriod() {
        // Drei Erledigungen bis Di 13.10. in einer Woche, die mit Mo 12.10. beginnt, geht nur mit Zähler 3 an
        // einem Tag nicht (Wert pro Tag höchstens 1): deshalb Ziel 2 an Mo und Di.
        let habit = make(target: 2, done: [october(12), october(13)])
        for day in 13...18 { #expect(engine.donePoints(habit, on: october(day)) == 1) }
        #expect(engine.donePoints(habit, on: october(19)) == 0)
    }

    @Test func aCompletionOnTheSundayBeforeDoesNotCountForTheNewWeek() {
        let habit = make(target: 1, done: [october(11)])
        #expect(engine.donePoints(habit, on: october(14)) == 0)
    }

    // MARK: Wochenbeginn

    @Test func aCompletionOnSundayBelongsToTheWeekAccordingToTheFirstWeekday() {
        let onSunday = make(done: [october(18)])
        let monday = Self.makeEngine(firstWeekday: 1)
        let sunday = Self.makeEngine(firstWeekday: 7)
        #expect(monday.period(for: onSunday, on: october(18))?.start == monday.startOfDay(october(12)))
        #expect(sunday.period(for: onSunday, on: october(18))?.start == sunday.startOfDay(october(18)))
        #expect(sunday.period(for: onSunday, on: october(18))?.end == sunday.startOfDay(october(24)))
        #expect(monday.windowProgress(onSunday, on: october(18))?.done == 1)
        #expect(sunday.windowProgress(onSunday, on: october(19))?.done == 1)
        #expect(monday.windowProgress(onSunday, on: october(19))?.done == 0)
    }

    // MARK: Pausen und angebrochene Zeiträume

    @Test func aPausedWeekIsNeverRed() {
        let habit = make(done: [october(12)], pauses: [(october(14), october(15))])
        #expect(engine.status(habit, on: october(18)) == .yellow)
        #expect(engine.period(for: habit, on: october(18))?.countsOnlyIfReached == true)
    }

    @Test func theWeekOfCreationIsNeverRed() {
        let habit = make(target: 5, created: october(15))
        #expect(engine.status(habit, on: october(17)) == .yellow)
        // Am ersten Tag der Woche erstellt: ein voller Zeitraum, also normale Ampel.
        let full = make(target: 5, created: october(12))
        #expect(engine.status(full, on: october(17)) == .red)
    }

    @Test func pausedWeekIsNeitherMetNorMissedInTheStreak() {
        // Woche vom 5.10. erfüllt (7 Tage), Woche vom 12.10. mit Pause und nur einer Erledigung: nicht gewertet.
        let habit = make(
            created: date(2026, 10, 5),
            done: [date(2026, 10, 5), date(2026, 10, 6), date(2026, 10, 7), october(12)],
            pauses: [(october(14), october(15))]
        )
        let stats = engine.statistics(habit, on: october(21))
        #expect(stats.currentStreak == 7)
        #expect(stats.longestStreak == 7)
        #expect(stats.rate30 == 1)
    }

    // MARK: Streak und Quote

    @Test func streakCountsWholeWeeksAndLeavesTheRunningWeekOpen() {
        let habit = make(
            created: date(2026, 10, 5),
            done: [date(2026, 10, 5), date(2026, 10, 6), date(2026, 10, 7), october(12), october(13), october(14)]
        )
        let stats = engine.statistics(habit, on: october(21))
        #expect(stats.currentStreak == 14)
        #expect(stats.longestStreak == 14)
        #expect(stats.rate30 == 1)
    }

    @Test func aMissedWeekBreaksTheStreak() {
        let habit = make(created: date(2026, 10, 5), done: [october(12), october(13), october(14)])
        let stats = engine.statistics(habit, on: october(21))
        #expect(stats.currentStreak == 7) // Woche vom 12.10. erfüllt, Woche vom 5.10. verpasst
        #expect(stats.longestStreak == 7)
        #expect(stats.rate30 == 0.5)
    }

    @Test func runningWeekCountsAsMetAsSoonAsTheGoalIsReached() {
        let habit = make(created: date(2026, 10, 12), done: [october(12), october(13), october(14)])
        #expect(engine.statistics(habit, on: october(14)).currentStreak == 3)
        let open = make(created: date(2026, 10, 12), done: [october(12)])
        #expect(engine.statistics(open, on: october(14)).currentStreak == 0)
        #expect(engine.statistics(open, on: october(14)).rate30 == nil)
    }

    // MARK: Weitere

    @Test func fulfilledWeeklyHabitMovesToOtherOnlyForTheRestOfTheWeek() {
        let habit = make(target: 1, done: [october(12)])
        #expect(engine.section(habit, on: october(12)) == .main)
        #expect(engine.section(habit, on: october(13)) == .other)
        #expect(engine.section(habit, on: october(18)) == .other)
        #expect(engine.section(habit, on: october(19)) == .main)
    }

    // MARK: Rollierend bleibt wie vorher

    @Test func rollingPeriodsKeepTheRollingWindow() {
        let rolling = Self.makeEngine(periods: .rolling)
        let habit = make(done: [october(12), october(13), october(14)])
        #expect(rolling.period(for: habit, on: october(18)) == nil)
        // Das Fenster vom 12. bis 18.10. enthält alle drei Erledigungen, am Mo 19.10. fällt die vom 12.10. heraus.
        #expect(rolling.windowProgress(habit, on: october(18))?.done == 3)
        #expect(rolling.status(habit, on: october(18)) == .yellow) // fällt in 2 Tagen heraus
        #expect(rolling.windowProgress(habit, on: october(19))?.done == 2)
        #expect(rolling.status(habit, on: october(19)) == .red)
        // Nach Kalender beginnt am Mo 19.10. eine neue Woche.
        #expect(engine.windowProgress(habit, on: october(19))?.done == 0)
        #expect(engine.status(habit, on: october(19)) == .green)
    }

    @Test func periodsSettingRoundTripsThroughItsRawValue() {
        #expect(Periods(rawValue: "rolling") == .rolling)
        #expect(Periods(rawValue: "calendar") == .calendar)
        #expect(Periods.allCases.map(\.title) == ["Rollierend", "Kalender"])
    }
}
