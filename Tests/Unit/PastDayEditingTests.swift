import Foundation
import SwiftData
import Testing
@testable import Habitus

/// Nachtragen an vergangenen Tagen (Spezifikation 5.4): Liste, Werte und Folgen für Heute.
@MainActor
struct PastDayEditingTests {
    let engine = HabitEngine()
    let container: ModelContainer
    let context: ModelContext
    let today: Date

    init() throws {
        container = try ModelContainer(
            for: Habit.self, Completion.self, Pause.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
        context.autosaveEnabled = false
        today = engine.startOfDay(.now)
    }

    func day(_ daysAgo: Int) -> Date {
        engine.calendar.date(byAdding: .day, value: -daysAgo, to: today)!
    }

    @discardableResult
    func makeHabit(
        _ name: String, rhythm: Rhythm = .daily, target: Int = 1, weekdays: [Int] = [], createdDaysAgo: Int = 30
    ) -> Habit {
        let habit = Habit(
            name: name, iconName: "drop.fill", colorKey: HabitColor.teal.rawValue,
            rhythm: rhythm, targetCount: target, weekdays: weekdays, createdAt: day(createdDaysAgo)
        )
        context.insert(habit)
        return habit
    }

    // MARK: Liste

    @Test func pastDayListsOnlyHabitsThatWereDueThen() {
        let lastWeek = day(7)
        let weekday = engine.weekday(of: lastWeek)
        let otherWeekday = weekday % 7 + 1

        makeHabit("Täglich")
        makeHabit("Genau dann", rhythm: .weekdays, weekdays: [weekday])
        makeHabit("Anderer Tag", rhythm: .weekdays, weekdays: [otherWeekday])
        makeHabit("Noch nicht da", createdDaysAgo: 3)

        let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        let names = Habit.dueInTodayOrder(habits, on: lastWeek, engine: engine).map(\.name)
        #expect(Set(names) == ["Täglich", "Genau dann"])
    }

    @Test func listOrdersOpenBeforeCompletedForThatDay() {
        let first = makeHabit("Erster")
        let second = makeHabit("Zweiter")
        first.setCount(1, on: day(5), engine: engine, in: context)

        let names = Habit.dueInTodayOrder([first, second], on: day(5), engine: engine).map(\.name)
        #expect(names == ["Zweiter", "Erster"])
        // Heute ist von der Erledigung an einem anderen Tag unberührt.
        #expect(Habit.dueInTodayOrder([first, second], on: today, engine: engine).map(\.name).first == "Erster")
    }

    // MARK: Nachtragen

    @Test func backfilledCompletionChangesOnlyThatDay() {
        let habit = makeHabit("Sport")
        habit.setCount(1, on: day(7), engine: engine, in: context)

        #expect(engine.count(on: day(7), in: habit.dayCounts) == 1)
        #expect(engine.count(on: day(6), in: habit.dayCounts) == 0)
        #expect(engine.count(on: today, in: habit.dayCounts) == 0)
    }

    @Test func backfillingChangesCalendarColorForThatDay() {
        let habits = [makeHabit("Wasser", target: 4), makeHabit("Lesen")]
        func progress() -> DayProgress { engine.dayProgress(habits.map(\.snapshot), on: day(7)) }

        #expect(progress() == DayProgress(done: 0, total: 5))
        #expect(MonthCalendar.fillOpacity(for: progress().fraction) == 0)

        habits[0].setCount(2, on: day(7), engine: engine, in: context)
        #expect(progress() == DayProgress(done: 2, total: 5))
        let partial = MonthCalendar.fillOpacity(for: progress().fraction)
        #expect(partial > 0)

        habits[0].setCount(4, on: day(7), engine: engine, in: context)
        habits[1].setCount(1, on: day(7), engine: engine, in: context)
        #expect(progress() == DayProgress(done: 5, total: 5))
        #expect(MonthCalendar.fillOpacity(for: progress().fraction) > partial)
    }

    @Test func backfillingYesterdayTurnsTodaysStatusAndDotsGreen() {
        let habit = makeHabit("Meditieren")
        #expect(engine.status(habit.snapshot, on: today) == .red)
        #expect(engine.weekDots(habit.snapshot, on: today)[5] == .fill(0))

        habit.setCount(1, on: day(1), engine: engine, in: context)
        #expect(engine.status(habit.snapshot, on: today) == .green)
        #expect(engine.weekDots(habit.snapshot, on: today)[5] == .fill(1))
    }

    @Test func backfillingAWeekAgoAffectsTheWindowStatusOfWeeklyHabits() {
        let habit = makeHabit("Joggen", rhythm: .weekly)
        #expect(engine.status(habit.snapshot, on: today) == .red)

        // Vor 5 Tagen: im Fenster, fällt aber in 2 Tagen heraus.
        habit.setCount(1, on: day(5), engine: engine, in: context)
        #expect(engine.status(habit.snapshot, on: today) == .yellow)
        #expect(engine.dayProgress([habit.snapshot], on: today) == DayProgress(done: 1, total: 1))

        // Vor 8 Tagen: schon aus dem Fenster von heute.
        habit.setCount(0, on: day(5), engine: engine, in: context)
        habit.setCount(1, on: day(8), engine: engine, in: context)
        #expect(engine.status(habit.snapshot, on: today) == .red)
    }

    @Test func uncheckingAPastDayRemovesTheCompletion() throws {
        let habit = makeHabit("Sport")
        habit.setCount(1, on: day(3), engine: engine, in: context)
        habit.setCount(0, on: day(3), engine: engine, in: context)
        #expect(try context.fetch(FetchDescriptor<Completion>()).isEmpty)
    }
}
