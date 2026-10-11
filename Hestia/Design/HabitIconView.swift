import SwiftUI

/// Quadratische Kachel (36 pt) mit Fläche `tint` und Symbol in `color`. Bei Status gelb oder rot sitzt oben rechts
/// eine quadratische Statusmarke, die die Kachel leicht überlappt und durch einen freien Rand von ihr abgesetzt ist.
/// Bei grün gibt es keine Marke, der Status bleibt für VoiceOver und Tests trotzdem als Wert verfügbar.
/// Ohne `status` (Habit Liste, Detail, Sheet "Neue Pause") ist das Icon reine Zierde und für VoiceOver ausgeblendet.
struct HabitIconView: View {
    let habitName: String
    let iconName: String
    let color: HabitColor
    var status: HabitStatus?

    var body: some View {
        Image(systemName: iconName)
            .font(Theme.Typography.icon)
            .fixedControlTypeSize()
            .foregroundStyle(color.color)
            .frame(width: Theme.iconSize, height: Theme.iconSize)
            .background(color.tint)
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
            .accessibilityHint(statusHint)
            .accessibilityIdentifier("status-\(habitName)")
            .accessibilityHidden(status == nil)
    }

    /// Mittelpunkt der Marke: auf der oberen rechten Ecke der Kachel.
    private var badgeCenter: CGPoint {
        CGPoint(x: Theme.iconSize, y: 0)
    }

    /// Schneidet rund um die Marke den freien Rand aus der Kachel.
    private var badgeCutout: some View {
        Rectangle()
            .overlay {
                Rectangle()
                    .frame(width: Theme.statusBadgeSize + 2 * Theme.statusBadgeGap)
                    .frame(height: Theme.statusBadgeSize + 2 * Theme.statusBadgeGap)
                    .position(badgeCenter)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
    }

    @ViewBuilder
    private var badge: some View {
        if let badgeColor {
            Rectangle()
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
        case .green, nil: nil
        case .yellow: Theme.statusYellow
        case .red: Theme.statusRed
        }
    }

    private var statusTitle: String {
        switch status {
        case .green, nil: "Grün"
        case .yellow: "Gelb"
        case .red: "Rot"
        }
    }

    /// Was die Farbe bedeutet (Spezifikation 3.5), damit VoiceOver mehr sagt als nur die Farbe.
    private var statusHint: String {
        switch status {
        case .green, nil: "Im Plan."
        case .yellow: "Ziel ist erfüllt, aber bald nicht mehr, wenn nichts dazukommt."
        case .red: "Ziel ist nicht erfüllt."
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
    .background { PaperBackground() }
}
