import XCTest

/// Prüft die Definition of Done von Phase 3.2 direkt in der Oberfläche: erledigte Habits nach unten,
/// Bearbeiten per langem Drücken und Status am Icon (ab Phase 3.3 als Statusmarke).
/// Jeder Test startet mit leerem Datenbestand (`-HestiaResetData`).
final class TodayPhase32UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func launchFresh(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-HestiaResetData"] + extraArguments
        app.launch()
        return app
    }

    /// Legt über das Sheet einen täglichen Habit an.
    @MainActor
    private func createHabit(named name: String, in app: XCUIApplication) {
        app.buttons["Neuer Habit"].tap()
        let field = app.textFields["name-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(name + "\n")
        app.buttons["Speichern"].tap()
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
    }

    /// Wartet, bis die Namen in dieser Reihenfolge von oben nach unten stehen (nach der Animation).
    @MainActor
    private func assertOrder(_ names: [String], in app: XCUIApplication, _ message: String) {
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            let positions = names.map { app.staticTexts[$0].frame.minY }
            if positions == positions.sorted(), Set(positions).count == positions.count { return }
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTFail("\(message): erwartete Reihenfolge \(names)")
    }

    // MARK: Erledigte nach unten

    @MainActor
    func testCheckingTheTopHabitMovesItToTheEndAndUncheckingBringsItBack() {
        let app = launchFresh()
        createHabit(named: "Erster", in: app)
        createHabit(named: "Zweiter", in: app)
        createHabit(named: "Dritter", in: app)
        assertOrder(["Erster", "Zweiter", "Dritter"], in: app, "Ausgangslage")

        app.buttons["check-Erster"].tap()
        assertOrder(["Zweiter", "Dritter", "Erster"], in: app, "Abgehakt rutscht ans Ende")

        app.buttons["check-Erster"].tap()
        assertOrder(["Erster", "Zweiter", "Dritter"], in: app, "Aufgehoben kommt zurück nach oben")
    }

    // MARK: Bearbeiten

    @MainActor
    func testTappingTheCardDoesNothingAndLongPressingOpensTheEditor() {
        let app = launchFresh()
        createHabit(named: "Lesen", in: app)

        app.staticTexts["Lesen"].tap()
        XCTAssertFalse(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 1.5), "Tippen öffnet kein Sheet")

        app.staticTexts["Lesen"].press(forDuration: 0.3)
        XCTAssertFalse(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 1.5), "Kurzes Drücken öffnet kein Sheet")

        app.staticTexts["Lesen"].press(forDuration: 1.5)
        XCTAssertTrue(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["name-field"].value as? String, "Lesen", "Das Sheet zeigt diesen Habit")
    }

    // MARK: Markierung des Tags

    // MARK: Status

}
