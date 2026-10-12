import SwiftUI

/// Quadrat mit 1 pt Rand in Habitfarbe, abgehakt gefüllt mit Häkchen in `onColor`. VoiceOver liest `label`
/// (z.B. den Habit Namen) und den Zustand, im Sheet "Neue Pause" "Ausgewählt" statt "Erledigt".
struct CheckBox: View {
    let isChecked: Bool
    let habitColor: HabitColor
    var label = localized("Abhaken")
    var checkedText = localized("Erledigt")
    var uncheckedText = localized("Offen")
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isChecked {
                    Rectangle().fill(habitColor.color)
                    Image(systemName: "checkmark")
                        .font(Theme.Typography.symbol)
                        .foregroundStyle(habitColor.onColor)
                        .fixedControlTypeSize()
                } else {
                    Rectangle().strokeBorder(habitColor.color, lineWidth: Theme.strokeWidth)
                }
            }
            .frame(width: Theme.controlSize, height: Theme.controlSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(isChecked ? checkedText : uncheckedText)
        .accessibilityAddTraits(isChecked ? .isSelected : [])
    }
}

#Preview {
    HStack(spacing: Theme.spacing) {
        CheckBox(isChecked: false, habitColor: .blue) {}
        CheckBox(isChecked: true, habitColor: .green) {}
    }
    .padding()
    .background { PaperBackground() }
}
