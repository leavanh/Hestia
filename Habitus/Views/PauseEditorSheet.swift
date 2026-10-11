import SwiftData
import SwiftUI

/// Sheet "Neue Pause": Mehrfachauswahl der Habits, Startdatum und Enddatum (beide Tage eingeschlossen),
/// Spezifikation 3.8 und 5.5.
struct PauseEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @State private var selection: Set<UUID> = []
    @State private var startDay = AppClock.now
    @State private var endDay = AppClock.now

    private let engine = HabitEngine()

    /// Aktive Habits in der Reihenfolge von Heute. Beendete lassen sich nicht pausieren.
    private var choices: [Habit] {
        habits.filter { $0.isAlive && $0.endedAt == nil }.sorted {
            $0.sortOrder != $1.sortOrder ? $0.sortOrder < $1.sortOrder : $0.createdAt < $1.createdAt
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.sectionSpacing) {
                    // Der kurze Zeitraum zuerst, damit er auch bei vielen Habits nicht ganz unten steht.
                    GlassSection(title: "Zeitraum") {
                        dateRows
                    }
                    GlassSection(title: "Habits") {
                        habitChoices
                    }
                }
                .padding(Theme.spacing)
            }
            .background { GlassBackground() }
            .navigationTitle("Neue Pause")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen", systemImage: "xmark", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern", systemImage: "checkmark", role: .confirm) {
                        save()
                    }
                    .disabled(selection.isEmpty)
                    .accessibilityIdentifier("pause-save")
                }
            }
            .onChange(of: startDay) { _, new in
                if engine.startOfDay(endDay) < engine.startOfDay(new) { endDay = new }
            }
        }
    }

    @ViewBuilder
    private var habitChoices: some View {
        if choices.isEmpty {
            Text("Es gibt keine aktiven Habits. Lege zuerst in Heute einen Habit an.")
                .font(.body)
                .foregroundStyle(.secondary)
        } else {
            VStack(spacing: Theme.spacing) {
                ForEach(choices) { habit in
                    let habitColor = HabitColor(key: habit.colorKey)
                    let pausedText = pausedText(for: habit)
                    HStack(spacing: Theme.spacing) {
                        HabitIconView(habitName: habit.name, iconName: habit.iconName, color: habitColor)
                            .opacity(pausedText == nil ? 1 : Theme.pausedOpacity)
                        VStack(alignment: .leading, spacing: Theme.textSpacing) {
                            AdaptiveStack(spacing: Theme.inlineSpacing) {
                                Text(habit.name)
                                    .font(.body)
                                    .foregroundStyle(pausedText == nil ? Color.primary : Color.secondary)
                                if pausedText != nil {
                                    DayBadge(text: "Pausiert", isToday: false)
                                }
                            }
                            if let pausedText {
                                Text(pausedText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("pause-state-\(habit.name)")
                        CheckCircle(
                            isChecked: selection.contains(habit.id), color: habitColor.color, label: habit.name,
                            checkedText: "Ausgewählt", uncheckedText: "Nicht ausgewählt"
                        ) {
                            toggle(habit)
                        }
                        .accessibilityIdentifier("pause-habit-\(habit.name)")
                    }
                }
            }
        }
    }

    private var dateRows: some View {
        VStack(spacing: Theme.spacing) {
            DatePicker("Von", selection: $startDay, displayedComponents: .date)
                .accessibilityIdentifier("pause-start")
            DatePicker("Bis", selection: $endDay, in: startDay..., displayedComponents: .date)
                .accessibilityIdentifier("pause-end")
        }
        .font(.body)
    }

    /// Die Zeiträume, in denen der Habit im gewählten Zeitraum schon pausiert ist ("13. Okt. – 15. Okt."), sonst `nil`.
    /// Der Habit lässt sich trotzdem auswählen.
    private func pausedText(for habit: Habit) -> String? {
        let chosen = PauseRange(start: startDay, end: max(startDay, endDay))
        let today = AppClock.now
        let overlapping = habit.pauses.map(\.range).filter { engine.overlaps($0, chosen) }.sorted { $0.start < $1.start }
        guard !overlapping.isEmpty else { return nil }
        return overlapping.map { $0.text(today: today, calendar: engine.calendar) }.joined(separator: ", ")
    }

    private func toggle(_ habit: Habit) {
        if selection.contains(habit.id) {
            selection.remove(habit.id)
        } else {
            selection.insert(habit.id)
        }
    }

    private func save() {
        let selected = choices.filter { selection.contains($0.id) }
        guard !selected.isEmpty else { return }
        let first = engine.startOfDay(startDay)
        let pause = Pause(startDay: first, endDay: max(first, engine.startOfDay(endDay)))
        context.insert(pause)
        pause.habits = selected
        try? context.save()
        dismiss()
    }
}

#Preview {
    PauseEditorSheet()
        .modelContainer(for: [Habit.self, Completion.self, Pause.self], inMemory: true)
}
