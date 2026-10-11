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
        app.openTab(.calendar)
        XCTAssertTrue(app.staticTexts[monthIdentifier(prefix: "calendar", plus: 0)].waitForExistence(timeout: 5))
        return app
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

}
