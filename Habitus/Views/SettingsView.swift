import SwiftData
import SwiftUI

/// Einstellungen (Spezifikation 5.5): Pausen und in Debug Builds der Entwicklerbereich.
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.sectionSpacing) {
                    ScreenTitle("Einstellungen")
                    PausesSection()
                    #if DEBUG
                    DeveloperSection()
                    #endif
                }
                .padding(Theme.spacing)
            }
            .scrollsToTopOnTabReselect()
            .background { PaperBackground() }
            .toolbarVisibility(.hidden, for: .navigationBar)
        }
    }
}

/// Einstellungen > Pausen: laufende und geplante Pausen. Eine laufende lässt sich beenden, eine geplante entfernen.
private struct PausesSection: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Pause.startDay) private var pauses: [Pause]

    @State private var isCreating = false

    private let engine = HabitEngine()

    /// Nur laufende und geplante Pausen, die laufenden zuerst. Vergangene Pausen stehen nicht in der Liste.
    private func listedPauses(today: Date) -> [Pause] {
        pauses.filter { engine.phase(of: $0.range, today: today) != .over && !$0.habits.isEmpty }
    }

    var body: some View {
        let today = AppClock.now
        let listed = listedPauses(today: today)

        PaperSection(title: "Pausen") {
            if listed.isEmpty {
                EmptyState(
                    title: "Keine Pausen",
                    message: "Es gibt keine laufenden oder geplanten Pausen. Mit einer Pause zählen Tage, an denen du einen Habit nicht machen kannst, nicht mit.",
                    identifier: "no-pauses",
                    showsHairline: false
                )
            }
            ForEach(listed) { pause in
                PauseRow(
                    habitNames: pause.habits.map(\.name).sorted().joined(separator: ", "),
                    rangeText: pause.range.text(today: today, calendar: engine.calendar),
                    phase: engine.phase(of: pause.range, today: today)
                ) {
                    pause.endEarly(today: today, engine: engine, in: context)
                }
            }
            HermesButton("Neue Pause") {
                isCreating = true
            }
            .padding(.top, Theme.inlineSpacing)
            .accessibilityIdentifier("new-pause")
        }
        .sheet(isPresented: $isCreating) {
            PauseEditorSheet()
        }
    }
}

#if DEBUG
/// Einstellungen > Entwickler: Testdaten erzeugen und alle Daten zurücksetzen. Nur in Debug Builds.
private struct DeveloperSection: View {
    @Environment(\.modelContext) private var context

    @State private var isConfirmingReset = false
    @State private var message: String?

    var body: some View {
        PaperSection(title: "Entwickler") {
            VStack(alignment: .leading, spacing: Theme.spacing) {
                HermesButton("Testdaten erzeugen", variant: .quiet) {
                    let habits = DebugData.insertSampleHabits(into: context)
                    message = "\(habits.count) Beispielhabits mit \(DebugData.historyDays) Tagen Historie angelegt."
                }
                .accessibilityIdentifier("create-sample-data")

                HermesButton("Alle Daten zurücksetzen", variant: .destructive, role: .destructive) {
                    isConfirmingReset = true
                }
                .accessibilityIdentifier("reset-all-data")

                if let message {
                    Text(message)
                        .bodyText()
                        .foregroundStyle(Theme.inkSecondary)
                        .accessibilityIdentifier("developer-message")
                }
            }
        }
        .alert("Alle Daten zurücksetzen?", isPresented: $isConfirmingReset) {
            Button("Abbrechen", role: .cancel) {}
            Button("Zurücksetzen", role: .destructive) {
                try? DebugData.resetAll(in: context)
                message = "Alle Daten wurden gelöscht."
            }
        } message: {
            Text("Alle Habits, Erledigungen und Pausen werden unwiderruflich gelöscht.")
        }
    }
}
#endif

#Preview {
    SettingsView()
        .modelContainer(for: [Habit.self, Completion.self, Pause.self], inMemory: true)
}
