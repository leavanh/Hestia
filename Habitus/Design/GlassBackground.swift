import SwiftUI

/// Ruhiger Farbverlauf für alle Bildschirme.
struct GlassBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Theme.backgroundTop, Theme.backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

extension View {
    /// Karte mit Liquid Glass, durch die der Verlauf leicht durchscheint.
    func glassCard() -> some View {
        padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: Theme.cornerRadius))
    }
}

#Preview {
    ZStack {
        GlassBackground()
        Text("Karte").glassCard().padding()
    }
}
