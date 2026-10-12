import SwiftData
import SwiftUI

/// Sortiermodus von Heute (Spezifikation 5.2): alle aktiven Habits in der gespeicherten Reihenfolge, unabhängig davon,
/// ob sie am angezeigten Tag fällig, erledigt oder pausiert sind. Alle lassen sich per Drag and Drop verschieben, die
/// neue Reihenfolge wird sofort gespeichert (`Habit.saveOrder`). Erledigt und pausiert sind nur leise markiert.
struct HabitSortList: View {
    @Environment(\.modelContext) private var context

    let habits: [Habit]
    let day: Date
    /// Beendet den Sortiermodus. "Fertig" steht rechts im Listenkopf, wie in Heute "Sortieren".
    let onDone: () -> Void

    @Environment(\.firstWeekday) private var firstWeekday
    @Environment(\.habitEngine) private var engine

    var body: some View {
        let shown = Habit.inSavedOrder(habits.filter { $0.isAlive && $0.endedAt == nil })

        List {
            Section {
                HStack {
                    Text(HabitCountText.text(shown.count))
                        .metaText()
                        .foregroundStyle(Theme.inkSecondary)
                        .accessibilityIdentifier("habit-count")
                    Spacer()
                    HermesButton("Fertig", variant: .text, action: onDone)
                        .fixedSize()
                        .accessibilityIdentifier("sort-toggle")
                }
                .moveDisabled(true)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sortieren")
                        .displayText()
                        .foregroundStyle(Theme.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Habits am Griff verschieben.")
                        .bodyText()
                        .foregroundStyle(Theme.inkSecondary)
                }
                .moveDisabled(true)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            Section {
                ForEach(shown) { habit in
                    row(habit)
                }
                .onMove { source, destination in
                    var reordered = shown
                    reordered.move(fromOffsets: source, toOffset: destination)
                    Habit.saveOrder(all: habits.filter(\.isAlive), shown: reordered, in: context)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background { PaperBackground() }
        .listSectionSpacing(0)
        .environment(\.editMode, .constant(.active))
        .accessibilityIdentifier("sort-list")
    }

    /// Icon, Name und Rhythmus wie in Heute, rechts leise markiert, ob der Habit am Tag erledigt oder pausiert ist.
    @ViewBuilder
    private func row(_ habit: Habit) -> some View {
        let snapshot = habit.snapshot
        let isPaused = engine.isShownAsPaused(snapshot, on: day)
        let isDone = !isPaused && engine.isCompleted(snapshot, on: day)

        HStack(spacing: Theme.spacing) {
            HabitIconView(habitName: habit.name, iconName: habit.iconName, color: HabitColor(key: habit.colorKey))
                .opacity(isPaused ? Theme.pausedOpacity : 1)
            VStack(alignment: .leading, spacing: Theme.textSpacing) {
                Text(habit.name)
                    .titleText()
                    .foregroundStyle(isPaused ? Theme.inkSecondary : Theme.ink)
                Text(snapshot.rhythmText(window: engine.windowProgress(snapshot, on: day), firstWeekday: firstWeekday, periods: engine.periods))
                    .metaText()
                    .foregroundStyle(Theme.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if isPaused {
                Chip(text: "Pausiert")
                    .opacity(Theme.pausedOpacity)
            } else if isDone {
                Image(systemName: "checkmark")
                    .font(Theme.Typography.symbol)
                    .foregroundStyle(Theme.inkSecondary)
                    .accessibilityLabel("Erledigt")
            }
        }
        .padding(.vertical, Theme.cardPadding)
        .overlay(alignment: .top) { Hairline() }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("sort-row-\(habit.name)")
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: Theme.spacing, bottom: 0, trailing: Theme.spacing))
    }
}
