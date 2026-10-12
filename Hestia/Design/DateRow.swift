import SwiftUI

/// Zeile für ein Datum (Spezifikation 4.5): Beschriftung links, Datum rechts, beides in Appschrift. Tippen klappt darunter
/// einen `MonthCalendar` zur Auswahl auf. Ein zweites Tippen oder die Wahl eines Tags klappt ihn wieder zu. Ob die Zeile
/// aufgeklappt ist, bestimmt der Aufrufer, damit höchstens eine Zeile offen ist.
struct DateRow: View {
    let title: LocalizedStringKey
    @Binding var date: Date
    @Binding var isExpanded: Bool
    /// Frühester wählbarer Tag. `nil` heißt ohne Grenze.
    var earliest: Date?
    /// Bezeichner der Zeile. Die Tage des Kalenders heißen `<id>-calendar-day-<Datum>`.
    let id: String

    private let engine = HabitEngine()

    /// So weit lässt sich in beide Richtungen blättern.
    private static let monthSpan = 36

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Button {
                isExpanded.toggle()
            } label: {
                HStack(spacing: Theme.controlSpacing) {
                    Text(title)
                        .bodyText()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(DayText.dateWithYear(date, engine: engine))
                        .bodyText()
                }
                .foregroundStyle(Theme.ink)
                .frame(minHeight: Theme.controlSize)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(DayText.fullDate(date))
            .accessibilityHint(isExpanded ? "Kalender schließen" : "Kalender öffnen")
            .accessibilityIdentifier(id)

            if isExpanded {
                MonthCalendar(
                    firstMonth: engine.calendar.date(byAdding: .month, value: -Self.monthSpan, to: AppClock.now) ?? date,
                    lastMonth: engine.calendar.date(byAdding: .month, value: Self.monthSpan, to: AppClock.now) ?? date,
                    today: AppClock.now,
                    progress: { _ in DayProgress(done: 0, total: 0) },
                    identifierPrefix: "\(id)-calendar",
                    selectedDay: date,
                    allowsFuture: true,
                    isDisabled: { day in earliest.map { engine.startOfDay(day) < engine.startOfDay($0) } ?? false },
                    initialMonth: date
                ) { day in
                    date = day
                    isExpanded = false
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: Theme.compactBarFadeDuration), value: isExpanded)
    }
}

#Preview {
    @Previewable @State var date = AppClock.now
    @Previewable @State var open = true
    DateRow(title: "Von", date: $date, isExpanded: $open, id: "preview")
        .padding()
        .background { PaperBackground() }
}
