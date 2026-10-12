import Foundation

/// Anzahl der Zeilen im Listenkopf von Heute (Spezifikation 5.2): "1 Habit", sonst "n Habits". Einzahl und Mehrzahl
/// stehen im String Catalog.
enum HabitCountText {
    static func text(_ count: Int, locale: Locale = .current) -> String {
        localized("\(count) Habits", locale: locale)
    }
}
