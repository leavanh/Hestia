import XCTest

/// Prüft die Definition of Done von Phase 6 direkt in der Oberfläche: Pausen, Beenden mit Historie behalten oder
/// löschen und Sortieren. Jeder Test startet mit leerem Datenbestand (`-HabitusResetData`).
final class SettingsPhase6UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func launchFresh(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-HabitusResetData"] + extraArguments
        app.launch()
        return app
    }

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

    /// Beendet einen Habit über das Bearbeiten Sheet (langes Drücken, "Habit beenden", Antwort im Dialog).
    @MainActor
    private func endHabit(named name: String, answer: String, in app: XCUIApplication) {
        app.staticTexts[name].press(forDuration: 1.5)
        XCTAssertTrue(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 5))
        let end = app.buttons["end-habit"]
        for _ in 0..<4 where !end.isHittable { app.swipeUp() }
        end.tap()
        let alert = app.alerts["Habit beenden?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons[answer].tap()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
    }

    // MARK: Beenden

    @MainActor
    private func scrollToExist(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        for _ in 0..<8 where !element.exists { app.scrollViews["calendar-scroll"].swipeUp() }
        return element.exists
    }

    @MainActor
    func testEndingAndDeletingTheHistoryRemovesTheHabitEverywhere() {
        let app = launchFresh()
        createHabit(named: "Lesen", in: app)
        createHabit(named: "Sport", in: app)

        endHabit(named: "Lesen", answer: "Historie löschen", in: app)
        XCTAssertFalse(app.staticTexts["Lesen"].exists, "Gelöscht: weg aus Heute")
        XCTAssertTrue(app.staticTexts["Sport"].exists)

        app.openTab(.calendar)
        XCTAssertTrue(app.buttons["calendar-previous"].waitForExistence(timeout: 5))
        XCTAssertTrue(scrollToExist(app.buttons["habit-row-Sport"], in: app))
        XCTAssertFalse(app.buttons["habit-row-Lesen"].exists, "Auch im Kalender ist er weg")
    }
}

/// Pausen mit Beispieldaten: eine vergangene Pause für "Lesen" (vorgestern und gestern) und eine geplante für "Sport".
final class PausesWithSampleDataUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-HabitusResetData", "-HabitusSampleData", "-HabitusSamplePauses"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Lesen"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor
    func testPausedDaysAreDashesInTheWeekDots() {
        let app = launch()
        // Lesen war vorgestern und gestern pausiert: heute stehen zwei Striche in den 7 Punkten.
        let dots = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@ AND value == %@", "Letzte 7 Tage", "2 Tage pausiert"))
        XCTAssertEqual(dots.count, 1, "Nur Lesen hat pausierte Tage")
    }

}
