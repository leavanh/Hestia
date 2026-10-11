import XCTest

/// Prüft die Definition of Done von Phase 3.3 direkt in der Oberfläche: Statusmarke nur bei gelb und rot.
/// Jeder Test startet mit leerem Datenbestand (`-HestiaResetData`).
final class TodayPhase33UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testOnlyYellowAndRedHabitsShowAStatusBadge() {
        let app = XCUIApplication()
        app.launchArguments = ["-HestiaResetData", "-HestiaSampleData"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Lesen"].waitForExistence(timeout: 5))

        let expected = [
            "Lesen": "Grün", "Sport": "Grün", "Joggen": "Gelb", "Meditieren": "Rot", "Gitarre üben": "Rot",
        ]
        for (name, value) in expected {
            let status = app.descendants(matching: .any)["status-\(name)"].firstMatch
            XCTAssertTrue(status.exists, name)
            XCTAssertEqual(status.value as? String, value, "\(name): Wert")

            let badge = app.descendants(matching: .any)["status-badge-\(name)"].firstMatch
            XCTAssertEqual(badge.exists, value != "Grün", "\(name): Statusmarke nur bei Gelb und Rot")
            if badge.exists {
                XCTAssertLessThan(badge.frame.width, status.frame.width, "\(name): Marke ist klein")
                XCTAssertGreaterThan(badge.frame.midX, status.frame.midX, "\(name): Marke rechts")
                XCTAssertLessThan(badge.frame.midY, status.frame.midY, "\(name): Marke oben")
            }
        }
    }
}
