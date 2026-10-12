import XCTest

/// Die drei Tabs der Tab Bar, angesteuert über ihre Bezeichner `tab-today` usw.
enum TabID: String {
    case today, calendar, settings

    var identifier: String { "tab-\(rawValue)" }

    /// Beschriftung in der Tab Bar (Tests laufen auf Deutsch). Direkt nach dem Start meldet die System Tab Bar ihre
    /// Buttons manchmal nur mit Beschriftung und noch ohne Bezeichner, deshalb gilt beides.
    var label: String {
        switch self {
        case .today: "Heute"
        case .calendar: "Kalender"
        case .settings: "Einstellungen"
        }
    }
}

extension XCUIApplication {
    /// Der Button des Tabs in der Tab Bar, gefunden über Bezeichner oder Beschriftung.
    @MainActor
    func tabButton(_ tab: TabID) -> XCUIElement {
        tabBars.buttons.matching(NSPredicate(format: "identifier == %@ OR label == %@", tab.identifier, tab.label)).firstMatch
    }

    /// Tippt in der Tab Bar auf den Tab. Wartet, bis die Tab Bar nach dem Start da ist.
    @MainActor
    func openTab(_ tab: TabID) {
        let button = tabButton(tab)
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Tab \(tab.rawValue) fehlt in der Tab Bar")
        button.tap()
    }

    /// Geht im Habit Detail mit dem Zurück Button des Systems (links in der Leiste) zurück.
    @MainActor
    func goBack() {
        let back = navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(back.waitForExistence(timeout: 5), "Zurück Button fehlt")
        back.tap()
    }

    /// Öffnet das Habit Detail per Antippen des Namens in der Karte und wartet, bis die Seite da ist.
    @MainActor
    func openDetail(ofCard name: String) {
        staticTexts[name].tap()
        XCTAssertTrue(scrollViews["habit-detail"].waitForExistence(timeout: 5), "Detail von \(name) öffnet nicht")
    }

    /// Ein Baustein mit Bezeichner, egal welchen Typ ihn XCTest meldet (z.B. `StepperControl`).
    @MainActor
    func control(_ identifier: String) -> XCUIElement {
        descendants(matching: .any)[identifier].firstMatch
    }

    /// Scrollt im Sheet, bis das Feld `monthday-<day>` im Bild ist, und gibt es zurück.
    @MainActor
    func revealMonthDay(_ day: Int) -> XCUIElement {
        let field = control("monthday-\(day)")
        _ = field.waitForExistence(timeout: 5)
        var attempts = 0
        while !field.isHittable && attempts < 5 {
            swipeUp()
            attempts += 1
        }
        return field
    }

    /// Wählt den Monatstag im Sheet mit einem Tippen im Raster von `monthday-picker`.
    @MainActor
    func setMonthDay(to day: Int) {
        revealMonthDay(day).tap()
    }
}
