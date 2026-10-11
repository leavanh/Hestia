import SwiftData
import SwiftUI

/// Sortiermodus von Heute (Spezifikation 5.2): Die offenen Habits des angezeigten Tags lassen sich per Drag and Drop
/// verschieben, die erledigten stehen darunter und bleiben, wo sie sind. Die neue Reihenfolge wird sofort
/// gespeichert (`Habit.saveOrder`).
struct HabitSortList: View {
    @Environment(\.modelContext) private var context

    let habits: [Habit]
    let day: Date

    private let engine = HabitEngine()

    var body: some View {
        let due = Habit.dueInTodayOrder(habits, on: day, engine: engine)
        let open = due.filter { !engine.isCompleted($0.snapshot, on: day) }
        let done = due.filter { engine.isCompleted($0.snapshot, on: day) }
        let paused = Habit.pausedInTodayOrder(habits, on: day, engine: engine)

        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sortieren")
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text("Verschiebe offene Habits am Griff.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .moveDisabled(true)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            Section {
                ForEach(open) { habit in
                    row(habit)
                }
                .onMove { source, destination in
                    var reordered = open
                    reordered.move(fromOffsets: source, toOffset: destination)
                    Habit.saveOrder(all: habits.filter(\.isAlive), open: reordered, done: done, in: context)
                }
            }
            Section {
                ForEach(done + paused) { habit in
                    row(habit)
                        .moveDisabled(true)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .listSectionSpacing(0)
        .environment(\.editMode, .constant(.active))
        .accessibilityIdentifier("sort-list")
    }

    /// Dieselbe Karte wie in Heute, im Sortiermodus nur zum Anschauen.
    private func row(_ habit: Habit) -> some View {
        DayHabitCard(habit: habit, day: day, onEdit: {})
            .allowsHitTesting(false)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: Theme.spacing / 2, leading: Theme.spacing, bottom: Theme.spacing / 2, trailing: Theme.spacing))
    }
}
