import XCTest

/// Prüft die Definition of Done von Phase 2 direkt in der Oberfläche.
/// Jeder Test startet mit leerem Datenbestand (`-HestiaResetData`).
final class TodayPhase2UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func launchFresh() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-HestiaResetData"]
        app.launch()
        return app
    }

    /// Legt über das Sheet einen täglichen Habit an.
    @MainActor
    private func createHabit(named name: String, target: Int = 1, in app: XCUIApplication) {
        app.buttons["Neuer Habit"].tap()

        let field = app.textFields["name-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(name + "\n")

        if target > 1 {
            let increment = app.buttons["target-stepper-plus"]
            XCTAssertTrue(increment.waitForExistence(timeout: 5))
            for _ in 1..<target { increment.tap() }
        }

        app.buttons["Speichern"].tap()
        XCTAssertTrue(app.staticTexts[name].firstMatch.waitForExistence(timeout: 5))
    }

    @MainActor
    func testCounterStaysBetweenZeroAndTarget() {
        let app = launchFresh()
        createHabit(named: "Wasser", target: 3, in: app)

        let minus = app.buttons["counter-Wasser-minus"]
        let plus = app.buttons["counter-Wasser-plus"]
        let value = app.otherElements["counter-Wasser-value"]
        XCTAssertTrue(value.waitForExistence(timeout: 5), "Habit mit Ziel 3 zeigt den Counter")
        XCTAssertFalse(app.buttons["check-Wasser"].exists, "Kein Abhakkreis bei Ziel 3")

        XCTAssertEqual(value.value as? String, "0 von 3")
        XCTAssertFalse(minus.isEnabled, "Minus geht nicht unter 0")

        for expected in 1...3 {
            plus.tap()
            XCTAssertEqual(value.value as? String, "\(expected) von 3")
        }
        XCTAssertFalse(plus.isEnabled, "Plus geht nicht über 3")

        minus.tap()
        XCTAssertEqual(value.value as? String, "2 von 3")
        XCTAssertTrue(plus.isEnabled)
    }

}
