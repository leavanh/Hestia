import Foundation
import SwiftData
import Testing
@testable import Habitus

@MainActor
struct CompletionStorageTests {
    let engine = HabitEngine()
    let container: ModelContainer
    let context: ModelContext

    init() throws {
        container = try ModelContainer(
            for: Habit.self, Completion.self, Pause.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
    }

    func makeHabit() -> Habit {
        let habit = Habit(name: "Sport", iconName: "figure.run", colorKey: HabitColor.orange.rawValue)
        context.insert(habit)
        return habit
    }

    @Test func checkingStoresOneCompletion() throws {
        let habit = makeHabit()
        habit.setCount(1, on: .now, engine: engine, in: context)
        try context.save()

        let completions = try context.fetch(FetchDescriptor<Completion>())
        #expect(completions.count == 1)
        #expect(completions.first?.day == engine.startOfDay(.now))
        #expect(engine.count(on: .now, in: habit.dayCounts) == 1)
    }

    @Test func uncheckingDeletesCompletion() throws {
        let habit = makeHabit()
        habit.setCount(1, on: .now, engine: engine, in: context)
        try context.save()
        habit.setCount(0, on: .now, engine: engine, in: context)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Completion>()).isEmpty)
        #expect(engine.count(on: .now, in: habit.dayCounts) == 0)
    }

    @Test func atMostOneCompletionPerDay() throws {
        let habit = makeHabit()
        habit.setCount(1, on: .now, engine: engine, in: context)
        habit.setCount(1, on: .now, engine: engine, in: context)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Completion>()).count == 1)
    }

    @Test func newHabitIsDailyOnce() {
        let habit = makeHabit()
        #expect(habit.rhythm == .daily)
        #expect(habit.targetCount == 1)
        #expect(habit.sortOrder == 0)
        #expect(habit.endedAt == nil)
    }
}
