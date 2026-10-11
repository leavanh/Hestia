import SwiftData
import SwiftUI

/// Die drei Tabs mit eigener Tab Bar (`PaperTabBar`). `TabView` hält nur den Zustand der Tabs, seine Leiste ist
/// ausgeblendet (Spezifikation 5.1). Beim Wechsel blendet der neue Inhalt kurz ein und gleitet dabei ein kleines Stück
/// aus der Richtung des Tabs herein (Tab weiter rechts: von rechts), bei Reduce Motion nur überblenden.
struct RootView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selection = AppTab.today
    @State private var reselectCounts: [AppTab: Int] = [:]
    /// Richtung des letzten Wechsels: 1 = der neue Tab liegt weiter rechts, -1 = weiter links.
    @State private var direction: CGFloat = 1

    /// Fortschritt des Übergangs: 1 = Anfang (unsichtbar, seitlich versetzt), 0 = fertig.
    private struct Transition {
        var progress = 0.0
    }

    private var selectionBinding: Binding<AppTab> {
        Binding(
            get: { selection },
            set: { new in
                guard new != selection else { return }
                let tabs = AppTab.allCases
                direction = (tabs.firstIndex(of: new) ?? 0) > (tabs.firstIndex(of: selection) ?? 0) ? 1 : -1
                selection = new
            }
        )
    }

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
        .keyframeAnimator(initialValue: Transition(), trigger: selection) { content, value in
            content
                .opacity(1 - value.progress)
                .offset(x: reduceMotion ? 0 : value.progress * Theme.tabSlideOffset * direction)
        } keyframes: { _ in
            KeyframeTrack(\.progress) {
                MoveKeyframe(1)
                CubicKeyframe(0, duration: Theme.tabChangeDuration)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PaperTabBar(selection: selectionBinding) { tab in
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
