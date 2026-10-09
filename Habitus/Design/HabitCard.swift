import SwiftUI

/// Karte eines Habits: links Icon, Name mit Statuspunkt, Rhythmus Zeile und 7 Tage Punkte, rechts Abhakkreis oder Counter.
/// Tippen auf die linke Seite ruft `onTap` auf, die rechte Seite bedient sich selbst.
struct HabitCard<Control: View>: View {
    let name: String
    let iconName: String
    let color: Color
    let status: HabitStatus
    let rhythmText: String
    let dots: [WeekDot]
    let onTap: () -> Void
    @ViewBuilder var control: Control

    var body: some View {
        HStack(spacing: Theme.spacing) {
            HStack(spacing: Theme.spacing) {
                HabitIconView(iconName: iconName, color: color)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(name)
                            .font(.headline)
                        StatusDot(status: status)
                            .accessibilityIdentifier("status-\(name)")
                    }
                    Text(rhythmText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .accessibilityIdentifier("repeat-\(name)")
                    WeekDots(dots: dots, color: color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            control
        }
        .glassCard()
    }
}

#Preview {
    ZStack {
        GlassBackground()
        VStack(spacing: Theme.spacing) {
            HabitCard(
                name: "Sport", iconName: "figure.run", color: HabitColor.orange.color, status: .yellow,
                rhythmText: "1 von 3 diese Woche",
                dots: [.fill(0), .fill(0), .fill(1), .fill(1), .fill(0), .fill(1), .fill(0)], onTap: {}
            ) {
                CheckCircle(isChecked: false, color: HabitColor.orange.color) {}
            }
            HabitCard(
                name: "Wasser trinken", iconName: "drop.fill", color: HabitColor.teal.color, status: .green,
                rhythmText: "3 pro Tag",
                dots: [.fill(1), .fill(0.66), .fill(0.33), .fill(1), .fill(0), .fill(1), .fill(0.66)], onTap: {}
            ) {
                CounterControl(count: 2, target: 3, color: HabitColor.teal.color, id: "p", onDecrement: {}, onIncrement: {})
            }
            HabitCard(
                name: "Yoga", iconName: "figure.walk", color: HabitColor.violet.color, status: .red,
                rhythmText: "Mo, Do",
                dots: [.fill(0), .fill(1), .fill(0), .fill(0), .fill(1), .fill(0), .fill(0)], onTap: {}
            ) {
                CheckCircle(isChecked: false, color: HabitColor.violet.color) {}
            }
        }
        .padding()
    }
}
