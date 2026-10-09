import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @State private var today = AppClock.now
    /// Der Tag, den die Ansicht zeigt: heute oder ein vergangener Tag (Spezifikation 5.2).
    @State private var shownDay = AppClock.now
    @State private var isCreating = false
    @State private var editingHabit: Habit?

    private let engine = HabitEngine()

    /// Habits, die am angezeigten Tag fällig sind (Spezifikation 3.2), in der Reihenfolge der Liste.
    private var dueHabits: [Habit] {
        Habit.inTodayOrder(habits.filter { $0.isAlive && engine.isDue($0.snapshot, on: shownDay) })
    }

    var body: some View {
        let due = dueHabits
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                    header(for: due)
                    VStack(spacing: Theme.spacing) {
                        ForEach(due) { habit in
                            card(for: habit)
                        }
                    }
                }
                .padding(.horizontal, Theme.spacing)
                .padding(.bottom, Theme.spacing)
            }
            .background { GlassBackground() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Neuer Habit", systemImage: "plus") {
                        isCreating = true
                    }
                }
            }
            .sheet(isPresented: $isCreating) {
                HabitEditorSheet()
            }
            .sheet(item: $editingHabit) { habit in
                HabitEditorSheet(habit: habit)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { showToday() }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .NSCalendarDayChanged) {
                showToday()
            }
        }
    }

    /// Beim Start, beim Zurückkehren in die App und um Mitternacht zeigt die Ansicht wieder heute.
    private func showToday() {
        today = AppClock.now
        shownDay = today
    }

    /// Wischen nach rechts zeigt den vorherigen Tag, nach links den nächsten. Über heute hinaus geht es nicht.
    private func swipe(by translation: CGSize) {
        guard abs(translation.width) > Theme.swipeDistance,
              abs(translation.width) > abs(translation.height) else { return }
        let step = translation.width > 0 ? -1 : 1
        guard let day = engine.calendar.date(byAdding: .day, value: step, to: shownDay),
              engine.startOfDay(day) <= engine.startOfDay(today) else { return }
        shownDay = day
    }

    private func header(for due: [Habit]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(shownDay.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE"))))
                .font(.title2.weight(.bold))
                .accessibilityIdentifier("today-date")
            ProgressHeader(progress: engine.dayProgress(due.map(\.snapshot), on: shownDay))
        }
        .glassCard()
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: Theme.swipeDistance)
                .onEnded { swipe(by: $0.translation) }
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("date-card")
    }

    @ViewBuilder
    private func card(for habit: Habit) -> some View {
        // Ein eben gelöschter Habit kann hier noch einmal ankommen, bevor die Liste neu aufgebaut ist.
        if habit.isAlive {
            let color = HabitColor(key: habit.colorKey).color
            let snapshot = habit.snapshot

            HabitCard(
                name: habit.name,
                iconName: habit.iconName,
                color: color,
                status: engine.status(snapshot, on: shownDay),
                dots: engine.weekDots(snapshot, on: shownDay),
                onTap: { editingHabit = habit }
            ) {
                control(for: habit, snapshot: snapshot, color: color)
            }
        }
    }

    /// Counter bei täglich mit Anzahl größer 1, sonst Abhakkreis. Abgehakt wird für den angezeigten Tag.
    @ViewBuilder
    private func control(for habit: Habit, snapshot: HabitSnapshot, color: Color) -> some View {
        let target = engine.dailyTarget(snapshot)
        let count = min(engine.count(on: shownDay, in: snapshot.counts), target)

        if engine.usesCounter(snapshot) {
            CounterControl(
                count: count,
                target: target,
                color: color,
                id: "counter-\(habit.name)",
                onDecrement: {
                    habit.setCount(engine.decrementedCount(count), on: shownDay, engine: engine, in: context)
                },
                onIncrement: {
                    habit.setCount(engine.incrementedCount(count, target: target), on: shownDay, engine: engine, in: context)
                }
            )
        } else {
            CheckCircle(isChecked: count >= 1, color: color) {
                habit.setCount(engine.toggledCount(count), on: shownDay, engine: engine, in: context)
            }
            .accessibilityIdentifier("check-\(habit.name)")
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Habit.self, Completion.self, Pause.self], inMemory: true)
}
