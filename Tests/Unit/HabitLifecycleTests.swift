import Foundation
import SwiftData
import Testing
@testable import Hestia

/// Beenden, Wieder aktivieren, Löschen, Pausen beenden und Sortieren gegen eine echte (In Memory) Datenbank
/// (Spezifikation 3.8, 3.9, 5.2).
@MainActor
struct HabitLifecycleTests {
    let engine: HabitEngine = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return HabitEngine(calendar: calendar)
    }()
    let container: ModelContainer
    let context: ModelContext

    init() throws {
        container = try ModelContainer(
            for: Habit.self, Completion.self, Pause.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
        context.autosaveEnabled = false
    }

    func date(_ day: Int) -> Date {
        engine.calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: 12))!
    }

    func makeHabit(_ name: String, sortOrder: Int = 0, createdAt: Date? = nil) -> Habit {
        let habit = Habit(
            name: name, iconName: "drop.fill", colorKey: HabitColor.teal.rawValue,
            sortOrder: sortOrder, createdAt: createdAt ?? date(1)
        )
        context.insert(habit)
        return habit
    }

    @discardableResult
    func makePause(_ from: Int, _ to: Int, habits: [Habit]) throws -> Pause {
        let pause = Pause(startDay: engine.startOfDay(date(from)), endDay: engine.startOfDay(date(to)))
        context.insert(pause)
        pause.habits = habits
        try context.save()
        return pause
    }

    // MARK: Snapshot

    @Test func pausesCanStartInThePastAndReachBackOverCompletedDays() throws {
        let habit = makeHabit("Sport")
        habit.setCount(1, on: date(7), engine: engine, in: context)
        try makePause(6, 9, habits: [habit])

        let snapshot = habit.snapshot
        for day in 6...9 {
            #expect(engine.isPaused(snapshot, on: date(day)))
            #expect(!engine.isDue(snapshot, on: date(day)))
        }
        #expect(engine.isDue(snapshot, on: date(10)))
    }

    @Test func snapshotCarriesPausesAndEndDay() throws {
        let habit = makeHabit("Sport")
        try makePause(8, 10, habits: [habit])
        habit.end(on: date(12), engine: engine, in: context)

        let snapshot = habit.snapshot
        #expect(snapshot.pauses == [PauseRange(start: engine.startOfDay(date(8)), end: engine.startOfDay(date(10)))])
        #expect(snapshot.endedAt == engine.startOfDay(date(12)))
        #expect(engine.isPaused(snapshot, on: date(9)))
        #expect(!engine.isDue(snapshot, on: date(12)))
    }

    // MARK: Beenden mit Historie behalten

    @Test func endingKeepsTheHistory() throws {
        let habit = makeHabit("Lesen")
        habit.setCount(1, on: date(10), engine: engine, in: context)

        habit.end(on: date(12), engine: engine, in: context)
        #expect(habit.endedAt == engine.startOfDay(date(12)))
        #expect(!engine.isDue(habit.snapshot, on: date(12)))
        #expect(engine.isDue(habit.snapshot, on: date(11)), "Die Historie davor bleibt")
        #expect(engine.count(on: date(10), in: habit.dayCounts) == 1)
        #expect(try context.fetchCount(FetchDescriptor<Habit>()) == 1)
    }

    // MARK: Beenden mit Historie löschen

    @Test func deletingRemovesHabitAndItsCompletions() throws {
        let habit = makeHabit("Lesen")
        let other = makeHabit("Sport")
        habit.setCount(1, on: date(10), engine: engine, in: context)
        habit.setCount(1, on: date(11), engine: engine, in: context)
        other.setCount(1, on: date(10), engine: engine, in: context)

        habit.deleteWithHistory(in: context)

        let habits = try context.fetch(FetchDescriptor<Habit>())
        #expect(habits.map(\.name) == ["Sport"])
        #expect(try context.fetchCount(FetchDescriptor<Completion>()) == 1, "Nur die Erledigung des anderen bleibt")
    }

    @Test func deletingRemovesTheHabitFromPausesAndDropsEmptyPauses() throws {
        let gone = makeHabit("Lesen")
        let stays = makeHabit("Sport")
        let shared = try makePause(8, 10, habits: [gone, stays])
        try makePause(11, 12, habits: [gone])

        gone.deleteWithHistory(in: context)

        let pauses = try context.fetch(FetchDescriptor<Pause>())
        #expect(pauses.count == 1, "Die Pause nur mit dem gelöschten Habit ist weg")
        #expect(pauses.first?.id == shared.id)
        #expect(pauses.first?.habits.map(\.name) == ["Sport"])
        #expect(stays.pauses.count == 1)
    }

    // MARK: Pausen beenden

    @Test func endingARunningPauseSetsItsEndToYesterday() throws {
        let habit = makeHabit("Sport")
        let pause = try makePause(8, 14, habits: [habit])

        pause.endEarly(today: date(12), engine: engine, in: context)

        #expect(pause.endDay == engine.startOfDay(date(11)))
        #expect(engine.isDue(habit.snapshot, on: date(12)), "Heute zählt der Habit wieder")
        #expect(!engine.isDue(habit.snapshot, on: date(11)))
    }

    @Test func endingAPauseThatStartsTodayOrLaterRemovesIt() throws {
        let habit = makeHabit("Sport")
        let startsToday = try makePause(12, 14, habits: [habit])
        let upcoming = try makePause(15, 16, habits: [habit])

        startsToday.endEarly(today: date(12), engine: engine, in: context)
        upcoming.endEarly(today: date(12), engine: engine, in: context)

        #expect(try context.fetchCount(FetchDescriptor<Pause>()) == 0)
        #expect(habit.pauses.isEmpty)
    }

    // MARK: Pause für einen Habit beenden (Phase 18.5)

    @Test func endingTheOwnRunningPauseSetsItsEndToYesterday() throws {
        let habit = makeHabit("Sport")
        let pause = try makePause(8, 14, habits: [habit])

        habit.endRunningPause(today: date(12), engine: engine, in: context)

        #expect(pause.endDay == engine.startOfDay(date(11)))
        #expect(!engine.isPaused(habit.snapshot, on: date(12)))
        #expect(engine.isPaused(habit.snapshot, on: date(11)))
    }

    @Test func endingASharedPauseKeepsItForTheOthers() throws {
        let sport = makeHabit("Sport")
        let reading = makeHabit("Lesen")
        let shared = try makePause(8, 14, habits: [sport, reading])

        sport.endRunningPause(today: date(12), engine: engine, in: context)

        #expect(shared.endDay == engine.startOfDay(date(14)))
        #expect(shared.habits.map(\.name) == ["Lesen"])
        #expect(engine.isPaused(reading.snapshot, on: date(13)))
        #expect(!engine.isPaused(sport.snapshot, on: date(12)))
        #expect(engine.isPaused(sport.snapshot, on: date(8)), "Die Tage bis gestern bleiben pausiert")
        #expect(engine.isPaused(sport.snapshot, on: date(11)))
        #expect(try context.fetchCount(FetchDescriptor<Pause>()) == 2)
    }

    @Test func endingASharedPauseThatStartedTodayDropsItForThisHabit() throws {
        let sport = makeHabit("Sport")
        let reading = makeHabit("Lesen")
        let shared = try makePause(12, 14, habits: [sport, reading])
        let upcoming = try makePause(20, 21, habits: [sport])

        sport.endRunningPause(today: date(12), engine: engine, in: context)

        #expect(shared.habits.map(\.name) == ["Lesen"])
        #expect(sport.pauses.map(\.id) == [upcoming.id], "Geplante Pausen bleiben")
    }

    // MARK: Sortieren

    @Test func movingADoneHabitBeforeAnOpenOneStoresItInFront() throws {
        let a = makeHabit("A", sortOrder: 0, createdAt: date(1))
        let b = makeHabit("B", sortOrder: 1, createdAt: date(2))
        let c = makeHabit("C", sortOrder: 2, createdAt: date(3))
        let today = date(12)
        c.setCount(1, on: today, engine: engine, in: context)

        // Im Sortiermodus stehen alle in gespeicherter Reihenfolge, der erledigte C wird vor A geschoben.
        Habit.saveOrder(all: [a, b, c], shown: [c, a, b], in: context)

        #expect([c, a, b].map(\.sortOrder) == [0, 1, 2])
        // In Heute steht er trotzdem weiter unten, die neue Reihenfolge gilt aber für alle Tage.
        #expect(Habit.mainInTodayOrder([a, b, c], on: today, engine: engine).map(\.name) == ["A", "B", "C"])
        #expect(Habit.mainInTodayOrder([a, b, c], on: date(11), engine: engine).map(\.name) == ["C", "A", "B"])
    }

    @Test func pausedAndNotDueHabitsKeepTheirRelativeSlotsWhenNotMoved() throws {
        let a = makeHabit("A", sortOrder: 0, createdAt: date(1))
        let paused = makeHabit("Pausiert", sortOrder: 1, createdAt: date(2))
        let monday = Habit(
            name: "Montags", iconName: "drop.fill", colorKey: HabitColor.teal.rawValue,
            rhythm: .weekdays, weekdays: [1], sortOrder: 2, createdAt: date(3)
        )
        context.insert(monday)
        let d = makeHabit("D", sortOrder: 3, createdAt: date(4))
        try makePause(14, 15, habits: [paused])

        // Nur D wird nach vorn geschoben. Pausiert und Montags behalten ihre Reihenfolge zueinander.
        Habit.saveOrder(all: [a, paused, monday, d], shown: [d, a, paused, monday], in: context)

        let stored = try context.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)]))
        #expect(stored.map(\.name) == ["D", "A", "Pausiert", "Montags"])
        #expect(stored.map(\.sortOrder) == [0, 1, 2, 3])
    }

    @Test func endedHabitsKeepTheirSlotWhenSorting() throws {
        let a = makeHabit("A", sortOrder: 0, createdAt: date(1))
        let ended = makeHabit("Beendet", sortOrder: 1, createdAt: date(2))
        let c = makeHabit("C", sortOrder: 2, createdAt: date(3))
        ended.end(on: date(12), engine: engine, in: context)

        Habit.saveOrder(all: [a, ended, c], shown: [c, a], in: context)

        #expect([c, ended, a].map(\.sortOrder) == [0, 1, 2])
    }

    @Test func todayListFollowsTheNewOrderInEveryGroup() throws {
        let a = makeHabit("A", sortOrder: 0, createdAt: date(1))
        let b = makeHabit("B", sortOrder: 1, createdAt: date(2))
        let c = makeHabit("C", sortOrder: 2, createdAt: date(3))
        let p1 = makeHabit("P1", sortOrder: 3, createdAt: date(4))
        let p2 = makeHabit("P2", sortOrder: 4, createdAt: date(5))
        let all = [a, b, c, p1, p2]
        let today = date(12)
        try makePause(12, 14, habits: [p1, p2])
        a.setCount(1, on: today, engine: engine, in: context)

        // Neue Reihenfolge: P2, C, A, P1, B.
        Habit.saveOrder(all: all, shown: [p2, c, a, p1, b], in: context)

        // Offen, erledigt, pausiert: jede Gruppe folgt der neuen Reihenfolge.
        #expect(Habit.mainInTodayOrder(all, on: today, engine: engine).map(\.name) == ["C", "B", "A"])
        #expect(Habit.otherInSavedOrder(all, on: today, engine: engine).map(\.name) == ["P2", "P1"])
    }

    @Test func ordersTiesByCreationDateWhenSavingFromDefaultSortOrders() throws {
        // Frisch angelegte Habits haben alle sortOrder 0.
        let first = makeHabit("Früh", createdAt: date(1))
        let second = makeHabit("Spät", createdAt: date(2))
        Habit.saveOrder(all: [second, first], shown: [second, first], in: context)
        #expect(second.sortOrder == 0)
        #expect(first.sortOrder == 1)
    }

    @Test func pausedHabitsAreNotDueButListedAfterTheOthers() throws {
        let paused = makeHabit("Pausiert", sortOrder: 0)
        let ended = makeHabit("Beendet", sortOrder: 1)
        let active = makeHabit("Aktiv", sortOrder: 2)
        try makePause(12, 14, habits: [paused])
        ended.end(on: date(12), engine: engine, in: context)
        let all = [paused, ended, active]

        // Nicht fällig, also nicht im Fortschritt, aber in Weitere.
        #expect(Habit.mainInTodayOrder(all, on: date(12), engine: engine).map(\.name) == ["Aktiv"])
        #expect(Habit.otherInSavedOrder(all, on: date(12), engine: engine).map(\.name) == ["Pausiert"])
        #expect(engine.dayProgress(all.map(\.snapshot), on: date(12)).total == 1)
        // Am Tag davor war noch keiner pausiert, der Beendete war noch da.
        #expect(Habit.mainInTodayOrder(all, on: date(11), engine: engine).count == 3)
        #expect(Habit.otherInSavedOrder(all, on: date(11), engine: engine).isEmpty)
    }

    @Test func otherListKeepsTheSavedOrderWithPausedHabitsAtTheEnd() throws {
        let second = makeHabit("Zweiter", sortOrder: 1)
        let first = makeHabit("Erster", sortOrder: 0)
        // Nur montags (12. Oktober 2026 ist ein Montag), pausiert vom 12. bis 14.
        let monday = Habit(
            name: "Montags", iconName: "drop.fill", colorKey: HabitColor.teal.rawValue,
            rhythm: .weekdays, weekdays: [1], sortOrder: 2, createdAt: date(1)
        )
        // Nur dienstags, nicht pausiert: steht am Montag in Weitere, vor den pausierten.
        let tuesday = Habit(
            name: "Dienstags", iconName: "drop.fill", colorKey: HabitColor.teal.rawValue,
            rhythm: .weekdays, weekdays: [2], sortOrder: 3, createdAt: date(1)
        )
        context.insert(monday)
        context.insert(tuesday)
        try makePause(12, 14, habits: [second, first, monday])
        let all = [second, first, monday, tuesday]

        #expect(Habit.otherInSavedOrder(all, on: date(12), engine: engine).map(\.name)
            == ["Dienstags", "Erster", "Zweiter", "Montags"])
        // Dienstag: der Montags Habit ist pausiert und steht deshalb auch dort am Ende von Weitere.
        #expect(Habit.otherInSavedOrder(all, on: date(13), engine: engine).map(\.name)
            == ["Erster", "Zweiter", "Montags"])
        #expect(Habit.mainInTodayOrder(all, on: date(13), engine: engine).map(\.name) == ["Dienstags"])
    }
}
