import XCTest

/// Prüft die Definition of Done von Phase 3.2 direkt in der Oberfläche: erledigte Habits nach unten,
/// Bearbeiten per langem Drücken und Status am Icon (ab Phase 3.3 als Statusmarke).
/// Jeder Test startet mit leerem Datenbestand (`-HabitusResetData`).
final class TodayPhase32UITests: XCTestCase {
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

    @MainActor
    func testOrderSurvivesRestart() {
        let app = launchFresh()
        createHabit(named: "Erster", in: app)
        createHabit(named: "Zweiter", in: app)
        app.buttons["check-Erster"].tap()
        assertOrder(["Zweiter", "Erster"], in: app, "Abgehakt rutscht ans Ende")

        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.staticTexts["Erster"].waitForExistence(timeout: 5))
        assertOrder(["Zweiter", "Erster"], in: app, "Nach dem Neustart")

        app.buttons["check-Erster"].tap()
        assertOrder(["Erster", "Zweiter"], in: app, "Aufgehoben: ursprüngliche Reihenfolge, sortOrder blieb unverändert")
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

    @MainActor
    func testBadgeNamesTheShownDay() {
        let app = launchFresh(extraArguments: ["-HabitusSampleData"])
        let list = app.scrollViews["today-list"]
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        let badge = app.staticTexts.matching(identifier: "today-badge")
        func assertBadge(_ text: String) {
            let match = badge.matching(NSPredicate(format: "label == %@", text)).firstMatch
            XCTAssertTrue(match.waitForExistence(timeout: 5), "Kapsel zeigt \(text)")
        }
        assertBadge("Heute")

        list.swipeRight()
        assertBadge("Gestern")
        list.swipeRight()
        assertBadge("Vorgestern")
        list.swipeRight()
        assertBadge("Vor 3 Tagen")

        list.swipeLeft()
        list.swipeLeft()
        list.swipeLeft()
        assertBadge("Heute")
    }

    @MainActor
    func testTodayButtonAppearsOnPastDaysAndJumpsBack() {
        let app = launchFresh(extraArguments: ["-HabitusSampleData"])
        let list = app.scrollViews["today-list"]
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        let button = app.buttons["back-to-today"]
        XCTAssertFalse(button.exists, "Auf heute gibt es keinen Button")

        list.swipeRight()
        list.swipeRight()
        XCTAssertTrue(button.waitForExistence(timeout: 5), "An einem vergangenen Tag erscheint der Button")
        button.tap()

        let badge = app.staticTexts.matching(identifier: "today-badge")
        XCTAssertTrue(badge.matching(NSPredicate(format: "label == %@", "Heute")).firstMatch.waitForExistence(timeout: 5))
        let deadline = Date().addingTimeInterval(5)
        while button.exists, Date() < deadline { Thread.sleep(forTimeInterval: 0.1) }
        XCTAssertFalse(button.exists, "Auf heute verschwindet der Button wieder")
    }

    // MARK: Status

    @MainActor
    func testStatusSitsOnTheIconAndNotNextToTheName() {
        let app = launchFresh(extraArguments: ["-HabitusSampleData"])
        XCTAssertTrue(app.staticTexts["Lesen"].waitForExistence(timeout: 5))

        let expected = [
            "Lesen": "Grün", "Meditieren": "Rot", "Sport": "Grün", "Joggen": "Gelb", "Gitarre üben": "Rot",
        ]
        for (name, value) in expected {
            let status = app.descendants(matching: .any)["status-\(name)"].firstMatch
            XCTAssertTrue(status.exists, name)
            XCTAssertEqual(status.value as? String, value, name)
            // Die Kachel misst 36 pt, ein Punkt neben dem Namen wäre viel kleiner.
            XCTAssertGreaterThanOrEqual(status.frame.width, 36, "\(name): am Icon")
            XCTAssertLessThanOrEqual(status.frame.maxX, app.staticTexts[name].frame.minX, "\(name): links vom Namen")
        }
    }
}
