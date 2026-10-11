import SwiftUI

/// Text "5 von 16 · 31 %" in Rolle `meta` und darunter die `SegmentBar`. Bis Phase 9 der Fortschritt in Heute und im
/// Sheet "Tag bearbeiten".
struct ProgressHeader: View {
    let progress: DayProgress

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.inlineSpacing) {
            Text(text)
                .metaText()
                .foregroundStyle(Theme.ink)
            SegmentBar(done: progress.done, total: progress.total)
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityIdentifier("progress-text")
        .accessibilityAddTraits(.isStaticText)
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
        ProgressHeader(progress: DayProgress(done: 4, total: 6))
        ProgressHeader(progress: DayProgress(done: 5, total: 16))
        ProgressHeader(progress: DayProgress(done: 0, total: 0))
    }
    .padding()
    .background { PaperBackground() }
}
