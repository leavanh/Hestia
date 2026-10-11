import XCTest

/// Prüft die Definition of Done von Phase 8.1 direkt in der Oberfläche: eigene Tab Bar, Plus und Sortieren ohne Glas,
/// `StepperControl` im Sheet.
/// Jeder Test startet mit leerem Datenbestand (`-HabitusResetData`).
final class Phase81UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func launch(sampleData: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-HabitusResetData"] + (sampleData ? ["-HabitusSampleData"] : [])
        app.launch()
        return app
    }

    // MARK: Tab Bar

    @MainActor
    func testTabBarSwitchesBetweenTheThreeTabs() {
        let app = launch()
        XCTAssertTrue(app.buttons["tab-today"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tab-today"].isSelected)
        XCTAssertFalse(app.buttons["tab-calendar"].isSelected)

        app.openTab(.calendar)
        XCTAssertTrue(app.staticTexts["calendar-empty"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tab-calendar"].isSelected)
        XCTAssertFalse(app.buttons["tab-today"].isSelected)

        app.openTab(.settings)
        XCTAssertTrue(app.staticTexts["no-pauses"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tab-settings"].isSelected)
        XCTAssertFalse(app.buttons["tab-calendar"].isSelected)

        app.openTab(.today)
        XCTAssertTrue(app.staticTexts["today-empty"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tab-today"].isSelected)
    }

    @MainActor
    func testTodayKeepsItsShownDayWhenSwitchingTabs() {
        let app = launch(sampleData: true)
        let list = app.scrollViews["today-list"]
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        list.swipeRight()
        let subtitle = app.staticTexts["today-subtitle"]
        XCTAssertTrue(app.staticTexts["today-badge"].label.localizedCaseInsensitiveContains("gestern"))
        let shown = subtitle.label

        app.openTab(.calendar)
        XCTAssertTrue(app.buttons["calendar-previous"].waitForExistence(timeout: 5))
        app.openTab(.today)

        XCTAssertTrue(subtitle.waitForExistence(timeout: 5))
        XCTAssertEqual(subtitle.label, shown, "Heute zeigt weiter denselben Tag")
        XCTAssertTrue(app.staticTexts["today-badge"].label.localizedCaseInsensitiveContains("gestern"))
    }

    @MainActor
    func testLastCardIsNotCoveredByTheTabBar() {
        let app = launch(sampleData: true)
        let list = app.scrollViews["today-list"]
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        for _ in 0..<8 { list.swipeUp() }

        let bar = app.buttons["tab-today"].frame
        let checks = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'check-' OR identifier BEGINSWITH 'counter-'"))
        XCTAssertGreaterThan(checks.count, 0)
        let lowest = (0..<checks.count)
            .map { checks.element(boundBy: $0) }
            .filter(\.isHittable)
            .map { $0.frame.maxY }
            .max() ?? 0
        XCTAssertGreaterThan(lowest, 0)
        XCTAssertLessThanOrEqual(lowest, bar.minY, "Die letzte Karte endet über der Leiste")
    }

    // MARK: Plus und Sortieren

    @MainActor
    func testPlusAndSortInTheBar() {
        let app = launch(sampleData: true)
        let sort = app.buttons["sort-toggle"]
        XCTAssertTrue(sort.waitForExistence(timeout: 5))
        XCTAssertEqual(sort.label, "Sortieren")

        app.buttons["Neuer Habit"].tap()
        XCTAssertTrue(app.navigationBars["Neuer Habit"].waitForExistence(timeout: 5))
        app.buttons["Abbrechen"].tap()
        XCTAssertTrue(sort.waitForExistence(timeout: 5))

        sort.tap()
        XCTAssertEqual(sort.label, "Fertig")
        XCTAssertFalse(app.buttons["Neuer Habit"].exists, "Im Sortiermodus gibt es kein Plus")
        sort.tap()
        XCTAssertEqual(sort.label, "Sortieren")
    }

    // MARK: StepperControl

    @MainActor
    func testStepperKeysChangeAndLimitTheCount() {
        let app = launch()
        app.buttons["Neuer Habit"].tap()
        let plus = app.buttons["target-stepper-plus"]
        let minus = app.buttons["target-stepper-minus"]
        XCTAssertTrue(plus.waitForExistence(timeout: 5))
        XCTAssertFalse(minus.isEnabled, "Bei 1 ist Minus gesperrt")

        plus.tap()
        XCTAssertEqual(app.control("target-stepper").label, "2x täglich")
        XCTAssertTrue(minus.isEnabled)

        app.otherElements["rhythm-picker"].buttons["Woche"].tap()
        for _ in 0..<10 { plus.tap() }
        XCTAssertEqual(app.control("target-stepper").label, "7x pro Woche")
        XCTAssertFalse(plus.isEnabled, "An der oberen Grenze ist Plus gesperrt")
    }

    @MainActor
    func testMonthDayStepperMovesByOne() {
        let app = launch()
        app.buttons["Neuer Habit"].tap()
        app.otherElements["rhythm-picker"].buttons["Monat"].tap()
        app.otherElements["variant-picker"].buttons["Monatstag"].tap()

        let value = app.control("monthday-picker")
        XCTAssertTrue(value.waitForExistence(timeout: 5))
        app.setMonthDay(to: 1)
        XCTAssertEqual(value.value as? String, "1.")
        XCTAssertFalse(app.buttons["monthday-picker-minus"].isEnabled)

        app.buttons["monthday-picker-plus"].tap()
        XCTAssertEqual(value.value as? String, "2.")
    }
}
