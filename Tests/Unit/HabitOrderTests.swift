import Foundation
import Testing
@testable import Habitus

/// Reihenfolge der Heute Liste (Spezifikation 5.2, 6): offene zuerst, dann erledigte.
struct HabitOrderTests {
    func habit(_ name: String, sortOrder: Int = 0, createdAt: Date) -> Habit {
        Habit(name: name, iconName: "drop.fill", colorKey: HabitColor.teal.rawValue, sortOrder: sortOrder, createdAt: createdAt)
    }

    let start = Date(timeIntervalSince1970: 1_790_000_000)

    @Test func ordersBySortOrder() {
        let habits = [
            habit("C", sortOrder: 2, createdAt: start),
            habit("A", sortOrder: 0, createdAt: start.addingTimeInterval(20)),
            habit("B", sortOrder: 1, createdAt: start.addingTimeInterval(10)),
        ]
        #expect(Habit.inTodayOrder(habits) { _ in false }.map(\.name) == ["A", "B", "C"])
    }

    @Test func tiesFallBackToCreationDate() {
        let habits = [
            habit("Spät", createdAt: start.addingTimeInterval(20)),
            habit("Früh", createdAt: start),
            habit("Mitte", createdAt: start.addingTimeInterval(10)),
        ]
        #expect(Habit.inTodayOrder(habits) { _ in false }.map(\.name) == ["Früh", "Mitte", "Spät"])
    }

    @Test func sortOrderWinsOverCreationDate() {
        let habits = [
            habit("Alt", sortOrder: 1, createdAt: start),
            habit("Neu", sortOrder: 0, createdAt: start.addingTimeInterval(100)),
        ]
        #expect(Habit.inTodayOrder(habits) { _ in false }.map(\.name) == ["Neu", "Alt"])
    }

    @Test func newHabitsStartWithSortOrderZero() {
        #expect(habit("A", createdAt: start).sortOrder == 0)
    }

    // MARK: Erledigte nach unten

    @Test func completedHabitMovesToTheEndAndBack() {
        let habits = [
            habit("A", sortOrder: 0, createdAt: start),
            habit("B", sortOrder: 1, createdAt: start),
            habit("C", sortOrder: 2, createdAt: start),
        ]
        #expect(Habit.inTodayOrder(habits) { $0.name == "A" }.map(\.name) == ["B", "C", "A"])
        #expect(Habit.inTodayOrder(habits) { _ in false }.map(\.name) == ["A", "B", "C"])
    }

    @Test func eachPartKeepsSortOrderThenCreationDate() {
        let habits = [
            habit("Erledigt 2", sortOrder: 1, createdAt: start),
            habit("Offen 2", sortOrder: 2, createdAt: start.addingTimeInterval(10)),
            habit("Erledigt 1", sortOrder: 0, createdAt: start.addingTimeInterval(20)),
            habit("Offen 1", sortOrder: 2, createdAt: start),
        ]
        let done: Set<String> = ["Erledigt 1", "Erledigt 2"]
        #expect(
            Habit.inTodayOrder(habits) { done.contains($0.name) }.map(\.name)
                == ["Offen 1", "Offen 2", "Erledigt 1", "Erledigt 2"]
        )
    }

    @Test func orderingDoesNotChangeSortOrder() {
        let habits = [habit("A", sortOrder: 0, createdAt: start), habit("B", sortOrder: 1, createdAt: start)]
        _ = Habit.inTodayOrder(habits) { $0.name == "A" }
        #expect(habits.map(\.sortOrder) == [0, 1])
    }
}
