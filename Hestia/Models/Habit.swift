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
    /// Kurzer Zusatz zum Namen, z.B. "20 Min". Leer bedeutet keiner (Spezifikation 5.3, höchstens 24 Zeichen).
    var detail: String = ""
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
        detail: String = "",
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
        self.detail = HabitDetail.normalized(detail)
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

    /// Die Habits der Hauptliste an `day` (Spezifikation 3.2), in der Reihenfolge von Heute. Heute, der Kalender
    /// und das Sheet "Tag bearbeiten" zeigen damit dieselbe Liste.
    static func mainInTodayOrder(_ habits: [Habit], on day: Date, engine: HabitEngine) -> [Habit] {
        inTodayOrder(habits.filter { $0.isAlive && engine.section($0.snapshot, on: day) == .main }) {
            engine.isCompleted($0.snapshot, on: day)
        }
    }

    /// Die Habits im Abschnitt Weitere an `day` in der gespeicherten Reihenfolge, die pausierten am Ende. Erledigte
    /// rutschen hier nicht nach unten. Sie zählen nicht im Fortschritt.
    static func otherInSavedOrder(_ habits: [Habit], on day: Date, engine: HabitEngine) -> [Habit] {
        let other = inSavedOrder(habits.filter { $0.isAlive && engine.section($0.snapshot, on: day) == .other })
        let isPaused = { (habit: Habit) in engine.isPaused(habit.snapshot, on: day) }
        return other.filter { !isPaused($0) } + other.filter(isPaused)
    }
}
