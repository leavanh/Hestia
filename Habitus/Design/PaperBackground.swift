import SwiftUI

/// Fläche `background` für alle Bildschirme und Sheets: hell Papier, dunkel Nachtblau.
struct PaperBackground: View {
    var body: some View {
        Theme.background
            .ignoresSafeArea()
    }
}

#Preview {
    ZStack {
        PaperBackground()
        Text("Papier").bodyText().foregroundStyle(Theme.ink)
    }
}
