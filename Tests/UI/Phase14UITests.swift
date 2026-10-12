import XCTest

/// Prüft die Definition of Done von Phase 14 direkt in der Oberfläche: Wochenbeginn. Ab Phase 15 die Zeiträume und ab Phase 18.1
/// auch Statusmarke ausblenden und das Sheet "Unterstützen". Die Einstellungen haben keinen Abschnitt "Über" mehr (Phase 17).
/// Alles in einem Test, weil jeder Start der App Zeit kostet. Er startet mit Testdaten und zurückgesetzten Einstellungen
/// (`-HestiaResetData`, `-HestiaSampleData`).
final class Phase14UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// Scrollt in den Einstellungen, bis das Element antippbar ist (erst nach unten, sonst zurück nach oben).
    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) -> XCUIElement {
        for _ in 0..<6 where !element.isHittable { app.swipeUp() }
        for _ in 0..<6 where !element.isHittable { app.swipeDown() }
        return element
    }

    @MainActor
    func testSettingsChangeTodayAndHaveNoAboutSection() {
        let app = XCUIApplication()
        app.launchArguments = ["-HestiaResetData", "-HestiaSampleData"]
        app.launch()

        let line = app.staticTexts["repeat-Gitarre üben"].firstMatch
        XCTAssertTrue(line.waitForExistence(timeout: 5))
        XCTAssertTrue(line.label.localizedCaseInsensitiveContains("in 7 Tagen"), "Voreinstellung ist rollierend: \(line.label)")
        XCTAssertTrue(app.control("status-badge-Meditieren").exists, "Mit Voreinstellung zeigt der rote Habit eine Marke")

        // Wochenbeginn Sonntag.
        app.openTab(.settings)
        reveal(app.control("settings-first-weekday-sunday"), in: app).tap()
        app.openTab(.today)
        let strip = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'week-strip-'"))
        XCTAssertTrue(strip.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(strip.count, 7)
        XCTAssertTrue(strip.element(boundBy: 0).label.hasPrefix("Sonntag"), "Das erste Feld des Wochenstreifens ist ein Sonntag")

        // Zeiträume: Kalender, dann wieder rollierend.
        selectPeriods("calendar", in: app)
        app.openTab(.today)
        XCTAssertTrue(line.waitForExistence(timeout: 5))
        XCTAssertTrue(line.label.localizedCaseInsensitiveContains("diese Woche"), "Kalender: \(line.label)")

        selectPeriods("rolling", in: app)
        app.openTab(.today)
        XCTAssertTrue(line.waitForExistence(timeout: 5))
        XCTAssertTrue(line.label.localizedCaseInsensitiveContains("in 7 Tagen"), "Zurück auf rollierend: \(line.label)")

        // Statusmarke ausblenden.
        app.openTab(.settings)
        reveal(app.control("settings-status-mark-hide"), in: app).tap()
        app.openTab(.today)
        let status = app.control("status-Meditieren")
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertEqual(status.value as? String, "Rot")
        XCTAssertFalse(app.control("status-badge-Meditieren").exists, "Keine Marke mehr")

        // Sheet "Unterstützen".
        app.openTab(.settings)
        reveal(app.control("settings-support"), in: app).tap()
        for tier in ["small", "medium", "large"] {
            XCTAssertTrue(app.control("support-tip-\(tier)").waitForExistence(timeout: 5), tier)
        }
        app.control("support-close").tap()
        XCTAssertTrue(app.control("settings-support").waitForExistence(timeout: 5))

        // Kein Abschnitt "Über".
        for _ in 0..<6 { app.swipeUp() }
        XCTAssertFalse(app.control("settings-about").exists, "Kein Abschnitt Über")
        XCTAssertFalse(app.staticTexts["Über Hestia"].exists)
    }

    @MainActor
    private func selectPeriods(_ value: String, in app: XCUIApplication) {
        app.openTab(.settings)
        reveal(app.control("settings-periods-\(value)"), in: app).tap()
    }
}
