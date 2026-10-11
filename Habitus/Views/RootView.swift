import SwiftData
import SwiftUI

/// Die drei Tabs mit eigener Tab Bar (`PaperTabBar`). `TabView` hält nur den Zustand der Tabs, seine Leiste ist
/// ausgeblendet (Spezifikation 5.1).
struct RootView: View {
    @State private var selection = AppTab.today
    @State private var reselectCounts: [AppTab: Int] = [:]

    var body: some View {
        TabView(selection: $selection) {
            Tab(AppTab.today.title, systemImage: AppTab.today.systemImage, value: AppTab.today) {
                TodayView().environment(\.tabReselectCount, reselectCounts[.today, default: 0])
            }
            Tab(AppTab.calendar.title, systemImage: AppTab.calendar.systemImage, value: AppTab.calendar) {
                CalendarView().environment(\.tabReselectCount, reselectCounts[.calendar, default: 0])
            }
            Tab(AppTab.settings.title, systemImage: AppTab.settings.systemImage, value: AppTab.settings) {
                SettingsView().environment(\.tabReselectCount, reselectCounts[.settings, default: 0])
            }
        }
        .toolbarVisibility(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PaperTabBar(selection: $selection) { tab in
                reselectCounts[tab, default: 0] += 1
            }
        }
        .tint(Theme.ink)
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Habit.self, Completion.self, Pause.self], inMemory: true)
}
