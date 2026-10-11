import SwiftUI

/// Auswahl einer Zahl mit Text links und rechts Taste "−", Wert, Taste "+" (Spezifikation 4.5). Ersetzt den System
/// `Stepper` und das Menü für den Monatstag. An den Grenzen ist die jeweilige Taste gesperrt. Für VoiceOver ist der Wert
/// ein einstellbares Element (Wischen nach oben oder unten zählt), der Text links wird dabei nicht doppelt gelesen.
struct StepperControl: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    /// Wie der Wert zwischen den Tasten steht, z.B. "15." für den Monatstag.
    var valueText: (Int) -> String = { "\($0)" }
    /// Bezeichner des Werts. Die Tasten heißen "<id>-minus" und "<id>-plus".
    let id: String

    var body: some View {
        HStack(spacing: Theme.controlSpacing) {
            Text(title)
                .bodyText()
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHidden(true)

            StepButton(systemImage: "minus", color: Theme.ink) { value -= 1 }
                .disabled(value <= range.lowerBound)
                .accessibilityLabel("Weniger")
                .accessibilityIdentifier("\(id)-minus")

            Text(valueText(value))
                .font(Theme.Typography.metaMedium)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .fixedControlTypeSize()
                .frame(minWidth: Theme.counterKeySize, minHeight: Theme.controlSize)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(title)
                .accessibilityValue(valueText(value))
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: if value < range.upperBound { value += 1 }
                    case .decrement: if value > range.lowerBound { value -= 1 }
                    @unknown default: break
                    }
                }
                .accessibilityIdentifier(id)

            StepButton(systemImage: "plus", color: Theme.ink) { value += 1 }
                .disabled(value >= range.upperBound)
                .accessibilityLabel("Mehr")
                .accessibilityIdentifier("\(id)-plus")
        }
        .frame(minHeight: Theme.controlSize)
    }
}

#Preview {
    @Previewable @State var count = 2
    @Previewable @State var day = 1
    VStack(spacing: Theme.spacing) {
        StepperControl(title: "2x pro Woche", value: $count, range: 1...7, id: "a")
        StepperControl(title: "Jeden Monat am", value: $day, range: 1...31, valueText: { "\($0)." }, id: "b")
    }
    .padding()
    .background { PaperBackground() }
}
