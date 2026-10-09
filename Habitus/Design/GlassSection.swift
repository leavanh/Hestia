import SwiftUI

/// Abschnitt mit kleiner Überschrift und Glaskarte, z.B. für Felder in Sheets.
struct GlassSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title)
            content
                .glassCard()
        }
    }
}
