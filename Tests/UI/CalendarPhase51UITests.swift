import XCTest

/// Prüft die Definition of Done von Phase 5.1: Der Kalender im Tab und im Habit Detail sind derselbe Monatskalender
/// mit Pfeilen links und rechts.
final class CalendarPhase51UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func monthIdentifier(prefix: String, plus months: Int) -> String {
        let date = Calendar.current.date(byAdding: .month, value: months, to: .now)!
        let parts = Calendar.current.dateComponents([.year, .month], from: date)
        return String(format: "%@-month-%04d-%02d", prefix, parts.year!, parts.month!)
    }

    @MainActor
    private func launchCalendar() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-HabitusResetData", "-HabitusSampleData"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Lesen"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Kalender"].tap()
        XCTAssertTrue(app.staticTexts[monthIdentifier(prefix: "calendar", plus: 0)].waitForExistence(timeout: 5))
        return app
    }

    @MainActor
    private func openDetail(in app: XCUIApplication) {
        let row = app.buttons["habit-row-Lesen"]
        for _ in 0..<12 where !row.exists || !row.isHittable {
            app.scrollViews["calendar-scroll"].swipeUp()
        }
        row.tap()
        XCTAssertTrue(app.scrollViews["habit-detail"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTabAndDetailBothHaveArrowsNextToTheMonthName() {
        let app = launchCalendar()
        XCTAssertTrue(app.buttons["calendar-previous"].exists)
        XCTAssertTrue(app.buttons["calendar-next"].exists)

        openDetail(in: app)
        XCTAssertTrue(app.buttons["habit-calendar-previous"].exists)
        XCTAssertTrue(app.buttons["habit-calendar-next"].exists)
        // Dieselben Wochentage und derselbe Monat in beiden Kalendern.
        XCTAssertTrue(app.staticTexts[monthIdentifier(prefix: "habit-calendar", plus: 0)].exists)
    }

    @MainActor
    func testArrowsAreDisabledAtTheEnds() {
        let app = launchCalendar()
        XCTAssertFalse(app.buttons["calendar-next"].isEnabled, "Im aktuellen Monat")
        for _ in 0..<3 { app.buttons["calendar-previous"].tap() }
        XCTAssertTrue(app.staticTexts[monthIdentifier(prefix: "calendar", plus: -3)].exists)
        XCTAssertFalse(app.buttons["calendar-previous"].isEnabled, "Im ersten Monat")
        XCTAssertTrue(app.buttons["calendar-next"].isEnabled)
    }

    @MainActor
    func testLastWeeksDayInThePreviousMonthCanBeOpened() {
        let app = launchCalendar()
        app.buttons["calendar-previous"].tap()
        let calendar = Calendar.current
        let previous = calendar.date(byAdding: .month, value: -1, to: .now)!
        let lastDay = calendar.range(of: .day, in: .month, for: previous)!.upperBound - 1
        let parts = calendar.dateComponents([.year, .month], from: previous)
        let id = String(format: "calendar-day-%04d-%02d-%02d", parts.year!, parts.month!, lastDay)
        app.buttons[id].tap()
        XCTAssertTrue(app.buttons["Fertig"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDetailMonthIsIndependentOfTheTabMonth() {
        let app = launchCalendar()
        app.buttons["calendar-previous"].tap()
        XCTAssertTrue(app.staticTexts[monthIdentifier(prefix: "calendar", plus: -1)].exists)

        openDetail(in: app)
        XCTAssertTrue(app.staticTexts[monthIdentifier(prefix: "habit-calendar", plus: 0)].exists, "Detail startet im aktuellen Monat")
        app.buttons["habit-calendar-previous"].tap()
        app.buttons["Fertig"].tap()

        XCTAssertTrue(app.staticTexts[monthIdentifier(prefix: "calendar", plus: -1)].waitForExistence(timeout: 5), "Tab bleibt im Vormonat")
    }
}
