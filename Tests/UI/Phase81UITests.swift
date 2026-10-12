import XCTest

/// Prüft die Definition of Done von Phase 8.1 direkt in der Oberfläche: eigene Tab Bar, Plus und Sortieren ohne Glas,
/// `StepperControl` im Sheet.
/// Jeder Test startet mit leerem Datenbestand (`-HestiaResetData`).
final class Phase81UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func launch(sampleData: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-HestiaResetData"] + (sampleData ? ["-HestiaSampleData"] : [])
        app.launch()
        return app
    }

    // MARK: Tab Bar

    @MainActor
    func testTabBarSwitchesBetweenTheThreeTabs() {
        let app = launch()
        XCTAssertTrue(app.tabButton(.today).waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabButton(.today).isSelected)
        XCTAssertFalse(app.tabButton(.calendar).isSelected)
        XCTAssertTrue(app.staticTexts["today-empty"].waitForExistence(timeout: 5), "Heute ohne Habits")
        XCTAssertFalse(app.buttons["sort-toggle"].isEnabled, "Ohne Habits gibt es nichts zu sortieren")

        app.openTab(.calendar)
        XCTAssertTrue(app.staticTexts["calendar-empty"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabButton(.calendar).isSelected)
        XCTAssertFalse(app.tabButton(.today).isSelected)

        app.openTab(.settings)
        XCTAssertTrue(app.staticTexts["no-pauses"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabButton(.settings).isSelected)
        XCTAssertFalse(app.tabButton(.calendar).isSelected)

        app.openTab(.today)
        XCTAssertTrue(app.staticTexts["today-empty"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabButton(.today).isSelected)
    }

    // MARK: Plus und Sortieren

    @MainActor
    func testPlusAndSortInTheBar() {
        let app = launch(sampleData: true)
        let sort = app.buttons["sort-toggle"]
        XCTAssertTrue(sort.waitForExistence(timeout: 5))
        XCTAssertEqual(sort.label, "Sortieren")
        // Ab Phase 9: Plus im Kopfband, Sortieren im Listenkopf neben der Anzahl der Habits.
        let header = app.otherElements["today-header"]
        XCTAssertTrue(header.buttons["Neuer Habit"].exists, "Plus steht im Kopfband")
        XCTAssertFalse(header.buttons["sort-toggle"].exists, "Sortieren steht nicht im Kopfband")
        let count = app.staticTexts["habit-count"]
        XCTAssertTrue(count.label.hasSuffix(" Habits"))
        XCTAssertEqual(sort.frame.midY, count.frame.midY, accuracy: 12, "Sortieren steht in der Zeile mit der Anzahl")

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

}
