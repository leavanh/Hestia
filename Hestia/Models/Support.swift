import Foundation

/// Die drei Stufen des Trinkgelds (Spezifikation Phase 18.1), in der Reihenfolge Klein, Mittel, Groß.
nonisolated enum TipTier: String, CaseIterable {
    case small, medium, large

    /// Produkt ID in App Store Connect: Bundle ID plus `.tip.<Stufe>`. Ändert sich die Bundle ID, ändern sich die IDs mit.
    func productID(bundleID: String) -> String {
        "\(bundleID).tip.\(rawValue)"
    }

    /// Name der Stufe in der Zeile im Sheet.
    var title: String {
        switch self {
        case .small: localized("Klein")
        case .medium: localized("Mittel")
        case .large: localized("Groß")
        }
    }
}

/// Bewertungsseite im App Store (Spezifikation Phase 18.1).
nonisolated enum ReviewLink {
    /// Die Apple ID der App aus App Store Connect. Leer, solange die App dort nicht angelegt ist (Phase 19), dann
    /// gibt es keine Bewertungszeile.
    static let appID = ""

    /// Seite zum Schreiben einer Bewertung. Ohne App ID gibt es keine URL.
    static func url(appID: String = ReviewLink.appID) -> URL? {
        guard !appID.isEmpty, appID.allSatisfy(\.isNumber) else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review")
    }
}
