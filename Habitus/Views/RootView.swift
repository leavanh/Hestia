import SwiftData
import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Heute", systemImage: "checkmark.circle") {
                TodayView()
            }
            Tab("Kalender", systemImage: "calendar") {
                CalendarView()
            }
            Tab("Einstellungen", systemImage: "gearshape") {
                SettingsView()
            }
        }
        .tint(Theme.ink)
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Habit.self, Completion.self, Pause.self], inMemory: true)
}
