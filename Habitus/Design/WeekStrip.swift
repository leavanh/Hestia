import SwiftUI

/// Wochenstreifen im Kopfband von Heute (Spezifikation 4.5 und 5.2): 7 Felder Mo bis So, der angezeigte Tag invertiert.
/// Tage nach heute sind blass und nicht antippbar. Innerhalb einer Woche wandert die Markierung kurz zum neuen Tag.
struct WeekStrip: View {
    let days: [WeekStripDay]
    let calendar: Calendar
    let onSelect: (Date) -> Void

    @Namespace private var marker

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.element.day) { index, day in
                Button {
                    if !day.isShown { onSelect(day.day) }
                } label: {
                    Text(DayText.weekdayNames[index % 7])
                        .labelText()
                        .lineLimit(1)
                        .foregroundStyle(day.isShown ? Theme.band : Theme.onBand)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.weekStripPadding)
                        .background {
                            if day.isShown {
                                Rectangle()
                                    .fill(Theme.onBand)
                                    .matchedGeometryEffect(id: "shown", in: marker)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!day.isSelectable)
                .opacity(day.isFuture ? Theme.calendarFutureOpacity : 1)
                .accessibilityLabel(DayText.fullDate(day.day))
                .accessibilityAddTraits(day.isShown ? .isSelected : [])
                .accessibilityIdentifier("week-strip-\(MonthCalendar.identifier(for: day.day, calendar: calendar))")
            }
        }
        .animation(.easeInOut(duration: Theme.weekStripMarkerDuration), value: days.firstIndex(where: \.isShown))
    }
}

#Preview {
    let engine = HabitEngine()
    WeekStrip(days: engine.weekStrip(.now, today: .now), calendar: engine.calendar) { _ in }
        .padding()
        .background(Theme.band)
}
