import XCTest

/// Prüft die Definition of Done von Phase 3.1 direkt in der Oberfläche: Tag wechseln per Wischen,
/// Rhythmus mit Varianten im Sheet, eine Liste und kein Text zum Fenster.
/// Jeder Test startet mit leerem Datenbestand (`-HabitusResetData`).
final class TodayPhase31UITests: XCTestCase {
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

    /// Datum wie in der Datumskarte, `offset` Tage nach heute.
    private func dateText(plus offset: Int = 0) -> String {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: .now)!
        return date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE")))
    }

    private func shownDate(in app: XCUIApplication) -> String {
        app.staticTexts["today-date"].label
    }

    @MainActor
    private func openEditor(named name: String, rhythm: String, variant: String, in app: XCUIApplication) {
        app.buttons["Neuer Habit"].tap()
        let field = app.textFields["name-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(name + "\n")
        app.otherElements["rhythm-picker"].buttons[rhythm].tap()
        app.otherElements["variant-picker"].buttons[variant].tap()
    }

    // MARK: Tag wechseln

    @MainActor
    func testSwipingOnTheDateCardChangesTheDay() {
        let app = launchFresh(extraArguments: ["-HabitusSampleData"])
        let card = app.otherElements["date-card"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertEqual(shownDate(in: app), dateText())

        card.swipeRight()
        XCTAssertEqual(shownDate(in: app), dateText(plus: -1), "Wischen nach rechts zeigt gestern")

        card.swipeRight()
        XCTAssertEqual(shownDate(in: app), dateText(plus: -2), "Weiter zurück geht es")

        card.swipeLeft()
        card.swipeLeft()
        XCTAssertEqual(shownDate(in: app), dateText(), "Wischen nach links zeigt wieder heute")

        card.swipeLeft()
        XCTAssertEqual(shownDate(in: app), dateText(), "Über heute hinaus geht es nicht")
    }

    @MainActor
    func testCheckingOnAPastDayDoesNotChangeToday() {
        let app = launchFresh(extraArguments: ["-HabitusSampleData"])
        let card = app.otherElements["date-card"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        // Beispieldaten: "Meditieren" ist weder heute noch gestern erledigt.
        XCTAssertFalse(app.buttons["check-Meditieren"].isSelected)
        let todayProgress = app.staticTexts["progress-text"].label

        card.swipeRight()
        XCTAssertEqual(shownDate(in: app), dateText(plus: -1))
        XCTAssertTrue(app.buttons["check-Meditieren"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["check-Meditieren"].isSelected)
        let pastProgress = app.staticTexts["progress-text"].label

        app.buttons["check-Meditieren"].tap()
        XCTAssertTrue(app.buttons["check-Meditieren"].isSelected, "Gestern ist abgehakt")
        XCTAssertNotEqual(app.staticTexts["progress-text"].label, pastProgress, "Der Fortschritt von gestern ändert sich")

        card.swipeLeft()
        XCTAssertEqual(shownDate(in: app), dateText())
        XCTAssertFalse(app.buttons["check-Meditieren"].isSelected, "Heute bleibt unverändert")
        XCTAssertEqual(app.staticTexts["progress-text"].label, todayProgress)

        card.swipeRight()
        XCTAssertTrue(app.buttons["check-Meditieren"].isSelected, "Der Wert von gestern ist gespeichert")
    }

    @MainActor
    func testReturningToTheAppShowsToday() {
        let app = launchFresh(extraArguments: ["-HabitusSampleData"])
        let card = app.otherElements["date-card"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.swipeRight()
        XCTAssertEqual(shownDate(in: app), dateText(plus: -1))

        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertEqual(shownDate(in: app), dateText())
    }

    // MARK: Liste

    @MainActor
    func testEveryHabitAppearsOnceInTheList() {
        let app = launchFresh(extraArguments: ["-HabitusSampleData"])
        XCTAssertTrue(app.staticTexts["Lesen"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(identifier: "Lesen").count, 1)
        XCTAssertEqual(app.staticTexts.matching(identifier: "Wasser trinken").count, 1)
    }

    // MARK: Sheet

    @MainActor
    func testSavingWeekdaysAndMonthDayKeepsTheVariant() {
        let app = launchFresh()
        let today = Calendar.current.component(.day, from: .now)
        let otherDay = today == 15 ? 16 : 15

        openEditor(named: "Yoga", rhythm: "Woche", variant: "Wochentage", in: app)
        app.buttons["Speichern"].tap()
        XCTAssertTrue(app.staticTexts["Yoga"].waitForExistence(timeout: 5), "Heutiger Wochentag ist vorausgewählt")

        openEditor(named: "Rechnungen", rhythm: "Monat", variant: "Monatstag", in: app)
        app.buttons["monthday-picker"].tap()
        app.buttons["\(otherDay)."].tap()
        app.buttons["Speichern"].tap()
        XCTAssertTrue(app.staticTexts["progress-text"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Rechnungen"].exists, "Anderer Tag im Monat: heute nicht fällig")

        openEditor(named: "Miete", rhythm: "Monat", variant: "Monatstag", in: app)
        app.buttons["Speichern"].tap()
        XCTAssertTrue(app.staticTexts["Miete"].waitForExistence(timeout: 5), "Heutiger Tag im Monat ist vorausgewählt")
    }

    @MainActor
    func testEditingOpensWithTheMatchingVariant() {
        let app = launchFresh()
        openEditor(named: "Yoga", rhythm: "Woche", variant: "Wochentage", in: app)
        app.buttons["Speichern"].tap()
        openEditor(named: "Miete", rhythm: "Monat", variant: "Monatstag", in: app)
        app.buttons["Speichern"].tap()
        openEditor(named: "Sport", rhythm: "Woche", variant: "Anzahl", in: app)
        app.buttons["Speichern"].tap()
        XCTAssertTrue(app.staticTexts["Sport"].waitForExistence(timeout: 5))

        app.staticTexts["Yoga"].tap()
        XCTAssertTrue(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["rhythm-picker"].buttons["Woche"].isSelected)
        XCTAssertTrue(app.otherElements["variant-picker"].buttons["Wochentage"].isSelected)
        XCTAssertTrue(app.buttons["weekday-1"].exists)
        app.buttons["Abbrechen"].tap()

        app.staticTexts["Miete"].tap()
        XCTAssertTrue(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["rhythm-picker"].buttons["Monat"].isSelected)
        XCTAssertTrue(app.otherElements["variant-picker"].buttons["Monatstag"].isSelected)
        XCTAssertTrue(app.buttons["monthday-picker"].exists)
        app.buttons["Abbrechen"].tap()

        app.staticTexts["Sport"].tap()
        XCTAssertTrue(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["rhythm-picker"].buttons["Woche"].isSelected)
        XCTAssertTrue(app.otherElements["variant-picker"].buttons["Anzahl"].isSelected)
        XCTAssertTrue(app.steppers["target-stepper"].exists)
    }

    // MARK: Rhythmus Zeile

    @MainActor
    func testCardsShowTheRhythmLine() {
        let app = launchFresh()
        openEditor(named: "Sport", rhythm: "Woche", variant: "Anzahl", in: app)
        app.buttons["target-stepper-Increment"].tap()
        app.buttons["Speichern"].tap()
        XCTAssertTrue(app.staticTexts["Sport"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["repeat-Sport"].label, "0 von 2 diese Woche")

        app.buttons["check-Sport"].tap()
        XCTAssertEqual(app.staticTexts["repeat-Sport"].label, "1 von 2 diese Woche")

        openEditor(named: "Pflanzen", rhythm: "Monat", variant: "Anzahl", in: app)
        app.buttons["Speichern"].tap()
        XCTAssertEqual(app.staticTexts["repeat-Pflanzen"].label, "0 von 1 diesen Monat")

        app.buttons["Neuer Habit"].tap()
        let field = app.textFields["name-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Wasser\n")
        app.buttons["target-stepper-Increment"].tap()
        app.buttons["Speichern"].tap()
        XCTAssertEqual(app.staticTexts["repeat-Wasser"].label, "2 pro Tag")

        app.buttons["Neuer Habit"].tap()
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Lesen\n")
        app.buttons["Speichern"].tap()
        XCTAssertEqual(app.staticTexts["repeat-Lesen"].label, "Täglich")
    }
}
