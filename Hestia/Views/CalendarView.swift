import SwiftData
import SwiftUI

/// Tab "Kalender": Monatskalender mit Pfeilen, der beim aktuellen Monat beginnt (Spezifikation 5.4). Jeder Tag ist
/// nach Tagesfortschritt eingefärbt. Ein Tag antippen öffnet das Sheet "Tag bearbeiten", zukünftige Tage sind
/// gesperrt. Darunter stehen alle Habits mit ihrem aktuellen Streak, ein Habit antippen öffnet sein Detail als ganze Seite,
/// langes Drücken auf einen aktiven Habit das Kontextmenü.
struct CalendarView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @State private var today = AppClock.now
    @State private var selectedDay: SelectedDay?
    @State private var openedHabit: Habit?

    @Environment(\.firstWeekday) private var firstWeekday
    @Environment(\.habitEngine) private var engine

    /// Der Tag, dessen Sheet offen ist. Das Datum ist zugleich die Identität.
    private struct SelectedDay: Identifiable {
        let day: Date
        var id: Date { day }
    }

    /// Aktive Habits zuerst, dann die beendeten, jeweils in der Reihenfolge von Heute.
    private var listedHabits: [Habit] {
        let alive = habits.filter(\.isAlive)
        let order = { (habit: Habit) in (habit.sortOrder, habit.createdAt) }
        let active = alive.filter { $0.endedAt == nil }.sorted { order($0) < order($1) }
        let ended = alive.filter { $0.endedAt != nil }.sorted { order($0) < order($1) }
        return active + ended
    }

    var body: some View {
        // Einmal pro Aufbau berechnet, nicht pro Tag.
        let snapshots = habits.filter(\.isAlive).map(\.snapshot)

        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.sectionSpacing) {
                    ScreenTitle("Kalender")
                    MonthCalendar(
                        firstMonth: engine.firstCalendarMonth(oldest: snapshots.map(\.createdAt).min(), today: today),
                        lastMonth: today,
                        today: today,
                        progress: { engine.dayProgress(snapshots, on: $0) },
                        isPaused: { engine.isEveryHabitPaused(snapshots, on: $0) },
                        onSelect: { selectedDay = SelectedDay(day: $0) }
                    )
                    habitList
                }
                .padding(Theme.spacing)
            }
            .accessibilityIdentifier("calendar-scroll")
            .scrollsToTopOnTabReselect()
            .background { PaperBackground() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .sheet(item: $selectedDay) { selected in
                DayEditSheet(day: selected.day)
            }
            .navigationDestination(item: $openedHabit) { habit in
                HabitDetailView(habit: habit, day: today, today: today)
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

extension CalendarView {
    /// Alle Habits mit aktuellem Streak, aktive zuerst, dann beendete. Ohne Habits ein Leerzustand.
    private var habitList: some View {
        VStack(spacing: 0) {
            if listedHabits.isEmpty {
                EmptyState(
                    engraving: .torch,
                    title: "Noch keine Daten",
                    message: "Sobald in Heute Habits angelegt und abgehakt sind, färben sich hier die Tage und Streaks erscheinen.",
                    identifier: "calendar-empty"
                )
            }
            ForEach(listedHabits) { habit in
                let snapshot = habit.snapshot
                HabitStatRow(
                    name: habit.name,
                    iconName: habit.iconName,
                    habitColor: HabitColor(key: habit.colorKey),
                    rhythmText: snapshot.rhythmText(window: engine.windowProgress(snapshot, on: today), firstWeekday: firstWeekday, periods: engine.periods),
                    streak: engine.currentStreak(snapshot, on: habit.statisticsDay(today: today, engine: engine))
                ) {
                    openedHabit = habit
                }
                .habitContextMenu(habit)
            }
        }
        .padding(.top, Theme.spacing)
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Habit.self, Completion.self, Pause.self], inMemory: true)
}
