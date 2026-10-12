import SwiftUI

/// Eine Kennzahl: Wert in Rolle `stat` (ab Phase 18.4 klein, 32 pt), darunter die Beschriftung in Rolle `meta`. Im Wert steht nur die Zahl
/// bzw. Prozentzahl, die Einheit gehört in die Beschriftung (Spezifikation 4.5).
struct StatValue: View {
    let title: LocalizedStringKey
    let value: String
    let identifier: String

    @Environment(\.inkOverride) private var inkOverride

    private var ink: Color { inkOverride ?? Theme.ink }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.textSpacing) {
            Text(value)
                .font(Theme.Typography.statSmall)
                .foregroundStyle(ink)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .accessibilityIdentifier(identifier)
            Text(title)
                .metaText()
                .foregroundStyle(ink.opacity(0.7))
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// "1 Tag", "5 Tage".
    static func daysText(_ days: Int, locale: Locale = .current) -> String {
        localized("\(days) Tage", locale: locale)
    }

    /// Einheit unter dem Streak in der Liste: "Tag" bzw. "Tage".
    static func dayUnitText(_ days: Int, locale: Locale = .current) -> String {
        days == 1 ? localized("Tag", locale: locale) : localized("Tage", locale: locale)
    }

    /// Zeile unter dem aktuellen Streak im Detail: "Tag in Folge" bzw. "Tage in Folge".
    static func inARowText(_ days: Int, locale: Locale = .current) -> String {
        days == 1 ? localized("Tag in Folge", locale: locale) : localized("Tage in Folge", locale: locale)
    }

    /// "67 %" bzw. "67%", ohne Quote ein Strich.
    static func rateText(_ percent: Int?, locale: Locale = .current) -> String {
        percent.map { PercentText.text($0, locale: locale) } ?? "–"
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
