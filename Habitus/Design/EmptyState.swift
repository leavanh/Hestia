import SwiftUI

/// Leerzustand in einer Glaskarte: Symbol, kurzer Titel, ein Satz Erklärung und optional ein Button.
/// Für Heute ohne Habits, den Kalender ohne Daten und die Einstellungen ohne Pausen.
struct EmptyState: View {
    let systemImage: String
    let title: String
    let message: String
    /// Bezeichner des Erklärungstexts für Tests.
    var identifier = "empty-state"
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Theme.textSpacing) {
            Image(systemName: systemImage)
                .font(.title)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
                .padding(.bottom, Theme.textSpacing)
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier(identifier)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.headline)
                    .buttonStyle(.glassProminent)
                    .padding(.top, Theme.spacing)
                    .accessibilityIdentifier("\(identifier)-action")
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacing)
        .glassCard()
    }
}

#Preview {
    ZStack {
        GlassBackground()
        VStack(spacing: Theme.spacing) {
            EmptyState(
                systemImage: "checkmark.circle", title: "Noch keine Habits",
                message: "Lege deinen ersten Habit an.", actionTitle: "Habit anlegen", action: {}
            )
            EmptyState(systemImage: "pause.circle", title: "Keine Pausen", message: "Es gibt keine laufenden oder geplanten Pausen.")
        }
        .padding()
    }
}
