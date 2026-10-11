import SwiftData
import SwiftUI

/// Habit Detail (Spezifikation 5.4, Stand Phase 8): Icon, Name, Rhythmus, eigener Monatskalender mit den Tagen der
/// Erledigung in Habitfarbe, aktueller Streak, längster Streak und Quote 30 Tage.
struct HabitDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let habit: Habit
    let today: Date

    private let engine = HabitEngine()

    var body: some View {
        NavigationStack {
            ScrollView {
                // Ein eben gelöschter Habit kann hier noch einmal ankommen, bevor das Sheet geschlossen ist.
                if habit.isAlive {
                    content
                }
            }
            .accessibilityIdentifier("habit-detail")
            .background { PaperBackground() }
            .navigationTitle("Habit Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig", systemImage: "checkmark", role: .confirm) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var content: some View {
        let snapshot = habit.snapshot
        let habitColor = HabitColor(key: habit.colorKey)
        let stats = engine.statistics(snapshot, on: habit.statisticsDay(today: today, engine: engine))

        return VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
            header(snapshot: snapshot, habitColor: habitColor)
            calendar(snapshot: snapshot, habitColor: habitColor)
            PaperSection(title: "Statistik") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), alignment: .topLeading)], alignment: .leading, spacing: Theme.sectionSpacing) {
                    StatValue(title: "Aktueller Streak", value: StatValue.daysText(stats.currentStreak), identifier: "stat-current-streak")
                    StatValue(title: "Längster Streak", value: StatValue.daysText(stats.longestStreak), identifier: "stat-longest-streak")
                    StatValue(title: "Quote 30 Tage", value: StatValue.rateText(stats.ratePercent), identifier: "stat-rate-30")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.spacing)
    }

    private func header(snapshot: HabitSnapshot, habitColor: HabitColor) -> some View {
        AdaptiveStack {
            HabitIconView(habitName: habit.name, iconName: habit.iconName, color: habitColor)
            VStack(alignment: .leading, spacing: Theme.textSpacing) {
                Text(habit.name)
                    .titleText()
                    .foregroundStyle(Theme.ink)
                    .accessibilityIdentifier("detail-name")
                Text(snapshot.rhythmText(window: engine.windowProgress(snapshot, on: today)))
                    .metaText()
                    .foregroundStyle(Theme.inkSecondary)
                    .accessibilityIdentifier("detail-rhythm")
            }
        }
    }

    // MARK: Monatskalender

    /// Derselbe Kalender wie im Tab, in Habitfarbe und nicht antippbar. Er reicht vom Erstellmonat bis zum
    /// aktuellen Monat, bei einem beendeten Habit bis zum Monat des Beendens.
    private func calendar(snapshot: HabitSnapshot, habitColor: HabitColor) -> some View {
        let target = engine.dailyTarget(snapshot)

        return MonthCalendar(
            firstMonth: habit.createdAt,
            lastMonth: habit.statisticsDay(today: today, engine: engine),
            today: today,
            progress: { DayProgress(done: min(engine.count(on: $0, in: snapshot.counts), target), total: target) },
            isPaused: { engine.isPaused(snapshot, on: $0) && engine.startOfDay($0) >= engine.startOfDay(snapshot.createdAt) },
            tint: habitColor.color,
            identifierPrefix: "habit-calendar"
        )
    }
}
