import Foundation

/// Kuratierte Auswahl an SF Symbols für Habits (Spezifikation 4.6): 6 Zeilen zu je 6, jede Zeile ein Thema.
nonisolated enum HabitIcons {
    static let all: [String] = [
        // Bewegung
        "figure.run", "figure.walk", "figure.hiking", "dumbbell.fill", "figure.yoga", "bicycle",
        // Pflege
        "sparkles", "bubbles.and.sparkles.fill", "face.smiling.fill", "mouth.fill", "comb.fill", "shower.fill",
        // Essen und Gesundheit
        "drop.fill", "cup.and.saucer.fill", "fork.knife", "carrot.fill", "pills.fill", "heart.fill",
        // Ruhe
        "bed.double.fill", "moon.fill", "sun.max.fill", "brain.head.profile", "figure.mind.and.body", "leaf.fill",
        // Lernen und Kreatives
        "book.fill", "pencil", "character.bubble.fill", "music.note", "paintbrush.fill", "camera.fill",
        // Alltag
        "house.fill", "washer.fill", "cart.fill", "banknote.fill", "iphone.slash", "pawprint.fill",
    ]

    static let `default` = all[0]

    /// Namen für VoiceOver in der Icon Auswahl, im String Catalog übersetzt.
    private static let titles: [String: String.LocalizationValue] = [
        "figure.run": "Laufen", "figure.walk": "Gehen", "figure.hiking": "Wandern", "dumbbell.fill": "Hantel",
        "figure.yoga": "Yoga", "bicycle": "Fahrrad",
        "sparkles": "Hautpflege", "bubbles.and.sparkles.fill": "Reinigung", "face.smiling.fill": "Gesicht",
        "mouth.fill": "Zähne", "comb.fill": "Haare", "shower.fill": "Dusche",
        "drop.fill": "Wasser", "cup.and.saucer.fill": "Tasse", "fork.knife": "Essen", "carrot.fill": "Gemüse",
        "pills.fill": "Tabletten", "heart.fill": "Herz",
        "bed.double.fill": "Bett", "moon.fill": "Mond", "sun.max.fill": "Sonne", "brain.head.profile": "Kopf",
        "figure.mind.and.body": "Meditation", "leaf.fill": "Blatt",
        "book.fill": "Buch", "pencil": "Schreiben", "character.bubble.fill": "Sprache", "music.note": "Musik",
        "paintbrush.fill": "Malen", "camera.fill": "Kamera",
        "house.fill": "Haushalt", "washer.fill": "Wäsche", "cart.fill": "Einkauf", "banknote.fill": "Geld",
        "iphone.slash": "Weniger Handy", "pawprint.fill": "Haustier",
    ]

    static func title(for icon: String, locale: Locale = .current) -> String {
        titles[icon].map { localized($0, locale: locale) } ?? icon
    }
}
