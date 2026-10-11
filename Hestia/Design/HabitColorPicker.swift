import SwiftUI

/// Farbauswahl im Sheet: 8 Quadrate (28 pt) in Habitfarbe in der Reihenfolge des Farbkreises, das gewählte
/// mit äußerem Rahmen in `ink`.
struct HabitColorPicker: View {
    @Binding var selection: HabitColor

    var body: some View {
        HStack {
            ForEach(HabitColor.allCases) { option in
                Button {
                    selection = option
                } label: {
                    Rectangle()
                        .fill(option.color)
                        .frame(width: Theme.swatchSize, height: Theme.swatchSize)
                        .padding(4)
                        .overlay {
                            if option == selection {
                                Rectangle().strokeBorder(Theme.ink, lineWidth: Theme.strokeWidth)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.title)
                .accessibilityAddTraits(option == selection ? .isSelected : [])
                .accessibilityIdentifier("color-\(option.rawValue)")
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    @Previewable @State var selection = HabitColor.teal
    HabitColorPicker(selection: $selection)
        .padding()
        .background { PaperBackground() }
}
