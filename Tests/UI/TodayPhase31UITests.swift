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

    /// Wochentag (Titel) und Datum (Untertitel) von Heute, `offset` Tage nach heute.
    private func expectedDay(plus offset: Int = 0) -> (title: String, subtitle: String) {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: .now)!
        let locale = Locale(identifier: "de_DE")
        return (
            date.formatted(.dateTime.weekday(.wide).locale(locale)),
            date.formatted(.dateTime.day().month(.wide).locale(locale))
        )
    }

    /// Wartet, bis Titel und Untertitel den Tag zeigen und nur noch ein Kopf im Bild ist (nach der Animation).
    @MainActor
    private func assertShownDay(plus offset: Int, in app: XCUIApplication, _ message: String) {
        let expected = expectedDay(plus: offset)
        let title = app.staticTexts.matching(identifier: "today-title")
        let subtitle = app.staticTexts.matching(identifier: "today-subtitle")
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if title.count == 1, subtitle.count == 1,
               title.firstMatch.label == expected.title, subtitle.firstMatch.label == expected.subtitle { return }
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTFail("\(message): erwartet \(expected.title), \(expected.subtitle)")
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
    func testSwipingOnTheListChangesTheDay() {
        let app = launchFresh(extraArguments: ["-HabitusSampleData"])
        let list = app.scrollViews["today-list"]
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        assertShownDay(plus: 0, in: app, "Start")

        list.swipeRight()
        assertShownDay(plus: -1, in: app, "Wischen nach rechts zeigt gestern")

        list.swipeRight()
        assertShownDay(plus: -2, in: app, "Weiter zurück geht es")

        list.swipeLeft()
        list.swipeLeft()
        assertShownDay(plus: 0, in: app, "Wischen nach links zeigt wieder heute")

        list.swipeLeft()
        assertShownDay(plus: 0, in: app, "Über heute hinaus geht es nicht")
    }

    @MainActor
    func testCheckingOnAPastDayDoesNotChangeToday() {
        let app = launchFresh(extraArguments: ["-HabitusSampleData"])
        let list = app.scrollViews["today-list"]
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        // Beispieldaten: "Meditieren" ist weder heute noch gestern erledigt.
        XCTAssertFalse(app.buttons["check-Meditieren"].isSelected)
        let todayProgress = app.staticTexts["progress-text"].label

        list.swipeRight()
        assertShownDay(plus: -1, in: app, "Gestern")
        XCTAssertTrue(app.buttons["check-Meditieren"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["check-Meditieren"].isSelected)
        let pastProgress = app.staticTexts["progress-text"].label

        app.buttons["check-Meditieren"].tap()
        XCTAssertTrue(app.buttons["check-Meditieren"].isSelected, "Gestern ist abgehakt")
        XCTAssertNotEqual(app.staticTexts["progress-text"].label, pastProgress, "Der Fortschritt von gestern ändert sich")

        list.swipeLeft()
        assertShownDay(plus: 0, in: app, "Heute")
        XCTAssertFalse(app.buttons["check-Meditieren"].isSelected, "Heute bleibt unverändert")
        XCTAssertEqual(app.staticTexts["progress-text"].label, todayProgress)

        list.swipeRight()
        assertShownDay(plus: -1, in: app, "Gestern")
        XCTAssertTrue(app.buttons["check-Meditieren"].isSelected, "Der Wert von gestern ist gespeichert")
    }

    @MainActor
    func testReturningToTheAppShowsToday() {
        let app = launchFresh(extraArguments: ["-HabitusSampleData"])
        let list = app.scrollViews["today-list"]
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        list.swipeRight()
        assertShownDay(plus: -1, in: app, "Gestern")

        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        assertShownDay(plus: 0, in: app, "Zurück in der App")
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
        app.setMonthDay(to: otherDay)
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

        app.staticTexts["Yoga"].press(forDuration: 1.5)
        XCTAssertTrue(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["rhythm-picker"].buttons["Woche"].isSelected)
        XCTAssertTrue(app.otherElements["variant-picker"].buttons["Wochentage"].isSelected)
        XCTAssertTrue(app.buttons["weekday-1"].exists)
        app.buttons["Abbrechen"].tap()

        app.staticTexts["Miete"].press(forDuration: 1.5)
        XCTAssertTrue(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["rhythm-picker"].buttons["Monat"].isSelected)
        XCTAssertTrue(app.otherElements["variant-picker"].buttons["Monatstag"].isSelected)
        XCTAssertTrue(app.control("monthday-picker").exists)
        app.buttons["Abbrechen"].tap()

        app.staticTexts["Sport"].press(forDuration: 1.5)
        XCTAssertTrue(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["rhythm-picker"].buttons["Woche"].isSelected)
        XCTAssertTrue(app.otherElements["variant-picker"].buttons["Anzahl"].isSelected)
        XCTAssertTrue(app.control("target-stepper").exists)
    }

    // MARK: Rhythmus Zeile

    @MainActor
    func testCardsShowTheRhythmLine() {
        let app = launchFresh()
        openEditor(named: "Sport", rhythm: "Woche", variant: "Anzahl", in: app)
        app.buttons["target-stepper-plus"].tap()
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
        app.buttons["target-stepper-plus"].tap()
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
