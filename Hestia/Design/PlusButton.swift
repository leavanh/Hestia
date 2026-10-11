import SwiftUI

/// Quadrat mit Plus Symbol auf dem Kopfband von Heute und in der kleinen Leiste (Variante `onBand`).
struct PlusButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(Theme.Typography.symbol)
                .fixedControlTypeSize()
        }
        .buttonStyle(.hermes(.onBand, isSquare: true))
        .accessibilityLabel("Neuer Habit")
    }
}

#Preview {
    PlusButton {}
        .padding()
        .background(Theme.band)
}
