import SwiftData
import SwiftUI

/// Die Aktionen eines Habits (Phase 18.4): Bearbeiten, Pausieren und Beenden. Das Habit Detail löst sie über seine
/// Buttons aus, Karten und Zeilen über das Kontextmenü beim langen Drücken. Beide nutzen dieselben Sheets und denselben
/// Dialog (`habitActions`).
struct HabitActionState {
    enum Sheet: Identifiable {
        case edit, pause

        var id: Self { self }
    }

    /// Das offene Sheet: "Habit bearbeiten" bzw. "Neue Pause" mit diesem Habit vorausgewählt.
    var sheet: Sheet?
    /// Ob der Dialog "Habit beenden?" offen ist (Spezifikation 3.9).
    var isConfirmingEnd = false
}

/// Die drei Einträge des Kontextmenüs.
struct HabitActionMenuItems: View {
    @Binding var state: HabitActionState

    var body: some View {
        Button("Bearbeiten", systemImage: "pencil") { state.sheet = .edit }
        Button("Pausieren", systemImage: "pause") { state.sheet = .pause }
        Button("Habit beenden", systemImage: "stop", role: .destructive) { state.isConfirmingEnd = true }
    }
}

/// Zeigt die Sheets und den Dialog zu `state`. Historie behalten: der Habit ist ab heute beendet. Historie löschen:
/// Habit, Erledigungen und Pausen Zuordnung sind weg (3.9), vorher ruft es `onDeleteHistory` (z.B. Zurück im Detail).
private struct HabitActionPresenter: ViewModifier {
    @Environment(\.modelContext) private var context
    @Environment(\.habitEngine) private var engine

    let habit: Habit
    @Binding var state: HabitActionState
    let onDeleteHistory: () -> Void

    func body(content: Content) -> some View {
        content
            .sheet(item: $state.sheet) { sheet in
                switch sheet {
                case .edit: HabitEditorSheet(habit: habit)
                case .pause: PauseEditorSheet(preselecting: habit)
                }
            }
            .alert("Habit beenden?", isPresented: $state.isConfirmingEnd) {
                Button("Historie behalten") { endHabit(keepingHistory: true) }
                Button("Historie löschen", role: .destructive) { endHabit(keepingHistory: false) }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Der Habit erscheint nicht mehr in Heute. Historie in Kalender und Statistik behalten oder löschen? Gelöschte Historie lässt sich nicht wiederherstellen.")
            }
    }

    private func endHabit(keepingHistory: Bool) {
        if keepingHistory {
            habit.end(on: AppClock.now, engine: engine, in: context)
        } else {
            onDeleteHistory()
            habit.deleteWithHistory(in: context)
        }
    }
}

/// Langes Drücken öffnet das Kontextmenü mit den Aktionen. Ein beendeter Habit hat kein Menü.
/// Die angehobene Karte hat rundum Luft (`Theme.spacing`), runde Ecken wie das Menü und keine Haarlinie: Die Fläche
/// reicht seitlich über die Zeile hinaus, ohne das Layout zu verschieben, und die Form der Vorschau ist um 1 pt
/// eingerückt, sodass die Haarlinie oben an der Karte abgeschnitten wird.
private struct HabitContextMenu: ViewModifier {
    let habit: Habit
    @State private var state = HabitActionState()

    func body(content: Content) -> some View {
        if habit.isAlive, habit.endedAt == nil {
            content
                .padding(.horizontal, Theme.spacing)
                .background(Theme.background)
                .contentShape(
                    .contextMenuPreview,
                    RoundedRectangle(cornerRadius: Theme.contextPreviewCornerRadius).inset(by: Theme.strokeWidth)
                )
                .contextMenu { HabitActionMenuItems(state: $state) }
                .padding(.horizontal, -Theme.spacing)
                .habitActions(habit, state: $state)
        } else {
            content
        }
    }
}

extension View {
    /// Sheets und Dialog für die Aktionen eines Habits, ausgelöst über `state`.
    func habitActions(_ habit: Habit, state: Binding<HabitActionState>, onDeleteHistory: @escaping () -> Void = {}) -> some View {
        modifier(HabitActionPresenter(habit: habit, state: state, onDeleteHistory: onDeleteHistory))
    }

    /// Kontextmenü mit Bearbeiten, Pausieren und Habit beenden beim langen Drücken.
    func habitContextMenu(_ habit: Habit) -> some View {
        modifier(HabitContextMenu(habit: habit))
    }
}
