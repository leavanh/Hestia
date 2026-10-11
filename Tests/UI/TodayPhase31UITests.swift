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

    /// Titel ("Heute", "Gestern" …) und Datumszeile (als vollständiges Datum für VoiceOver) des Tags `offset` Tage nach heute.
    private func expectedDay(plus offset: Int = 0) -> (title: String, date: String) {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: .now)!
        let titles = ["Heute", "Gestern", "Vorgestern"]
        return (
            -offset < titles.count ? titles[-offset] : "Vor \(-offset) Tagen",
            date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE")))
        )
    }

    /// Wartet, bis Titel und Datumszeile den Tag zeigen und nur noch ein Kopf im Bild ist (nach der Animation).
    @MainActor
    private func assertShownDay(plus offset: Int, in app: XCUIApplication, _ message: String) {
        let expected = expectedDay(plus: offset)
        let title = app.staticTexts.matching(identifier: "today-title")
        let date = app.staticTexts.matching(identifier: "today-date")
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if title.count == 1, date.count == 1,
               title.firstMatch.label == expected.title, date.firstMatch.label == expected.date { return }
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTFail("\(message): erwartet \(expected.title), \(expected.date)")
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

    // MARK: Liste

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
        XCTAssertEqual(app.staticTexts["repeat-Miete"].label, "Am \(today). des Monats")

        // Bearbeiten zeigt den gespeicherten Tag im Raster als ausgewählt.
        app.staticTexts["Miete"].press(forDuration: 1.5)
        XCTAssertTrue(app.control("monthday-\(today)").waitForExistence(timeout: 5))
        XCTAssertTrue(app.control("monthday-\(today)").isSelected)
        XCTAssertFalse(app.control("monthday-\(otherDay)").isSelected)
    }

    // MARK: Rhythmus Zeile

}
