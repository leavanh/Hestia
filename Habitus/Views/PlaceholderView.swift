import SwiftUI

/// Vorläufiger Inhalt für Tabs, die in späteren Phasen gebaut werden.
struct PlaceholderView: View {
    let title: String
    let systemImage: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(title, systemImage: systemImage, description: Text("Kommt bald."))
                .background { GlassBackground() }
                .navigationTitle(title)
        }
    }
}
