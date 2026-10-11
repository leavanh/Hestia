import SwiftUI

/// Auswahl aus wenigen Optionen in einer Zeile, wie ein Segmentfeld: 0,5 pt Rahmen in `ink`, Segmente in Rolle `label`,
/// das gewählte Segment invertiert (Fläche `ink`, Schrift `background`). Lange Beschriftungen werden kleiner statt
/// abgeschnitten.
struct SegmentedChoice<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let title: (Value) -> String
    let id: (Value) -> String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    selection = option
                } label: {
                    Text(title(option))
                        .labelText()
                        .foregroundStyle(isSelected ? Theme.background : Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity, minHeight: Theme.segmentHeight)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: Theme.cornerRadius).fill(Theme.ink)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier(id(option))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .strokeBorder(Theme.ink, lineWidth: Theme.hairlineWidth)
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    @Previewable @State var group = RhythmGroup.week
    SegmentedChoice(options: RhythmGroup.allCases, selection: $group, title: \.title, id: { "\($0)" })
        .padding()
        .background { PaperBackground() }
}
