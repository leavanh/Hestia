import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var iconName: String
    /// Schlüssel aus der Palette (`HabitColor`).
    var colorKey: String
    var rhythm: Rhythm
    /// Pro Tag bei daily, pro Fenster bei weekly/monthly, sonst 1.
    var targetCount: Int
    /// 1 = Montag bis 7 = Sonntag.
    var weekdays: [Int]
    var monthDay: Int?
    /// Reihenfolge in der Heute Ansicht, bei Gleichstand gilt `createdAt`.
    var sortOrder: Int = 0
    var createdAt: Date
    var endedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \Completion.habit)
    var completions: [Completion] = []

    /// Gegenseite von `Pause.habits`.
    var pauses: [Pause] = []

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        colorKey: String,
        rhythm: Rhythm = .daily,
        targetCount: Int = 1,
        weekdays: [Int] = [],
        monthDay: Int? = nil,
        sortOrder: Int = 0,
        createdAt: Date = .now,
        endedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorKey = colorKey
        self.rhythm = rhythm
        self.targetCount = targetCount
        self.weekdays = weekdays
        self.monthDay = monthDay
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.endedAt = endedAt
    }
}

extension Habit {
    /// Reihenfolge der Heute Ansicht: nach `sortOrder`, bei Gleichstand nach `createdAt`.
    static func inTodayOrder(_ habits: [Habit]) -> [Habit] {
        habits.sorted { lhs, rhs in
            lhs.sortOrder != rhs.sortOrder ? lhs.sortOrder < rhs.sortOrder : lhs.createdAt < rhs.createdAt
        }
    }
}
