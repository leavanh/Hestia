import SwiftUI

/// Minus im Kreis, Ring mit Zahl in der Mitte, Plus im Kreis. Kreise wie bei `CheckCircle`.
struct CounterControl: View {
    let count: Int
    let target: Int
    let color: Color
    /// Grundlage für die Bezeichner der drei Teile ("<id>-minus", "<id>-value", "<id>-plus").
    let id: String
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: Theme.controlSpacing) {
            StepButton(systemImage: "minus", color: color, action: onDecrement)
                .disabled(count <= 0)
                .accessibilityLabel("Weniger")
                .accessibilityIdentifier("\(id)-minus")

            ZStack {
                ProgressRing(fraction: target > 0 ? Double(count) / Double(target) : 0, color: color)
                Text("\(count)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(Theme.ringWidth + 1)
            }
            .frame(width: Theme.controlSize, height: Theme.controlSize)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Erledigt")
            .accessibilityValue("\(count) von \(target)")
            .accessibilityIdentifier("\(id)-value")

            StepButton(systemImage: "plus", color: color, action: onIncrement)
                .disabled(count >= target)
                .accessibilityLabel("Mehr")
                .accessibilityIdentifier("\(id)-plus")
        }
    }
}

/// Kreis mit Umriss in Habitfarbe und Symbol, gedimmt wenn nicht benutzbar.
private struct StepButton: View {
    @Environment(\.isEnabled) private var isEnabled

    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().strokeBorder(color, lineWidth: Theme.strokeWidth)
                Image(systemName: systemImage)
                    .font(.body.weight(.bold))
                    .foregroundStyle(color)
            }
            .frame(width: Theme.controlSize, height: Theme.controlSize)
            .contentShape(Circle())
            .opacity(isEnabled ? 1 : Theme.disabledOpacity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: Theme.spacing) {
        CounterControl(count: 0, target: 3, color: HabitColor.teal.color, id: "a", onDecrement: {}, onIncrement: {})
        CounterControl(count: 2, target: 3, color: HabitColor.teal.color, id: "b", onDecrement: {}, onIncrement: {})
        CounterControl(count: 10, target: 10, color: HabitColor.pink.color, id: "c", onDecrement: {}, onIncrement: {})
    }
    .padding()
}
