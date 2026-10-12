import SwiftUI

/// Auswahl des Monatstags im Sheet (Spezifikation 4.5 und 5.3): Raster 1 bis 31 in 7 Spalten aus Quadraten wie im
/// `MonthCalendar`. Der gewählte Tag ist in `ink` gefüllt, die anderen haben keine Fläche. Ein Tippen wählt den Tag.
/// Bei 29, 30 und 31 steht darunter, dass in kürzeren Monaten der letzte Tag gilt (Spezifikation 3.1).
struct MonthDayPicker: View {
    @Binding var selection: Int

    private static let days = 1...31

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            LazyVGrid(columns: CalendarWeekdayHeader.columns, spacing: Theme.calendarDaySpacing) {
                ForEach(Self.days, id: \.self) { day in
                    cell(day)
                }
            }
            if selection >= 29 {
                Text("Hat der Monat den Tag nicht, gilt der letzte Tag.")
                    .metaText()
                    .foregroundStyle(Theme.inkSecondary)
                    .accessibilityIdentifier("monthday-hint")
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("monthday-picker")
    }

    private func cell(_ day: Int) -> some View {
        let isSelected = day == selection
        return Button {
            selection = day
        } label: {
            Text("\(day)")
                .font(isSelected ? Theme.Typography.metaMedium : Theme.Typography.meta)
                .fixedControlTypeSize()
                .foregroundStyle(isSelected ? Theme.background : Theme.ink)
                .frame(width: Theme.calendarDaySize, height: Theme.calendarDaySize)
                .background {
                    if isSelected { Rectangle().fill(Theme.ink) }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(localized("\(day). des Monats"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("monthday-\(day)")
    }
}

#Preview {
    @Previewable @State var day = 31
    MonthDayPicker(selection: $day)
        .padding()
        .background { PaperBackground() }
}
