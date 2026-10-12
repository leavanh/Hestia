import SwiftUI

/// Kopfband in Heute (Spezifikation 4.5 und 5.2): randlos in `band`, von oben nach unten Datumszeile mit
/// Kalenderwoche und Plus, Titel relativ zu heute mit "Heute ›" an vergangenen Tagen, Fortschritt mit `SegmentBar`
/// und `WeekStrip`. Die Fläche reicht nach oben unter die Statusleiste.
///
/// Beim Tageswechsel gleiten Datumszeile, Titel und Fortschritt mit `transition` heraus und federn herein
/// (`dayEntrance`). Der Wochenstreifen gleitet nur, wenn sich die Woche ändert, dann gleichzeitig und gleich schnell
/// wie Datumszeile und Titel (ohne Verzögerung), sonst wandert nur seine Markierung, ebenso sofort.
struct DayHeader: View {
    let day: Date
    let today: Date
    let progress: DayProgress
    let engine: HabitEngine
    /// Übergang der Teile, die beim Tageswechsel gleiten.
    let transition: AnyTransition
    /// Kante, von der die Teile beim Tageswechsel hereinfedern. `nil` heißt ohne Kaskade.
    let entranceEdge: Edge?
    let onAdd: () -> Void
    let onBackToToday: () -> Void
    let onSelectDay: (Date) -> Void
    /// Meldet, ob gerade über den Wochenstreifen gezogen wird.
    var onScrubbingChange: (Bool) -> Void = { _ in }

    @Environment(\.firstWeekday) private var firstWeekday

    private var daysAgo: Int {
        engine.calendar.dateComponents([.day], from: engine.startOfDay(day), to: engine.startOfDay(today)).day ?? 0
    }

    var body: some View {
        let dayKey = engine.startOfDay(day)
        VStack(alignment: .leading, spacing: Theme.bandSpacing) {
            HStack(spacing: Theme.inlineSpacing) {
                sliding(id: dayKey, index: 0) { dateLine }
                PlusButton(action: onAdd)
            }
            sliding(id: dayKey, index: 0) { titleRow }
            sliding(id: dayKey, index: 1) { progressBlock }
            sliding(id: engine.startOfWeek(day, firstWeekday: firstWeekday), index: 0) {
                WeekStrip(
                    days: engine.weekStrip(day, today: today, firstWeekday: firstWeekday),
                    calendar: engine.calendar,
                    onScrubbingChange: onScrubbingChange,
                    onSelect: onSelectDay
                )
            }
        }
        .padding(.horizontal, Theme.spacing)
        .padding(.bottom, Theme.spacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(Theme.onBand)
        .background(alignment: .bottom) {
            Theme.band.padding(.top, -Theme.bandOverscroll)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("today-header")
    }

    /// Hält abgehenden und neuen Inhalt übereinander, damit beide beim Wechsel an derselben Stelle stehen.
    private func sliding<Content: View>(
        id: Date, index: Int, @ViewBuilder _ content: () -> Content
    ) -> some View {
        ZStack(alignment: .leading) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .dayEntrance(from: entranceEdge, index: index)
                .id(id)
                .transition(transition)
        }
    }

    /// "So · 11. Okt · KW 41" in Rolle `meta`.
    private var dateLine: some View {
        HStack(spacing: 0) {
            Text(DayText.dateLine(day, engine: engine))
                .accessibilityLabel(DayText.fullDate(day))
                .accessibilityIdentifier("today-date")
            Text(" · ")
                .accessibilityHidden(true)
            Text(DayText.weekNumber(day, engine: engine, firstWeekday: firstWeekday))
                .accessibilityLabel(DayText.weekNumberSpoken(day, engine: engine, firstWeekday: firstWeekday))
                .accessibilityIdentifier("week-number")
        }
        .metaText()
        .lineLimit(1)
        .foregroundStyle(Theme.onBandSecondary)
    }

    private var titleRow: some View {
        HStack(spacing: Theme.inlineSpacing) {
            Text(RelativeDay.text(daysAgo: daysAgo))
                .displayText()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("today-title")
            Spacer(minLength: 0)
            if daysAgo > 0 {
                backToTodayButton
            }
        }
    }

    /// Springt animiert zu heute zurück. Das Chevron zeigt vorwärts in Richtung heute.
    private var backToTodayButton: some View {
        Button(action: onBackToToday) {
            HStack(spacing: 2) {
                Text("Heute").labelText()
                Image(systemName: "chevron.right")
                    .font(Theme.Typography.symbolSmall)
            }
        }
        .buttonStyle(.hermes(.onBand))
        .fixedSize()
        .accessibilityIdentifier("back-to-today")
    }

    /// Groß "4/6", daneben "Erledigt" und die Prozent, darunter die `SegmentBar`. Ohne Punkte nur "Nichts fällig".
    @ViewBuilder
    private var progressBlock: some View {
        if progress.total == 0 {
            Text("Nichts fällig")
                .titleText()
                .accessibilityIdentifier("progress-text")
        } else {
            VStack(alignment: .leading, spacing: Theme.bandSpacing) {
                HStack(alignment: .lastTextBaseline, spacing: Theme.inlineSpacing) {
                    Text("\(progress.done)/\(progress.total)")
                        .font(Theme.Typography.numeral)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Erledigt")
                                        Text(PercentText.text(progress.percent))
                    }
                    .metaText()
                    .foregroundStyle(Theme.onBandSecondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(localized("\(progress.done) von \(progress.total) erledigt, \(PercentText.text(progress.percent))"))
                .accessibilityAddTraits(.isStaticText)
                .accessibilityIdentifier("progress-text")
                SegmentBar(done: progress.done, total: progress.total)
            }
        }
    }
}

#Preview {
    let engine = HabitEngine()
    ScrollView {
        DayHeader(
            day: .now, today: .now, progress: DayProgress(done: 4, total: 6), engine: engine,
            transition: .opacity, entranceEdge: nil, onAdd: {}, onBackToToday: {}, onSelectDay: { _ in }
        )
    }
    .background { PaperBackground() }
}
