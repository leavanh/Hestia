import SwiftUI

/// Sieben Quadrate M D M D F S S zur Auswahl von Wochentagen (1 = Montag bis 7 = Sonntag).
struct WeekdayPicker: View {
    @Binding var selection: Set<Int>
    let habitColor: HabitColor

    private static let days: [(number: Int, initial: String, name: String)] = [
        (1, "M", "Montag"), (2, "D", "Dienstag"), (3, "M", "Mittwoch"), (4, "D", "Donnerstag"),
        (5, "F", "Freitag"), (6, "S", "Samstag"), (7, "S", "Sonntag"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Self.days, id: \.number) { day in
                let isSelected = selection.contains(day.number)
                Button {
                    toggle(day.number)
                } label: {
                    Text(day.initial)
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
                .accessibilityLabel(day.name)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("weekday-\(day.number)")
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
