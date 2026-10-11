import SwiftUI

/// Stich in einem Leerzustand (Phase 12): gemeinfreier Stich, blau gerastert, hell Blau und dunkel Papier.
/// Dekorativ und für VoiceOver ausgeblendet. Quellen in Branding/QUELLEN.md, erzeugt von Branding/render_engravings.py.
struct EngravingImage: View {
    enum Motif: String {
        /// Fackel zwischen Altar und Statuette (Met 371844), Kalender ohne Daten.
        case torch = "EngravingTorch"
        /// Vestalin (Met 402697), Heute ohne Habits.
        case vestal = "EngravingVestal"
    }

    let motif: Motif

    var body: some View {
        Image(motif.rawValue)
            .resizable()
            .scaledToFit()
            .frame(height: Theme.engravingMaxHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityHidden(true)
            .accessibilityIdentifier("engraving-\(motif.rawValue)")
    }
}

#Preview {
    VStack {
        EngravingImage(motif: .torch)
        EngravingImage(motif: .vestal)
    }
    .padding()
    .background { PaperBackground() }
}
