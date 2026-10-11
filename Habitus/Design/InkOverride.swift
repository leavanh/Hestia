import SwiftUI

extension EnvironmentValues {
    /// Tinte, die in einem Bereich statt `Theme.ink` gilt. Im Habit Detail ist es die Habitfarbe, damit Kennzahlen,
    /// Linien und Kalender unter dem Band durchgehend in ihr stehen. `nil` heißt `Theme.ink`.
    @Entry var inkOverride: Color?
}

extension View {
    /// Färbt Text, Linien und Bedienelemente der Bausteine darin (`StatValue`, `MonthCalendar`, `Hairline`) in `color`.
    func inkOverride(_ color: Color) -> some View {
        environment(\.inkOverride, color)
            .foregroundStyle(color)
    }
}
