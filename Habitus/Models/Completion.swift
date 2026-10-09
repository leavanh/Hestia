import Foundation
import SwiftData

/// "An Tag X habe ich Habit Y n mal gemacht". Pro Habit und Tag höchstens ein Eintrag.
@Model
final class Completion {
    var id: UUID
    /// Tagesbeginn (lokale Zeitzone).
    var day: Date
    var count: Int
    var habit: Habit?

    init(id: UUID = UUID(), day: Date, count: Int, habit: Habit? = nil) {
        self.id = id
        self.day = day
        self.count = count
        self.habit = habit
    }
}
