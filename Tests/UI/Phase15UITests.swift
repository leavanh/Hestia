import XCTest

/// Prüft die Definition of Done von Phase 15 direkt in der Oberfläche: Zeiträume in den Einstellungen und die
/// Rhythmus Zeile eines Wochen Habits. Der Test startet mit Testdaten und zurückgesetzten Einstellungen
/// (`-HestiaResetData`, `-HestiaSampleData`).
final class Phase15UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testPeriodsChangeTheRhythmLineOfAWeeklyHabit() {
        let app = XCUIApplication()
        app.launchArguments = ["-HestiaResetData", "-HestiaSampleData"]
        app.launch()

        let line = app.staticTexts["repeat-Gitarre üben"].firstMatch
        XCTAssertTrue(line.waitForExistence(timeout: 5))
        XCTAssertTrue(line.label.contains("in 7 Tagen"), "Voreinstellung ist rollierend: \(line.label)")

        selectPeriods("calendar", in: app)
        app.openTab(.today)
        XCTAssertTrue(line.waitForExistence(timeout: 5))
        XCTAssertTrue(line.label.contains("diese Woche"), "Kalender: \(line.label)")

        selectPeriods("rolling", in: app)
        app.openTab(.today)
        XCTAssertTrue(line.waitForExistence(timeout: 5))
        XCTAssertTrue(line.label.contains("in 7 Tagen"), "Zurück auf rollierend: \(line.label)")
    }

    @MainActor
    private func selectPeriods(_ value: String, in app: XCUIApplication) {
        app.openTab(.settings)
        let option = app.control("settings-periods-\(value)")
        for _ in 0..<4 where !option.isHittable { app.swipeUp() }
        option.tap()
    }
}
