import CoreText
import UIKit

/// Registriert die eingebetteten Schriften (Spezifikation 4.3) einmalig für den Prozess. Das Projekt erzeugt seine
/// Info.plist selbst, deshalb gibt es keinen `UIAppFonts` Eintrag.
enum FontRegistry {
    /// PostScript Namen der 6 Schnitte.
    static let barlowExtraLight = "BarlowCondensed-ExtraLight"
    static let barlowRegular = "BarlowCondensed-Regular"
    static let barlowMedium = "BarlowCondensed-Medium"
    static let antonioThin = "Antonio-Thin"
    static let geistMonoRegular = "GeistMono-Regular"
    static let geistMonoMedium = "GeistMono-Medium"

    static let allFontNames = [
        barlowExtraLight, barlowRegular, barlowMedium, antonioThin, geistMonoRegular, geistMonoMedium,
    ]

    private static let once: Void = {
        let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        for name in allFontNames where UIFont(name: name, size: 12) == nil {
            assertionFailure("Schrift \(name) fehlt")
        }
    }()

    /// Mehrfaches Aufrufen ist harmlos. Auch `Theme.Typography` ruft es auf, damit Vorschauen und Tests die Schriften haben.
    static func registerAll() {
        _ = once
    }
}
