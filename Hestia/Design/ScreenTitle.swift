import SwiftUI

/// Großer Titel eines Tabs (Kalender, Einstellungen) in Rolle `display`, links bündig im Inhalt.
struct ScreenTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .displayText()
            .foregroundStyle(Theme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    ScreenTitle("Einstellungen")
        .padding()
        .background { PaperBackground() }
}
