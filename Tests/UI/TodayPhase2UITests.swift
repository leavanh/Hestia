import XCTest

/// Prüft die Definition of Done von Phase 2 direkt in der Oberfläche.
/// Jeder Test startet mit leerem Datenbestand (`-HabitusResetData`).
final class TodayPhase2UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func launchFresh() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-HabitusResetData"]
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

    @MainActor
    func testProgressWithTwoHabitsAndTwoCompletions() {
        let app = launchFresh()
        XCTAssertEqual(app.staticTexts["progress-text"].label, "Heute nichts fällig")

        createHabit(named: "Sport", target: 1, in: app)
        createHabit(named: "Wasser", target: 3, in: app)
        XCTAssertEqual(app.staticTexts["progress-text"].label, "0 von 4 · 0\u{00A0}%")

        app.buttons["check-Sport"].tap()
        app.buttons["counter-Wasser-plus"].tap()
        XCTAssertEqual(app.staticTexts["progress-text"].label, "2 von 4 · 50\u{00A0}%")

        app.buttons["check-Sport"].tap()
        XCTAssertEqual(app.staticTexts["progress-text"].label, "1 von 4 · 25\u{00A0}%")
    }

    @MainActor
    func testLongPressingCardOpensEditorAndChangesTarget() {
        let app = launchFresh()
        createHabit(named: "Lesen", in: app)
        XCTAssertTrue(app.buttons["check-Lesen"].exists)

        app.staticTexts["Lesen"].press(forDuration: 1.5)
        XCTAssertTrue(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 5))
        let field = app.textFields["name-field"]
        XCTAssertEqual(field.value as? String, "Lesen", "Das Sheet zeigt die bisherigen Werte")

        let increment = app.buttons["target-stepper-plus"]
        increment.tap()
        increment.tap()
        app.buttons["Speichern"].tap()

        XCTAssertTrue(app.otherElements["counter-Lesen-value"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.otherElements["counter-Lesen-value"].value as? String, "0 von 3")
        XCTAssertFalse(app.buttons["check-Lesen"].exists)
    }

    @MainActor
    func testTappingTheCircleDoesNotOpenEditor() {
        let app = launchFresh()
        createHabit(named: "Yoga", in: app)

        app.buttons["check-Yoga"].tap()
        XCTAssertFalse(app.navigationBars["Habit bearbeiten"].exists)
        XCTAssertTrue(app.buttons["check-Yoga"].isSelected)
    }

    @MainActor
    func testCountSurvivesRestart() {
        let app = launchFresh()
        createHabit(named: "Wasser", target: 3, in: app)
        app.buttons["counter-Wasser-plus"].tap()
        app.buttons["counter-Wasser-plus"].tap()

        app.terminate()
        app.launchArguments = []
        app.launch()
        let value = app.otherElements["counter-Wasser-value"]
        XCTAssertTrue(value.waitForExistence(timeout: 5))
        XCTAssertEqual(value.value as? String, "2 von 3")
    }
}
