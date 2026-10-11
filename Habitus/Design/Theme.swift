import SwiftUI
import UIKit

/// Zentrale Definition aller Farben und Maße (Spezifikation 4.2 und 4.4). Ansichten verwenden keine eigenen Farbwerte.
enum Theme {
    // MARK: Maße

    static let spacing: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let cardPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 2
    /// Linienstärke der Haarlinien zwischen Zeilen und Abschnitten.
    static let hairlineWidth: CGFloat = 0.5
    /// Abstand zwischen Textzeilen, die zusammengehören (Name und Rhythmus Zeile, Titel und Untertitel).
    static let textSpacing: CGFloat = 6
    /// Abstand zwischen kleinen Elementen in einer Zeile (Name und Chip) und zwischen Überschrift und Inhalt.
    static let inlineSpacing: CGFloat = 8
    /// Größte Schrift für Symbole und Zahlen in Quadraten fester Größe (Häkchen, Counter, Icon, Kalendertag).
    static let maxControlTypeSize: DynamicTypeSize = .xxxLarge
    /// Größe von `CheckBox`, `HabitIconView` und der Höhe von `CounterControl`.
    static let controlSize: CGFloat = 36
    /// Abstand zwischen den Teilen von `CounterControl`.
    static let controlSpacing: CGFloat = 8
    /// Kantenlänge der Counter Tasten.
    static let counterKeySize: CGFloat = 26
    /// Rand von Häkchen, Counter Tasten und Farbauswahl.
    static let strokeWidth: CGFloat = 1
    /// Kantenlänge und Abstand der 7 Tage Punkte.
    static let dotSize: CGFloat = 6
    static let dotSpacing: CGFloat = 3
    /// Größe des Icons auf `HabitCard`.
    static let iconSize: CGFloat = 36
    /// Kantenlänge der Quadrate in der Farbauswahl im Sheet.
    static let swatchSize: CGFloat = 28
    /// Höhe eines Segments in `SegmentedChoice`.
    static let segmentHeight: CGFloat = 32
    /// Kantenlänge der Statusmarke oben rechts an `HabitIconView` und Breite des freien Rands zwischen Marke und Kachel.
    static let statusBadgeSize: CGFloat = 10
    static let statusBadgeGap: CGFloat = 2
    /// Strichstärke und Abstand des äußeren Rahmens um den angezeigten Tag in `WeekDots`.
    static let dotRingWidth: CGFloat = 1
    static let dotRingGap: CGFloat = 1.5
    /// Höhe der Balken in `SegmentBar`, Abstand dazwischen und die Anzahl Punkte, ab der ein durchgehender Balken folgt.
    static let segmentBarHeight: CGFloat = 3
    static let segmentBarSpacing: CGFloat = 3
    nonisolated static let segmentBarMaxSegments = 12
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
    /// Innenabstände von `Chip`.
    static let chipPaddingHorizontal: CGFloat = 6
    static let chipPaddingVertical: CGFloat = 2
    /// Innenabstände von `HermesButtonStyle` und Mindesthöhe (Tippfläche).
    static let buttonPaddingHorizontal: CGFloat = 16
    static let buttonPaddingVertical: CGFloat = 10
    static let buttonMinHeight: CGFloat = 44
    /// Wie weit der Inhalt beim Wischen über heute hinaus nachgibt, bevor er zurückfedert.
    static let swipeBounceDistance: CGFloat = 28
    /// Ab dieser Scrolltiefe steht der Titel von Heute klein in der Leiste.
    static let barTitleScrollOffset: CGFloat = 44
    /// Höhe des Strichs über dem gewählten Tab in `PaperTabBar`.
    static let tabIndicatorHeight: CGFloat = 2
    /// Höhe des Strichs, der in `WeekDots` einen pausierten Tag zeigt.
    static let pausedDashHeight: CGFloat = 1
    /// Kantenlänge eines Tages in `MonthCalendar` und Abstand zwischen den Tagen.
    static let calendarDaySize: CGFloat = 40
    static let calendarDaySpacing: CGFloat = 6

    // MARK: Marke

    private static let brandHex: UInt32 = 0x0000F2
    private static let paperHex: UInt32 = 0xF2F2F2
    private static let nightHex: UInt32 = 0x000030

    /// Markenblau.
    static let brand = Color(hex: brandHex)
    /// Fläche im hellen Modus, Schrift auf Blau.
    static let paper = Color(hex: paperHex)
    /// Fläche im dunklen Modus (Blau, 80 % abgedunkelt).
    static let night = Color(hex: nightHex)
    /// Blau, 40 % abgedunkelt: Kopfband in der kleinen Leiste im dunklen Modus, falls nötig.
    static let frame = Color(hex: 0x000091)

