import Foundation
import SwiftData

/// Pause von `startDay` bis `endDay` (beide Tage eingeschlossen) für ausgewählte Habits.
@Model
final class Pause {
    var id: UUID
    var startDay: Date
    var endDay: Date

    @Relationship(inverse: \Habit.pauses)
    var habits: [Habit] = []

    init(id: UUID = UUID(), startDay: Date, endDay: Date, habits: [Habit] = []) {
        self.id = id
        self.startDay = startDay
        self.endDay = endDay
        self.habits = habits
    }
}
