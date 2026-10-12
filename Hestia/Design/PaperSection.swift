import SwiftUI

/// Abschnitt ohne Karte: oben eine Haarlinie, darunter die Überschrift in Rolle `meta` und der Inhalt.
/// Für Felder in Sheets und die Abschnitte der Einstellungen.
struct PaperSection<Content: View>: View {
    let title: LocalizedStringKey
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
        HairlineColor()
            .frame(height: Theme.hairlineWidth)
            .accessibilityHidden(true)
    }
}

/// Farbe der Haarlinien: `hairline`, im Bereich einer überschriebenen Tinte (`inkOverride`) diese Tinte mit 25 % (hell)
/// bzw. 20 % (dunkel).
struct HairlineColor: View {
    @Environment(\.inkOverride) private var inkOverride
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if let inkOverride {
            inkOverride.opacity(colorScheme == .dark ? 0.2 : 0.25)
        } else {
            Theme.hairline
        }
    }
}

#Preview {
    PaperSection(title: "Zeitraum") {
        Text("Von bis").bodyText()
    }
    .padding()
    .background { PaperBackground() }
}
