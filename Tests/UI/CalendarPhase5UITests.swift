import XCTest

/// Prüft die Definition of Done von Phase 5 in der Oberfläche: Habit Liste mit aktuellem Streak unter dem Kalender
/// und Habit Detail mit Monatskalender, Streaks und Quote 30 Tage.
/// Die Testdaten sind relativ zu heute aufgebaut. "Lesen" ist gestern erledigt, vorgestern nicht, davor in Blöcken
/// von 4 Tagen mit einer Lücke alle 5 Tage. Heute ist offen. Das ergibt:
/// aktueller Streak 1, längster Streak 4, Quote 30 Tage 23 von 29 bewerteten Tagen = 79 %.
/// Dazu (Phase 11): 48 Erledigungen seit der Erstellung vor 60 Tagen (59 Tage ab vorgestern, davon 12 Lücken, plus
/// gestern) und keine Pause.
final class CalendarPhase5UITests: XCTestCase {
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
        XCTAssertEqual(app.staticTexts["detail-rhythm"].label, "20 Min · Täglich")
        // Streak im Band, vier Kennzahlen im Raster. Im Wert steht nur die Zahl, die Einheit in der Beschriftung.
        XCTAssertEqual(app.staticTexts["stat-current-streak"].label, "Aktueller Streak: 1 Tag")
        XCTAssertEqual(app.staticTexts["stat-longest-streak"].label, "4")
        XCTAssertEqual(app.staticTexts["stat-rate-30"].label, "79\u{00A0}%")
        XCTAssertEqual(app.staticTexts["stat-total"].label, "48")
        XCTAssertEqual(app.staticTexts["stat-pauses"].label, "0")
    }
}
