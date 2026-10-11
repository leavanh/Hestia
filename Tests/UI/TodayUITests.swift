import XCTest

/// Prüft die Definition of Done von Phase 1 direkt in der Oberfläche.
final class TodayUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// Legt über das Sheet einen Habit mit Name, Icon und Farbe an.
    @MainActor
    private func createHabit(named name: String, in app: XCUIApplication) {
        app.buttons["Neuer Habit"].tap()

        let save = app.buttons["Speichern"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertFalse(save.isEnabled, "Speichern darf bei leerem Namen nicht möglich sein")

        let field = app.textFields["name-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(name + "\n")

        app.buttons["icon-drop.fill"].tap()
        app.buttons["color-teal"].tap()

        XCTAssertTrue(save.isEnabled)
        save.tap()

        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCreateCheckUncheckAndPersist() {
        let name = "Wasser \(UUID().uuidString.prefix(4))"
        let app = XCUIApplication()
        app.launch()

        createHabit(named: name, in: app)

        let check = app.buttons["check-\(name)"]
        XCTAssertFalse(check.isSelected)
        check.tap()
        XCTAssertTrue(check.isSelected, "Abhaken")
        check.tap()
        XCTAssertFalse(check.isSelected, "Aufheben")
        check.tap()
        XCTAssertTrue(check.isSelected)

        // Beenden und neu starten: Habit und Häkchen sind noch da.
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["check-\(name)"].isSelected)
    }

    @MainActor
    func testDetailShowsInRhythmLineAndEditor() {
        let name = "Lauf \(UUID().uuidString.prefix(4))"
        let app = XCUIApplication()
        app.launch()

        app.buttons["Neuer Habit"].tap()
        let nameField = app.textFields["name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(name + "\n")
        let detailField = app.textFields["detail-field"]
        detailField.tap()
        detailField.typeText("20 Min\n")
        app.buttons["Speichern"].tap()

        let rhythm = app.staticTexts["repeat-\(name)"]
        XCTAssertTrue(rhythm.waitForExistence(timeout: 5))
        XCTAssertTrue(rhythm.label.localizedCaseInsensitiveContains("20 Min"), "Rhythmus Zeile zeigt den Zusatz: \(rhythm.label)")

        app.staticTexts[name].press(forDuration: 1.5)
        XCTAssertTrue(app.textFields["detail-field"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["detail-field"].value as? String, "20 Min", "Bearbeiten zeigt den Zusatz im Feld")

        // Zusatz löschen und sichern: die Rhythmus Zeile zeigt ihn nicht mehr.
        let field = app.textFields["detail-field"]
        field.tap()
        field.press(forDuration: 1.2)
        if app.menuItems["Select All"].waitForExistence(timeout: 2) { app.menuItems["Select All"].tap() }
        field.typeText(XCUIKeyboardKey.delete.rawValue)
        app.buttons["Speichern"].tap()
        XCTAssertTrue(rhythm.waitForExistence(timeout: 5))
        XCTAssertFalse(rhythm.label.localizedCaseInsensitiveContains("20 Min"), "Gelöschter Zusatz verschwindet: \(rhythm.label)")
    }
}
