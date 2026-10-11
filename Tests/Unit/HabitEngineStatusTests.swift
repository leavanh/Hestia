import Foundation
import Testing
@testable import Hestia

/// Fälligkeit, Zählung im Fortschritt und Ampelstatus (Spezifikation 3.2, 3.4, 3.5) mit festen Daten.
struct HabitEngineStatusTests {
    let engine: HabitEngine = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return HabitEngine(calendar: calendar)
    }()

    func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        engine.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    /// Montag, 12. Oktober 2026. Der 8. Oktober (Donnerstag) steht in den Tests von Phase 2.
    var monday: Date { date(2026, 10, 12) }
    var tuesday: Date { date(2026, 10, 13) }
    var wednesday: Date { date(2026, 10, 14) }

    /// Der Tag, `days` Tage vor `day` (Standard: Montag).
    func ago(_ days: Int, from day: Date? = nil) -> Date {
        engine.calendar.date(byAdding: .day, value: -days, to: day ?? monday)!
    }

    /// Habit, der an den Tagen in `done` genau einmal erledigt wurde. Standardmäßig lange vor den Tests erstellt.
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

    // MARK: Wochentage zählen ab Montag

    @Test func weekdaysAreNumberedFromMondayToSunday() {
        #expect(engine.weekday(of: date(2026, 10, 12)) == 1) // Montag
        #expect(engine.weekday(of: date(2026, 10, 13)) == 2)
        #expect(engine.weekday(of: date(2026, 10, 14)) == 3)
        #expect(engine.weekday(of: date(2026, 10, 15)) == 4)
        #expect(engine.weekday(of: date(2026, 10, 16)) == 5)
        #expect(engine.weekday(of: date(2026, 10, 17)) == 6) // Samstag
        #expect(engine.weekday(of: date(2026, 10, 18)) == 7) // Sonntag
    }

    // MARK: Fälligkeit (3.2)

    @Test func dailyWeeklyAndMonthlyAreDueEveryDay() {
        for rhythm in [Rhythm.daily, .weekly, .monthly] {
            let habit = make(rhythm)
            for offset in 0..<14 {
                #expect(engine.isDue(habit, on: ago(offset)))
            }
        }
    }

    @Test func weekdaysAreDueOnlyOnTheirDays() {
        let yoga = make(.weekdays, weekdays: [1, 4]) // Montag und Donnerstag
        #expect(engine.isDue(yoga, on: date(2026, 10, 12)))
        #expect(!engine.isDue(yoga, on: date(2026, 10, 13)))
        #expect(!engine.isDue(yoga, on: date(2026, 10, 14)))
        #expect(engine.isDue(yoga, on: date(2026, 10, 15)))
        #expect(!engine.isDue(yoga, on: date(2026, 10, 16)))
        #expect(!engine.isDue(yoga, on: date(2026, 10, 17)))
        #expect(!engine.isDue(yoga, on: date(2026, 10, 18)))
    }

    @Test func mondayHabitDoesNotAppearOnWednesday() {
        let habit = make(.weekdays, weekdays: [1])
        #expect(engine.isDue(habit, on: monday))
        #expect(!engine.isDue(habit, on: wednesday))
        // Auch die Fortschrittszählung enthält ihn dann nicht.
        #expect(engine.dayProgress([habit], on: wednesday) == DayProgress(done: 0, total: 0))
    }

    @Test func sundayIsSeven() {
        let habit = make(.weekdays, weekdays: [7])
        #expect(engine.isDue(habit, on: date(2026, 10, 11)))
        #expect(engine.isDue(habit, on: date(2026, 10, 18)))
        #expect(!engine.isDue(habit, on: date(2026, 10, 12)))
        #expect(!engine.isDue(habit, on: date(2026, 10, 17)))
    }

    @Test func dueIgnoresTimeOfDay() {
        let habit = make(.weekdays, weekdays: [1])
        #expect(engine.isDue(habit, on: date(2026, 10, 12, 0)))
        #expect(engine.isDue(habit, on: date(2026, 10, 12, 23)))
        #expect(!engine.isDue(habit, on: date(2026, 10, 13, 0)))
    }

    @Test func fixedHabitWithoutDaysIsNeverDue() {
        #expect(!engine.isDue(make(.weekdays, weekdays: []), on: monday))
        #expect(!engine.isDue(make(.monthDay, monthDay: nil), on: monday))
    }

    @Test func monthDayIsDueOnThatDayOnly() {
        let habit = make(.monthDay, monthDay: 15)
        #expect(engine.isDue(habit, on: date(2026, 10, 15)))
        #expect(!engine.isDue(habit, on: date(2026, 10, 14)))
        #expect(!engine.isDue(habit, on: date(2026, 10, 16)))
        #expect(engine.isDue(habit, on: date(2026, 11, 15)))
    }

    @Test func monthDay31IsDueOnTheLastDayOfShorterMonths() {
        let habit = make(.monthDay, monthDay: 31)
        // Februar 2026 hat 28 Tage.
        #expect(engine.isDue(habit, on: date(2026, 2, 28)))
        #expect(!engine.isDue(habit, on: date(2026, 2, 27)))
        // April hat 30, Januar 31 Tage.
        #expect(engine.isDue(habit, on: date(2026, 4, 30)))
        #expect(!engine.isDue(habit, on: date(2026, 4, 29)))
        #expect(engine.isDue(habit, on: date(2026, 1, 31)))
        #expect(!engine.isDue(habit, on: date(2026, 1, 30)))
    }

    @Test func monthDay31InLeapYearFebruary() {
        let habit = make(.monthDay, monthDay: 31, created: date(2020, 1, 1))
        #expect(engine.isDue(habit, on: date(2028, 2, 29)))
        #expect(!engine.isDue(habit, on: date(2028, 2, 28)))
    }

    @Test func monthDay30InFebruaryIsDueOnTheLastDay() {
        let habit = make(.monthDay, monthDay: 30)
        #expect(engine.isDue(habit, on: date(2026, 2, 28)))
        #expect(engine.isDue(habit, on: date(2026, 3, 30)))
        #expect(!engine.isDue(habit, on: date(2026, 3, 31)))
    }

    @Test func habitIsNotDueBeforeItWasCreated() {
        let habit = make(.daily, created: monday)
        #expect(!engine.isDue(habit, on: ago(1)))
        #expect(engine.isDue(habit, on: monday))
    }

    // MARK: Zählung im Fortschritt (3.4)

    @Test func threePerWeekWithOneDoneIsOnePointAndOpen() {
        // Pflicht: 3x pro Woche, 1x erledigt: 1 Punkt im Fortschritt, offen.
        let habit = make(.weekly, target: 3, done: [ago(2)])
        #expect(engine.points(habit, on: monday) == 1)
        #expect(engine.donePoints(habit, on: monday) == 0)
        #expect(engine.dayProgress([habit], on: monday) == DayProgress(done: 0, total: 1))
    }

    @Test func threePerWeekDoneTodayCountsTodayEvenIfWindowIsOpen() {
        let habit = make(.weekly, target: 3, done: [monday])
        #expect(engine.donePoints(habit, on: monday) == 1)
    }

    @Test func twoPerWeekFulfilledInWindowCountsAsDoneWithoutTodaysCheck() {
        // Pflicht: 2x pro Woche, im Fenster erfüllt, heute nicht abgehakt: Punkt zählt als erledigt.
        let habit = make(.weekly, target: 2, done: [ago(1), ago(3)])
        #expect(engine.count(on: monday, in: habit.counts) == 0)
        #expect(engine.points(habit, on: monday) == 1)
        #expect(engine.donePoints(habit, on: monday) == 1)
        // Ab Phase 13 steht der erfüllte, grüne Habit in Weitere und zählt nicht im Tagesfortschritt (3.4).
        #expect(engine.section(habit, on: monday) == .other)
        #expect(engine.dayProgress([habit], on: monday) == DayProgress(done: 0, total: 0))
    }

    @Test func monthlyFulfilledInWindowCountsAsDone() {
        let habit = make(.monthly, done: [ago(20)])
        #expect(engine.donePoints(habit, on: monday) == 1)
    }

    @Test func completionOutsideTheWindowDoesNotCount() {
        #expect(engine.donePoints(make(.weekly, done: [ago(7)]), on: monday) == 0)
        #expect(engine.donePoints(make(.monthly, done: [ago(30)]), on: monday) == 0)
    }

    @Test func fixedDaysAreOnePointDoneOnlyWhenCheckedToday() {
        let weekdays = make(.weekdays, weekdays: [1], done: [ago(7)])
        #expect(engine.points(weekdays, on: monday) == 1)
        #expect(engine.donePoints(weekdays, on: monday) == 0)

        let checked = make(.weekdays, weekdays: [1], done: [monday])
        #expect(engine.donePoints(checked, on: monday) == 1)

        let monthDay = make(.monthDay, monthDay: 12, done: [monday])
        #expect(engine.points(monthDay, on: monday) == 1)
        #expect(engine.donePoints(monthDay, on: monday) == 1)
    }

    @Test func progressMixesAllRhythmsAndSkipsHabitsThatAreNotDue() {
        let water = make(.daily, target: 3, done: [monday])                         // 1 von 3
        let sport = make(.weekly, target: 2, done: [ago(1), ago(3)])               // erfüllt und grün: Weitere
        let yoga = make(.weekdays, weekdays: [1])                                   // fällig, offen: 0 von 1
        let rent = make(.monthDay, monthDay: 1)                                     // nicht fällig
        let tuesdayOnly = make(.weekdays, weekdays: [2], done: [monday])            // nicht fällig
        let progress = engine.dayProgress([water, sport, yoga, rent, tuesdayOnly], on: monday)
        #expect(progress == DayProgress(done: 1, total: 4))
    }

    @Test func windowProgressCountsDaysInTheWindow() {
        let weekly = make(.weekly, target: 3, done: [ago(0), ago(2), ago(6), ago(7)])
        #expect(engine.windowProgress(weekly, on: monday) == WindowProgress(done: 3, target: 3))

        let monthly = make(.monthly, target: 4, done: [ago(1), ago(29), ago(30)])
        #expect(engine.windowProgress(monthly, on: monday) == WindowProgress(done: 2, target: 4))
    }

    @Test func windowProgressIsNilWithoutWindow() {
        #expect(engine.windowProgress(make(.daily), on: monday) == nil)
        #expect(engine.windowProgress(make(.weekdays, weekdays: [1]), on: monday) == nil)
        #expect(engine.windowProgress(make(.monthDay, monthDay: 1), on: monday) == nil)
    }

    @Test func windowCountsAtMostOnePerDay() {
        // Stand 3 vom früheren täglichen Rhythmus: für pro Woche zählt der Tag einmal.
        let habit = make(.weekly, target: 2, counts: [(ago(1), 3)])
        #expect(engine.windowProgress(habit, on: monday) == WindowProgress(done: 1, target: 2))
        #expect(engine.status(habit, on: monday) == .red)
    }

    // MARK: Status täglich (3.5)

    @Test func dailyReachedYesterdayAndNotTodayIsGreen() {
        // Pflicht: Täglich, gestern erreicht, heute noch nicht: grün.
        #expect(engine.status(make(.daily, done: [ago(1)]), on: monday) == .green)
    }

    @Test func dailyMissedYesterdayAndNotTodayIsRed() {
        // Pflicht: Täglich, gestern verpasst, heute noch nicht: rot.
        #expect(engine.status(make(.daily, done: [ago(2)]), on: monday) == .red)
        #expect(engine.status(make(.daily), on: monday) == .red)
    }

    @Test func dailyReachedTodayIsGreenEvenIfYesterdayWasMissed() {
        #expect(engine.status(make(.daily, done: [monday]), on: monday) == .green)
    }

    @Test func dailyNeedsTheFullTargetNotJustSomeProgress() {
        let partialYesterday = make(.daily, target: 3, counts: [(ago(1), 2)])
        #expect(engine.status(partialYesterday, on: monday) == .red)
        let fullYesterday = make(.daily, target: 3, counts: [(ago(1), 3)])
        #expect(engine.status(fullYesterday, on: monday) == .green)
        let partialToday = make(.daily, target: 3, counts: [(monday, 2)])
        #expect(engine.status(partialToday, on: monday) == .red)
    }

    @Test func dailyCreatedTodayIsGreen() {
        #expect(engine.status(make(.daily, created: monday), on: monday) == .green)
    }

    @Test func dailyCreatedYesterdayAndMissedIsRed() {
        let created = make(.daily, created: ago(1))
        #expect(engine.status(created, on: monday) == .red)
        #expect(engine.status(make(.daily, created: ago(1), done: [ago(1)]), on: monday) == .green)
    }

    // MARK: Status pro Woche (3.5)

    @Test func weeklyDoneOnFridayAndTodayMondayIsGreen() {
        // Pflicht: 1x pro Woche, erledigt Freitag, heute Montag: grün.
        let friday = date(2026, 10, 9)
        #expect(engine.status(make(.weekly, done: [friday]), on: monday) == .green)
    }

    @Test func weeklyDoneFiveDaysAgoIsYellow() {
        // Pflicht: 1x pro Woche, erledigt vor 5 Tagen: gelb (fällt in 2 Tagen raus).
        #expect(engine.status(make(.weekly, done: [ago(5)]), on: monday) == .yellow)
    }

    @Test func weeklyDoneSevenDaysAgoIsRed() {
        // Pflicht: 1x pro Woche, erledigt vor 7 Tagen: rot.
        #expect(engine.status(make(.weekly, done: [ago(7)]), on: monday) == .red)
    }

    @Test func weeklyBoundariesOfTheWindow() {
        let expected: [(daysAgo: Int, status: HabitStatus)] = [
            (0, .green), (1, .green), (2, .green), (3, .green), (4, .green),
            (5, .yellow), (6, .yellow), (7, .red), (8, .red),
        ]
        for (daysAgo, status) in expected {
            #expect(engine.status(make(.weekly, done: [ago(daysAgo)]), on: monday) == status, "vor \(daysAgo) Tagen")
        }
    }

    @Test func weeklyIsYellowWhenOnlyPartOfTheGoalWouldExpire() {
        // 2x pro Woche: eine Erledigung vor 5 Tagen fällt raus, danach bliebe nur eine.
        #expect(engine.status(make(.weekly, target: 2, done: [ago(5), ago(1)]), on: monday) == .yellow)
        #expect(engine.status(make(.weekly, target: 2, done: [ago(3), ago(1)]), on: monday) == .green)
    }

    @Test func weeklyGoalNotMetIsRed() {
        #expect(engine.status(make(.weekly, target: 3, done: [ago(2)]), on: monday) == .red)
    }

    @Test func weeklyDoneTodayIsGreen() {
        #expect(engine.status(make(.weekly, done: [monday]), on: monday) == .green)
    }

    // MARK: Status pro Monat (3.5)

    @Test func monthlyDone26DaysAgoIsYellow() {
        // Pflicht: 1x pro Monat, erledigt vor 26 Tagen: gelb.
        #expect(engine.status(make(.monthly, done: [ago(26)]), on: monday) == .yellow)
    }

    @Test func monthlyBoundariesOfTheWindow() {
        let expected: [(daysAgo: Int, status: HabitStatus)] = [
            (0, .green), (10, .green), (24, .green),
            (25, .yellow), (26, .yellow), (29, .yellow),
            (30, .red), (45, .red),
        ]
        for (daysAgo, status) in expected {
            #expect(engine.status(make(.monthly, done: [ago(daysAgo)]), on: monday) == status, "vor \(daysAgo) Tagen")
        }
    }

    // MARK: Status neu angelegter Wochen und Monats Habits (3.5)

    @Test func newWeeklyHabitIsGreenOnDay3AndYellowOnDay6() {
        // Pflicht: Neu angelegter Wochen Habit, Tag 3: grün; Tag 6 ohne Erledigung: gelb.
        let created = monday // Tag 1
        let newHabit = make(.weekly, created: created)
        let day3 = engine.calendar.date(byAdding: .day, value: 2, to: created)!
        let day6 = engine.calendar.date(byAdding: .day, value: 5, to: created)!
        #expect(engine.status(newHabit, on: day3) == .green)
        #expect(engine.status(newHabit, on: day6) == .yellow)
    }

    @Test func newWeeklyHabitFollowsTheWholeFirstWindow() {
        let newHabit = make(.weekly, created: monday)
        let expected: [HabitStatus] = [.green, .green, .green, .green, .green, .yellow, .yellow, .red, .red]
        for (index, status) in expected.enumerated() {
            let day = engine.calendar.date(byAdding: .day, value: index, to: monday)!
            #expect(engine.status(newHabit, on: day) == status, "Tag \(index + 1)")
        }
    }

    @Test func newWeeklyHabitDoneInFirstWindowFollowsTheNormalRules() {
        // Erstellt und erledigt am Montag: Tag 1 bis 5 grün, Tag 6 und 7 gelb (fällt gleich raus), danach rot.
        let newHabit = make(.weekly, created: monday, done: [monday])
        let expected: [HabitStatus] = [.green, .green, .green, .green, .green, .yellow, .yellow, .red]
        for (index, status) in expected.enumerated() {
            let day = engine.calendar.date(byAdding: .day, value: index, to: monday)!
            #expect(engine.status(newHabit, on: day) == status, "Tag \(index + 1)")
        }
    }

    @Test func newMonthlyHabitHasNoRedInTheFirstWindow() {
        let newHabit = make(.monthly, created: monday)
        for index in 0..<30 {
            let day = engine.calendar.date(byAdding: .day, value: index, to: monday)!
            let expected: HabitStatus = index >= 25 ? .yellow : .green // letzte 5 Tage
            #expect(engine.status(newHabit, on: day) == expected, "Tag \(index + 1)")
        }
        let day31 = engine.calendar.date(byAdding: .day, value: 30, to: monday)!
        #expect(engine.status(newHabit, on: day31) == .red)
    }

    // MARK: Status feste Tage (3.5)

    @Test func mondayHabitOnTuesdayWithMissedMondayIsRed() {
        // Pflicht: Montag fest, heute Dienstag, Montag nicht abgehakt: rot.
        let habit = make(.weekdays, weekdays: [1], done: [ago(7)])
        #expect(engine.status(habit, on: tuesday) == .red)
    }

    @Test func mondayHabitOnTuesdayWithCheckedMondayIsGreen() {
        #expect(engine.status(make(.weekdays, weekdays: [1], done: [monday]), on: tuesday) == .green)
    }

    @Test func fixedWeekdaysUseTheLastDueDayEvenIfNotDueToday() {
        // Montag und Donnerstag: am Mittwoch zählt der Montag, am Freitag der Donnerstag.
        let thursday = date(2026, 10, 15)
        let friday = date(2026, 10, 16)
        let onlyMonday = make(.weekdays, weekdays: [1, 4], done: [monday])
        #expect(engine.status(onlyMonday, on: wednesday) == .green)
        #expect(engine.status(onlyMonday, on: friday) == .red) // Donnerstag verpasst
        #expect(engine.status(make(.weekdays, weekdays: [1, 4], done: [monday, thursday]), on: friday) == .green)
    }

    @Test func fixedWeekdayDueTodayAndUncheckedIsJudgedByTheLastDueDay() {
        // Heute Montag, noch nicht abgehakt: es zählt der Montag davor.
        #expect(engine.status(make(.weekdays, weekdays: [1], done: [ago(7)]), on: monday) == .green)
        #expect(engine.status(make(.weekdays, weekdays: [1]), on: monday) == .red)
    }

    @Test func fixedWeekdayCheckedTodayIsGreenEvenIfTheLastOneWasMissed() {
        #expect(engine.status(make(.weekdays, weekdays: [1], done: [monday]), on: monday) == .green)
    }

    @Test func fixedDaysHaveNoYellow() {
        let days = (0..<40).map { ago($0) }
        for day in days {
            let weekdays = engine.status(make(.weekdays, weekdays: [1, 4], done: [ago(3), ago(9)]), on: day)
            let monthDay = engine.status(make(.monthDay, monthDay: 15, done: [date(2026, 9, 15)]), on: day)
            #expect(weekdays != .yellow)
            #expect(monthDay != .yellow)
        }
    }

    @Test func fixedDaysIgnoreDueDaysBeforeCreation() {
        // Erstellt am Dienstag: der Montag davor war noch nicht fällig und kann nicht verpasst sein.
        let habit = make(.weekdays, weekdays: [1], created: tuesday)
        #expect(engine.status(habit, on: wednesday) == .green)
    }

    @Test func fixedDayDueOnTheCreationDayCanBeMissed() {
        let habit = make(.weekdays, weekdays: [1], created: monday)
        #expect(engine.status(habit, on: tuesday) == .red)
        #expect(engine.status(make(.weekdays, weekdays: [1], created: monday, done: [monday]), on: tuesday) == .green)
    }

    @Test func monthDayStatusUsesTheLastMonth() {
        // Jeden 1.: am 8. Oktober zählt der 1. Oktober.
        let today = date(2026, 10, 8)
        #expect(engine.status(make(.monthDay, monthDay: 1, done: [date(2026, 10, 1)]), on: today) == .green)
        #expect(engine.status(make(.monthDay, monthDay: 1, done: [date(2026, 9, 1)]), on: today) == .red)
    }

    @Test func monthDay31UsesTheLastDayOfShortMonthsForStatus() {
        // Am 1. März zählt der 28. Februar.
        let march1 = date(2026, 3, 1)
        #expect(engine.status(make(.monthDay, monthDay: 31, done: [date(2026, 2, 28)]), on: march1) == .green)
        #expect(engine.status(make(.monthDay, monthDay: 31, done: [date(2026, 1, 31)]), on: march1) == .red)
    }

    @Test func fixedHabitWithoutAnyDueDayIsGreen() {
        #expect(engine.status(make(.weekdays, weekdays: []), on: monday) == .green)
        #expect(engine.status(make(.monthDay, monthDay: nil), on: monday) == .green)
    }

    // MARK: Zeitraum und Übergänge

    @Test func statusIgnoresTimeOfDay() {
        let habit = make(.weekly, done: [date(2026, 10, 7, 23)])
        #expect(engine.status(habit, on: date(2026, 10, 12, 0)) == .yellow)
        #expect(engine.status(habit, on: date(2026, 10, 12, 23)) == .yellow)
    }

    @Test func windowsAcrossTheDaylightSavingChange() {
        // Zeitumstellung am 25. Oktober 2026: das Fenster zählt Kalendertage, keine 24 Stunden.
        let today = date(2026, 10, 27)
        #expect(engine.status(make(.weekly, done: [date(2026, 10, 23)]), on: today) == .green)  // vor 4 Tagen
        #expect(engine.status(make(.weekly, done: [date(2026, 10, 22)]), on: today) == .yellow) // vor 5 Tagen
        #expect(engine.status(make(.weekly, done: [date(2026, 10, 20)]), on: today) == .red)    // vor 7 Tagen
    }

    @Test func snapshotOfAHabitKeepsRhythmDetails() {
        let snapshot = make(.weekdays, weekdays: [2, 5])
        #expect(snapshot.weekdays == [2, 5])
        #expect(snapshot.monthDay == nil)
    }
}
