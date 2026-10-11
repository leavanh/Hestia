import XCTest

/// Prüft die Definition of Done von Phase 5 in der Oberfläche: Habit Liste mit aktuellem Streak unter dem Kalender
/// und Habit Detail mit Monatskalender, Streaks und Quote 30 Tage.
/// Die Testdaten sind relativ zu heute aufgebaut. "Lesen" ist gestern erledigt, vorgestern nicht, davor in Blöcken
/// von 4 Tagen mit einer Lücke alle 5 Tage. Heute ist offen. Das ergibt:
/// aktueller Streak 1, längster Streak 4, Quote 30 Tage 23 von 29 bewerteten Tagen = 79 %.
final class CalendarPhase5UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func launchCalendar() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-HabitusResetData", "-HabitusSampleData"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Lesen"].waitForExistence(timeout: 5))
        app.openTab(.calendar)
        XCTAssertTrue(app.scrollViews["calendar-scroll"].waitForExistence(timeout: 5))
        return app
    }

    /// Scrollt nach unten, bis das Element im Bild ist. Liegt es schon oberhalb, wieder nach oben.
    @MainActor
    private func scrollDown(to element: XCUIElement, in app: XCUIApplication) {
        let scroll = app.scrollViews["calendar-scroll"]
        for _ in 0..<12 where !element.exists || !element.isHittable {
            scroll.swipeUp()
        }
        for _ in 0..<12 where !element.exists || !element.isHittable {
            scroll.swipeDown()
        }
        XCTAssertTrue(element.exists && element.isHittable, "Element nicht gefunden: \(element)")
    }

    @MainActor
    private func openDetail(of name: String, in app: XCUIApplication) {
        let row = app.buttons["habit-row-\(name)"]
        scrollDown(to: row, in: app)
        row.tap()
        XCTAssertTrue(app.scrollViews["habit-detail"].waitForExistence(timeout: 5))
    }

    // MARK: Liste unter dem Kalender

    @MainActor
    func testHabitListShowsEveryHabitWithItsCurrentStreakBelowTheCalendar() {
        let app = launchCalendar()
        for name in ["Wasser trinken", "Lesen", "Meditieren", "Vitamine"] {
            scrollDown(to: app.buttons["habit-row-\(name)"], in: app)
        }
        scrollDown(to: app.buttons["habit-row-Lesen"], in: app)
        XCTAssertEqual(app.staticTexts["streak-Lesen"].label, "Aktueller Streak: 1 Tag")
        // Meditieren ist gestern nicht erledigt: Streak 0.
        scrollDown(to: app.buttons["habit-row-Meditieren"], in: app)
        XCTAssertEqual(app.staticTexts["streak-Meditieren"].label, "Aktueller Streak: 0 Tage")
    }

    // MARK: Habit Detail

    @MainActor
    func testDetailShowsStreaksAndRate() {
        let app = launchCalendar()
        openDetail(of: "Lesen", in: app)

        XCTAssertEqual(app.staticTexts["detail-name"].label, "Lesen")
        XCTAssertEqual(app.staticTexts["detail-rhythm"].label, "Täglich")
        XCTAssertEqual(app.staticTexts["stat-current-streak"].label, "1 Tag")
        XCTAssertEqual(app.staticTexts["stat-longest-streak"].label, "4 Tage")
        XCTAssertEqual(app.staticTexts["stat-rate-30"].label, "79 %")
    }

    @MainActor
    func testDetailCalendarShowsOnlyThisHabitAndPagesThroughMonths() {
        let app = launchCalendar()
        openDetail(of: "Lesen", in: app)

        let current = Calendar.current.dateComponents([.year, .month], from: .now)
        let currentMonth = String(format: "habit-calendar-month-%04d-%02d", current.year!, current.month!)
        XCTAssertTrue(app.staticTexts[currentMonth].exists)
        XCTAssertFalse(app.buttons["habit-calendar-next"].isEnabled, "Weiter als der aktuelle Monat geht es nicht")

        app.buttons["habit-calendar-previous"].tap()
        XCTAssertFalse(app.staticTexts[currentMonth].exists)
        XCTAssertTrue(app.buttons["habit-calendar-next"].isEnabled)

        app.buttons["habit-calendar-next"].tap()
        XCTAssertTrue(app.staticTexts[currentMonth].exists)
    }

    @MainActor
    func testDetailClosesWithDone() {
        let app = launchCalendar()
        openDetail(of: "Lesen", in: app)
        app.buttons["Fertig"].tap()
        XCTAssertTrue(app.scrollViews["calendar-scroll"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.scrollViews["habit-detail"].exists)
    }

    @MainActor
    func testStreakChangesWhenADayIsFilledIn() {
        let app = launchCalendar()
        openDetail(of: "Lesen", in: app)
        XCTAssertEqual(app.staticTexts["stat-current-streak"].label, "1 Tag")
        app.buttons["Fertig"].tap()

        // Vorgestern nachtragen: Streak aus gestern, vorgestern und den 4 Tagen davor (3 bis 6 Tage zurück).
        let day = Calendar.current.date(byAdding: .day, value: -2, to: .now)!
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: day)
        let id = String(format: "calendar-day-%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
        let button = app.buttons[id]
        if !button.exists { app.buttons["calendar-previous"].tap() }
        button.tap()
        XCTAssertTrue(app.buttons["check-Lesen"].waitForExistence(timeout: 5))
        app.buttons["check-Lesen"].tap()
        app.buttons["Fertig"].tap()

        openDetail(of: "Lesen", in: app)
        XCTAssertEqual(app.staticTexts["stat-current-streak"].label, "6 Tage")
        XCTAssertEqual(app.staticTexts["stat-longest-streak"].label, "6 Tage")
    }
}
