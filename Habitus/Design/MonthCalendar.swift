import SwiftUI

/// Ein Monat im durchgehenden Kalender: Monatsname und seine Tage. Jeder Tag ist nach dem Tagesfortschritt in der
/// Akzentfarbe eingefärbt: keine Farbe bei 0 %, dann zunehmend kräftiger bis 100 %. Zukünftige Tage sind blass und gesperrt.
struct MonthCalendar: View {
    let grid: MonthGrid
    let today: Date
    let progress: (Date) -> DayProgress
    let onSelect: (Date) -> Void

    private let engine = HabitEngine()

    /// Deckkraft der Akzentfarbe für einen Anteil von 0 bis 1. Bei 0 gibt es keine Farbe.
    static func fillOpacity(for fraction: Double) -> Double {
        guard fraction > 0 else { return 0 }
        let range = Theme.calendarFillOpacity
        return range.lowerBound + (range.upperBound - range.lowerBound) * min(fraction, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text(grid.firstDay.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "de_DE"))))
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("calendar-month-\(Self.monthIdentifier(for: grid.firstDay, calendar: engine.calendar))")
            LazyVGrid(columns: CalendarWeekdayHeader.columns, spacing: Theme.calendarDaySpacing) {
                ForEach(0..<grid.leadingBlanks, id: \.self) { _ in
                    Color.clear.frame(height: Theme.calendarDaySize)
                }
                ForEach(grid.days, id: \.self) { day in
                    dayCell(day)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dayCell(_ day: Date) -> some View {
        let isFuture = engine.isFuture(day, today: today)
        let isToday = engine.startOfDay(day) == engine.startOfDay(today)
        let dayProgress = progress(day)
        let opacity = isFuture ? 0 : Self.fillOpacity(for: dayProgress.fraction)

        return Button {
            onSelect(day)
        } label: {
            Text("\(engine.calendar.component(.day, from: day))")
                .font(.subheadline.weight(isToday ? .bold : .regular))
                .foregroundStyle(opacity >= Theme.calendarOnAccentThreshold ? Theme.onAccent : Color.primary)
                .frame(width: Theme.calendarDaySize, height: Theme.calendarDaySize)
                .background {
                    Circle().fill(Theme.accent.opacity(opacity))
                }
                .overlay {
                    if isToday {
                        Circle().strokeBorder(Theme.accent, lineWidth: Theme.strokeWidth)
                    }
                }
                .contentShape(Circle())
                .opacity(isFuture ? Theme.calendarFutureOpacity : 1)
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE"))))
        .accessibilityValue(isFuture ? "" : value(for: dayProgress))
        .accessibilityIdentifier("calendar-day-\(Self.identifier(for: day, calendar: engine.calendar))")
    }

    private func value(for progress: DayProgress) -> String {
        progress.total == 0 ? "Nichts fällig" : "\(progress.percent) %"
    }

    /// Bezeichner im Format `2026-10-08` für Accessibility und Tests.
    static func identifier(for day: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// Bezeichner im Format `2026-10` für Accessibility und Tests.
    static func monthIdentifier(for month: Date, calendar: Calendar) -> String {
        String(identifier(for: month, calendar: calendar).dropLast(3))
    }
}

/// Wochentagszeile Mo bis So über dem durchgehenden Kalender. Sie bleibt beim Scrollen stehen.
struct CalendarWeekdayHeader: View {
    private static let weekdays = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    /// Sieben gleich breite Spalten, auch für die Tage darunter.
    static var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Theme.calendarDaySpacing), count: 7)
    }

    var body: some View {
        LazyVGrid(columns: Self.columns, spacing: 0) {
            ForEach(Self.weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, Theme.spacing)
        .accessibilityHidden(true)
    }
}

#Preview {
    let engine = HabitEngine()
    ZStack {
        GlassBackground()
        VStack {
            CalendarWeekdayHeader()
            MonthCalendar(
                grid: engine.monthGrid(containing: .now),
                today: .now,
                progress: { day in DayProgress(done: min(engine.calendar.component(.day, from: day) % 5, 4), total: 4) },
                onSelect: { _ in }
            )
            .padding(.horizontal, Theme.spacing)
        }
    }
}
