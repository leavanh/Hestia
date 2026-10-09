import SwiftUI
import UIKit

/// Zentrale Definition aller Farben und Maße. Ansichten verwenden keine eigenen Farbwerte.
enum Theme {
    // MARK: Maße

    static let spacing: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let cardPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 24
    /// Größe von `CheckCircle` und der Kreise in `CounterControl`.
    static let controlSize: CGFloat = 36
    /// Abstand zwischen den Kreisen in `CounterControl`.
    static let controlSpacing: CGFloat = 8
    /// Größe des Rings in `ProgressHeader`.
    static let progressRingSize: CGFloat = 32
    /// Linienstärke von `ProgressRing`.
    static let ringWidth: CGFloat = 3
    /// Durchmesser und Abstand der 7 Tage Punkte.
    static let dotSize: CGFloat = 8
    static let dotSpacing: CGFloat = 6
    /// Größe des Icons auf `HabitCard`.
    static let iconSize: CGFloat = 44
    /// Größe der Auswahlkreise im Sheet.
    static let swatchSize: CGFloat = 28
    static let strokeWidth: CGFloat = 2
    /// Höhe eines Segments in `SegmentedChoice`.
    static let segmentHeight: CGFloat = 32
    /// Durchmesser des `StatusDot` neben dem Namen.
    static let statusDotSize: CGFloat = 10
    /// Mindeststrecke, ab der ein Wischen auf der Datumskarte den Tag wechselt.
    static let swipeDistance: CGFloat = 40

    // MARK: Farben

    /// Hintergrundverlauf: hell sehr helles Blau zu hellem Flieder, dunkel tiefes Marineblau zu dunklem Violett.
    static let backgroundTop = dynamic(light: (0.91, 0.95, 1.00), dark: (0.04, 0.08, 0.19))
    static let backgroundBottom = dynamic(light: (0.95, 0.92, 1.00), dark: (0.15, 0.08, 0.25))

    /// Akzentfarbe für Fortschritt, der keinem Habit gehört (Fortschrittsring, später Kalender).
    static let accent = Color.accentColor
    /// Statusfarben, nur für den `StatusDot`.
    static let statusGreen = Color(uiColor: .systemGreen)
    static let statusYellow = Color(uiColor: .systemYellow)
    static let statusRed = Color(uiColor: .systemRed)
    /// Spur und gewähltes Segment in `SegmentedChoice`.
    static let segmentTrack = Color(uiColor: .tertiarySystemFill)
    static let segmentSelected = dynamic(light: (1.00, 1.00, 1.00), dark: (0.39, 0.39, 0.40))
    /// Vordergrund auf gefüllten Habitfarben (z.B. Häkchen).
    static let onHabitColor = Color.white
    /// Deckkraft der Icon Fläche in Habitfarbe.
    static let iconBackgroundOpacity: Double = 0.18
    /// Deckkraft der Spur hinter dem Fortschritt in `ProgressRing`.
    static let ringTrackOpacity: Double = 0.2
    /// Deckkraft eines 7 Tage Punkts bei Teilerledigung: von knapp über 0 % bis knapp unter 100 %.
    static let dotPartialOpacity: ClosedRange<Double> = 0.3...0.8
    /// Deckkraft eines Bedienelements, das gerade nicht benutzbar ist (z.B. Minus bei 0).
    static let disabledOpacity: Double = 0.35

    private static func dynamic(
        light: (Double, Double, Double),
        dark: (Double, Double, Double)
    ) -> Color {
        Color(uiColor: UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
    }
}
