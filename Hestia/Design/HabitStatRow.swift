import SwiftUI

/// Flache Zeile in der Habit Liste unter dem Kalender, oben eine Haarlinie: Icon, Name, Rhythmus Zeile und rechts der
/// aktuelle Streak als Zahl mit "Tage" darunter. Antippen öffnet das Habit Detail.
struct HabitStatRow: View {
    let name: String
    let iconName: String
    let habitColor: HabitColor
    let rhythmText: String
    let streak: Int
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            // Bei großer Schrift stehen Icon, Texte und Streak untereinander.
            AdaptiveStack {
                HabitIconView(habitName: name, iconName: iconName, color: habitColor)
                VStack(alignment: .leading, spacing: Theme.textSpacing) {
                    Text(name)
                        .titleText()
                        .foregroundStyle(Theme.ink)
                    Text(rhythmText)
                        .metaText()
                        .foregroundStyle(Theme.inkSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(streak)")
                        .font(Theme.Typography.statSmall)
                        .foregroundStyle(streak > 0 ? Theme.ink : Theme.inkSecondary)
                        .accessibilityLabel(localized("Aktueller Streak: \(StatValue.daysText(streak))"))
                        .accessibilityIdentifier("streak-\(name)")
                    Text(StatValue.dayUnitText(streak))
                        .metaText()
                        .foregroundStyle(Theme.inkSecondary)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) { Hairline() }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("habit-row-\(name)")
    }
}

#Preview {
    ZStack {
        PaperBackground()
        VStack(spacing: 0) {
            HabitStatRow(name: "Lesen", iconName: "book.fill", habitColor: .violet, rhythmText: "Täglich", streak: 12) {}
            HabitStatRow(name: "Sport", iconName: "dumbbell.fill", habitColor: .orange, rhythmText: "1 von 2 diese Woche", streak: 1) {}
            HabitStatRow(name: "Yoga", iconName: "figure.yoga", habitColor: .teal, rhythmText: "Mo · Do", streak: 0) {}
        }
        .padding(.horizontal)
    }
}
