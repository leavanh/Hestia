import XCTest

/// Prüft die Definition of Done von Phase 14 direkt in der Oberfläche: Wochenbeginn. Die Einstellungen haben keinen Abschnitt "Über" mehr (Phase 17).
/// Der Test startet mit leerem Datenbestand und zurückgesetzten Einstellungen (`-HestiaResetData`).
final class Phase14UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testFirstWeekdaySundayAndNoAboutSection() {
        let app = XCUIApplication()
        app.launchArguments = ["-HestiaResetData"]
        app.launch()

        app.openTab(.settings)
        let sunday = app.control("settings-first-weekday-sunday")
        for _ in 0..<4 where !sunday.isHittable { app.swipeUp() }
        sunday.tap()

        app.openTab(.today)
        let strip = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'week-strip-'"))
        XCTAssertTrue(strip.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(strip.count, 7)
        XCTAssertTrue(strip.element(boundBy: 0).label.hasPrefix("Sonntag"), "Das erste Feld des Wochenstreifens ist ein Sonntag")

        app.openTab(.settings)
        for _ in 0..<6 { app.swipeUp() }
        XCTAssertFalse(app.control("settings-about").exists, "Kein Abschnitt Über")
        XCTAssertFalse(app.staticTexts["Über Hestia"].exists)
    }
}
