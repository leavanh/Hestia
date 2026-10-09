import SwiftUI

/// Kleiner Punkt in Statusfarbe (grün, gelb, rot) neben dem Namen eines Habits.
struct StatusDot: View {
    let status: HabitStatus

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: Theme.statusDotSize, height: Theme.statusDotSize)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Status")
            .accessibilityValue(title)
    }

    private var color: Color {
        switch status {
        case .green: Theme.statusGreen
        case .yellow: Theme.statusYellow
        case .red: Theme.statusRed
        }
    }

    private var title: String {
        switch status {
        case .green: "Grün"
        case .yellow: "Gelb"
        case .red: "Rot"
        }
    }
}

#Preview {
    HStack(spacing: Theme.spacing) {
        StatusDot(status: .green)
        StatusDot(status: .yellow)
        StatusDot(status: .red)
    }
    .padding()
}
