import SwiftData
import SwiftUI

/// Sheet "Tag bearbeiten": dieselbe Liste wie Heute für einen gewählten Tag, mit Abhaken und Counter
/// (Spezifikation 5.4). Änderungen werden sofort gespeichert.
struct DayEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    let day: Date

    @State private var editingHabit: Habit?

    @Environment(\.habitEngine) private var engine

    var body: some View {
        let due = Habit.mainInTodayOrder(habits, on: day, engine: engine)
        let other = Habit.otherInSavedOrder(habits, on: day, engine: engine)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                    progressSummary(engine.dayProgress(due.map(\.snapshot), on: day))
                    if due.isEmpty && other.isEmpty {
                        EmptyState(
                            title: "Nichts fällig",
                            message: "An diesem Tag gab es keinen fälligen Habit.",
                            identifier: "day-empty"
                        )
                    }
                    VStack(spacing: 0) {
                        ForEach(due) { habit in
                            DayHabitCard(habit: habit, day: day) { editingHabit = habit }
                        }
                        OtherHabitsSection(habits: other, day: day) { editingHabit = $0 }
                    }
                    .animation(.smooth, value: due.map(\.id))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.spacing)
            }
            .accessibilityIdentifier("day-edit-list")
            .background { PaperBackground() }
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

    /// Einfacher Kopf des Sheets: "5 von 16 · 31 %" in Rolle `meta` und darunter die `SegmentBar`.
    private func progressSummary(_ progress: DayProgress) -> some View {
        // Geschütztes Leerzeichen, damit "%" bei großer Schrift nicht allein umbricht.
        let text = progress.total == 0
            ? "Nichts fällig"
            : "\(progress.done) von \(progress.total) · \(progress.percent)\u{00A0}%"
        return VStack(alignment: .leading, spacing: Theme.inlineSpacing) {
            Text(text)
                .metaText()
                .accessibilityIdentifier("progress-text")
            SegmentBar(done: progress.done, total: progress.total)
        }
        .foregroundStyle(Theme.ink)
    }
}

#Preview {
    DayEditSheet(day: .now)
        .modelContainer(for: [Habit.self, Completion.self, Pause.self], inMemory: true)
}
