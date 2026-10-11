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
    /// Reihenfolge der Heute Ansicht: offene Habits zuerst, dann die erledigten. Innerhalb beider Teile
    /// nach `sortOrder`, bei Gleichstand nach `createdAt`. `sortOrder` selbst bleibt unverändert.
    static func inTodayOrder(_ habits: [Habit], isCompleted: (Habit) -> Bool) -> [Habit] {
        let done = Dictionary(uniqueKeysWithValues: habits.map { ($0.id, isCompleted($0)) })
        return habits.sorted { lhs, rhs in
            if done[lhs.id] != done[rhs.id] { return done[rhs.id] == true }
            return lhs.sortOrder != rhs.sortOrder ? lhs.sortOrder < rhs.sortOrder : lhs.createdAt < rhs.createdAt
        }
    }

    /// Die Habits, die an `day` in der Liste erscheinen (Spezifikation 3.2), in der Reihenfolge von Heute.
    /// Heute, der Kalender und das Sheet "Tag bearbeiten" zeigen damit dieselbe Liste.
    static func dueInTodayOrder(_ habits: [Habit], on day: Date, engine: HabitEngine) -> [Habit] {
        inTodayOrder(habits.filter { $0.isAlive && engine.isDue($0.snapshot, on: day) }) {
            engine.isCompleted($0.snapshot, on: day)
        }
    }

    /// Die Habits, die am Tag pausiert sind (und sonst fällig wären). Sie stehen in der Liste nach allen anderen,
    /// in der gespeicherten Reihenfolge, und zählen nicht im Fortschritt.
    static func pausedInTodayOrder(_ habits: [Habit], on day: Date, engine: HabitEngine) -> [Habit] {
        habits.filter { $0.isAlive && engine.isShownAsPaused($0.snapshot, on: day) }.sorted {
            $0.sortOrder != $1.sortOrder ? $0.sortOrder < $1.sortOrder : $0.createdAt < $1.createdAt
        }
    }
}
