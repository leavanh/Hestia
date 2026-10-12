import SwiftData
import SwiftUI

/// Zeile eines Habits für einen angezeigten Tag, mit `CheckBox` oder Counter. Heute und das Sheet
/// "Tag bearbeiten" nutzen dieselbe Karte. Abgehakt wird für `day`. Ist der Habit an dem Tag pausiert, ist die Karte
/// ausgegraut und nicht bedienbar.
struct DayHabitCard: View {
    @Environment(\.modelContext) private var context

    let habit: Habit
    let day: Date
    let onEdit: () -> Void

    @Environment(\.firstWeekday) private var firstWeekday
    @Environment(\.habitEngine) private var engine

    var body: some View {
        // Ein eben gelöschter Habit kann hier noch einmal ankommen, bevor die Liste neu aufgebaut ist.
        if habit.isAlive {
            let habitColor = HabitColor(key: habit.colorKey)
            let snapshot = habit.snapshot

            HabitCard(
                name: habit.name,
                iconName: habit.iconName,
                habitColor: habitColor,
                status: engine.status(snapshot, on: day),
                rhythmText: snapshot.rhythmText(window: engine.windowProgress(snapshot, on: day), firstWeekday: firstWeekday, periods: engine.periods),
                dots: engine.weekDots(snapshot, on: day),
                isPaused: engine.isPaused(snapshot, on: day),
                onEdit: onEdit
            ) {
                control(snapshot: snapshot, habitColor: habitColor)
            }
        }
    }

    /// Counter bei täglich mit Anzahl größer 1, sonst `CheckBox`.
    @ViewBuilder
    private func control(snapshot: HabitSnapshot, habitColor: HabitColor) -> some View {
        let target = engine.dailyTarget(snapshot)
        let count = min(engine.count(on: day, in: snapshot.counts), target)

        if engine.usesCounter(snapshot) {
            CounterControl(
                count: count,
                target: target,
                habitColor: habitColor,
                label: habit.name,
                id: "counter-\(habit.name)",
                onDecrement: {
                    habit.setCount(engine.decrementedCount(count), on: day, engine: engine, in: context)
                },
                onIncrement: {
                    habit.setCount(engine.incrementedCount(count, target: target), on: day, engine: engine, in: context)
                }
            )
        } else {
            CheckBox(isChecked: count >= 1, habitColor: habitColor, label: habit.name) {
                habit.setCount(engine.toggledCount(count), on: day, engine: engine, in: context)
            }
            .accessibilityIdentifier("check-\(habit.name)")
        }
    }
}
