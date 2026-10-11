import XCTest

/// Die drei Tabs der eigenen Tab Bar (`PaperTabBar`), angesteuert über ihre Bezeichner `tab-today` usw.
enum TabID: String {
    case today, calendar, settings

    var identifier: String { "tab-\(rawValue)" }
}

extension XCUIApplication {
    /// Tippt in der Tab Bar auf den Tab.
    @MainActor
    func openTab(_ tab: TabID) {
        buttons[tab.identifier].tap()
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
