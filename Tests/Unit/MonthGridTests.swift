import Foundation
import Testing
@testable import Habitus

/// Monatsraster und Einfärbung des Kalenders (Spezifikation 5.4).
@MainActor
struct MonthGridTests {
    let engine: HabitEngine = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        // Absichtlich Sonntag: das Raster muss unabhängig von der Region mit Montag beginnen.
        calendar.firstWeekday = 1
        return HabitEngine(calendar: calendar)
    }()

    func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        engine.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test func octoberTwentyTwentySixStartsOnThursday() {
        let grid = engine.monthGrid(containing: date(2026, 10, 15))
        #expect(grid.firstDay == date(2026, 10, 1, 0))
        #expect(grid.days.count == 31)
        #expect(grid.days.first == date(2026, 10, 1, 0))
        #expect(grid.days.last == date(2026, 10, 31, 0))
        #expect(grid.leadingBlanks == 3)
    }

    @Test func monthStartingOnMondayHasNoBlanks() {
        let grid = engine.monthGrid(containing: date(2027, 2, 20))
        #expect(grid.leadingBlanks == 0)
        #expect(grid.days.count == 28)
    }

    @Test func monthStartingOnSundayHasSixBlanks() {
        let grid = engine.monthGrid(containing: date(2026, 11, 3))
        #expect(grid.leadingBlanks == 6)
        #expect(grid.days.count == 30)
    }

    @Test func leapFebruaryHasTwentyNineDays() {
        #expect(engine.monthGrid(containing: date(2028, 2, 10)).days.count == 29)
    }

    @Test func daysAreStartsOfDayInAscendingOrder() {
        let days = engine.monthGrid(containing: date(2026, 3, 31, 23)).days
        #expect(days.allSatisfy { $0 == engine.startOfDay($0) })
        #expect(days == days.sorted())
        // Zeitumstellung am 29. März 2026: der Monat hat trotzdem 31 verschiedene Tage.
        #expect(Set(days).count == 31)
    }

    @Test func monthStartsRunFromFirstThroughLastMonthInclusive() {
        let months = engine.monthStarts(from: date(2026, 8, 20), through: date(2026, 10, 3))
        #expect(months == [date(2026, 8, 1, 0), date(2026, 9, 1, 0), date(2026, 10, 1, 0)])
    }

    @Test func monthStartsCrossYearBoundaries() {
        let months = engine.monthStarts(from: date(2025, 11, 30), through: date(2026, 2, 1))
        #expect(months == [date(2025, 11, 1, 0), date(2025, 12, 1, 0), date(2026, 1, 1, 0), date(2026, 2, 1, 0)])
    }

    @Test func monthStartsOfOneMonthIsThatMonth() {
        #expect(engine.monthStarts(from: date(2026, 10, 1), through: date(2026, 10, 31)) == [date(2026, 10, 1, 0)])
    }

    @Test func monthStartsAreEmptyWhenFirstIsAfterLast() {
        #expect(engine.monthStarts(from: date(2026, 11, 1), through: date(2026, 10, 31)).isEmpty)
    }

    @Test func onlyDaysAfterTodayAreFuture() {
        let today = date(2026, 10, 10, 9)
        #expect(!engine.isFuture(date(2026, 10, 9, 23), today: today))
        #expect(!engine.isFuture(date(2026, 10, 10, 23), today: today))
        #expect(engine.isFuture(date(2026, 10, 11, 0), today: today))
    }

    // MARK: Einfärbung

    @Test func noFillAtZeroPercent() {
        #expect(MonthCalendar.fillOpacity(for: 0) == 0)
    }

    @Test func fillGrowsWithProgressUpToTheMaximum() {
        let steps = [0.01, 0.25, 0.5, 0.75, 1].map(MonthCalendar.fillOpacity(for:))
        #expect(steps == steps.sorted())
        #expect(Set(steps).count == steps.count)
        #expect(steps.first! > 0)
        #expect(steps.last! == Theme.calendarFillOpacity.upperBound)
    }

    @Test func fillNeverExceedsTheMaximum() {
        #expect(MonthCalendar.fillOpacity(for: 2) == Theme.calendarFillOpacity.upperBound)
    }

    @Test func dayIdentifierIsIsoDate() {
        #expect(MonthCalendar.identifier(for: date(2026, 10, 8), calendar: engine.calendar) == "2026-10-08")
    }

    @Test func monthIdentifierIsYearAndMonth() {
        #expect(MonthCalendar.monthIdentifier(for: date(2026, 10, 1), calendar: engine.calendar) == "2026-10")
    }

    // MARK: Monatswechsel (Spezifikation 5.4)

    @Test func steppingMovesByWholeMonthsAndReturnsTheFirstOfTheMonth() {
        let first = date(2026, 1, 20), last = date(2026, 10, 3)
        #expect(engine.steppedMonth(date(2026, 8, 17), by: -1, from: first, through: last) == date(2026, 7, 1, 0))
        #expect(engine.steppedMonth(date(2026, 8, 17), by: 1, from: first, through: last) == date(2026, 9, 1, 0))
    }

    @Test func steppingStopsAtTheLastMonth() {
        let first = date(2026, 1, 20), last = date(2026, 10, 3)
        #expect(engine.steppedMonth(date(2026, 10, 1, 0), by: 1, from: first, through: last) == date(2026, 10, 1, 0))
    }

    @Test func steppingStopsAtTheFirstMonth() {
        let first = date(2026, 1, 20), last = date(2026, 10, 3)
        #expect(engine.steppedMonth(date(2026, 1, 1, 0), by: -1, from: first, through: last) == date(2026, 1, 1, 0))
    }

    @Test func steppingCrossesYearBoundaries() {
        let first = date(2025, 6, 1), last = date(2026, 10, 3)
        #expect(engine.steppedMonth(date(2026, 1, 1, 0), by: -1, from: first, through: last) == date(2025, 12, 1, 0))
        #expect(engine.steppedMonth(date(2025, 12, 31), by: 1, from: first, through: last) == date(2026, 1, 1, 0))
    }

    @Test func steppingFromOutsideTheRangeClampsIntoIt() {
        let first = date(2026, 5, 1), last = date(2026, 7, 1)
        #expect(engine.steppedMonth(date(2026, 12, 1, 0), by: 1, from: first, through: last) == date(2026, 7, 1, 0))
        #expect(engine.steppedMonth(date(2026, 1, 1, 0), by: -1, from: first, through: last) == date(2026, 5, 1, 0))
    }

    @Test func aSingleMonthRangeHasNowhereToGo() {
        let day = date(2026, 10, 12)
        #expect(engine.steppedMonth(day, by: 1, from: day, through: day) == date(2026, 10, 1, 0))
        #expect(engine.steppedMonth(day, by: -1, from: day, through: day) == date(2026, 10, 1, 0))
    }
}
