import SwiftData
import SwiftUI

@main
struct HabitusApp: App {
    private let container: ModelContainer = {
        do {
            let container = try ModelContainer(for: Habit.self, Completion.self, Pause.self)
            #if DEBUG
            // Startargument für UI Tests: beginnt mit leerem Datenbestand.
            if ProcessInfo.processInfo.arguments.contains("-HabitusResetData") {
                try DebugData.resetAll(in: container.mainContext)
            }
            // Startargument für Vorschauen: legt zusätzlich die Testdaten aus den Einstellungen an.
            if ProcessInfo.processInfo.arguments.contains("-HabitusSampleData") {
                DebugData.insertSampleHabits(into: container.mainContext)
            }
            #endif
            return container
        } catch {
            fatalError("Datenbank konnte nicht geöffnet werden: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
