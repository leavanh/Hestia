import SwiftData
import SwiftUI

@main
struct HabitusApp: App {
    init() {
        FontRegistry.registerAll()
        NavigationAppearance.apply()
    }

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
                let habits = DebugData.insertSampleHabits(into: container.mainContext)
                // Startargument für Vorschauen: dazu zwei Beispielpausen (eine vergangene, eine geplante).
                if ProcessInfo.processInfo.arguments.contains("-HabitusSamplePauses") {
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
