import SwiftUI

/// Eine Kennzahl: großer Wert in Rolle `stat`, darunter die Beschriftung in Rolle `meta`. Im Wert steht nur die Zahl
/// bzw. Prozentzahl, die Einheit gehört in die Beschriftung (Spezifikation 4.5).
struct StatValue: View {
    let title: String
    let value: String
    let identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.textSpacing) {
            Text(value)
                .font(Theme.Typography.stat)
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .accessibilityIdentifier(identifier)
            Text(title)
                .metaText()
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// "1 Tag", "5 Tage".
    static func daysText(_ days: Int) -> String {
        days == 1 ? "1 Tag" : "\(days) Tage"
    }

    /// "67 %", ohne Quote ein Strich.
    static func rateText(_ percent: Int?) -> String {
        percent.map { "\($0) %" } ?? "–"
    }
}

#Preview {
    HStack {
        StatValue(title: "Erledigungen", value: "5", identifier: "a")
        StatValue(title: "Längster Streak · Tage", value: "12", identifier: "b")
        StatValue(title: "Quote 30 Tage", value: StatValue.rateText(67), identifier: "c")
    }
    .padding()
    .background { PaperBackground() }
}
