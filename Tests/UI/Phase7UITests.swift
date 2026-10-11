import XCTest

/// Prüft die Definition of Done von Phase 7 direkt in der Oberfläche: Leerzustände und VoiceOver Beschriftungen.
/// Jeder Test startet mit leerem Datenbestand (`-HabitusResetData`).
final class Phase7UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func launch(_ arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-HabitusResetData"] + arguments
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

    @MainActor
    func testEmptyTodayButtonCreatesTheFirstHabit() {
        let app = launch()
        let create = app.buttons["today-empty-action"]
        XCTAssertTrue(create.waitForExistence(timeout: 5))
        XCTAssertEqual(create.label, "Lege deinen ersten Habit an")
        create.tap()

        let field = app.textFields["name-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("Lesen\n")
        app.buttons["Speichern"].tap()

        XCTAssertTrue(app.staticTexts["Lesen"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["today-empty"].exists, "Mit einem Habit ist der Leerzustand weg")
        XCTAssertTrue(app.buttons["sort-toggle"].isEnabled)
    }

    @MainActor
    func testVoiceOverLabelsForCheckCircleCounterAndStatusBadge() {
        let app = launch(["-HabitusSampleData"])
        XCTAssertTrue(app.staticTexts["Lesen"].waitForExistence(timeout: 5))

        let check = app.buttons["check-Lesen"]
        XCTAssertEqual(check.label, "Lesen")
        let before = check.value as? String
        XCTAssertTrue(["Erledigt", "Offen"].contains(before ?? ""))
        check.tap()
        XCTAssertNotEqual(check.value as? String, before, "Der Zustand wird mitgelesen")

        let counter = app.descendants(matching: .any)["counter-Wasser trinken-value"].firstMatch
        XCTAssertEqual(counter.label, "Wasser trinken")
        XCTAssertTrue((counter.value as? String)?.hasSuffix("von 3") ?? false)
        XCTAssertEqual(app.buttons["counter-Wasser trinken-plus"].label, "Mehr")
        XCTAssertEqual(app.buttons["counter-Wasser trinken-minus"].label, "Weniger")

        let status = app.descendants(matching: .any)["status-Meditieren"].firstMatch
        XCTAssertEqual(status.label, "Status")
        XCTAssertEqual(status.value as? String, "Rot")
    }
}
