import SwiftData
import SwiftUI

@main
struct HestiaApp: App {
    init() {
        FontRegistry.registerAll()
        NavigationAppearance.apply()
    }

    private let container: ModelContainer = {
        do {
            let container = try ModelContainer(for: Habit.self, Completion.self, Pause.self)
            #if DEBUG
            // Startargument für UI Tests: beginnt mit leerem Datenbestand.
            if ProcessInfo.processInfo.arguments.contains("-HestiaResetData") {
                try DebugData.resetAll(in: container.mainContext)
            }
            // Startargument für Vorschauen: legt zusätzlich die Testdaten aus den Einstellungen an.
            if ProcessInfo.processInfo.arguments.contains("-HestiaSampleData") {
                let habits = DebugData.insertSampleHabits(into: container.mainContext)
                // Startargument für Vorschauen: dazu zwei Beispielpausen (eine vergangene, eine geplante).
                if ProcessInfo.processInfo.arguments.contains("-HestiaSamplePauses") {
                    DebugData.insertSamplePauses(into: container.mainContext, habits: habits)
                }
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
