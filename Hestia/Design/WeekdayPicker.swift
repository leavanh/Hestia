import SwiftUI

/// Sieben Quadrate mit den Anfangsbuchstaben der Wochentage, ab dem Wochenbeginn, zur Auswahl von Wochentagen
/// (1 = Montag bis 7 = Sonntag).
struct WeekdayPicker: View {
    @Binding var selection: Set<Int>
    let habitColor: HabitColor

    @Environment(\.firstWeekday) private var firstWeekday

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DayText.weekdays(startingAt: firstWeekday), id: \.self) { day in
                let isSelected = selection.contains(day)
                Button {
                    toggle(day)
                } label: {
                    Text(DayText.weekdayInitial(day))
                        .labelText()
                        .fixedControlTypeSize()
                        .foregroundStyle(isSelected ? habitColor.onColor : habitColor.color)
                        .frame(width: Theme.controlSize, height: Theme.controlSize)
                        .background {
                            if isSelected {
                                Rectangle().fill(habitColor.color)
                            } else {
                                Rectangle().strokeBorder(habitColor.color, lineWidth: Theme.strokeWidth)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(DayText.weekdayFullName(day))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("weekday-\(day)")
            }
        }
    }

    /// Mindestens ein Wochentag bleibt immer ausgewählt.
    private func toggle(_ number: Int) {
        if selection.contains(number) {
            guard selection.count > 1 else { return }
            selection.remove(number)
        } else {
            selection.insert(number)
        }
    }
}

#Preview {
    @Previewable @State var selection: Set<Int> = [1, 4]
    WeekdayPicker(selection: $selection, habitColor: .violet)
        .padding()
        .background { PaperBackground() }
}
