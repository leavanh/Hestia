import Foundation

/// Text aus dem String Catalog (`Localizable.xcstrings`) in der Sprache der App. Mit `locale` lässt sich eine andere
/// Sprache erzwingen, das nutzen die Tests für Englisch. `String(localized:locale:)` allein wählt nur das Format,
/// nicht die Sprache, deshalb kommt der Text aus dem passenden `.lproj` Bundle.
nonisolated func localized(_ key: String.LocalizationValue, locale: Locale = .current) -> String {
    String(localized: key, bundle: AppLanguage.bundle(for: locale), locale: locale)
}

nonisolated enum AppLanguage {
    /// Das Bundle mit den Texten der Sprache von `locale`. Gibt es die Sprache nicht, gilt das Hauptbundle, das selbst
    /// die passende Sprache wählt (sonst die Entwicklungssprache Deutsch).
    static func bundle(for locale: Locale) -> Bundle {
        guard let code = locale.language.languageCode?.identifier,
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else { return .main }
        return bundle
    }

    /// Name der aktuellen Sprache der App in ihrer eigenen Sprache, z.B. "Deutsch" oder "English".
    static func currentName() -> String {
        let language = Bundle.main.preferredLocalizations.first ?? "de"
        return Locale(identifier: language).localizedString(forLanguageCode: language) ?? language
    }
}

/// Prozent in der Schreibweise der Sprache: "67 %" (mit geschütztem Leerzeichen) bzw. "67%".
nonisolated enum PercentText {
    static func text(_ percent: Int, locale: Locale = .current) -> String {
        (Double(percent) / 100).formatted(.percent.precision(.fractionLength(0)).locale(locale))
    }
}
