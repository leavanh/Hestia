import XCTest

/// Prüft die Definition of Done von Phase 1 direkt in der Oberfläche.
final class TodayUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// Wartet, bis das Element nicht mehr wandert (z.B. weil ein erledigter Habit animiert nach unten rutscht).
    @MainActor
    private func waitUntilStill(_ element: XCUIElement) {
        var last = element.frame
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            Thread.sleep(forTimeInterval: 0.3)
            let current = element.frame
            if current == last { return }
            last = current
        }
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
        waitUntilStill(check)
        check.tap()
        XCTAssertTrue(check.isSelected, "Abhaken")
        waitUntilStill(check)
        check.tap()
        XCTAssertFalse(check.isSelected, "Aufheben")
        waitUntilStill(check)
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

        let extra = app.staticTexts["extra-\(name)"]
        XCTAssertTrue(extra.waitForExistence(timeout: 5))
        XCTAssertTrue(extra.label.localizedCaseInsensitiveContains("20 Min"), "Der Zusatz steht neben dem Namen: \(extra.label)")
        XCTAssertFalse(app.staticTexts["repeat-\(name)"].label.localizedCaseInsensitiveContains("20 Min"), "Die Häufigkeit steht ohne Zusatz")

        // Langes Drücken öffnet das Kontextmenü (Phase 18.4), "Bearbeiten" darin öffnet das Sheet.
        app.staticTexts[name].press(forDuration: 1.2)
        XCTAssertTrue(app.buttons["Bearbeiten"].waitForExistence(timeout: 5), "Kontextmenü zeigt Bearbeiten")
        XCTAssertTrue(app.buttons["Pausieren"].exists, "Kontextmenü zeigt Pausieren")
        XCTAssertTrue(app.buttons["Habit beenden"].exists, "Kontextmenü zeigt Habit beenden")
        app.buttons["Bearbeiten"].tap()
        XCTAssertTrue(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 5), "Bearbeiten im Kontextmenü öffnet das Sheet")
        app.buttons["Abbrechen"].tap()

        app.openDetail(ofCard: name)
        app.buttons["detail-edit"].tap()
        XCTAssertTrue(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 5), "Bearbeiten im Detail öffnet das Sheet")
        XCTAssertFalse(app.buttons["end-habit"].exists, "Beenden steht nicht mehr im Sheet")
        XCTAssertTrue(app.textFields["detail-field"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["detail-field"].value as? String, "20 Min", "Bearbeiten zeigt den Zusatz im Feld")

        // Zusatz löschen und sichern: die Rhythmus Zeile zeigt ihn nicht mehr.
        let field = app.textFields["detail-field"]
        field.tap()
        field.press(forDuration: 1.2)
        if app.menuItems["Select All"].waitForExistence(timeout: 2) { app.menuItems["Select All"].tap() }
        field.typeText(XCUIKeyboardKey.delete.rawValue)
        app.buttons["Speichern"].tap()
        app.goBack()
        XCTAssertTrue(app.staticTexts["repeat-\(name)"].waitForExistence(timeout: 5))
        XCTAssertFalse(extra.exists && extra.label.localizedCaseInsensitiveContains("20 Min"), "Gelöschter Zusatz verschwindet")
    }

    /// Antippen öffnet das Detail mit dem Stand des Tages, Abhaken dort gilt auch für die Karte in Heute.
    @MainActor
    func testTappingACardOpensTheDetailWhereTheHabitCanBeChecked() {
        let app = XCUIApplication()
        app.launchArguments = ["-HestiaResetData", "-HestiaSampleData"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Meditieren"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["check-Meditieren"].isSelected)

        app.openDetail(ofCard: "Meditieren")
        XCTAssertFalse(app.tabBars.firstMatch.isHittable, "Im Detail ist die Tab Bar ausgeblendet")
        XCTAssertEqual(app.staticTexts["detail-day"].label, "Heute")
        XCTAssertEqual(app.staticTexts["detail-state"].label, "Offen")

        let check = app.buttons["detail-check"]
        check.tap()
        XCTAssertTrue(check.isSelected)
        XCTAssertEqual(app.staticTexts["detail-state"].label, "Erledigt")

        app.goBack()
        XCTAssertTrue(app.buttons["check-Meditieren"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["check-Meditieren"].isSelected, "Die Karte in Heute ist abgehakt")

        app.openDetail(ofCard: "Meditieren")
        app.buttons["detail-edit"].tap()
        XCTAssertTrue(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 5))
    }
}
