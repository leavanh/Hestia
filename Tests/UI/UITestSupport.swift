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

    /// Stellt den Monatstag im Sheet mit den Tasten von `monthday-picker` auf `day`.
    @MainActor
    func setMonthDay(to day: Int) {
        let value = control("monthday-picker")
        while let current = Int((value.value as? String ?? "").dropLast()), current != day {
            buttons[current < day ? "monthday-picker-plus" : "monthday-picker-minus"].tap()
        }
    }
}
