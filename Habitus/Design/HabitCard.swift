import SwiftUI

/// Karte eines Habits: links Icon mit Statusmarke, Name, Rhythmus Zeile und 7 Tage Punkte, rechts Abhakkreis oder Counter.
/// Festes Drücken (`Theme.editPressDuration`) auf die linke Seite ruft `onEdit` auf (auch als VoiceOver Aktion "Bearbeiten"),
/// die rechte Seite bedient sich selbst. Dabei sinkt die Karte kurz ein und gibt einen leichten, beim Auslösen einen festen Impuls.
struct HabitCard<Control: View>: View {
    let name: String
    let iconName: String
    let habitColor: HabitColor
    let status: HabitStatus
    let rhythmText: String
    let dots: [WeekDot]
    let onEdit: () -> Void
    @ViewBuilder var control: Control

    @State private var editCount = 0
    @State private var isPressing = false
    /// Wird nach `Theme.editPressPreviewDelay` Drücken wahr, nicht schon beim bloßen Berühren (z.B. zum Scrollen).
    @State private var isPreviewing = false

    var body: some View {
        HStack(spacing: Theme.spacing) {
            HStack(spacing: Theme.spacing) {
                HabitIconView(habitName: name, iconName: iconName, color: habitColor, status: status)
                VStack(alignment: .leading, spacing: 6) {
                    Text(name)
                        .font(.headline)
                    Text(rhythmText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .accessibilityIdentifier("repeat-\(name)")
                    WeekDots(dots: dots, color: habitColor.color)
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
        }
        .glassCard()
        .scaleEffect(isPreviewing ? Theme.pressedCardScale : 1)
        .animation(.spring(duration: 0.25, bounce: 0.3), value: isPreviewing)
    }
}

#Preview {
    ZStack {
        GlassBackground()
        VStack(spacing: Theme.spacing) {
            HabitCard(
                name: "Sport", iconName: "figure.run", habitColor: .orange, status: .yellow,
                rhythmText: "1 von 3 diese Woche",
                dots: [.fill(0), .fill(0), .fill(1), .fill(1), .fill(0), .fill(1), .fill(0)], onEdit: {}
            ) {
                CheckCircle(isChecked: false, color: HabitColor.orange.color) {}
            }
            HabitCard(
                name: "Wasser trinken", iconName: "drop.fill", habitColor: .teal, status: .green,
                rhythmText: "3 pro Tag",
                dots: [.fill(1), .fill(0.66), .fill(0.33), .fill(1), .fill(0), .fill(1), .fill(0.66)], onEdit: {}
            ) {
                CounterControl(count: 2, target: 3, color: HabitColor.teal.color, id: "p", onDecrement: {}, onIncrement: {})
            }
            HabitCard(
                name: "Yoga", iconName: "figure.walk", habitColor: .violet, status: .red,
                rhythmText: "Mo, Do",
                dots: [.fill(0), .fill(1), .fill(0), .fill(0), .fill(1), .fill(0), .fill(0)], onEdit: {}
            ) {
                CheckCircle(isChecked: false, color: HabitColor.violet.color) {}
            }
        }
        .padding()
    }
}
