import Foundation

/// Anzahl der Zeilen im Listenkopf von Heute (Spezifikation 5.2): "1 Habit", sonst "n Habits".
enum HabitCountText {
    static func text(_ count: Int) -> String {
        count == 1 ? "1 Habit" : "\(count) Habits"
    }
}
