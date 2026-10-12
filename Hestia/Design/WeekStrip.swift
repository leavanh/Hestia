import SwiftUI

/// Wochenstreifen im Kopfband von Heute (Spezifikation 4.5 und 5.2): 7 Felder ab dem Wochenbeginn, der angezeigte Tag invertiert.
/// Tage nach heute sind blass und nicht wählbar. Innerhalb einer Woche wandert die Markierung kurz zum neuen Tag.
/// Ab Phase 18.4 lässt sich mit dem Finger über den Streifen ziehen: die Markierung folgt dem Finger von Tag zu Tag
/// (höchstens bis heute), beim Loslassen ruft er `onSelect` mit diesem Tag auf. Antippen ist ein Ziehen ohne Bewegung.
struct WeekStrip: View {
    let days: [WeekStripDay]
    let calendar: Calendar
    /// Meldet, ob gerade gezogen wird, damit Heute in dieser Zeit nicht zusätzlich per Wischen den Tag wechselt.
    var onScrubbingChange: (Bool) -> Void = { _ in }
    let onSelect: (Date) -> Void

    @Namespace private var marker
    /// Das Feld unter dem Finger, solange gezogen wird.
    @State private var scrubIndex: Int?
    @State private var isScrubbing = false
    @State private var width: CGFloat = 0
    private var engine: HabitEngine { HabitEngine(calendar: calendar) }

    /// Das markierte Feld: beim Ziehen das unter dem Finger, sonst der angezeigte Tag.
    private var markedIndex: Int? {
        scrubIndex ?? days.firstIndex(where: \.isShown)
    }

    var body: some View {
        let marked = markedIndex
        HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.element.day) { index, day in
                Text(DayText.weekdayName(engine.weekday(of: day.day)))
                    .labelText()
                    .lineLimit(1)
                    .foregroundStyle(index == marked ? Theme.band : Theme.onBand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.weekStripPadding)
                    .background {
                        if index == marked {
                            Rectangle()
                                .fill(Theme.onBand)
                                .matchedGeometryEffect(id: "shown", in: marker)
                        }
                    }
                    .opacity(day.isFuture ? Theme.calendarFutureOpacity : 1)
                    // Ohne Markierung meldete die Zelle sonst nur den Rahmen des Texts an VoiceOver.
                    .contentShape(Rectangle())
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(DayText.fullDate(day.day))
                    .accessibilityAddTraits(day.isSelectable ? [.isButton] : [])
                    .accessibilityAddTraits(day.isShown ? .isSelected : [])
                    .disabled(!day.isSelectable)
                    .accessibilityAction {
                        if day.isSelectable, !day.isShown { onSelect(day.day) }
                    }
                    .accessibilityIdentifier("week-strip-\(MonthCalendar.identifier(for: day.day, calendar: calendar))")
            }
        }
        .contentShape(Rectangle())
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .gesture(scrub)
        .onChange(of: days.firstIndex(where: \.isShown)) { scrubIndex = nil }
        .animation(.easeInOut(duration: Theme.weekStripMarkerDuration), value: marked)
        .sensoryFeedback(.selection, trigger: scrubIndex) { old, new in old != nil && new != nil }
    }

    /// Ziehen ab der ersten Berührung: das Feld unter dem Finger wird markiert, beim Loslassen gewählt.
    private var scrub: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isScrubbing {
                    isScrubbing = true
                    onScrubbingChange(true)
                }
                scrubIndex = days.scrubIndex(atX: value.location.x, width: width)
            }
            .onEnded { value in
                isScrubbing = false
                onScrubbingChange(false)
                // Die Markierung bleibt auf dem gewählten Tag, bis Heute ihn zeigt (`onChange` oben), sonst spränge sie kurz zurück.
                if let index = days.scrubIndex(atX: value.location.x, width: width), !days[index].isShown {
                    scrubIndex = index
                    onSelect(days[index].day)
                } else {
                    scrubIndex = nil
                }
            }
    }
}

#Preview {
    let engine = HabitEngine()
    WeekStrip(days: engine.weekStrip(.now, today: .now), calendar: engine.calendar) { _ in }
        .padding()
        .background(Theme.band)
}
