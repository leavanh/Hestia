import SwiftUI

/// Flache Zeile eines Habits mit Haarlinie oben: links Icon mit Statusmarke, daneben in drei festen Zeilen der Name mit
/// dem Zusatz klein rechts daneben, die Häufigkeit und die 7 Tage Punkte (ab Phase 18.4), rechts `CheckBox` oder
/// `CounterControl`.
/// Antippen der linken Seite ruft `onOpen` auf (Habit Detail, für VoiceOver ein Button mit dem Namen des Habits),
/// die rechte Seite bedient sich selbst. Ein pausierter Habit ist ausgegraut, trägt den Chip "Pausiert" neben dem Namen
/// und lässt sich nicht abhaken.
struct HabitCard<Control: View>: View {
    let name: String
    let iconName: String
    let habitColor: HabitColor
    let status: HabitStatus
    /// Der Zusatz (Spezifikation 5.3), leer wenn keiner da ist.
    var extraText = ""
    /// Die Häufigkeit ohne Zusatz (`HabitSnapshot.frequencyText`).
    let rhythmText: String
    let dots: [WeekDot]
    var isPaused = false
    let onOpen: () -> Void
    @ViewBuilder var control: Control

    var body: some View {
        // Bei großer Schrift stehen Icon, Texte und Bedienelement untereinander, damit nichts abgeschnitten wird.
        AdaptiveStack {
            AdaptiveStack {
                HabitIconView(habitName: name, iconName: iconName, color: habitColor, status: isPaused ? .green : status)
                    .opacity(isPaused ? Theme.pausedOpacity : 1)
                VStack(alignment: .leading, spacing: Theme.textSpacing) {
                    AdaptiveStack(verticalAlignment: .firstTextBaseline, spacing: Theme.inlineSpacing) {
                        Text(name)
                            .titleText()
                            .foregroundStyle(isPaused ? Theme.inkSecondary : Theme.ink)
                            .layoutPriority(1)
                        if !extraText.isEmpty {
                            Text(extraText)
                                .metaText()
                                .lineLimit(1)
                                .foregroundStyle(Theme.inkSecondary)
                                .accessibilityIdentifier("extra-\(name)")
                        }
                        if isPaused {
                            Chip(text: "Pausiert")
                                .accessibilityIdentifier("paused-\(name)")
                        }
                    }
                    rhythmLine
                    weekDots
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpen)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(name)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(.default, onOpen)
            .accessibilityIdentifier("open-\(name)")

            control
                .disabled(isPaused)
                .opacity(isPaused ? Theme.pausedOpacity : 1)
        }
        .padding(.vertical, Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { Hairline() }
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
                name: "Sport", iconName: "figure.run", habitColor: .orange, status: .yellow, extraText: "45 Min",
                rhythmText: "1 von 3 diese Woche",
                dots: [.fill(0), .fill(0), .fill(1), .fill(1), .fill(0), .fill(1), .fill(0)], onOpen: {}
            ) {
                CheckBox(isChecked: false, habitColor: .orange) {}
            }
            HabitCard(
                name: "Wasser trinken", iconName: "drop.fill", habitColor: .teal, status: .green,
                rhythmText: "3 pro Tag",
                dots: [.fill(1), .fill(0.66), .fill(0.33), .fill(1), .fill(0), .fill(1), .fill(0.66)], onOpen: {}
            ) {
                CounterControl(count: 2, target: 3, habitColor: .teal, id: "p", onDecrement: {}, onIncrement: {})
            }
            HabitCard(
                name: "Yoga", iconName: "figure.walk", habitColor: .violet, status: .red,
                rhythmText: "Mo · Do",
                dots: [.fill(0), .fill(1), .fill(0), .fill(0), .fill(1), .fill(0), .fill(0)], onOpen: {}
            ) {
                CheckBox(isChecked: true, habitColor: .violet) {}
            }
            HabitCard(
                name: "Lesen", iconName: "book.fill", habitColor: .pink, status: .green,
                rhythmText: "Täglich",
                dots: [.fill(1), .fill(1), .paused, .paused, .paused, .paused, .paused], isPaused: true, onOpen: {}
            ) {
                CheckBox(isChecked: false, habitColor: .pink) {}
            }
        }
        .padding(.horizontal)
    }
}
