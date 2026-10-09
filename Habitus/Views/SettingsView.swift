import SwiftData
import SwiftUI

/// Einstellungen. Pausen und beendete Habits kommen in Phase 6, bis dahin nur der Entwicklerbereich.
struct SettingsView: View {
    var body: some View {
        #if DEBUG
        DeveloperSettings()
        #else
        PlaceholderView(title: "Einstellungen", systemImage: "gearshape")
        #endif
    }
}

#if DEBUG
/// Einstellungen > Entwickler: Testdaten erzeugen und alle Daten zurücksetzen. Nur in Debug Builds.
private struct DeveloperSettings: View {
    @Environment(\.modelContext) private var context

    @State private var isConfirmingReset = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.sectionSpacing) {
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
                }
                .padding(Theme.spacing)
            }
            .background { GlassBackground() }
            .navigationTitle("Einstellungen")
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
}
#endif

#Preview {
    SettingsView()
        .modelContainer(for: [Habit.self, Completion.self, Pause.self], inMemory: true)
}
