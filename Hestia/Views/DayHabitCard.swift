import SwiftData
import SwiftUI

/// Zeile eines Habits für einen angezeigten Tag, mit `CheckBox` oder Counter (`HabitDayControl`). Heute und das Sheet
/// "Tag bearbeiten" nutzen dieselbe Karte. Abgehakt wird für `day`, Antippen der linken Seite öffnet das Habit Detail.
/// Ist der Habit an dem Tag pausiert, ist die Karte ausgegraut und nicht bedienbar.
struct DayHabitCard: View {
    let habit: Habit
    let day: Date
    let onOpen: () -> Void

    @Environment(\.firstWeekday) private var firstWeekday
    @Environment(\.habitEngine) private var engine

    var body: some View {
        // Ein eben gelöschter Habit kann hier noch einmal ankommen, bevor die Liste neu aufgebaut ist.
        if habit.isAlive {
            let habitColor = HabitColor(key: habit.colorKey)
            let snapshot = habit.snapshot

            HabitCard(
                name: habit.name,
                iconName: habit.iconName,
                habitColor: habitColor,
                status: engine.status(snapshot, on: day),
                rhythmText: snapshot.rhythmText(window: engine.windowProgress(snapshot, on: day), firstWeekday: firstWeekday, periods: engine.periods),
                dots: engine.weekDots(snapshot, on: day),
                isPaused: engine.isPaused(snapshot, on: day),
                onOpen: onOpen
            ) {
                HabitDayControl(habit: habit, day: day)
            }
        }
    }
}
