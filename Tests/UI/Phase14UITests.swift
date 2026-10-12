import XCTest

/// Prüft die Definition of Done von Phase 14 direkt in der Oberfläche: Wochenbeginn und "Über Hestia".
/// Der Test startet mit leerem Datenbestand und zurückgesetzten Einstellungen (`-HestiaResetData`).
final class Phase14UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testFirstWeekdaySundayAndAboutSheet() {
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
        let about = app.control("settings-about")
        for _ in 0..<6 where !about.isHittable { app.swipeUp() }
        about.tap()
        XCTAssertTrue(app.control("about-font-Barlow Condensed").waitForExistence(timeout: 5))
        app.buttons["about-done"].tap()
        XCTAssertTrue(app.control("settings-about").waitForExistence(timeout: 5))
        XCTAssertFalse(app.control("about-font-Barlow Condensed").exists)
    }
}
