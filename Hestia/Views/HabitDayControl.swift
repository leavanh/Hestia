import SwiftData
import SwiftUI

/// Bedienelement eines Habits für einen Tag: `CounterControl` bei täglich mit Anzahl größer 1, sonst `CheckBox`.
/// Abgehakt wird für `day`. Die Karte in Heute und im Sheet "Tag bearbeiten" und die Tageszeile im Habit Detail nutzen
/// denselben Baustein, damit beide dieselbe Logik haben (`setCount`).
struct HabitDayControl: View {
    @Environment(\.modelContext) private var context
    @Environment(\.habitEngine) private var engine

    let habit: Habit
    let day: Date
    /// Bezeichner des Kreises bzw. Counters (Voreinstellung `check-<Name>` und `counter-<Name>`). Die Teile des
    /// Counters hängen "-minus", "-value" und "-plus" an.
    var checkID: String?
    var counterID: String?

    var body: some View {
        let snapshot = habit.snapshot
        let habitColor = HabitColor(key: habit.colorKey)
        let target = engine.dailyTarget(snapshot)
        let count = min(engine.count(on: day, in: snapshot.counts), target)

        if engine.usesCounter(snapshot) {
            CounterControl(
                count: count,
                target: target,
                habitColor: habitColor,
                label: habit.name,
                id: counterID ?? "counter-\(habit.name)",
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
            .accessibilityIdentifier(checkID ?? "check-\(habit.name)")
        }
    }
}
