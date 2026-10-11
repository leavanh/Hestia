import SwiftUI

/// Abschnitt ohne Karte: oben eine Haarlinie, darunter die Überschrift in Rolle `meta` und der Inhalt.
/// Für Felder in Sheets und die Abschnitte der Einstellungen.
struct PaperSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.inlineSpacing) {
            Hairline()
            Text(title)
                .metaText()
                .foregroundStyle(Theme.inkSecondary)
                .padding(.top, Theme.textSpacing)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Haarlinie (0,5 pt) in `hairline`.
struct Hairline: View {
    var body: some View {
        Theme.hairline
            .frame(height: Theme.hairlineWidth)
            .accessibilityHidden(true)
    }
}

#Preview {
    PaperSection(title: "Zeitraum") {
        Text("Von bis").bodyText()
    }
    .padding()
    .background { PaperBackground() }
}
