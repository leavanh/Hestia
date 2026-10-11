import SwiftUI

extension Theme {
    /// Die 7 Schriftrollen (Spezifikation 4.3). Alle nutzen `Font.custom(_:size:relativeTo:)`, damit Dynamic Type wirkt.
    /// Versalien und Laufweite stehen in den Modifiern `labelText()` und `metaText()`, nicht in der Schrift selbst.
    enum Typography {
        /// Titel im Kopfband, Habit Name im Detail, Titel der Leerzustände.
        static var display: Font { custom(FontRegistry.barlowExtraLight, 58, .largeTitle) }
        static var displaySmall: Font { custom(FontRegistry.barlowExtraLight, 40, .largeTitle) }
        /// Fortschritt "4/6", Streak im Detail.
        static var numeral: Font { custom(FontRegistry.antonioThin, 76, .largeTitle).monospacedDigit() }
        /// Kennzahlen im Detail.
        static var stat: Font { custom(FontRegistry.antonioThin, 52, .title).monospacedDigit() }
        static var statSmall: Font { custom(FontRegistry.antonioThin, 32, .title).monospacedDigit() }
        /// Habit Name auf Karten und Zeilen, Sheet Titel.
        static var title: Font { custom(FontRegistry.barlowRegular, 21, .headline) }
        /// Buttons, Segmente, Wochentage, Chips.
        static var label: Font { custom(FontRegistry.barlowMedium, 14, .subheadline) }
        static var labelSmall: Font { custom(FontRegistry.barlowMedium, 11, .caption) }
        /// Wortmarke "HESTIA / HABITS" im Fuß der Einstellungen (Phase 12).
        static var wordmark: Font { custom(FontRegistry.barlowRegular, 56, .largeTitle) }
        /// Fließtext, Eingabefelder, Erklärungen.
        static var body: Font { custom(FontRegistry.geistMonoRegular, 14, .body) }
        /// Rhythmus Zeile, Datum im Band, Abschnittsüberschriften, Beschriftungen unter Kennzahlen.
        static var meta: Font { custom(FontRegistry.geistMonoRegular, 11, .caption) }
        static var metaMedium: Font { custom(FontRegistry.geistMonoMedium, 11, .caption).monospacedDigit() }
        /// Symbole (SF Symbols) in Bedienelementen, dünn passend zur Schrift.
        static var symbol: Font { .system(.body, weight: .regular) }
        static var symbolSmall: Font { .system(.caption, weight: .regular) }
        /// Symbol auf der Icon Kachel.
        static var icon: Font { .system(.title3, weight: .regular) }

        /// Laufweite in Anteilen der Schriftgröße.
        static let labelTracking: CGFloat = 14 * 0.10
        static let labelSmallTracking: CGFloat = 11 * 0.10
        static let metaTracking: CGFloat = 11 * 0.04
        static let displayTracking: CGFloat = -58 * 0.02
        static let wordmarkTracking: CGFloat = 56 * 0.04

        private static func custom(_ name: String, _ size: CGFloat, _ style: Font.TextStyle) -> Font {
            FontRegistry.registerAll()
            return .custom(name, size: size, relativeTo: style)
        }
    }
}

extension View {
    /// Rolle `display`: Titel, enge Laufweite und Zeilenhöhe.
    func displayText(small: Bool = false) -> some View {
        font(small ? Theme.Typography.displaySmall : Theme.Typography.display)
            .tracking(Theme.Typography.displayTracking * (small ? 40.0 / 58 : 1))
            .lineSpacing(-4)
    }

    /// Rolle `label`: Versalien mit Laufweite für Buttons, Segmente, Wochentage und Chips.
    func labelText(small: Bool = false) -> some View {
        font(small ? Theme.Typography.labelSmall : Theme.Typography.label)
            .textCase(.uppercase)
            .tracking(small ? Theme.Typography.labelSmallTracking : Theme.Typography.labelTracking)
    }

    /// Rolle `meta`: Versalien mit Laufweite für Rhythmus Zeile, Datum und Beschriftungen.
    func metaText() -> some View {
        font(Theme.Typography.meta)
            .textCase(.uppercase)
            .tracking(Theme.Typography.metaTracking)
    }

    /// Rolle `title`: Habit Name auf Karten und Zeilen.
    func titleText() -> some View {
        font(Theme.Typography.title)
    }

    /// Rolle `body`: Fließtext und Eingabefelder.
    func bodyText() -> some View {
        font(Theme.Typography.body)
    }
}
