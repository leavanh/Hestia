import SwiftUI

/// Zeile in der Habit Liste unter dem Kalender: Icon, Name, Rhythmus Zeile und rechts der aktuelle Streak.
/// Antippen öffnet das Habit Detail.
struct HabitStatRow: View {
    let name: String
    let iconName: String
    let habitColor: HabitColor
    let rhythmText: String
    let streak: Int
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Theme.spacing) {
                HabitIconView(habitName: name, iconName: iconName, color: habitColor, status: .green)
                VStack(alignment: .leading, spacing: 6) {
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(rhythmText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Label(StatValue.daysText(streak), systemImage: "flame.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(streak > 0 ? Color.primary : Color.secondary)
                    .accessibilityLabel("Aktueller Streak: \(StatValue.daysText(streak))")
                    .accessibilityIdentifier("streak-\(name)")
            }
            .glassCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("habit-row-\(name)")
    }
}

#Preview {
    ZStack {
        GlassBackground()
        VStack(spacing: Theme.spacing) {
            HabitStatRow(name: "Lesen", iconName: "book.fill", habitColor: .violet, rhythmText: "Täglich", streak: 12) {}
            HabitStatRow(name: "Sport", iconName: "dumbbell.fill", habitColor: .orange, rhythmText: "1 von 2 diese Woche", streak: 1) {}
            HabitStatRow(name: "Yoga", iconName: "figure.yoga", habitColor: .teal, rhythmText: "Mo, Do", streak: 0) {}
        }
        .padding()
    }
}
