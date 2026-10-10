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
    /// Strichstärke und Abstand des Statusrings um die Kreisfläche von `HabitIconView`.
    static let statusRingWidth: CGFloat = 2.5
    static let statusRingGap: CGFloat = 2
    /// Strichstärke und Abstand des äußeren Rings um den angezeigten Tag in `WeekDots`.
    static let dotRingWidth: CGFloat = 1.5
    static let dotRingGap: CGFloat = 2
    /// Mindeststrecke, ab der ein Wischen in Heute den Tag wechselt.
    static let swipeDistance: CGFloat = 40
    /// Dauer des Tageswechsels in Heute.
    static let dayChangeDuration: Double = 0.5
    /// Der ausgleitende Tag wird dabei auf diesen Anteil verkleinert.
    static let dayChangeScale: CGFloat = 0.9
    /// Beim Tageswechsel gleiten Kopf und Karten um so viel von der Seite herein, nacheinander im Abstand `entranceStagger`.
    static let entranceOffset: CGFloat = 90
    static let entranceStagger: Double = 0.05
    static let entranceMaxStaggeredItems = 8
    /// Abstand zwischen Leiste und großem Titel in Heute.
    static let headerTopSpacing: CGFloat = 28
    /// So lange muss eine Karte gedrückt werden, bis das Bearbeiten Sheet öffnet.
    static let editPressDuration: Double = 0.6
    /// Nach dieser Zeit gibt die Karte beim Drücken ein erstes Zeichen (leichter Impuls, kurz einsinken).
    static let editPressPreviewDelay: Double = 0.25
    /// Größe der Karte, solange sie gedrückt wird.
    static let pressedCardScale: CGFloat = 0.97
    /// Innenabstände der Kapsel `DayBadge`.
    static let badgePaddingHorizontal: CGFloat = 8
    static let badgePaddingVertical: CGFloat = 2
    /// Wie weit der Inhalt beim Wischen über heute hinaus nachgibt, bevor er zurückfedert.
    static let swipeBounceDistance: CGFloat = 28
    /// Ab dieser Scrolltiefe steht der Titel von Heute klein in der Leiste.
    static let barTitleScrollOffset: CGFloat = 44

    // MARK: Farben

    /// Hintergrundverlauf: hell sehr helles Blau zu hellem Flieder, dunkel tiefes Marineblau zu dunklem Violett.
    static let backgroundTop = dynamic(light: (0.91, 0.95, 1.00), dark: (0.04, 0.08, 0.19))
    static let backgroundBottom = dynamic(light: (0.95, 0.92, 1.00), dark: (0.15, 0.08, 0.25))

    /// Akzentfarbe für Fortschritt, der keinem Habit gehört (Fortschrittsring, später Kalender).
    static let accent = Color.accentColor
    /// Statusfarben, nur für den Ring um das Icon.
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
    /// Deckkraft der Fläche hinter "Heute" in `DayBadge`.
    static let badgeOpacity: Double = 0.18
    /// Deckkraft des äußeren Rings um den angezeigten Tag in `WeekDots`.
    static let dotRingOpacity: Double = 0.4
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
