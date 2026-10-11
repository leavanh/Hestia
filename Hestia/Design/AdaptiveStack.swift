import SwiftUI

/// Nebeneinander wie ein `HStack`, bei großer Schrift (Dynamic Type, Bedienungshilfen Größen) untereinander wie ein
/// `VStack`, damit nichts abgeschnitten wird oder Wort für Wort umbricht.
struct AdaptiveStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var verticalAlignment: VerticalAlignment = .center
    var spacing: CGFloat = Theme.spacing
    @ViewBuilder var content: Content

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
            : AnyLayout(HStackLayout(alignment: verticalAlignment, spacing: spacing))
        layout { content }
    }
}

extension View {
    /// Für Symbole und Zahlen in Quadraten fester Größe: wachsen mit der Schrift nur so weit, wie das Quadrat Platz hat.
    func fixedControlTypeSize() -> some View {
        dynamicTypeSize(...Theme.maxControlTypeSize)
    }
}

#Preview {
    AdaptiveStack {
        Text("Sport")
        Chip(text: "Pausiert")
    }
    .padding()
    .background { PaperBackground() }
}
