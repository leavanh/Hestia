/// Kuratierte Auswahl an SF Symbols für Habits.
nonisolated enum HabitIcons {
    static let all: [String] = [
        "figure.run", "figure.walk", "dumbbell.fill", "figure.yoga", "bicycle", "figure.pool.swim",
        "drop.fill", "cup.and.saucer.fill", "fork.knife", "carrot.fill", "pills.fill", "heart.fill",
        "bed.double.fill", "moon.fill", "sun.max.fill", "brain.head.profile", "leaf.fill", "tree.fill",
        "book.fill", "pencil", "graduationcap.fill", "music.note", "paintbrush.fill", "camera.fill",
        "house.fill", "cart.fill", "creditcard.fill", "phone.fill", "envelope.fill", "pawprint.fill",
    ]

    static let `default` = all[0]

    /// Deutsche Namen für VoiceOver in der Icon Auswahl.
    private static let titles: [String: String] = [
        "figure.run": "Laufen", "figure.walk": "Gehen", "dumbbell.fill": "Hantel", "figure.yoga": "Yoga",
        "bicycle": "Fahrrad", "figure.pool.swim": "Schwimmen", "drop.fill": "Tropfen", "cup.and.saucer.fill": "Tasse",
        "fork.knife": "Besteck", "carrot.fill": "Karotte", "pills.fill": "Tabletten", "heart.fill": "Herz",
        "bed.double.fill": "Bett", "moon.fill": "Mond", "sun.max.fill": "Sonne", "brain.head.profile": "Kopf",
        "leaf.fill": "Blatt", "tree.fill": "Baum", "book.fill": "Buch", "pencil": "Stift",
        "graduationcap.fill": "Doktorhut", "music.note": "Musik", "paintbrush.fill": "Pinsel", "camera.fill": "Kamera",
        "house.fill": "Haus", "cart.fill": "Einkaufswagen", "creditcard.fill": "Karte", "phone.fill": "Telefon",
        "envelope.fill": "Brief", "pawprint.fill": "Pfote",
    ]

    static func title(for icon: String) -> String {
        titles[icon] ?? icon
    }
}
