import SwiftData
import SwiftUI

/// Tab "Kalender": durchgehender Kalender, in dem die Monate untereinander stehen und der beim aktuellen
/// Monat beginnt (Spezifikation 5.4). Jeder Tag ist nach Tagesfortschritt eingefärbt. Ein Tag antippen öffnet
/// das Sheet "Tag bearbeiten", zukünftige Tage sind gesperrt.
struct CalendarView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @State private var today = AppClock.now
    @State private var selectedDay: SelectedDay?

    private let engine = HabitEngine()

    /// So viele Monate vor dem aktuellen gibt es mindestens, auch wenn der älteste Habit jünger ist.
    private static let minimumMonthsBack = 3

    /// Der Tag, dessen Sheet offen ist. Das Datum ist zugleich die Identität.
    private struct SelectedDay: Identifiable {
        let day: Date
        var id: Date { day }
    }

    /// Vom Monat des ältesten Habits (mindestens `minimumMonthsBack` zurück) bis zum aktuellen Monat.
    private func months(for snapshots: [HabitSnapshot]) -> [MonthGrid] {
        let fallback = engine.calendar.date(byAdding: .month, value: -Self.minimumMonthsBack, to: today) ?? today
        let first = min(snapshots.map(\.createdAt).min() ?? fallback, fallback)
        return engine.monthStarts(from: first, through: today).map { engine.monthGrid(containing: $0) }
    }

    var body: some View {
        // Einmal pro Aufbau berechnet, nicht pro Tag.
        let snapshots = habits.filter(\.isAlive).map(\.snapshot)

        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Theme.sectionSpacing) {
                    ForEach(months(for: snapshots), id: \.firstDay) { grid in
                        MonthCalendar(
                            grid: grid,
                            today: today,
                            progress: { engine.dayProgress(snapshots, on: $0) },
                            onSelect: { selectedDay = SelectedDay(day: $0) }
                        )
                    }
                }
                .padding(.horizontal, Theme.spacing)
                .padding(.vertical, Theme.spacing)
            }
            // Beginnt unten, also beim aktuellen Monat. Nach oben geht es in die Vergangenheit.
            .defaultScrollAnchor(.bottom)
            .accessibilityIdentifier("calendar-scroll")
            .background { GlassBackground() }
            .safeAreaInset(edge: .top, spacing: 0) {
                CalendarWeekdayHeader()
                    .background(.bar)
            }
            .navigationTitle("Kalender")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedDay) { selected in
                DayEditSheet(day: selected.day)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { today = AppClock.now }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .NSCalendarDayChanged) {
                today = AppClock.now
            }
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Habit.self, Completion.self, Pause.self], inMemory: true)
}
