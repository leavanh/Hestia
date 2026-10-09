import Foundation
import Testing
@testable import Habitus

/// Reihenfolge der Heute Liste (Spezifikation 5.2, 6).
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
        #expect(Habit.inTodayOrder(habits).map(\.name) == ["A", "B", "C"])
    }

    @Test func tiesFallBackToCreationDate() {
        let habits = [
            habit("Spät", createdAt: start.addingTimeInterval(20)),
            habit("Früh", createdAt: start),
            habit("Mitte", createdAt: start.addingTimeInterval(10)),
        ]
        #expect(Habit.inTodayOrder(habits).map(\.name) == ["Früh", "Mitte", "Spät"])
    }

    @Test func sortOrderWinsOverCreationDate() {
        let habits = [
            habit("Alt", sortOrder: 1, createdAt: start),
            habit("Neu", sortOrder: 0, createdAt: start.addingTimeInterval(100)),
        ]
        #expect(Habit.inTodayOrder(habits).map(\.name) == ["Neu", "Alt"])
    }

    @Test func newHabitsStartWithSortOrderZero() {
        #expect(habit("A", createdAt: start).sortOrder == 0)
    }
}
