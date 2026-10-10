import SwiftData
import SwiftUI

/// Karte eines Habits für einen angezeigten Tag, mit Abhakkreis oder Counter. Heute und das Sheet
/// "Tag bearbeiten" nutzen dieselbe Karte. Abgehakt wird für `day`.
struct DayHabitCard: View {
    @Environment(\.modelContext) private var context

    let habit: Habit
    let day: Date
    let onEdit: () -> Void

    private let engine = HabitEngine()

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
                rhythmText: snapshot.rhythmText(window: engine.windowProgress(snapshot, on: day)),
                dots: engine.weekDots(snapshot, on: day),
                onEdit: onEdit
            ) {
                control(snapshot: snapshot, color: habitColor.color)
            }
        }
    }

    /// Counter bei täglich mit Anzahl größer 1, sonst Abhakkreis.
    @ViewBuilder
    private func control(snapshot: HabitSnapshot, color: Color) -> some View {
        let target = engine.dailyTarget(snapshot)
        let count = min(engine.count(on: day, in: snapshot.counts), target)

        if engine.usesCounter(snapshot) {
            CounterControl(
                count: count,
                target: target,
                color: color,
                id: "counter-\(habit.name)",
                onDecrement: {
                    habit.setCount(engine.decrementedCount(count), on: day, engine: engine, in: context)
                },
                onIncrement: {
                    habit.setCount(engine.incrementedCount(count, target: target), on: day, engine: engine, in: context)
                }
            )
        } else {
            CheckCircle(isChecked: count >= 1, color: color) {
                habit.setCount(engine.toggledCount(count), on: day, engine: engine, in: context)
            }
            .accessibilityIdentifier("check-\(habit.name)")
        }
    }
}
