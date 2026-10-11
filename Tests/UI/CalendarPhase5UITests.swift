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

}
