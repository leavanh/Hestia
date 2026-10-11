import SwiftUI

/// Flache Zeile einer laufenden oder geplanten Pause in den Einstellungen, oben eine Haarlinie: Zeitraum in `title`,
/// betroffene Habits in `meta`, ein Chip "Läuft" bzw. "Geplant" und der Button zum Beenden (laufend) bzw. Entfernen (geplant).
struct PauseRow: View {
    let habitNames: String
    let rangeText: String
    let phase: PausePhase
    let onEnd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.inlineSpacing) {
            AdaptiveStack(verticalAlignment: .firstTextBaseline, spacing: Theme.inlineSpacing) {
                Text(rangeText)
                    .titleText()
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Chip(text: phase == .running ? "Läuft" : "Geplant", isInverted: phase == .running)
            }
            Text(habitNames)
                .metaText()
                .foregroundStyle(Theme.inkSecondary)
            HermesButton(phase == .running ? "Pause beenden" : "Pause entfernen", variant: .quiet, action: onEnd)
                .accessibilityIdentifier("end-pause-\(habitNames)")
        }
        .padding(.vertical, Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { Hairline() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pause-row-\(habitNames)")
    }
}

#Preview {
    ZStack {
        PaperBackground()
        VStack(spacing: 0) {
            PauseRow(habitNames: "Sport, Lesen", rangeText: "8. Okt. – 10. Okt.", phase: .running) {}
            PauseRow(habitNames: "Yoga", rangeText: "20. Okt. – 25. Okt.", phase: .upcoming) {}
        }
        .padding()
    }
}
