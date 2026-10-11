import Foundation
import Testing
@testable import Habitus

/// Pausen und Beenden in der `HabitEngine` (Spezifikation 3.5, 3.7, 3.8, 3.9) mit festen Daten.
/// Heute ist Montag, der 12. Oktober 2026.
struct PauseEngineTests {
    let engine: HabitEngine = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return HabitEngine(calendar: calendar)
    }()

    func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        engine.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    var monday: Date { date(2026, 10, 12) }

    /// Der Tag im Oktober 2026.
    func october(_ day: Int) -> Date { date(2026, 10, day) }

    func pause(_ from: Int, _ to: Int) -> PauseRange {
        PauseRange(start: october(from), end: october(to))
    }

    func make(
        _ rhythm: Rhythm,
        target: Int = 1,
        weekdays: [Int] = [],
        created: Date? = nil,
        done: [Int] = [],
        pauses: [PauseRange] = [],
        endedAt: Date? = nil
    ) -> HabitSnapshot {
        HabitSnapshot(
            rhythm: rhythm,
            targetCount: target,
            weekdays: weekdays,
            createdAt: created ?? date(2026, 1, 1),
            counts: done.map { DayCount(day: engine.startOfDay(october($0)), count: 1) },
            pauses: pauses,
            endedAt: endedAt
        )
    }

    // MARK: Fälligkeit und Fortschritt

    @Test func pausedHabitIsNotDueOnPausedDaysIncludingBothEnds() {
        let habit = make(.daily, pauses: [pause(12, 14)])
        #expect(!engine.isPaused(habit, on: october(11)))
        for day in 12...14 {
            #expect(engine.isPaused(habit, on: october(day)))
            #expect(!engine.isDue(habit, on: october(day)))
        }
        #expect(engine.isDue(habit, on: october(15)))
        #expect(engine.isDue(habit, on: october(11)))
    }

    @Test func twoHabitsPausedForThreeDaysLeaveTheProgress() {
        let paused = [pause(12, 14)]
        let habits = [
            make(.daily, done: [12], pauses: paused),
            make(.weekly, pauses: paused),
            make(.daily, target: 3, done: [12]),
        ]
        for day in 12...14 {
            let progress = engine.dayProgress(habits, on: october(day))
            #expect(progress.total == 3, "Nur der unpausierte Habit zählt")
        }
        #expect(engine.dayProgress(habits, on: october(15)).total == 5)
    }

    @Test func pausedDaysDoNotCountEvenIfSomethingWasChecked() {
        let habit = make(.daily, done: [12], pauses: [pause(12, 12)])
        #expect(engine.dayProgress([habit], on: monday) == DayProgress(done: 0, total: 0))
    }

    // MARK: Fenster überspringen Pausentage

    @Test func windowSkipsPausedDays() {
        // Pro Woche 2x, erledigt am 5. und 7. Oktober, Pause vom 8. bis 10.
        let habit = make(.weekly, target: 2, done: [5, 7], pauses: [pause(8, 10)])
        // Ohne Pause reicht das Fenster vom 6. bis 12. Oktober und enthält nur den 7.
        #expect(engine.windowProgress(make(.weekly, target: 2, done: [5, 7]), on: monday) == WindowProgress(done: 1, target: 2))
        // Mit Pause sind es die letzten 7 nicht pausierten Tage: 12., 11., 7., 6., 5., 4., 3.
        #expect(engine.windowProgress(habit, on: monday) == WindowProgress(done: 2, target: 2))
    }

    @Test func pauseKeepsAWeeklyHabitGreenThatWouldOtherwiseFallOut() {
        // Erledigt am Mittwoch, 7. Oktober. Heute (12.) wäre er ohne Pause gelb: in 2 Tagen fällt er aus dem Fenster.
        let without = make(.weekly, done: [7])
        #expect(engine.status(without, on: monday) == .yellow)

        // Ohne die Pause vom 8. bis 10. hätte er das Fenster gesprengt. Mit Pause bleibt er grün.
        let with = make(.weekly, done: [7], pauses: [pause(8, 10)])
        #expect(engine.status(with, on: monday) == .green)
    }

    @Test func pauseKeepsAWeeklyHabitFromTurningRed() {
        // Erledigt am Montag, 5. Oktober: ohne Pause nach 7 Tagen rot.
        #expect(engine.status(make(.weekly, done: [5]), on: monday) == .red)
        #expect(engine.status(make(.weekly, done: [5], pauses: [pause(8, 10)]), on: monday) != .red)
    }

    @Test func monthlyWindowSkipsPausedDaysToo() {
        // Erledigt am 11. September (31 Tage vor dem 12. Oktober): ohne Pause rot.
        let done = [DayCount(day: engine.startOfDay(date(2026, 9, 11)), count: 1)]
        let plain = HabitSnapshot(rhythm: .monthly, targetCount: 1, createdAt: date(2026, 1, 1), counts: done)
        #expect(engine.status(plain, on: monday) == .red)

        var paused = plain
        paused.pauses = [PauseRange(start: date(2026, 9, 20), end: date(2026, 9, 29))]
        #expect(engine.status(paused, on: monday) != .red, "10 Pausentage verschieben das Fenster")
    }

    @Test func firstWindowOfANewHabitCountsOnlyUnpausedDays() {
        // Erstellt am 5. Oktober. Am 12. ist das erste Fenster ohne Pause vorbei (rot).
        let created = october(5)
        #expect(engine.status(make(.weekly, created: created), on: monday) == .red)
        // Pause vom 6. bis 8.: erst 4 Tage (5., 9., 10., 11.) des ersten Fensters sind gezählt, also noch kein Rot.
        #expect(engine.status(make(.weekly, created: created, pauses: [pause(6, 8)]), on: monday) == .green)
    }

    @Test func dailyUsesTheLastUnpausedDayBeforeToday() {
        // Freitag 9. erreicht, Samstag 10. und Sonntag 11. pausiert, heute noch nicht: grün.
        let habit = make(.daily, done: [9], pauses: [pause(10, 11)])
        #expect(engine.status(habit, on: monday) == .green)
        // Ohne Pause wäre der Sonntag verpasst: rot.
        #expect(engine.status(make(.daily, done: [9]), on: monday) == .red)
    }

    @Test func fixedWeekdaySkipsPausedDueDays() {
        // Montags (1), heute Dienstag 13. Der Montag 12. ist pausiert, der Montag davor (5.) war erledigt.
        let tuesday = october(13)
        let habit = make(.weekdays, weekdays: [1], done: [5], pauses: [pause(12, 12)])
        #expect(engine.status(habit, on: tuesday) == .green)
        // Ohne Pause: der Montag 12. nicht abgehakt, rot.
        #expect(engine.status(make(.weekdays, weekdays: [1], done: [5]), on: tuesday) == .red)
    }

    // MARK: 7 Tage Punkte

    @Test func pausedDaysAreDashesInTheDots() {
        let habit = make(.daily, done: [6, 12], pauses: [pause(10, 11)])
        let dots = engine.weekDots(habit, on: monday)
        #expect(dots == [.fill(1), .fill(0), .fill(0), .fill(0), .paused, .paused, .fill(1)])
    }

    @Test func shownDayCanBePausedInTheDots() {
        let habit = make(.daily, pauses: [pause(12, 12)])
        #expect(engine.weekDots(habit, on: monday).last == .paused)
        #expect(engine.weekDots(habit, on: monday).count == 7)
    }

    @Test func daysBeforeCreationStayEmptyOutlinesEvenIfPaused() {
        let habit = make(.daily, created: october(11), pauses: [pause(6, 11)])
        let dots = engine.weekDots(habit, on: monday)
        #expect(dots[0...4].allSatisfy { $0 == .fill(0) })
        #expect(dots[5] == .paused)
    }

    // MARK: Statistik

    @Test func aPauseDoesNotBreakTheStreak() {
        // Täglich: 7., 8. erledigt, 9. und 10. pausiert, 11. und 12. erledigt.
        let habit = make(.daily, created: october(7), done: [7, 8, 11, 12], pauses: [pause(9, 10)])
        let stats = engine.statistics(habit, on: monday)
        #expect(stats.currentStreak == 4)
        #expect(stats.longestStreak == 4)

        // Ohne Pause ist der Streak nach den zwei verpassten Tagen nur 2 lang.
        let plain = make(.daily, created: october(7), done: [7, 8, 11, 12])
        #expect(engine.statistics(plain, on: monday).currentStreak == 2)
        #expect(engine.statistics(plain, on: monday).longestStreak == 2)
    }

    @Test func pausedDaysDoNotCountAsDaysInTheStreak() {
        // Nur die Pausentage dazwischen: sie zählen nicht mit.
        let habit = make(.daily, created: october(8), done: [8, 12], pauses: [pause(9, 11)])
        #expect(engine.currentStreak(habit, on: monday) == 2)
    }

    @Test func rateLeavesOutPausedDays() throws {
        // Erstellt am 5. Oktober. Erledigt am 5., 6., 7. Pause 8. und 9. Verpasst 10. und 11. Heute (12.) offen.
        let habit = make(.daily, created: october(5), done: [5, 6, 7], pauses: [pause(8, 9)])
        let stats = engine.statistics(habit, on: monday)
        #expect(stats.currentStreak == 0)
        let rate = try #require(stats.rate30)
        #expect(rate == 3.0 / 5.0)
        #expect(stats.ratePercent == 60)
    }

    @Test func allDaysPausedMeansNoRate() {
        let habit = make(.daily, created: october(10), pauses: [pause(10, 12)])
        let stats = engine.statistics(habit, on: monday)
        #expect(stats.rate30 == nil)
        #expect(stats.currentStreak == 0)
    }

    @Test func weeklyStreakContinuesThroughAPause() {
        // Pro Woche 1x, erledigt am 1. Oktober, Pause vom 3. bis 10.: am 12. ist das Fenster noch erfüllt.
        let habit = make(.weekly, created: date(2026, 9, 1), done: [1], pauses: [pause(3, 10)])
        #expect(engine.status(habit, on: monday) != .red)
        #expect(engine.currentStreak(habit, on: monday) > 0)
    }

    // MARK: Beenden (3.9)

    @Test func endedHabitIsNotDueFromTheEndDayOn() {
        let habit = make(.daily, endedAt: october(10))
        #expect(engine.isDue(habit, on: october(9)), "Davor bleibt die Historie sichtbar")
        #expect(!engine.isDue(habit, on: october(10)))
        #expect(!engine.isDue(habit, on: october(11)))
        #expect(engine.dayProgress([habit], on: monday).total == 0)
    }

    @Test func statisticsStopAtTheEndDay() {
        // Täglich seit 5. Oktober erledigt, beendet am 9.: danach geht nichts mehr in Streak und Quote ein.
        let habit = make(.daily, created: october(5), done: [5, 6, 7, 8], endedAt: october(9))
        let stats = engine.statistics(habit, on: monday)
        #expect(stats.currentStreak == 4)
        #expect(stats.longestStreak == 4)
        #expect(stats.rate30 == 1)
    }

    // MARK: Kalender

    @Test func calendarDayIsGreyOnlyIfEveryExistingHabitIsPaused() {
        let a = make(.daily, pauses: [pause(10, 11)])
        let b = make(.daily, pauses: [pause(11, 12)])
        #expect(!engine.isEveryHabitPaused([a, b], on: october(10)))
        #expect(engine.isEveryHabitPaused([a, b], on: october(11)))
        #expect(!engine.isEveryHabitPaused([a, b], on: october(12)))
        #expect(!engine.isEveryHabitPaused([], on: october(11)), "Ohne Habits gibt es nichts zu pausieren")
    }

    @Test func calendarIgnoresHabitsThatDoNotExistYet() {
        let old = make(.daily, pauses: [pause(10, 12)])
        let new = make(.daily, created: october(12))
        #expect(engine.isEveryHabitPaused([old, new], on: october(11)), "Der neue Habit gibt es am 11. noch nicht")
        #expect(!engine.isEveryHabitPaused([old, new], on: october(12)))
    }

    // MARK: Pausen verwalten (3.8, 5.5)

    @Test func phaseOfAPause() {
        #expect(engine.phase(of: pause(14, 16), today: monday) == .upcoming)
        #expect(engine.phase(of: pause(12, 14), today: monday) == .running)
        #expect(engine.phase(of: pause(10, 12), today: monday) == .running)
        #expect(engine.phase(of: pause(8, 11), today: monday) == .over)
    }

    @Test func endingARunningPauseEarlySetsTheEndToYesterday() {
        let shortened = engine.endedEarly(pause(10, 14), today: monday)
        #expect(shortened == PauseRange(start: october(10), end: engine.startOfDay(october(11))))
        #expect(engine.phase(of: shortened!, today: monday) == .over)
    }

    @Test func aPauseThatWouldHaveNoDayLeftIsGone() {
        #expect(engine.endedEarly(pause(12, 14), today: monday) == nil, "Heute begonnen")
        #expect(engine.endedEarly(pause(14, 16), today: monday) == nil, "Geplant")
    }

    @Test func pausesOverlapIfTheyShareADay() {
        #expect(engine.overlaps(pause(10, 12), pause(12, 14)))
        #expect(engine.overlaps(pause(10, 14), pause(11, 12)))
        #expect(engine.overlaps(pause(12, 12), pause(12, 12)))
        #expect(!engine.overlaps(pause(10, 11), pause(12, 14)))
        #expect(!engine.overlaps(pause(14, 15), pause(10, 13)))
    }

    // MARK: Reihenfolge (5.2)

    @Test func openHabitsTakeTheFrontSlotsAndDoneFollow() {
        // Alle: A B C D. Heute sichtbar offen in neuer Reihenfolge C, A. Erledigt D. B ist nicht fällig.
        let merged = HabitOrder.merged(all: ["A", "B", "C", "D"], open: ["C", "A"], done: ["D"])
        #expect(merged == ["C", "B", "A", "D"])
    }

    @Test func orderWithoutHiddenHabitsIsOpenThenDone() {
        #expect(HabitOrder.merged(all: [1, 2, 3], open: [3, 2], done: [1]) == [3, 2, 1])
        #expect(HabitOrder.merged(all: [1, 2, 3], open: [1, 2, 3], done: []) == [1, 2, 3])
    }

    @Test func doneHabitsKeepTheirOrderAfterMoving() {
        // Visible: 1 (done), 2, 3 offen. Nach dem Tauschen von 2 und 3 bleiben die erledigten dahinter.
        let merged = HabitOrder.merged(all: [1, 2, 3, 4], open: [3, 2, 4], done: [1])
        #expect(merged == [3, 2, 4, 1])
    }
}
