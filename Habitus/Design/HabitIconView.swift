import SwiftUI

/// Icon in gedämpfter Habitfarbe auf zarter Kreisfläche derselben Farbe. Bei Status gelb oder rot sitzt oben rechts
/// eine kleine runde Statusmarke, die den Kreis leicht überlappt und durch einen freien Rand von ihm abgesetzt ist.
/// Bei grün gibt es keine Marke, der Status bleibt für VoiceOver und Tests trotzdem als Wert verfügbar.
struct HabitIconView: View {
    let habitName: String
    let iconName: String
    let color: HabitColor
    let status: HabitStatus

    var body: some View {
        Image(systemName: iconName)
            .font(.title3)
            .foregroundStyle(color.mutedColor)
            .frame(width: Theme.iconSize, height: Theme.iconSize)
            .background(color.mutedColor.opacity(Theme.iconBackgroundOpacity), in: Circle())
            .mask {
                if badgeColor != nil {
                    badgeCutout
                } else {
                    Rectangle()
                }
            }
            .overlay { badge }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Status")
            .accessibilityValue(statusTitle)
            .accessibilityIdentifier("status-\(habitName)")
    }

    /// Mittelpunkt der Marke: auf dem Rand der Kreisfläche, oben rechts im Winkel von 45 Grad.
    private var badgeCenter: CGPoint {
        let radius = Theme.iconSize / 2
        let offset = radius / 2.0.squareRoot()
        return CGPoint(x: radius + offset, y: radius - offset)
    }

    /// Schneidet rund um die Marke den freien Rand aus der Kreisfläche.
    private var badgeCutout: some View {
        Rectangle()
            .overlay {
                Circle()
                    .frame(width: Theme.statusBadgeSize + 2 * Theme.statusBadgeGap)
                    .position(badgeCenter)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
    }

    @ViewBuilder
    private var badge: some View {
        if let badgeColor {
            Circle()
                .fill(badgeColor)
                .frame(width: Theme.statusBadgeSize, height: Theme.statusBadgeSize)
                .position(badgeCenter)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Statusmarke")
                .accessibilityIdentifier("status-badge-\(habitName)")
        }
    }

    private var badgeColor: Color? {
        switch status {
        case .green: nil
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
        HabitIconView(habitName: "Sport", iconName: "figure.run", color: .orange, status: .green)
        HabitIconView(habitName: "Wasser", iconName: "drop.fill", color: .teal, status: .yellow)
        HabitIconView(habitName: "Lesen", iconName: "book.fill", color: .violet, status: .red)
    }
    .padding()
}
