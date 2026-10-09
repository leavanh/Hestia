import Foundation

/// Die drei Segmente im Sheet (Spezifikation 5.3). Feste Wochentage sind eine Variante von Woche,
/// fester Monatstag eine Variante von Monat.
enum RhythmGroup: CaseIterable {
    case daily
    case week
    case month

    var title: String {
        switch self {
        case .daily: "Täglich"
        case .week: "Woche"
        case .month: "Monat"
        }
    }

    /// Die Rhythmen des Segments, der erste ist die Voreinstellung.
    var rhythms: [Rhythm] {
        switch self {
        case .daily: [.daily]
        case .week: [.weekly, .weekdays]
        case .month: [.monthly, .monthDay]
        }
    }
}

/// Rhythmus eines Habits (Spezifikation 3.1).
enum Rhythm: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
    case weekdays
    case monthDay

    /// Segment im Sheet: Täglich, Woche oder Monat (Spezifikation 5.3).
    var group: RhythmGroup {
        switch self {
        case .daily: .daily
        case .weekly, .weekdays: .week
        case .monthly, .monthDay: .month
        }
    }

    /// Beschriftung der Variante unter Woche bzw. Monat. Täglich hat keine Variante.
    var variantTitle: String? {
        switch self {
        case .daily: nil
        case .weekly, .monthly: "Anzahl"
        case .weekdays: "Wochentage"
        case .monthDay: "Monatstag"
        }
    }

    /// Erlaubte Anzahl pro Tag, Woche bzw. Monat. `nil`, wenn der Rhythmus keine Anzahl hat.
    var targetRange: ClosedRange<Int>? {
        switch self {
        case .daily: 1...10
        case .weekly: 1...7
        case .monthly: 1...30
        case .weekdays, .monthDay: nil
        }
    }

    /// Text zur Anzahl, z.B. "3x pro Woche".
    func targetText(_ count: Int) -> String {
        switch self {
        case .daily: "\(count)x täglich"
        case .weekly: "\(count)x pro Woche"
        case .monthly: "\(count)x pro Monat"
        case .weekdays, .monthDay: ""
        }
    }
}
