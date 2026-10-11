import SwiftUI

/// Monatskalender: Monatsname mit Pfeil links und rechts, Wochentagszeile und die Tage des Monats. Jeder Tag ist nach
/// dem Tagesfortschritt in `tint` eingefärbt: keine Farbe bei 0 %, dann zunehmend kräftiger bis 100 %. Jeder Tag ist ein
/// Quadrat mit der Tageszahl, heute hat einen äußeren quadratischen Rahmen. Zukünftige Tage sind blass und gesperrt.
/// Der Monat wechselt mit den Pfeilen zwischen `firstMonth` und `lastMonth` (Spezifikation 5.4).
/// Im Tab ist es `progress` (Blau) mit antippbaren Tagen, im Habit Detail die Habitfarbe ohne Antippen.
/// Pausierte Tage sind in blasser `ink` statt eingefärbt. Als Datumsauswahl (`DateRow`) zeigt `selectedDay` den gewählten
/// Tag gefüllt, `allowsFuture` erlaubt auch Tage nach heute und `isDisabled` sperrt einzelne Tage.
struct MonthCalendar: View {
    /// Ein Tag aus dem ersten und einer aus dem letzten Monat, zwischen denen man blättern kann.
    let firstMonth: Date
    let lastMonth: Date
    let today: Date
    let progress: (Date) -> DayProgress
    /// Ob der Tag pausiert ist. Solche Tage sind grau und haben keine Einfärbung.
    var isPaused: (Date) -> Bool = { _ in false }
    var tint: Color = Theme.progress
    var identifierPrefix = "calendar"
    /// Als Datumsauswahl: der gewählte Tag, voll in `tint` gefüllt.
    var selectedDay: Date?
    /// Als Datumsauswahl: Tage nach heute sind nicht gesperrt.
    var allowsFuture = false
    /// Tage, die sich nicht wählen lassen (blass wie Zukunft).
    var isDisabled: (Date) -> Bool = { _ in false }
    /// Der Monat, den der Kalender zuerst zeigt. Standard ist der letzte (`lastMonth`).
    var initialMonth: Date?
    /// `nil`, wenn die Tage nicht antippbar sind (Habit Detail).
    var onSelect: ((Date) -> Void)?

    /// Der gezeigte Monat. Beim Start der letzte, also der aktuelle.
    @State private var month: Date?

    private let engine = HabitEngine()

    /// Deckkraft der Tinte für einen Anteil von 0 bis 1. Bei 0 gibt es keine Farbe.
    static func fillOpacity(for fraction: Double) -> Double {
        guard fraction > 0 else { return 0 }
        let range = Theme.calendarFillOpacity
        return range.lowerBound + (range.upperBound - range.lowerBound) * min(fraction, 1)
    }

    /// Gezeigter Monat, immer innerhalb der Grenzen (sie können sich ändern, z.B. um Mitternacht).
    private var shownMonth: Date {
        engine.steppedMonth(month ?? initialMonth ?? lastMonth, by: 0, from: firstMonth, through: lastMonth)
    }

    private func step(_ months: Int) {
        month = engine.steppedMonth(shownMonth, by: months, from: firstMonth, through: lastMonth)
    }

    var body: some View {
        let grid = engine.monthGrid(containing: shownMonth)

        VStack(alignment: .leading, spacing: Theme.spacing) {
            HStack {
                Text(grid.firstDay.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "de_DE"))))
                    .metaText()
                    .foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("\(identifierPrefix)-month-\(Self.monthIdentifier(for: grid.firstDay, calendar: engine.calendar))")
                Spacer()
                HStack(spacing: Theme.spacing) {
                    Button("Voriger Monat", systemImage: "chevron.left") { step(-1) }
                        .disabled(shownMonth <= engine.firstOfMonth(containing: firstMonth))
                        .accessibilityIdentifier("\(identifierPrefix)-previous")
                    Button("Nächster Monat", systemImage: "chevron.right") { step(1) }
                        .disabled(shownMonth >= engine.firstOfMonth(containing: lastMonth))
                        .accessibilityIdentifier("\(identifierPrefix)-next")
                }
                .labelStyle(.iconOnly)
                .font(Theme.Typography.symbol)
                .foregroundStyle(Theme.ink)
                .buttonStyle(.plain)
            }
            CalendarWeekdayHeader()
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
        let isFuture = (engine.isFuture(day, today: today) && !allowsFuture) || isDisabled(day)
        let isSelected = selectedDay.map { engine.startOfDay($0) == engine.startOfDay(day) } ?? false
        let isToday = engine.startOfDay(day) == engine.startOfDay(today)
        let dayProgress = progress(day)
        let isPausedDay = !isFuture && isPaused(day)
        let opacity = isSelected ? 1 : (isFuture || isPausedDay ? 0 : Self.fillOpacity(for: dayProgress.fraction))

        let label = Text("\(engine.calendar.component(.day, from: day))")
            .font(isToday ? Theme.Typography.metaMedium : Theme.Typography.meta)
            .fixedControlTypeSize()
            .foregroundStyle(opacity >= Theme.calendarOnFillThreshold ? Theme.background : Theme.ink)
            .frame(width: Theme.calendarDaySize, height: Theme.calendarDaySize)
            .background {
                Rectangle().fill(isPausedDay ? Theme.ink.opacity(Theme.pausedDayOpacity) : tint.opacity(opacity))
            }
            .overlay {
                if isToday {
                    Rectangle()
                        .strokeBorder(tint, lineWidth: Theme.strokeWidth)
                        .padding(-(Theme.dotRingGap + Theme.strokeWidth))
                }
            }
            .contentShape(Rectangle())
            .opacity(isFuture ? Theme.calendarFutureOpacity : 1)

        return Group {
            if let onSelect {
                Button {
                    onSelect(day)
                } label: {
                    label
                }
                .buttonStyle(.plain)
                .disabled(isFuture)
            } else {
                label.accessibilityElement(children: .ignore)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel(DayText.fullDate(day))
        .accessibilityValue(accessibilityValue(isFuture: isFuture, isPausedDay: isPausedDay, isSelected: isSelected, progress: dayProgress))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("\(identifierPrefix)-day-\(Self.identifier(for: day, calendar: engine.calendar))")
    }

    private func accessibilityValue(isFuture: Bool, isPausedDay: Bool, isSelected: Bool, progress: DayProgress) -> String {
        if selectedDay != nil { return isSelected ? "Ausgewählt" : "" }
        return isFuture ? "" : (isPausedDay ? "Pausiert" : value(for: progress))
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

/// Wochentagszeile Mo bis So unter dem Monatsnamen.
struct CalendarWeekdayHeader: View {
    /// Sieben gleich breite Spalten, auch für die Tage darunter.
    static var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Theme.calendarDaySpacing), count: 7)
    }

    var body: some View {
        LazyVGrid(columns: Self.columns, spacing: 0) {
            ForEach(DayText.weekdayNames, id: \.self) { weekday in
                Text(weekday)
                    .labelText(small: true)
                    .fixedControlTypeSize()
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    let engine = HabitEngine()
    ZStack {
        PaperBackground()
        MonthCalendar(
            firstMonth: engine.calendar.date(byAdding: .month, value: -3, to: .now) ?? .now,
            lastMonth: .now,
            today: .now,
            progress: { day in DayProgress(done: min(engine.calendar.component(.day, from: day) % 5, 4), total: 4) },
            onSelect: { _ in }
        )
        .padding(.horizontal, Theme.spacing)
    }
}
