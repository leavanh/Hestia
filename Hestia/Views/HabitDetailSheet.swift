import SwiftData
import SwiftUI

/// Habit Detail (Spezifikation 5.4, ab Phase 11): oben ein randloses Band in Habitfarbe mit Rhythmus Zeile (bei einem
/// beendeten Habit "Beendet am …"), Name und aktuellem Streak. Darunter ein Raster aus vier Kennzahlen und der kompakte
/// Monatskalender, alles in Habitfarbe. Die Leiste hat keinen Titel und keinen Hintergrund, nur oben rechts den runden
/// Haken, der das Sheet schließt. Bearbeitet wird nicht im Detail.
struct HabitDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let habit: Habit
    let today: Date

    @Environment(\.firstWeekday) private var firstWeekday
    @Environment(\.habitEngine) private var engine

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
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .scrollEdgeEffectHidden(true, for: .top)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig", systemImage: "checkmark", role: .confirm) {
                        dismiss()
                    }
                    .accessibilityIdentifier("detail-done")
                    // Papier auf dem Band in Habitfarbe, damit der Haken nicht mit der blauen Systemtönung mischt.
                    .tint(HabitColor(key: habit.colorKey).onColor)
                }
            }
        }
    }

    private var content: some View {
        let snapshot = habit.snapshot
        let habitColor = HabitColor(key: habit.colorKey)
        let stats = engine.statistics(snapshot, on: habit.statisticsDay(today: today, engine: engine))

        return VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
            band(snapshot: snapshot, habitColor: habitColor, stats: stats)
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                statGrid(stats: stats)
                calendar(snapshot: snapshot, habitColor: habitColor)
            }
            .padding(.horizontal, Theme.spacing)
            .padding(.bottom, Theme.spacing)
            // Unter dem Band stehen Kennzahlen, Linien und Kalender durchgehend in der Habitfarbe.
            .inkOverride(habitColor.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Band

    private func band(snapshot: HabitSnapshot, habitColor: HabitColor, stats: HabitStatistics) -> some View {
        VStack(alignment: .leading, spacing: Theme.bandSpacing) {
            Text(metaLine(snapshot: snapshot))
                .metaText()
                .foregroundStyle(habitColor.onColor.opacity(0.8))
                .accessibilityIdentifier("detail-rhythm")
            Text(habit.name)
                .displayText()
                .lineLimit(3)
                .minimumScaleFactor(0.6)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("detail-name")
            HStack(alignment: .lastTextBaseline, spacing: Theme.inlineSpacing) {
                Text("\(stats.currentStreak)")
                    .font(Theme.Typography.numeral)
                    .lineLimit(1)
                    .accessibilityLabel("Aktueller Streak: \(StatValue.daysText(stats.currentStreak))")
                    .accessibilityIdentifier("stat-current-streak")
                Text(stats.currentStreak == 1 ? "Tag in Folge" : "Tage in Folge")
                    .metaText()
                    .foregroundStyle(habitColor.onColor.opacity(0.8))
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, Theme.spacing)
        .padding(.bottom, Theme.spacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(habitColor.onColor)
        .background(alignment: .bottom) {
            habitColor.color.padding(.top, -Theme.bandOverscroll)
        }
    }

    /// "20 Min · Täglich", bei einem beendeten Habit "Beendet am 3. Okt".
    private func metaLine(snapshot: HabitSnapshot) -> String {
        if let endedAt = habit.endedAt {
            return "Beendet am \(DayText.shortDate(endedAt, engine: engine))"
        }
        return snapshot.rhythmText(window: engine.windowProgress(snapshot, on: today), firstWeekday: firstWeekday, periods: engine.periods)
    }

    // MARK: Kennzahlen

    /// 2 × 2 Kennzahlen, getrennt durch Haarlinien. Die Einheit steht in der Beschriftung, im Wert nur die Zahl.
    private func statGrid(stats: HabitStatistics) -> some View {
        VStack(spacing: 0) {
            Hairline()
            statRow(
                StatValue(title: "Quote · 30 Tage", value: StatValue.rateText(stats.ratePercent), identifier: "stat-rate-30"),
                StatValue(title: "Längster Streak · Tage", value: "\(stats.longestStreak)", identifier: "stat-longest-streak")
            )
            Hairline()
            statRow(
                StatValue(title: "Erledigungen", value: "\(stats.totalCompletions)", identifier: "stat-total"),
                StatValue(title: "Pausen", value: "\(stats.pauseCount)", identifier: "stat-pauses")
            )
            Hairline()
        }
    }

    private func statRow(_ first: StatValue, _ second: StatValue) -> some View {
        HStack(alignment: .top, spacing: 0) {
            first
                .padding(.vertical, Theme.spacing)
            HairlineColor()
                .frame(width: Theme.hairlineWidth)
                .accessibilityHidden(true)
            second
                .padding(.vertical, Theme.spacing)
                .padding(.leading, Theme.spacing)
        }
    }

    // MARK: Monatskalender

    /// Derselbe Kalender wie im Tab, kompakt, in Habitfarbe und nicht antippbar. Er reicht vom Erstellmonat bis zum
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
            identifierPrefix: "habit-calendar",
            isCompact: true
        )
    }
}
