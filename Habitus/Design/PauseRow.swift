import SwiftUI

/// Zeile einer laufenden oder geplanten Pause in den Einstellungen: betroffene Habits, Zeitraum, ein Kapsel-Hinweis
/// "Läuft" bzw. "Geplant" und der Button zum Beenden (laufend) bzw. Entfernen (geplant).
struct PauseRow: View {
    let habitNames: String
    let rangeText: String
    let phase: PausePhase
    let onEnd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(habitNames)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                DayBadge(text: phase == .running ? "Läuft" : "Geplant", isToday: phase == .running)
            }
            Text(rangeText)
                .font(.caption)
                .foregroundStyle(.secondary)
            Button(phase == .running ? "Pause beenden" : "Pause entfernen", action: onEnd)
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.borderless)
                .accessibilityIdentifier("end-pause-\(habitNames)")
        }
        .glassCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pause-row-\(habitNames)")
    }
}

#Preview {
    ZStack {
        GlassBackground()
        VStack(spacing: Theme.spacing) {
            PauseRow(habitNames: "Sport, Lesen", rangeText: "8. Okt. – 10. Okt.", phase: .running) {}
            PauseRow(habitNames: "Yoga", rangeText: "20. Okt. – 25. Okt.", phase: .upcoming) {}
        }
        .padding()
    }
}
