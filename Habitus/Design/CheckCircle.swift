import SwiftUI

/// Kreis mit Umriss in Habitfarbe, abgehakt gefüllt mit Häkchen. VoiceOver liest `label` (z.B. den Habit Namen)
/// und den Zustand, im Sheet "Neue Pause" "Ausgewählt" statt "Erledigt".
struct CheckCircle: View {
    let isChecked: Bool
    let color: Color
    var label = "Abhaken"
    var checkedText = "Erledigt"
    var uncheckedText = "Offen"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isChecked {
                    Circle().fill(color)
                    Image(systemName: "checkmark")
                        .font(.body.weight(.bold))
                        .foregroundStyle(Theme.onHabitColor)
                        .fixedCircleTypeSize()
                } else {
                    Circle().strokeBorder(color, lineWidth: Theme.strokeWidth)
                }
            }
            .frame(width: Theme.controlSize, height: Theme.controlSize)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(isChecked ? checkedText : uncheckedText)
        .accessibilityAddTraits(isChecked ? .isSelected : [])
    }
}

#Preview {
    HStack(spacing: Theme.spacing) {
        CheckCircle(isChecked: false, color: HabitColor.blue.color) {}
        CheckCircle(isChecked: true, color: HabitColor.green.color) {}
    }
    .padding()
}
