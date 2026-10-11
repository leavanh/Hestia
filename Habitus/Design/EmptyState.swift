import SwiftUI

/// Leerzustand ohne Karte: Titel in Rolle `display` (klein), ein Satz Erklärung in `body` und optional ein Button.
/// Für Heute ohne Habits, den Kalender ohne Daten und die Einstellungen ohne Pausen.
struct EmptyState: View {
    let title: String
    let message: String
    /// Bezeichner des Erklärungstexts für Tests.
    var identifier = "empty-state"
    /// Haarlinie oben. Entfällt, wenn der Leerzustand schon in einem `PaperSection` steht.
    var showsHairline = true
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.inlineSpacing) {
            if showsHairline { Hairline() }
            Text(title)
                .displayText(small: true)
                .foregroundStyle(Theme.ink)
                .padding(.top, showsHairline ? Theme.textSpacing : 0)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .bodyText()
                .foregroundStyle(Theme.inkSecondary)
                .accessibilityIdentifier(identifier)
            if let actionTitle, let action {
                HermesButton(actionTitle, action: action)
                    .padding(.top, Theme.spacing)
                    .accessibilityIdentifier("\(identifier)-action")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Theme.spacing)
    }
}

#Preview {
    ZStack {
        PaperBackground()
        VStack(spacing: Theme.spacing) {
            EmptyState(
                title: "Noch keine Habits",
                message: "Lege deinen ersten Habit an.", actionTitle: "Habit anlegen", action: {}
            )
            EmptyState(title: "Keine Pausen", message: "Es gibt keine laufenden oder geplanten Pausen.")
        }
        .padding()
    }
}
