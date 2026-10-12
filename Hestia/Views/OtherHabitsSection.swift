import SwiftUI

/// Abschnitt "Weitere" unter der Hauptliste von Heute und im Sheet "Tag bearbeiten" (Spezifikation 5.2): Kopfzeile
/// mit Anzahl und Chevron zum Auf- und Zuklappen, darunter die Karten. Ist die Liste leer, fehlt der Abschnitt.
/// Der Zustand gilt für jeden Tag und bleibt gespeichert, Voreinstellung zu.
struct OtherHabitsSection: View {
    @AppStorage(Self.expandedKey) private var isExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let expandedKey = "HestiaOtherExpanded"

    let habits: [Habit]
    let day: Date
    /// Kante und Platz in der Kaskade beim Tageswechsel (`dayEntrance`), nur in Heute.
    var entranceEdge: Edge?
    var entranceIndex = 0
    let onEdit: (Habit) -> Void

    var body: some View {
        if !habits.isEmpty {
            VStack(spacing: 0) {
                header
                    .dayEntrance(from: entranceEdge, index: entranceIndex)
                if isExpanded {
                    ForEach(Array(habits.enumerated()), id: \.element.id) { index, habit in
                        DayHabitCard(habit: habit, day: day) { onEdit(habit) }
                            .dayEntrance(from: entranceEdge, index: entranceIndex + index + 1)
                    }
                }
            }
        }
    }

    private var header: some View {
        Button {
            withAnimation(reduceMotion ? nil : .smooth) { isExpanded.toggle() }
        } label: {
            HStack {
                Text("Weitere · \(habits.count)")
                    .metaText()
                Spacer()
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.footnote.weight(.semibold))
            }
            .foregroundStyle(Theme.inkSecondary)
            .padding(.vertical, Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) { Hairline() }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(localized("Weitere, \(HabitCountText.text(habits.count))"))
        .accessibilityValue(isExpanded ? localized("aufgeklappt") : localized("zugeklappt"))
        .accessibilityIdentifier("other-habits-toggle")
    }
}
