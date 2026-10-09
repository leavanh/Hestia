import SwiftUI

/// Auswahl aus wenigen Optionen in einer Zeile, wie ein Segmentfeld. Lange Beschriftungen werden
/// kleiner statt abgeschnitten.
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
                        .font(.footnote.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity, minHeight: Theme.segmentHeight)
                        .background {
                            if isSelected {
                                Capsule().fill(Theme.segmentSelected)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier(id(option))
            }
        }
        .padding(2)
        .background(Theme.segmentTrack, in: Capsule())
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    @Previewable @State var group = RhythmGroup.week
    SegmentedChoice(options: RhythmGroup.allCases, selection: $group, title: \.title, id: { "\($0)" })
        .padding()
}
