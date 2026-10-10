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
    func testNextDayStartsUnchecked() {
        let name = "Lesen \(UUID().uuidString.prefix(4))"
        let app = XCUIApplication()
        app.launch()

        createHabit(named: name, in: app)
        app.buttons["check-\(name)"].tap()
        XCTAssertTrue(app.buttons["check-\(name)"].isSelected)

        // Morgen: gleiches Habit, aber leer, und das Datum ist weitergesprungen.
        app.terminate()
        app.launchArguments = ["-HabitusDayOffset", "1"]
        app.launch()
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["check-\(name)"].isSelected)

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now)!
        let locale = Locale(identifier: "de_DE")
        XCTAssertEqual(app.staticTexts["today-title"].label, tomorrow.formatted(.dateTime.weekday(.wide).locale(locale)))
        XCTAssertEqual(app.staticTexts["today-subtitle"].label, tomorrow.formatted(.dateTime.day().month(.wide).locale(locale)))

        // Zurück zu heute: das Häkchen von heute ist unverändert.
        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["check-\(name)"].isSelected)
    }
}
