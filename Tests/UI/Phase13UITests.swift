import XCTest

/// Prüft die Definition of Done von Phase 13 direkt in der Oberfläche: Weitere in Heute. Dazu (Phase 3.3) die Statusmarke, die nur
/// gelbe und rote Habits zeigen.
/// Der Test startet mit leerem Datenbestand und den Testdaten (`-HestiaResetData`, `-HestiaSampleData`).
final class Phase13UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testOtherHabitsAreCollapsedAndOnlyYellowAndRedHabitsShowAStatusBadge() {
        let app = XCUIApplication()
        app.launchArguments = ["-HestiaResetData", "-HestiaSampleData"]
        app.launch()

        // "Blumen gießen" hat einen festen Wochentag (übermorgen) und steht damit nie in der Hauptliste.
        let toggle = app.control("other-habits-toggle")
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        let check = app.control("check-Blumen gießen")
        XCTAssertFalse(check.exists, "Weitere ist beim ersten Start zugeklappt")

        let progress = app.staticTexts["progress-text"].firstMatch
        XCTAssertTrue(progress.waitForExistence(timeout: 5))
        let before = progress.label

        toggle.tap()
        XCTAssertTrue(check.waitForExistence(timeout: 5), "Aufgeklappt ist der Habit mit festem Wochentag zu sehen")
        check.tap()
        XCTAssertEqual(check.value as? String, "Erledigt", "Der Habit in Weitere lässt sich abhaken")
        XCTAssertEqual(progress.label, before, "Der Fortschritt im Band ändert sich nicht")

        // "Sport" ist erfüllt und grün und steht deshalb in Weitere (aufgeklappt).
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
