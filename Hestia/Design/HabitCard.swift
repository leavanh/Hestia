import SwiftUI

/// Flache Zeile eines Habits mit Haarlinie oben: links Icon mit Statusmarke, Name und darunter Rhythmus Zeile mit den
/// 7 Tage Punkten rechts daneben, rechts `CheckBox` oder `CounterControl`.
/// Festes Drücken (`Theme.editPressDuration`) auf die linke Seite ruft `onEdit` auf (auch als VoiceOver Aktion "Bearbeiten"),
/// die rechte Seite bedient sich selbst. Ein pausierter Habit ist ausgegraut, trägt den Chip "Pausiert" neben dem Namen
/// und lässt sich nicht abhaken. Dabei sinkt die Zeile kurz ein und gibt einen leichten, beim Auslösen einen festen Impuls.
struct HabitCard<Control: View>: View {
    let name: String
    let iconName: String
    let habitColor: HabitColor
    let status: HabitStatus
    let rhythmText: String
    let dots: [WeekDot]
    var isPaused = false
    let onEdit: () -> Void
    @ViewBuilder var control: Control

    @State private var editCount = 0
    @State private var isPressing = false
    /// Wird nach `Theme.editPressPreviewDelay` Drücken wahr, nicht schon beim bloßen Berühren (z.B. zum Scrollen).
    @State private var isPreviewing = false

    var body: some View {
        // Bei großer Schrift stehen Icon, Texte und Bedienelement untereinander, damit nichts abgeschnitten wird.
        AdaptiveStack {
            AdaptiveStack {
                HabitIconView(habitName: name, iconName: iconName, color: habitColor, status: isPaused ? .green : status)
                    .opacity(isPaused ? Theme.pausedOpacity : 1)
                VStack(alignment: .leading, spacing: Theme.textSpacing) {
                    AdaptiveStack(spacing: Theme.inlineSpacing) {
                        Text(name)
                            .titleText()
                            .foregroundStyle(isPaused ? Theme.inkSecondary : Theme.ink)
                        if isPaused {
                            Chip(text: "Pausiert")
                                .accessibilityIdentifier("paused-\(name)")
                        }
                    }
                    // Rhythmus Zeile und 7 Tage Punkte in einer Zeile, bei zu wenig Platz die Punkte darunter.
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: Theme.inlineSpacing) {
                            rhythmLine.fixedSize()
                            weekDots
                        }
                        VStack(alignment: .leading, spacing: Theme.textSpacing) {
                            rhythmLine
                            weekDots
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: Theme.editPressDuration) {
                editCount += 1
                onEdit()
            } onPressingChanged: { pressing in
                isPressing = pressing
            }
            .task(id: isPressing) {
                guard isPressing else {
                    isPreviewing = false
                    return
                }
                try? await Task.sleep(for: .seconds(Theme.editPressPreviewDelay))
                if !Task.isCancelled { isPreviewing = true }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: isPreviewing) { _, preview in preview }
            .sensoryFeedback(.impact(flexibility: .rigid, intensity: 1), trigger: editCount)
            .accessibilityElement(children: .contain)
            .accessibilityAction(named: "Bearbeiten", onEdit)

            control
                .disabled(isPaused)
                .opacity(isPaused ? Theme.pausedOpacity : 1)
        }
        .padding(.vertical, Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { Hairline() }
        .scaleEffect(isPreviewing ? Theme.pressedCardScale : 1)
        .animation(.spring(duration: 0.25, bounce: 0.3), value: isPreviewing)
    }

    private var rhythmLine: some View {
        Text(rhythmText)
            .metaText()
            .foregroundStyle(Theme.inkSecondary)
            .accessibilityIdentifier("repeat-\(name)")
    }

    private var weekDots: some View {
        WeekDots(dots: dots, color: habitColor.color)
    }
}

#Preview {
    ZStack {
        PaperBackground()
        VStack(spacing: 0) {
            HabitCard(
                name: "Sport", iconName: "figure.run", habitColor: .orange, status: .yellow,
                rhythmText: "1 von 3 diese Woche",
                dots: [.fill(0), .fill(0), .fill(1), .fill(1), .fill(0), .fill(1), .fill(0)], onEdit: {}
            ) {
                CheckBox(isChecked: false, habitColor: .orange) {}
            }
            HabitCard(
                name: "Wasser trinken", iconName: "drop.fill", habitColor: .teal, status: .green,
                rhythmText: "3 pro Tag",
                dots: [.fill(1), .fill(0.66), .fill(0.33), .fill(1), .fill(0), .fill(1), .fill(0.66)], onEdit: {}
            ) {
                CounterControl(count: 2, target: 3, habitColor: .teal, id: "p", onDecrement: {}, onIncrement: {})
            }
            HabitCard(
                name: "Yoga", iconName: "figure.walk", habitColor: .violet, status: .red,
                rhythmText: "Mo · Do",
                dots: [.fill(0), .fill(1), .fill(0), .fill(0), .fill(1), .fill(0), .fill(0)], onEdit: {}
            ) {
                CheckBox(isChecked: true, habitColor: .violet) {}
            }
            HabitCard(
                name: "Lesen", iconName: "book.fill", habitColor: .pink, status: .green,
                rhythmText: "Täglich",
                dots: [.fill(1), .fill(1), .paused, .paused, .paused, .paused, .paused], isPaused: true, onEdit: {}
            ) {
                CheckBox(isChecked: false, habitColor: .pink) {}
            }
        }
        .padding(.horizontal)
    }
}
