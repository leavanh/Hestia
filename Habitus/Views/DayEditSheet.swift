import SwiftData
import SwiftUI

/// Sheet "Tag bearbeiten": dieselbe Liste wie Heute für einen gewählten Tag, mit Abhaken und Counter
/// (Spezifikation 5.4). Änderungen werden sofort gespeichert.
struct DayEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    let day: Date

    @State private var editingHabit: Habit?

    private let engine = HabitEngine()

    var body: some View {
        let due = Habit.dueInTodayOrder(habits, on: day, engine: engine)
        let paused = Habit.pausedInTodayOrder(habits, on: day, engine: engine)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                    ProgressHeader(progress: engine.dayProgress(due.map(\.snapshot), on: day))
                    if due.isEmpty && paused.isEmpty {
                        EmptyState(
                            systemImage: "calendar",
                            title: "Nichts fällig",
                            message: "An diesem Tag gab es keinen fälligen Habit.",
                            identifier: "day-empty"
                        )
                    }
                    VStack(spacing: Theme.spacing) {
                        ForEach(due + paused) { habit in
                            DayHabitCard(habit: habit, day: day) { editingHabit = habit }
                        }
                    }
                    .animation(.smooth, value: (due + paused).map(\.id))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.spacing)
            }
            .accessibilityIdentifier("day-edit-list")
            .background { GlassBackground() }
            .navigationTitle(day.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE"))))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig", systemImage: "checkmark", role: .confirm) {
                        dismiss()
                    }
                }
            }
            .sheet(item: $editingHabit) { habit in
                HabitEditorSheet(habit: habit)
            }
        }
    }
}

#Preview {
    DayEditSheet(day: .now)
        .modelContainer(for: [Habit.self, Completion.self, Pause.self], inMemory: true)
}
