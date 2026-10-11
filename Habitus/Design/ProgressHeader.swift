import SwiftUI

/// Fortschrittsring und Text "5 von 16 · 31 %".
struct ProgressHeader: View {
    let progress: DayProgress

    var body: some View {
        HStack(spacing: Theme.spacing) {
            ProgressRing(fraction: progress.fraction, color: Theme.accent)
                .frame(width: Theme.progressRingSize, height: Theme.progressRingSize)
            Text(text)
                .font(.headline)
                .accessibilityIdentifier("progress-text")
        }
        .accessibilityElement(children: .combine)
    }

    /// Zwischen Zahl und Prozentzeichen ein geschütztes Leerzeichen, damit "%" bei großer Schrift nicht allein umbricht.
    private var text: String {
        progress.total == 0
            ? "Heute nichts fällig"
            : "\(progress.done) von \(progress.total) · \(progress.percent)\u{00A0}%"
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Theme.spacing) {
        ProgressHeader(progress: DayProgress(done: 5, total: 16))
        ProgressHeader(progress: DayProgress(done: 0, total: 0))
    }
    .padding()
}
