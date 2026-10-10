import SwiftUI

/// Icon in Habitfarbe auf zarter Kreisfläche derselben Farbe, außen ein Ring in Statusfarbe.
struct HabitIconView: View {
    let iconName: String
    let color: Color
    let status: HabitStatus

    var body: some View {
        Image(systemName: iconName)
            .font(.title3)
            .foregroundStyle(color)
            .frame(width: Theme.iconSize, height: Theme.iconSize)
            .background(color.opacity(Theme.iconBackgroundOpacity), in: Circle())
            .padding(Theme.statusRingGap + Theme.statusRingWidth)
            .overlay {
                Circle()
                    .inset(by: Theme.statusRingWidth / 2)
                    .stroke(statusColor, lineWidth: Theme.statusRingWidth)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Status")
            .accessibilityValue(statusTitle)
    }

    private var statusColor: Color {
        switch status {
        case .green: Theme.statusGreen
        case .yellow: Theme.statusYellow
        case .red: Theme.statusRed
        }
    }

    private var statusTitle: String {
        switch status {
        case .green: "Grün"
        case .yellow: "Gelb"
        case .red: "Rot"
        }
    }
}

#Preview {
    HStack(spacing: Theme.spacing) {
        HabitIconView(iconName: "figure.run", color: HabitColor.orange.color, status: .green)
        HabitIconView(iconName: "drop.fill", color: HabitColor.teal.color, status: .yellow)
        HabitIconView(iconName: "book.fill", color: HabitColor.violet.color, status: .red)
    }
    .padding()
}
