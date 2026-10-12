import Foundation
import SwiftUI
import Testing
@testable import Hestia

/// Wochenbeginn in Wochenstreifen, Kalenderwoche, Monatsraster und Rhythmus Zeile (Spezifikation 5.5, Phase 14).
struct FirstWeekdayTests {
    let engine: HabitEngine = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return HabitEngine(calendar: calendar)
    }()

    func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        engine.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    let monday = 1
    let sunday = 7

    @Test func mondayGivesTheSameValuesAsBefore() {
        let strip = engine.weekStrip(date(2026, 10, 14), today: date(2026, 10, 14), firstWeekday: monday)
        #expect(strip.map(\.day) == (12...18).map { date(2026, 10, $0, 0) })
        #expect(engine.weekOfYear(date(2026, 10, 11), firstWeekday: monday) == 41)
        #expect(engine.weekOfYear(date(2025, 12, 29), firstWeekday: monday) == 1)
        #expect(engine.weekOfYear(date(2027, 1, 1), firstWeekday: monday) == 53)
    }

    @Test func sundayStripStartsOnSundayAndSharesOneWeekNumber() {
        let strip = engine.weekStrip(date(2026, 10, 14), today: date(2026, 10, 14), firstWeekday: sunday)
        #expect(strip.map(\.day) == (11...17).map { date(2026, 10, $0, 0) })
        #expect(strip.map(\.isShown) == [false, false, false, true, false, false, false])
        let weeks = strip.map { engine.weekOfYear($0.day, firstWeekday: sunday) }
        #expect(Set(weeks).count == 1)
        #expect(engine.weekOfYear(date(2026, 10, 11), firstWeekday: sunday) == engine.weekOfYear(date(2026, 10, 17), firstWeekday: sunday))
    }

    @Test func sundayStartOfWeekOfASundayIsThatSunday() {
        #expect(engine.startOfWeek(date(2026, 10, 11), firstWeekday: sunday) == date(2026, 10, 11, 0))
        #expect(engine.startOfWeek(date(2026, 10, 11), firstWeekday: monday) == date(2026, 10, 5, 0))
    }

    @Test func monthGridBlanksFollowTheFirstWeekday() {
        // Der 1. Oktober 2026 ist ein Donnerstag.
        #expect(engine.monthGrid(containing: date(2026, 10, 15), firstWeekday: monday).leadingBlanks == 3)
        #expect(engine.monthGrid(containing: date(2026, 10, 15), firstWeekday: sunday).leadingBlanks == 4)
    }

    @Test func rhythmTextFollowsTheFirstWeekday() {
        let habit = HabitSnapshot(
            rhythm: .weekdays, targetCount: 1, weekdays: [1, 7], createdAt: date(2026, 10, 1), counts: []
        )
        #expect(habit.rhythmText(window: nil, firstWeekday: monday) == "Mo · So")
        #expect(habit.rhythmText(window: nil, firstWeekday: sunday) == "So · Mo")
    }

    @Test func automaticFollowsTheRegion() {
        #expect(FirstWeekdaySetting.automatic.start(locale: Locale(identifier: "de_DE")) == monday)
        #expect(FirstWeekdaySetting.automatic.start(locale: Locale(identifier: "en_US")) == sunday)
        #expect(FirstWeekdaySetting.monday.start(locale: Locale(identifier: "en_US")) == monday)
        #expect(FirstWeekdaySetting.sunday.start(locale: Locale(identifier: "de_DE")) == sunday)
    }

    @Test func weekdayNamesComeFromTheCalendar() {
        #expect(DayText.weekdayNames(startingAt: monday) == ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"])
        #expect(DayText.weekdayNames(startingAt: sunday) == ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"])
        #expect((1...7).map { DayText.weekdayInitial($0) } == ["M", "D", "M", "D", "F", "S", "S"])
        #expect(DayText.weekdayFullName(1) == "Montag")
        #expect(DayText.weekdayFullName(7) == "Sonntag")
    }

    @Test func appearanceMapsToColorSchemes() {
        #expect(AppearanceSetting.system.colorScheme == nil)
        #expect(AppearanceSetting.light.colorScheme == .light)
        #expect(AppearanceSetting.dark.colorScheme == .dark)
    }

    @Test func aboutLicensesAreInTheBundle() {
        for font in AboutFont.all {
            #expect(font.licenseText.contains("SIL OPEN FONT LICENSE"), "Lizenz für \(font.name) fehlt")
        }
    }
}
