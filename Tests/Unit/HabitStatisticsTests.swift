import Foundation
import Testing
@testable import Habitus

/// Streaks und Quote 30 Tage (Spezifikation 3.7) mit festen Daten und von Hand nachgerechneten Fällen.
struct HabitStatisticsTests {
    let engine: HabitEngine = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return HabitEngine(calendar: calendar)
    }()

    func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        engine.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    /// Heute ist Montag, der 12. Oktober 2026.
    var monday: Date { date(2026, 10, 12) }

    /// Der Tag, `days` Tage vor heute.
    func ago(_ days: Int) -> Date {
        engine.calendar.date(byAdding: .day, value: -days, to: monday)!
    }

    func make(
        _ rhythm: Rhythm,
        target: Int = 1,
        weekdays: [Int] = [],
        monthDay: Int? = nil,
        created: Date? = nil,
        done: [Date] = [],
        counts: [(Date, Int)] = []
    ) -> HabitSnapshot {
        HabitSnapshot(
            rhythm: rhythm,
            targetCount: target,
            weekdays: weekdays,
            monthDay: monthDay,
            createdAt: created ?? date(2026, 1, 1),
            counts: (done.map { ($0, 1) } + counts).map { DayCount(day: engine.startOfDay($0.0), count: $0.1) }
        )
    }

    func current(_ habit: HabitSnapshot) -> Int { engine.currentStreak(habit, on: monday) }
    func longest(_ habit: HabitSnapshot) -> Int { engine.longestStreak(habit, on: monday) }
    func rate(_ habit: HabitSnapshot) -> Double? { engine.rate30(habit, on: monday) }

    // MARK: Täglich

    @Test func dailyFiveDaysInARowIsFive() {
        let habit = make(.daily, done: (0...4).map(ago))
        #expect(current(habit) == 5)
        #expect(longest(habit) == 5)
    }

    @Test func dailyTodayStillOpenDoesNotBreakTheStreak() {
        let habit = make(.daily, done: (1...5).map(ago))
        #expect(current(habit) == 5)
    }

    @Test func dailyMissedDayResetsToCountFromToday() {
        // Heute und vor 2 bis 4 Tagen erledigt, gestern verpasst.
        let habit = make(.daily, done: [ago(0)] + (2...4).map(ago))
        #expect(current(habit) == 1)
        #expect(longest(habit) == 3)
    }

    @Test func dailyMissedYesterdayAndOpenTodayIsZero() {
        let habit = make(.daily, done: (2...4).map(ago))
        #expect(current(habit) == 0)
        #expect(longest(habit) == 3)
    }

    @Test func dailyWithCounterNeedsTheFullTarget() {
        // Ziel 3: vor 2 Tagen nur 2, gestern und heute 3.
        let habit = make(.daily, target: 3, counts: [(ago(0), 3), (ago(1), 3), (ago(2), 2), (ago(3), 3)])
        #expect(current(habit) == 2)
        #expect(longest(habit) == 2)
    }

    @Test func dailyNewHabitWithoutDoneDaysHasNoStreakAndNoRate() {
        let habit = make(.daily, created: monday)
        #expect(current(habit) == 0)
        #expect(longest(habit) == 0)
        #expect(rate(habit) == nil)
    }

    @Test func dailyCreatedAndDoneToday() {
        let habit = make(.daily, created: monday, done: [monday])
        #expect(current(habit) == 1)
        #expect(rate(habit) == 1)
    }

    @Test func dailyStreakDoesNotCountDaysBeforeCreation() {
        let habit = make(.daily, created: ago(2), done: (0...6).map(ago))
        #expect(current(habit) == 3)
        #expect(longest(habit) == 3)
    }

    // MARK: Pro Woche und pro Monat

    @Test func weeklyStreakContinuesAsLongAsTheWindowIsFulfilled() {
        // Ziel 1, erledigt vor 8 und vor 2 Tagen: jeder Tag von vor 8 Tagen bis heute hat ein erfülltes Fenster.
        let habit = make(.weekly, done: [ago(8), ago(2)])
        #expect(current(habit) == 9)
        #expect(longest(habit) == 9)
    }

    @Test func weeklyStreakEndsWhenTheWindowIsNoLongerFulfilled() {
        // Ziel 2, erledigt vor 10 und vor 8 Tagen: erfüllt von vor 8 bis vor 4 Tagen (5 Tage), danach nicht mehr.
        let habit = make(.weekly, target: 2, done: [ago(10), ago(8)])
        #expect(current(habit) == 0)
        #expect(longest(habit) == 5)
    }

    @Test func weeklyFirstWindowIsNotMissed() {
        // Erst 3 Tage alt: noch nichts verpasst, aber auch nichts erreicht.
        let habit = make(.weekly, created: ago(3))
        #expect(current(habit) == 0)
        #expect(rate(habit) == nil)
    }

    @Test func weeklyMissedAfterTheFirstWindowCountsAgainstTheRate() {
        // Vor 10 Tagen erstellt, nie erledigt: vor 10 bis 4 Tagen im ersten Fenster, danach 3 verpasste Tage
        // (vor 3, 2 und 1 Tag). Heute ist noch offen.
        let habit = make(.weekly, created: ago(10))
        #expect(rate(habit) == 0)
        #expect(current(habit) == 0)
    }

    @Test func monthlyStreakHasAGapWhereTheWindowRunsEmpty() {
        // Erledigt vor 40 und vor 5 Tagen. Fenster 30 Tage: erfüllt von vor 40 bis vor 11 Tagen (30 Tage),
        // dann Lücke von vor 10 bis vor 6 Tagen, ab vor 5 Tagen wieder erfüllt (6 Tage mit heute).
        let habit = make(.monthly, done: [ago(40), ago(5)])
        #expect(current(habit) == 6)
        #expect(longest(habit) == 30)
    }

    // MARK: Feste Wochentage und fester Monatstag

    @Test func weekdaysOnlyDueDaysCountAndOtherDaysDoNotBreakTheStreak() {
        // Montag und Donnerstag: 1. Okt (Do), 5. Okt (Mo), 8. Okt (Do), 12. Okt (Mo).
        let habit = make(.weekdays, weekdays: [1, 4], done: [date(2026, 10, 1), date(2026, 10, 5), date(2026, 10, 8), monday])
        #expect(current(habit) == 4)
        #expect(longest(habit) == 4)
    }

    @Test func weekdaysMissedDueDayBreaksTheStreak() {
        let habit = make(.weekdays, weekdays: [1, 4], done: [date(2026, 10, 1), date(2026, 10, 5), monday])
        #expect(current(habit) == 1)
        #expect(longest(habit) == 2)
    }

    @Test func weekdaysDueTodayButStillOpenDoesNotBreakTheStreak() {
        let habit = make(.weekdays, weekdays: [1, 4], done: [date(2026, 10, 1), date(2026, 10, 5), date(2026, 10, 8)])
        #expect(current(habit) == 3)
    }

    @Test func monthDayCountsOneDayPerMonth() {
        // Am 12. des Monats: 12. Aug, 12. Sep und 12. Okt (heute) erledigt, davor nicht.
        let habit = make(.monthDay, monthDay: 12, created: date(2026, 7, 20),
                         done: [date(2026, 8, 12), date(2026, 9, 12), monday])
        #expect(current(habit) == 3)
        #expect(longest(habit) == 3)
    }

    // MARK: Längster Streak

    @Test func longestStreakIsNeverSmallerThanTheCurrentOne() {
        let habits = [
            make(.daily, done: (0...12).map(ago)),
            make(.daily, done: [ago(0), ago(1), ago(5), ago(6), ago(7)]),
            make(.daily, target: 2, counts: [(ago(1), 2), (ago(2), 2)]),
            make(.weekly, target: 2, done: [ago(1), ago(5)]),
            make(.monthly, done: [ago(3)]),
            make(.weekdays, weekdays: [1, 4], done: [monday]),
            make(.monthDay, monthDay: 12, done: [monday]),
            make(.daily, created: monday),
        ]
        for habit in habits {
            #expect(longest(habit) >= current(habit))
        }
    }

    @Test func statisticsMatchTheSingleFunctions() {
        let habit = make(.daily, done: [ago(0), ago(1), ago(3)])
        let stats = engine.statistics(habit, on: monday)
        #expect(stats.currentStreak == current(habit))
        #expect(stats.longestStreak == longest(habit))
        #expect(stats.rate30 == rate(habit))
    }

    // MARK: Quote 30 Tage

    @Test func rateOfTwentyOfThirtyDaysIsSixtySevenPercent() {
        // Heute und die 19 Tage davor erledigt: 20 von 30 Tagen, von Hand nachgerechnet.
        let habit = make(.daily, done: (0...19).map(ago))
        #expect(rate(habit) == 20.0 / 30.0)
        #expect(engine.statistics(habit, on: monday).ratePercent == 67)
    }

    @Test func rateLooksAtThe30DaysEndingTodayOnly() {
        // 5 Erledigungen vor 30 bis 34 Tagen liegen außerhalb.
        let habit = make(.daily, done: [ago(0), ago(29), ago(30), ago(31), ago(32), ago(33), ago(34)])
        #expect(rate(habit) == 2.0 / 30.0)
    }

    @Test func rateLeavesOutTheOpenToday() {
        // Heute offen: bewertet werden die 29 Tage davor, davon 10 erledigt.
        let habit = make(.daily, done: (1...10).map(ago))
        #expect(rate(habit) == 10.0 / 29.0)
    }

    @Test func rateStartsAtCreation() {
        // Vor 9 Tagen erstellt: 10 Tage, davon 5 erledigt.
        let habit = make(.daily, created: ago(9), done: (0...4).map(ago))
        #expect(rate(habit) == 0.5)
    }

    @Test func rateOfFixedDaysOnlyUsesDueDays() {
        // Montag und Donnerstag zwischen 13. Sep und heute: Mo 14., 21., 28. Sep, 5., 12. Okt und
        // Do 17., 24. Sep, 1., 8. Okt, also 9 fällige Tage. Davon 6 erledigt.
        let habit = make(.weekdays, weekdays: [1, 4], done: [
            monday, date(2026, 10, 8), date(2026, 10, 5), date(2026, 10, 1), date(2026, 9, 28), date(2026, 9, 24),
        ])
        #expect(rate(habit) == 6.0 / 9.0)
    }

    @Test func rateOfAWeeklyHabitCountsDaysWithAFulfilledWindow() {
        // Ziel 1, erledigt vor 10 und vor 2 Tagen: Fenster erfüllt vor 10 bis vor 4 Tagen (7 Tage) und
        // vor 2 Tagen bis heute (3 Tage), also 10 von 30. Vor 3 Tagen und vor 11 bis 29 Tagen verpasst.
        let habit = make(.weekly, done: [ago(10), ago(2)])
        #expect(rate(habit) == 10.0 / 30.0)
    }
}