    // MARK: Rollen

    /// Fläche aller Bildschirme: hell Papier, dunkel Nachtblau.
    static let background = Color(uiColor: backgroundUIColor)
    /// Text, Linien und Bedienelemente: hell Markenblau, dunkel Papier.
    static let ink = Color(uiColor: inkUIColor)
    static let inkSecondary = ink.opacity(0.7)
    static let hairline = dynamic(light: brandHex, dark: paperHex, lightAlpha: 0.25, darkAlpha: 0.2)
    /// Kopfband in Heute, in Hell und Dunkel gleich.
    static let band = brand
    static let onBand = paper
    static let onBandSecondary = onBand.opacity(0.8)

    /// Einfärbung des Kalenders im Tab: hell Markenblau, dunkel Leuchtfarbe Blau, damit er in beiden Modi blau ist.
    static let progress = dynamic(light: brandHex, dark: 0x7979F2)

    /// Dieselben Farben für UIKit (Navigationsleiste). Sie bleiben dynamisch und lösen sich erst beim Zeichnen auf,
    /// damit sie dem Modus folgen und nicht dem beim Start.
    static let backgroundUIColor = dynamicUIColor(light: paperHex, dark: nightHex)
    static let inkUIColor = dynamicUIColor(light: brandHex, dark: paperHex)

    /// Statusfarben, nur für die Statusmarke am Icon. Für grün gibt es keine Farbe.
    static let statusYellow = dynamic(light: 0xA88000, dark: 0xF2C200)
    static let statusRed = dynamic(light: 0xE00000, dark: 0xF27979)

    // MARK: Deckkraft

    /// Deckkraft der Flächen aus `ink` (Chip, Button `secondary`) und der Icon Kachel in Habitfarbe.
    static let fillOpacity: Double = 0.14
    /// Deckkraft der Fläche des Buttons `onBand`.
    static let onBandFillOpacity: Double = 0.2
    /// Deckkraft eines 7 Tage Punkts ohne Erledigung, bei Teilerledigung von knapp über 0 % bis knapp unter 100 %.
    static let dotEmptyOpacity: Double = 0.22
    static let dotPartialOpacity: ClosedRange<Double> = 0.3...0.8
    /// Deckkraft des äußeren Rahmens um den angezeigten Tag in `WeekDots`.
    static let dotRingOpacity: Double = 0.4
    /// Deckkraft der Tinte in `MonthCalendar`: von knapp über 0 % bis 100 % Tagesfortschritt. Bei 0 % keine Farbe.
    static let calendarFillOpacity: ClosedRange<Double> = 0.15...0.9
    /// Ab dieser Deckkraft steht die Tageszahl in `background` statt in `ink`.
    static let calendarOnFillThreshold: Double = 0.5
    /// Deckkraft von Icon und Bedienelement eines pausierten Habits sowie des Strichs eines pausierten Tages.
    static let pausedOpacity: Double = 0.6
    /// Deckkraft der Fläche eines pausierten Tages in `MonthCalendar`.
    static let pausedDayOpacity: Double = 0.3
    /// Deckkraft zukünftiger, gesperrter Tage in `MonthCalendar`.
    static let calendarFutureOpacity: Double = 0.35
    /// Deckkraft eines Bedienelements, das gerade nicht benutzbar ist (z.B. Minus bei 0).
    static let disabledOpacity: Double = 0.35
    /// Deckkraft der offenen Segmente in `SegmentBar`.
    static let segmentOpenOpacity: Double = 0.25

    /// Farbe, die sich mit dem Modus ändert, aus Hex Werten (`0xRRGGBB`).
    static func dynamic(light: UInt32, dark: UInt32, lightAlpha: CGFloat = 1, darkAlpha: CGFloat = 1) -> Color {
        Color(uiColor: dynamicUIColor(light: light, dark: dark, lightAlpha: lightAlpha, darkAlpha: darkAlpha))
    }

    static func dynamicUIColor(light: UInt32, dark: UInt32, lightAlpha: CGFloat = 1, darkAlpha: CGFloat = 1) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark, alpha: darkAlpha)
                : UIColor(hex: light, alpha: lightAlpha)
        }
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(uiColor: UIColor(hex: hex, alpha: CGFloat(alpha)))
    }
}
