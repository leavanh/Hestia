import Foundation
import Testing
@testable import Hestia

/// Kalenderwoche und Wochenstreifen im Kopfband von Heute (Spezifikation 5.2, Phase 9).
struct WeekStripTests {
    let engine: HabitEngine = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return HabitEngine(calendar: calendar)
    }()

    func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        engine.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test func weekOfYearFollowsISO8601() {
        #expect(engine.weekOfYear(date(2026, 10, 11)) == 41)
        #expect(engine.weekOfYear(date(2025, 12, 29)) == 1)
        #expect(engine.weekOfYear(date(2027, 1, 1)) == 53)
    }

    @Test func weekOfYearIgnoresTheFirstWeekdayOfTheCalendar() {
        var calendar = engine.calendar
        calendar.firstWeekday = 1
        calendar.minimumDaysInFirstWeek = 1
        #expect(HabitEngine(calendar: calendar).weekOfYear(date(2026, 10, 11)) == 41)
    }

    @Test func stripOnSundayTodayShowsMondayToSunday() {
        let strip = engine.weekStrip(date(2026, 10, 11), today: date(2026, 10, 11))
        #expect(strip.map(\.day) == (5...11).map { date(2026, 10, $0, 0) })
        #expect(strip.map(\.isShown) == [false, false, false, false, false, false, true])
        #expect(strip.map(\.isSelectable) == Array(repeating: true, count: 7))
    }

    @Test func daysAfterTodayAreFutureAndNotSelectable() {
        let strip = engine.weekStrip(date(2026, 10, 14), today: date(2026, 10, 14))
        #expect(strip.map(\.day) == (12...18).map { date(2026, 10, $0, 0) })
        #expect(strip.map(\.isFuture) == [false, false, false, true, true, true, true])
        #expect(strip.map(\.isSelectable) == [true, true, true, false, false, false, false])
        #expect(strip[2].isShown)
    }

    @Test func pastWeekHasNoFutureDays() {
        let strip = engine.weekStrip(date(2026, 10, 4), today: date(2026, 10, 11))
        #expect(strip.first?.day == date(2026, 9, 28, 0))
        #expect(strip.last?.isShown == true)
        #expect(strip.map(\.isSelectable) == Array(repeating: true, count: 7))
    }

    @Test func habitCountText() {
        #expect(HabitCountText.text(1) == "1 Habit")
        #expect(HabitCountText.text(6) == "6 Habits")
        #expect(HabitCountText.text(0) == "0 Habits")
    }
}

/// Datumszeile im Kopfband von Heute.
struct DayTextTests {
    let engine: HabitEngine = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return HabitEngine(calendar: calendar)
    }()

    func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        engine.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    @Test func dateLineShowsShortWeekdayDayAndMonth() {
        #expect(DayText.dateLine(date(2026, 10, 11), engine: engine) == "So · 11. Okt")
        #expect(DayText.dateLine(date(2026, 10, 5), engine: engine) == "Mo · 5. Okt")
    }

    @Test func weekNumberText() {
        #expect(DayText.weekNumber(date(2026, 10, 11), engine: engine) == "KW 41")
    }

    // MARK: Ziehen über den Streifen (Phase 18.4)

    @Test func fingerPositionSelectsTheFieldBelowIt() {
        let strip = engine.weekStrip(date(2026, 10, 11), today: date(2026, 10, 11))
        #expect(strip.scrubIndex(atX: 0, width: 350) == 0)
        #expect(strip.scrubIndex(atX: 49, width: 350) == 0)
        #expect(strip.scrubIndex(atX: 51, width: 350) == 1)
        #expect(strip.scrubIndex(atX: 220, width: 350) == 4)
        #expect(strip.scrubIndex(atX: 349, width: 350) == 6)
    }

    @Test func fingerOutsideTheStripStaysOnTheFirstOrLastField() {
        let strip = engine.weekStrip(date(2026, 10, 11), today: date(2026, 10, 11))
        #expect(strip.scrubIndex(atX: -40, width: 350) == 0)
        #expect(strip.scrubIndex(atX: 500, width: 350) == 6)
    }

    @Test func fingerOnAFutureDayStopsAtToday() {
        // Mittwoch: Do bis So liegen in der Zukunft.
        let strip = engine.weekStrip(date(2026, 10, 14), today: date(2026, 10, 14))
        #expect(strip.scrubIndex(atX: 300, width: 350) == 2)
        #expect(strip.scrubIndex(atX: 500, width: 350) == 2)
    }

    @Test func noFieldWithoutWidth() {
        let strip = engine.weekStrip(date(2026, 10, 11), today: date(2026, 10, 11))
        #expect(strip.scrubIndex(atX: 10, width: 0) == nil)
    }
}
