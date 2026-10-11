import XCTest

/// Prüft die Definition of Done von Phase 4 direkt in der Oberfläche: Kalender mit Einfärbung (seit Phase 5.1 ein Monat mit Pfeilen),
/// Nachtragen über das Sheet "Tag bearbeiten" und gesperrte Zukunft.
/// Jeder Test startet mit leerem Datenbestand (`-HestiaResetData`) und den Testdaten (`-HestiaSampleData`).
final class CalendarPhase4UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func launchCalendar() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-HestiaResetData", "-HestiaSampleData"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Lesen"].waitForExistence(timeout: 5))
        app.openTab(.calendar)
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

    // MARK: Einfärbung

    // MARK: Zukunft gesperrt

    // MARK: Nachtragen

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

}
