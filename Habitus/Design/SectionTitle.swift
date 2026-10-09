import SwiftUI

/// Kleine Überschrift über einer Glaskarte (Felder im Sheet).
struct SectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, Theme.cardPadding)
            .accessibilityAddTraits(.isHeader)
    }
}
