import SwiftData
import SwiftUI

/// Habit Detail (Spezifikation 5.4, ab Phase 18.3 eine ganze Seite): oben ein randloses Band in Habitfarbe mit Rhythmus
/// Zeile (bei einem beendeten Habit "Beendet am …"), Name und aktuellem Streak. Darunter die Tageszeile mit dem Stand am
/// Tag groß und dem großen Bedienelement zum Abhaken, ein Raster aus vier kleinen Kennzahlen, der kompakte Monatskalender und unten
/// "Pausieren" und "Habit beenden". Die Leiste hat keinen Titel und keinen Hintergrund, links den Zurück Button des
/// Systems, rechts "Bearbeiten". Die Tab Bar ist ausgeblendet. Ein beendeter Habit zeigt nur Band, Kennzahlen und Kalender.
struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let habit: Habit
    /// Der Tag, für den die Tageszeile steht und abgehakt wird.
    let day: Date
    let today: Date

    /// Bearbeiten, Pausieren und Beenden über dieselben Sheets und denselben Dialog wie das Kontextmenü.
    @State private var actions = HabitActionState()

    @Environment(\.firstWeekday) private var firstWeekday
    @Environment(\.habitEngine) private var engine

    var body: some View {
        ScrollView {
            // Ein eben gelöschter Habit kann hier noch einmal ankommen, bevor die Seite geschlossen ist.
            if habit.isAlive {
                content
            }
        }
        .accessibilityIdentifier("habit-detail")
        .background { PaperBackground() }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarVisibility(.hidden, for: .tabBar)
        .scrollEdgeEffectHidden(true, for: .top)
        // Die Symbole der Leiste stehen auf dem Band in `onColor`: hell im hellen Modus, dunkel im dunklen.
        .toolbarColorScheme(colorScheme == .dark ? .light : .dark, for: .navigationBar)
        .toolbar {
            if habit.isAlive, habit.endedAt == nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        actions.sheet = .edit
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel("Bearbeiten")
                    .accessibilityIdentifier("detail-edit")
                }
            }
        }
        // Nach "Historie löschen" geht die Seite zurück, nach "Historie behalten" zeigt sie den beendeten Habit.
        .habitActions(habit, state: $actions) { dismiss() }
    }

    private var content: some View {
        let snapshot = habit.snapshot
        let habitColor = HabitColor(key: habit.colorKey)
        let stats = engine.statistics(snapshot, on: habit.statisticsDay(today: today, engine: engine))

        return VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
            band(snapshot: snapshot, habitColor: habitColor, stats: stats)
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                if habit.endedAt == nil {
                    dayRow(snapshot: snapshot, habitColor: habitColor)
                }
                statGrid(stats: stats)
                calendar(snapshot: snapshot, habitColor: habitColor)
                if habit.endedAt == nil {
                    actionButtons
                }
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
                    .accessibilityLabel(localized("Aktueller Streak: \(StatValue.daysText(stats.currentStreak))"))
                    .accessibilityIdentifier("stat-current-streak")
                Text(StatValue.inARowText(stats.currentStreak))
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
            return localized("Beendet am \(DayText.shortDate(endedAt, engine: engine))")
        }
        return snapshot.rhythmText(window: engine.windowProgress(snapshot, on: today), firstWeekday: firstWeekday, periods: engine.periods)
    }

    // MARK: Tageszeile

    /// Haarlinie oben, links klein der Tag relativ ("Heute", "Gestern") und darunter groß der Stand ("Erledigt",
    /// "Offen", bei einem Counter "2 von 3"), rechts Kreis bzw. Counter in groß, mit derselben Logik wie in der Karte.
    /// An einem pausierten Tag steht groß "Pausiert" und das Bedienelement ist ausgegraut und gesperrt.
    private func dayRow(snapshot: HabitSnapshot, habitColor: HabitColor) -> some View {
        let isPaused = engine.isPaused(snapshot, on: day)
        let target = engine.dailyTarget(snapshot)
        let count = min(engine.count(on: day, in: snapshot.counts), target)
        let state: String = if isPaused {
            localized("Pausiert")
        } else if engine.usesCounter(snapshot) {
            localized("\(count) von \(target)")
        } else {
            localized(count >= 1 ? "Erledigt" : "Offen")
        }

        return AdaptiveStack {
            VStack(alignment: .leading, spacing: Theme.textSpacing) {
                Text(RelativeDay.text(daysAgo: daysAgo))
                    .metaText()
                    .foregroundStyle(habitColor.color.opacity(0.7))
                    .accessibilityIdentifier("detail-day")
                Text(state)
                    .displayText(small: true)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .opacity(isPaused ? Theme.pausedOpacity : 1)
                    .accessibilityIdentifier("detail-state")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .contain)

            HabitDayControl(habit: habit, day: day, checkID: "detail-check", counterID: "detail-counter", isLarge: true)
                .disabled(isPaused)
                .opacity(isPaused ? Theme.pausedOpacity : 1)
        }
        .padding(.vertical, Theme.spacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { Hairline() }
    }

    private var daysAgo: Int {
        engine.calendar.dateComponents([.day], from: engine.startOfDay(day), to: engine.startOfDay(today)).day ?? 0
    }

    // MARK: Pausieren und Beenden

    private var actionButtons: some View {
        VStack(spacing: Theme.inlineSpacing) {
            HermesButton("Pausieren", variant: .quiet, fillsWidth: true) {
                actions.sheet = .pause
            }
            .accessibilityIdentifier("detail-pause")
            HermesButton("Habit beenden", variant: .destructive, role: .destructive, fillsWidth: true) {
                actions.isConfirmingEnd = true
            }
            .accessibilityIdentifier("detail-end")
        }
    }

    // MARK: Kennzahlen

    /// 2 × 2 kleine Kennzahlen, getrennt durch Haarlinien. Die Einheit steht in der Beschriftung, im Wert nur die Zahl.
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
                .padding(.vertical, Theme.inlineSpacing)
            HairlineColor()
                .frame(width: Theme.hairlineWidth)
                .accessibilityHidden(true)
            second
                .padding(.vertical, Theme.inlineSpacing)
                .padding(.leading, Theme.spacing)
        }
    }

    // MARK: Monatskalender

    /// Derselbe Kalender wie im Tab, kompakt, in Habitfarbe und nicht antippbar. Er reicht wie im Tab vom Erstellmonat,
    /// mindestens 3 Monate zurück, bis zum aktuellen Monat, bei einem beendeten Habit bis zum Monat des Beendens.
    private func calendar(snapshot: HabitSnapshot, habitColor: HabitColor) -> some View {
        let target = engine.dailyTarget(snapshot)

        return MonthCalendar(
            firstMonth: engine.firstCalendarMonth(oldest: habit.createdAt, today: today),
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
