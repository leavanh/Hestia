import SwiftUI

/// Eine Kennzahl im Habit Detail: großer Wert, darunter eine kleine Beschriftung.
struct StatValue: View {
    let title: String
    let value: String
    let identifier: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.semibold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .accessibilityIdentifier(identifier)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
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
        StatValue(title: "Aktueller Streak", value: StatValue.daysText(5), identifier: "a")
        StatValue(title: "Längster Streak", value: StatValue.daysText(12), identifier: "b")
        StatValue(title: "Quote 30 Tage", value: StatValue.rateText(67), identifier: "c")
    }
    .glassCard()
    .padding()
    .background { GlassBackground() }
}
