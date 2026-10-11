import SwiftUI

/// Kleine Kapsel mit 2 pt Ecken für "Pausiert", "Läuft", "Geplant" und (bis Phase 9) den Tag in Heute.
/// Ein invertierter Chip (Fläche `ink`, Schrift `background`) hebt den Tag "Heute" hervor.
struct Chip: View {
    let text: String
    var isInverted = false

    var body: some View {
        Text(text)
            .labelText(small: true)
            .foregroundStyle(isInverted ? Theme.background : Theme.ink)
            .padding(.horizontal, Theme.chipPaddingHorizontal)
            .padding(.vertical, Theme.chipPaddingVertical)
            .background(
                isInverted ? Theme.ink : Theme.ink.opacity(Theme.fillOpacity),
                in: RoundedRectangle(cornerRadius: Theme.cornerRadius)
            )
    }
}

#Preview {
    HStack {
        Chip(text: "Heute", isInverted: true)
        Chip(text: "Gestern")
        Chip(text: "Pausiert")
    }
    .padding()
    .background { PaperBackground() }
}
