import XCTest

/// Prüft die Definition of Done von Phase 14 direkt in der Oberfläche: Wochenbeginn. Ab Phase 18.1 auch Statusmarke ausblenden und das Sheet "Unterstützen". Die Einstellungen haben keinen Abschnitt "Über" mehr (Phase 17).
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

    @MainActor
    func testHideStatusMarkAndOpenSupportSheet() {
        let app = XCUIApplication()
        app.launchArguments = ["-HestiaResetData", "-HestiaSampleData"]
        app.launch()

        let badge = app.control("status-badge-Meditieren")
        XCTAssertTrue(badge.waitForExistence(timeout: 5), "Mit Voreinstellung zeigt der rote Habit eine Marke")

        app.openTab(.settings)
        let hide = app.control("settings-status-mark-hide")
        for _ in 0..<4 where !hide.isHittable { app.swipeUp() }
        hide.tap()

        app.openTab(.today)
        let status = app.control("status-Meditieren")
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertEqual(status.value as? String, "Rot")
        XCTAssertFalse(app.control("status-badge-Meditieren").exists, "Keine Marke mehr")

        app.openTab(.settings)
        let support = app.control("settings-support")
        for _ in 0..<6 where !support.isHittable { app.swipeUp() }
        support.tap()
        for tier in ["small", "medium", "large"] {
            XCTAssertTrue(app.control("support-tip-\(tier)").waitForExistence(timeout: 5), tier)
        }
        app.control("support-close").tap()
        XCTAssertTrue(app.control("settings-support").waitForExistence(timeout: 5))
    }
}
