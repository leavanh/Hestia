import Foundation

/// Beschriftung des angezeigten Tags im Verhältnis zu heute (Spezifikation 5.2).
enum RelativeDay {
    /// "Heute", "Gestern", "Vorgestern", sonst "Vor n Tagen". `daysAgo` ist 0 für heute.
    static func text(daysAgo: Int) -> String {
        switch daysAgo {
        case ...0: "Heute"
        case 1: "Gestern"
        case 2: "Vorgestern"
        default: "Vor \(daysAgo) Tagen"
        }
    }
}
