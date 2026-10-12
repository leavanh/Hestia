import SwiftData
import SwiftUI

/// Die drei Tabs mit der Tab Bar des Systems, in `ink` getönt (Spezifikation 5.1). Beim Wechsel blendet der
/// neue Inhalt kurz ein und gleitet dabei ein kleines Stück aus der Richtung des Tabs herein (Tab weiter rechts: von
/// rechts), bei Reduce Motion nur überblenden.
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
                guard new != selection else {
                    reselectCounts[new, default: 0] += 1
                    return
                }
                let tabs = AppTab.allCases
                direction = (tabs.firstIndex(of: new) ?? 0) > (tabs.firstIndex(of: selection) ?? 0) ? 1 : -1
                selection = new
            }
        )
    }

    var body: some View {
        TabView(selection: selectionBinding) {
            Tab(value: AppTab.today) {
                slideIn(TodayView().environment(\.tabReselectCount, reselectCounts[.today, default: 0]))
            } label: {
                tabLabel(.today)
            }
            .accessibilityIdentifier(AppTab.today.identifier)
            Tab(value: AppTab.calendar) {
                slideIn(CalendarView().environment(\.tabReselectCount, reselectCounts[.calendar, default: 0]))
            } label: {
                tabLabel(.calendar)
            }
            .accessibilityIdentifier(AppTab.calendar.identifier)
            Tab(value: AppTab.settings) {
                slideIn(SettingsView().environment(\.tabReselectCount, reselectCounts[.settings, default: 0]))
            } label: {
                tabLabel(.settings)
            }
            .accessibilityIdentifier(AppTab.settings.identifier)
        }
        .tint(Theme.ink)
    }

    /// Name und Symbol eines Tabs. Die Tab Bar von iOS 26 färbt nicht gewählte Tabs immer schwarz bzw. weiß und
    /// übernimmt dafür weder `unselectedItemTintColor` noch eine Textfarbe. Deshalb ist das Symbol eines nicht gewählten
    /// Tabs schon eingefärbt (`ink` mit 45 %, ab Phase 18.4), das des gewählten bleibt eine Vorlage und folgt der
    /// Tönung in `ink`. Die Beschriftung bleibt in der Farbe des Systems.
    private func tabLabel(_ tab: AppTab) -> some View {
        Label {
            Text(tab.title)
        } icon: {
            if tab == selection {
                Image(systemName: tab.systemImage)
            } else {
                Image(uiImage: Self.tintedSymbol(tab.systemImage))
            }
        }
    }

    /// Wie das System die gefüllte Variante des Symbols, falls es eine gibt.
    private static func tintedSymbol(_ name: String) -> UIImage {
        let image = UIImage(systemName: "\(name).fill") ?? UIImage(systemName: name) ?? UIImage()
        return image.withTintColor(Theme.tabUnselectedUIColor, renderingMode: .alwaysOriginal)
    }

    /// Lässt den Inhalt eines Tabs beim Wechsel einblenden und ein Stück aus Richtung des Tabs hereingleiten.
    private func slideIn<Content: View>(_ content: Content) -> some View {
        // Vorab gelesen, weil die Closure des `keyframeAnimator` nicht auf dem Main Actor läuft.
        let slideOffset = reduceMotion ? 0 : Theme.tabSlideOffset * direction
        return content.keyframeAnimator(initialValue: Transition(), trigger: selection) { content, value in
            content
                .opacity(1 - value.progress)
                .offset(x: value.progress * slideOffset)
        } keyframes: { _ in
            KeyframeTrack(\.progress) {
                MoveKeyframe(1)
                CubicKeyframe(0, duration: Theme.tabChangeDuration)
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Habit.self, Completion.self, Pause.self], inMemory: true)
}
