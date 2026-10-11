import XCTest

/// Prüft die Definition of Done von Phase 4 direkt in der Oberfläche: Kalender mit Einfärbung (seit Phase 5.1 ein Monat mit Pfeilen),
/// Nachtragen über das Sheet "Tag bearbeiten" und gesperrte Zukunft.
/// Jeder Test startet mit leerem Datenbestand (`-HabitusResetData`) und den Testdaten (`-HabitusSampleData`).
final class CalendarPhase4UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func launchCalendar() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-HabitusResetData", "-HabitusSampleData"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Lesen"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Kalender"].tap()
        XCTAssertTrue(app.buttons[identifier(plus: 0)].waitForExistence(timeout: 5), "Der Kalender beginnt beim aktuellen Monat")
        return app
    }

    private func identifier(plus offset: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: .now)!
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "calendar-day-%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }

    private func monthIdentifier(plus months: Int) -> String {
        let date = Calendar.current.date(byAdding: .month, value: months, to: .now)!
        let parts = Calendar.current.dateComponents([.year, .month], from: date)
        return String(format: "calendar-month-%04d-%02d", parts.year!, parts.month!)
    }

    /// Blättert mit den Pfeilen zum Monat `offset` Monate nach dem aktuellen.
    @MainActor
    private func show(month offset: Int, in app: XCUIApplication) {
        let title = app.staticTexts[monthIdentifier(plus: offset)]
        let arrow = app.buttons[offset < 0 ? "calendar-previous" : "calendar-next"]
        for _ in 0..<12 where !title.exists && arrow.isEnabled {
            arrow.tap()
        }
        XCTAssertTrue(title.exists, "Monat nicht gefunden: \(offset)")
    }

    /// Der Button des Tages `offset` Tage nach heute, nach Blättern in den Monat des Tages.
    @MainActor
    private func dayButton(plus offset: Int, in app: XCUIApplication) -> XCUIElement {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: offset, to: .now)!
        let months = calendar.dateComponents(
            [.month],
            from: calendar.date(from: calendar.dateComponents([.year, .month], from: .now))!,
            to: calendar.date(from: calendar.dateComponents([.year, .month], from: day))!
        ).month!
        show(month: months, in: app)
        let button = app.buttons[identifier(plus: offset)]
        XCTAssertTrue(button.exists && button.isHittable, "Tag nicht gefunden: \(offset)")
        return button
    }

    @MainActor
    private func closeSheet(in app: XCUIApplication) {
        app.buttons["Fertig"].tap()
        XCTAssertTrue(app.scrollViews["calendar-scroll"].waitForExistence(timeout: 5))
    }

    // MARK: Monatskalender

    @MainActor
    func testStartsAtCurrentMonthAndPagesBackIntoThePast() {
        let app = launchCalendar()
        XCTAssertTrue(app.staticTexts[monthIdentifier(plus: 0)].exists, "Aktueller Monat ist im Bild")
        XCTAssertFalse(app.staticTexts[monthIdentifier(plus: -1)].exists, "Es ist immer nur ein Monat zu sehen")

        // Der Kalender reicht mindestens 3 Monate zurück, nicht weiter als der älteste Habit.
        show(month: -3, in: app)
        XCTAssertFalse(app.buttons["calendar-previous"].isEnabled, "Weiter zurück als der erste Monat geht es nicht")
    }

    @MainActor
    func testThereIsNoMonthAfterTheCurrentOne() {
        let app = launchCalendar()
        XCTAssertFalse(app.buttons["calendar-next"].isEnabled)
        XCTAssertFalse(app.staticTexts[monthIdentifier(plus: 1)].exists)
    }

    // MARK: Einfärbung

    @MainActor
    func testDaysAreColoredByDifferentProgress() {
        let app = launchCalendar()
        show(month: -1, in: app)
        let days = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'calendar-day-' AND isEnabled == true"))
        XCTAssertGreaterThanOrEqual(days.count, 20)

        let values = Set((0..<days.count).compactMap { days.element(boundBy: $0).value as? String })
        XCTAssertGreaterThan(values.count, 3, "Tage sind unterschiedlich weit erledigt: \(values)")
        XCTAssertTrue(values.allSatisfy { $0.hasSuffix("%") || $0 == "Nichts fällig" }, "\(values)")
    }

    // MARK: Zukunft gesperrt

    @MainActor
    func testFutureDaysAreDisabledAndTodayAndPastAreNot() {
        let app = launchCalendar()
        XCTAssertTrue(app.buttons[identifier(plus: 0)].isEnabled, "Heute")
        XCTAssertTrue(dayButton(plus: -1, in: app).isEnabled, "Gestern")

        // Morgen liegt am Monatsende im nächsten Monat, den es nicht gibt. Sonst ist er sichtbar und gesperrt.
        let tomorrow = app.buttons[identifier(plus: 1)]
        if tomorrow.exists {
            XCTAssertFalse(tomorrow.isEnabled, "Morgen")
            tomorrow.tap()
            XCTAssertFalse(app.buttons["Fertig"].waitForExistence(timeout: 1), "Kein Sheet für zukünftige Tage")
        }
        let lastDayOfMonth = Calendar.current.range(of: .day, in: .month, for: .now)!.upperBound - 1
        let todayNumber = Calendar.current.component(.day, from: .now)
        if todayNumber < lastDayOfMonth {
            XCTAssertTrue(tomorrow.exists, "Die Tage nach heute stehen noch im aktuellen Monat")
        }
    }

    // MARK: Nachtragen

    @MainActor
    func testSheetForLastWeekShowsOnlyHabitsDueThen() {
        let app = launchCalendar()
        dayButton(plus: -7, in: app).tap()
        XCTAssertTrue(app.buttons["Fertig"].waitForExistence(timeout: 5))

        // Nur die Liste im Sheet zählt, die Habit Liste unter dem Kalender dahinter nennt alle Habits.
        let list = app.scrollViews["day-edit-list"]
        // Tagebuch und Yoga sind am heutigen Wochentag fällig, also auch vor genau 7 Tagen.
        XCTAssertTrue(list.staticTexts["Tagebuch"].waitForExistence(timeout: 5))
        XCTAssertTrue(list.staticTexts["Yoga"].exists)
        // Wäsche waschen ist erst morgen fällig, damit auch nicht vor 7 Tagen.
        XCTAssertFalse(list.staticTexts["Wäsche waschen"].exists)
        XCTAssertTrue(app.staticTexts["progress-text"].exists)
    }

    @MainActor
    func testCheckingInTheSheetChangesCalendarColorForThatDayOnly() {
        let app = launchCalendar()
        let todayBefore = app.buttons[identifier(plus: 0)].value as? String
        let lastWeek = dayButton(plus: -7, in: app)
        let before = lastWeek.value as? String
        lastWeek.tap()

        // Hakt den ersten offenen Kreis ab (offene Habits stehen oben).
        let checks = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'check-'"))
        XCTAssertTrue(checks.firstMatch.waitForExistence(timeout: 5))
        let progress = app.staticTexts["progress-text"]
        let progressBefore = progress.label
        checks.firstMatch.tap()
        XCTAssertNotEqual(progress.label, progressBefore, "Fortschritt im Sheet ändert sich")

        closeSheet(in: app)
        let after = dayButton(plus: -7, in: app).value as? String
        XCTAssertNotEqual(after, before, "Kalenderfarbe der Woche zuvor ändert sich")
        show(month: 0, in: app)
        let today = app.buttons[identifier(plus: 0)]
        XCTAssertEqual(today.value as? String, todayBefore, "Heute bleibt unverändert")
    }

    @MainActor
    func testBackfilledCheckAppearsInTodaysDots() {
        let app = launchCalendar()
        // Gestern abhaken: Sheet öffnen, Habit "Meditieren" (gestern nicht erledigt, heute deshalb rot).
        dayButton(plus: -1, in: app).tap()
        let check = app.buttons["check-Meditieren"]
        XCTAssertTrue(check.waitForExistence(timeout: 5))
        check.tap()
        closeSheet(in: app)

        app.tabBars.buttons["Heute"].tap()
        let status = app.descendants(matching: .any)["status-Meditieren"].firstMatch
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertEqual(status.value as? String, "Grün", "Gestern nachgetragen: Meditieren ist heute nicht mehr rot")
    }
}
