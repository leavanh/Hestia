import Foundation

/// Liefert "jetzt" für die App. In Debug Builds kann per Startargument
/// `-HabitusDayOffset <n>` ein Tagesversatz gesetzt werden (für UI Tests des Tageswechsels).
enum AppClock {
    static var now: Date {
        #if DEBUG
        let offset = UserDefaults.standard.integer(forKey: "HabitusDayOffset")
        if offset != 0, let shifted = Calendar.current.date(byAdding: .day, value: offset, to: .now) {
            return shifted
        }
        #endif
        return .now
    }
}
