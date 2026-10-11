import SwiftUI

/// Ein Button Stil mit Varianten (Spezifikation 4.4): Fläche, Farbe und Abstände. Die Schrift (Rolle `label`, Versalien)
/// setzt der Text im Button mit `labelText()`, nicht der Stil: Versalien im Stil würden auch den Namen ändern, den
/// VoiceOver und UI Tests lesen. `HermesButton` ist der übliche Weg.
struct HermesButtonStyle: ButtonStyle {
    enum Variant {
        /// Fläche `ink`, Schrift `background`.
        case primary
        /// Leise Variante (in der Spezifikation "secondary"): Fläche `ink` mit 14 %, Schrift `ink`.
        case quiet
        /// Fläche `onBand` mit 20 %, Schrift `onBand`, für das Kopfband.
        case onBand
        /// Ohne Fläche, Schrift `ink`.
        case text
        /// Wie `quiet`, Schrift und Fläche in Statusrot.
        case destructive
    }

    @Environment(\.isEnabled) private var isEnabled

    let variant: Variant
    /// Quadrat in Mindesthöhe ohne seitlichen Abstand, für Buttons mit nur einem Symbol (z.B. Plus in der Leiste).
    var isSquare = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .multilineTextAlignment(.center)
            .padding(.horizontal, variant == .text || isSquare ? 0 : Theme.buttonPaddingHorizontal)
            .padding(.vertical, isSquare ? 0 : Theme.buttonPaddingVertical)
            .frame(minWidth: isSquare ? Theme.buttonMinHeight : nil, minHeight: Theme.buttonMinHeight)
            .background {
                if let fill {
                    RoundedRectangle(cornerRadius: Theme.cornerRadius).fill(fill)
                }
            }
            .contentShape(Rectangle())
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : Theme.disabledOpacity)
    }

    private var foreground: Color {
        switch variant {
        case .primary: Theme.background
        case .quiet, .text: Theme.ink
        case .onBand: Theme.onBand
        case .destructive: Theme.statusRed
        }
    }

    private var fill: Color? {
        switch variant {
        case .primary: Theme.ink
        case .quiet: Theme.ink.opacity(Theme.fillOpacity)
        case .onBand: Theme.onBand.opacity(Theme.onBandFillOpacity)
        case .text: nil
        case .destructive: Theme.statusRed.opacity(Theme.fillOpacity)
        }
    }
}

/// Button mit Titel in Rolle `label` im Stil `HermesButtonStyle`.
struct HermesButton: View {
    let title: String
    var variant: HermesButtonStyle.Variant
    var role: ButtonRole?
    let action: () -> Void

    init(_ title: String, variant: HermesButtonStyle.Variant = .primary, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.variant = variant
        self.role = role
        self.action = action
    }

    var body: some View {
        Button(role: role, action: action) {
            Text(title).labelText()
        }
        .buttonStyle(.hermes(variant))
    }
}

extension ButtonStyle where Self == HermesButtonStyle {
    static func hermes(_ variant: HermesButtonStyle.Variant, isSquare: Bool = false) -> HermesButtonStyle {
        HermesButtonStyle(variant: variant, isSquare: isSquare)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Theme.spacing) {
        HermesButton("Ersten Habit anlegen") {}
        HermesButton("Pause beenden", variant: .quiet) {}
        HermesButton("Sortieren", variant: .text) {}
        HermesButton("Habit beenden", variant: .destructive) {}
        HermesButton("Heute ›", variant: .onBand) {}
            .padding().background(Theme.band)
    }
    .padding()
    .background { PaperBackground() }
}
