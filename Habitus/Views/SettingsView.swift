import SwiftData
import SwiftUI

/// Einstellungen (Spezifikation 5.5): Pausen und in Debug Builds der Entwicklerbereich.
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.sectionSpacing) {
                    PausesSection()
                    #if DEBUG
                    DeveloperSection()
                    #endif
                }
                .padding(Theme.spacing)
            }
            .background { GlassBackground() }
            .navigationTitle("Einstellungen")
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

        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("Pausen")
            if listed.isEmpty {
                Text("Keine laufenden oder geplanten Pausen.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .glassCard()
                    .accessibilityIdentifier("no-pauses")
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
            Button {
                isCreating = true
            } label: {
                Label("Neue Pause", systemImage: "pause.circle")
                    .font(.body)
                    .glassCard()
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
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
        GlassSection(title: "Entwickler") {
            VStack(alignment: .leading, spacing: 16) {
                Button("Testdaten erzeugen") {
                    let habits = DebugData.insertSampleHabits(into: context)
                    message = "\(habits.count) Beispielhabits mit \(DebugData.historyDays) Tagen Historie angelegt."
                }
                .accessibilityIdentifier("create-sample-data")

                Button("Alle Daten zurücksetzen", role: .destructive) {
                    isConfirmingReset = true
                }
                .accessibilityIdentifier("reset-all-data")

                if let message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
