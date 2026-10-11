import XCTest

/// Prüft die Definition of Done von Phase 7 direkt in der Oberfläche: Leerzustände.
/// Jeder Test startet mit leerem Datenbestand (`-HestiaResetData`).
final class Phase7UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func launch(_ arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-HestiaResetData"] + arguments
        app.launch()
        return app
    }

    @MainActor
    func testEmptyStatesOnEveryScreen() {
        let app = launch()

        XCTAssertTrue(app.staticTexts["today-empty"].waitForExistence(timeout: 5), "Heute ohne Habits")
        XCTAssertFalse(app.buttons["sort-toggle"].isEnabled, "Ohne Habits gibt es nichts zu sortieren")

        app.openTab(.calendar)
        XCTAssertTrue(app.staticTexts["calendar-empty"].waitForExistence(timeout: 5), "Kalender ohne Daten")

        app.openTab(.settings)
        XCTAssertTrue(app.staticTexts["no-pauses"].waitForExistence(timeout: 5), "Keine Pausen")
    }

}
