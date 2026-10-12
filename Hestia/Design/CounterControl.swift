import SwiftUI

/// Taste "−", Wert als "5/8", Taste "+". Die Tasten sind Quadrate wie bei `CheckBox`, die Gesamthöhe ist dieselbe.
/// Für VoiceOver ist der Wert ein einstellbares Element ("Sport, 2 von 3"), Wischen nach oben oder unten zählt.
struct CounterControl: View {
    let count: Int
    let target: Int
    let habitColor: HabitColor
    /// Was VoiceOver für den Wert liest, z.B. der Habit Name.
    var label = localized("Erledigt")
    /// Grundlage für die Bezeichner der drei Teile ("<id>-minus", "<id>-value", "<id>-plus").
    let id: String
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: Theme.controlSpacing) {
            StepButton(systemImage: "minus", color: habitColor.color, action: onDecrement)
                .disabled(count <= 0)
                .accessibilityLabel("Weniger")
                .accessibilityHint("Zählt eins zurück.")
                .accessibilityIdentifier("\(id)-minus")

            Text("\(count)/\(target)")
                .font(Theme.Typography.metaMedium)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .fixedControlTypeSize()
                .frame(minWidth: Theme.counterKeySize, minHeight: Theme.controlSize)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
                .accessibilityValue(localized("\(count) von \(target)"))
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: if count < target { onIncrement() }
                    case .decrement: if count > 0 { onDecrement() }
                    @unknown default: break
                    }
                }
                .accessibilityIdentifier("\(id)-value")

            StepButton(systemImage: "plus", color: habitColor.color, action: onIncrement)
                .disabled(count >= target)
                .accessibilityLabel("Mehr")
                .accessibilityHint("Zählt eins dazu.")
                .accessibilityIdentifier("\(id)-plus")
        }
        .frame(height: Theme.controlSize)
    }
}

/// Quadrat mit 1 pt Rand in `color` und Symbol, gedimmt wenn nicht benutzbar. Auch für `StepperControl`.
struct StepButton: View {
    @Environment(\.isEnabled) private var isEnabled

    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle().strokeBorder(color, lineWidth: Theme.strokeWidth)
                Image(systemName: systemImage)
                    .font(Theme.Typography.symbolSmall)
                    .foregroundStyle(color)
                    .fixedControlTypeSize()
            }
            .frame(width: Theme.counterKeySize, height: Theme.counterKeySize)
            .frame(minHeight: Theme.controlSize)
            .contentShape(Rectangle())
            .opacity(isEnabled ? 1 : Theme.disabledOpacity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: Theme.spacing) {
        CounterControl(count: 0, target: 3, habitColor: .teal, id: "a", onDecrement: {}, onIncrement: {})
        CounterControl(count: 2, target: 3, habitColor: .teal, id: "b", onDecrement: {}, onIncrement: {})
        CounterControl(count: 10, target: 10, habitColor: .pink, id: "c", onDecrement: {}, onIncrement: {})
    }
    .padding()
    .background { PaperBackground() }
}
