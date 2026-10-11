import XCTest

/// Prüft die Definition of Done von Phase 3 direkt in der Oberfläche.
/// Jeder Test startet mit leerem Datenbestand (`-HabitusResetData`).
final class TodayPhase3UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func launchFresh(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-HabitusResetData"] + extraArguments
        app.launch()
        return app
    }

    /// Wochentag nach der Zählung der App (1 = Montag bis 7 = Sonntag), `offset` Tage nach heute.
    private func weekday(plus offset: Int = 0) -> Int {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: .now)!
        return (Calendar.current.component(.weekday, from: date) + 5) % 7 + 1
    }

    /// Beschriftung des Anzahl Steppers, z.B. "3x pro Woche".
    private func stepperText(in app: XCUIApplication) -> String {
        app.steppers["target-stepper"].label
    }

    private func status(of name: String, in app: XCUIApplication) -> String? {
        app.descendants(matching: .any)["status-\(name)"].firstMatch.value as? String
    }

    /// Öffnet das Sheet, gibt den Namen ein und wählt Rhythmus (Täglich, Woche, Monat) und Variante
    /// (Anzahl, Wochentage, Monatstag). Speichert noch nicht.
    @MainActor
    private func openEditor(
        named name: String, rhythm: String? = nil, variant: String? = nil, in app: XCUIApplication
    ) {
        app.buttons["Neuer Habit"].tap()
        let field = app.textFields["name-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(name + "\n")
        if let rhythm {
            app.otherElements["rhythm-picker"].buttons[rhythm].tap()
        }
        if let variant {
            app.otherElements["variant-picker"].buttons[variant].tap()
        }
    }

    @MainActor
    private func save(_ name: String, in app: XCUIApplication) {
        app.buttons["Speichern"].tap()
    }

    // MARK: Sheet

    @MainActor
    func testRhythmSegmentsShowTheMatchingSetting() {
        let app = launchFresh()
        app.buttons["Neuer Habit"].tap()
        let picker = app.otherElements["rhythm-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        XCTAssertEqual(picker.buttons.count, 3)
        for title in ["Täglich", "Woche", "Monat"] {
            XCTAssertTrue(picker.buttons[title].exists, "Segment \(title)")
        }

        let variants = app.otherElements["variant-picker"]
        XCTAssertTrue(picker.buttons["Täglich"].isSelected)
        XCTAssertFalse(variants.exists, "Täglich hat keine Variante")
        XCTAssertEqual(stepperText(in: app), "1x täglich")

        picker.buttons["Woche"].tap()
        XCTAssertEqual(variants.buttons.count, 2)
        XCTAssertTrue(variants.buttons["Anzahl"].isSelected)
        XCTAssertTrue(variants.buttons["Wochentage"].exists)
        XCTAssertEqual(stepperText(in: app), "1x pro Woche")
        XCTAssertFalse(app.buttons["weekday-1"].exists)

        variants.buttons["Wochentage"].tap()
        for number in 1...7 {
            XCTAssertTrue(app.buttons["weekday-\(number)"].exists, "Wochentag \(number)")
        }
        XCTAssertFalse(app.steppers["target-stepper"].exists)

        picker.buttons["Monat"].tap()
        XCTAssertEqual(variants.buttons.count, 2)
        XCTAssertTrue(variants.buttons["Anzahl"].isSelected, "Beim Wechsel gilt die Variante Anzahl")
        XCTAssertTrue(variants.buttons["Monatstag"].exists)
        XCTAssertEqual(stepperText(in: app), "1x pro Monat")
        XCTAssertFalse(app.buttons["weekday-1"].exists)

        variants.buttons["Monatstag"].tap()
        XCTAssertTrue(app.buttons["monthday-picker"].exists)
        XCTAssertFalse(app.steppers["target-stepper"].exists)

        picker.buttons["Täglich"].tap()
        XCTAssertFalse(variants.exists)
        XCTAssertEqual(stepperText(in: app), "1x täglich")
    }

    @MainActor
    func testStepperRangeFollowsTheRhythm() {
        let app = launchFresh()
        app.buttons["Neuer Habit"].tap()
        let picker = app.otherElements["rhythm-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))

        // Pro Woche höchstens 7: weiteres Tippen ändert nichts.
        picker.buttons["Woche"].tap()
        let increment = app.buttons["target-stepper-Increment"]
        for _ in 0..<10 { increment.tap() }
        XCTAssertEqual(stepperText(in: app), "7x pro Woche")

        // Pro Monat geht es weiter, die 7 bleibt erhalten.
        picker.buttons["Monat"].tap()
        XCTAssertEqual(stepperText(in: app), "7x pro Monat")
        increment.tap()
        XCTAssertEqual(stepperText(in: app), "8x pro Monat")

        // Täglich: die 8 bleibt erhalten, höchstens 10.
        picker.buttons["Täglich"].tap()
        XCTAssertEqual(stepperText(in: app), "8x täglich")
        for _ in 0..<5 { increment.tap() }
        XCTAssertEqual(stepperText(in: app), "10x täglich")

        // Zurück zu pro Woche: auf 7 begrenzt.
        picker.buttons["Woche"].tap()
        XCTAssertEqual(stepperText(in: app), "7x pro Woche")
    }

    @MainActor
    func testLastWeekdayCannotBeDeselected() {
        let app = launchFresh()
        openEditor(named: "Yoga", rhythm: "Woche", variant: "Wochentage", in: app)

        let today = weekday()
        XCTAssertTrue(app.buttons["weekday-\(today)"].isSelected, "Heutiger Wochentag ist vorausgewählt")
        app.buttons["weekday-\(today)"].tap()
        XCTAssertTrue(app.buttons["weekday-\(today)"].isSelected, "Mindestens ein Wochentag bleibt ausgewählt")

        let other = weekday(plus: 1)
        app.buttons["weekday-\(other)"].tap()
        XCTAssertTrue(app.buttons["weekday-\(other)"].isSelected)
        app.buttons["weekday-\(today)"].tap()
        let deselected = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isSelected == false"), object: app.buttons["weekday-\(today)"]
        )
        XCTAssertEqual(XCTWaiter().wait(for: [deselected], timeout: 5), .completed)
    }

    // MARK: Pro Woche / pro Monat

    @MainActor
    func testWeeklyHabitCountsInProgress() {
        let app = launchFresh()
        openEditor(named: "Sport", rhythm: "Woche", in: app)
        app.buttons["target-stepper-Increment"].tap()
        app.buttons["target-stepper-Increment"].tap()
        XCTAssertEqual(stepperText(in: app), "3x pro Woche")
        save("Sport", in: app)

        XCTAssertTrue(app.staticTexts["Sport"].waitForExistence(timeout: 5))
        XCTAssertEqual(status(of: "Sport", in: app), "Grün", "Neu angelegt: kein Rot im ersten Fenster")
        XCTAssertEqual(app.staticTexts["progress-text"].label, "0 von 1 · 0\u{00A0}%")

        // Abhaken zählt im Fortschritt.
        app.buttons["check-Sport"].tap()
        XCTAssertEqual(app.staticTexts["progress-text"].label, "1 von 1 · 100\u{00A0}%")
        app.buttons["check-Sport"].tap()
        XCTAssertEqual(app.staticTexts["progress-text"].label, "0 von 1 · 0\u{00A0}%")
    }

    @MainActor
    func testMonthlyHabitHasCheckCircle() {
        let app = launchFresh()
        openEditor(named: "Pflanzen", rhythm: "Monat", in: app)
        save("Pflanzen", in: app)

        XCTAssertTrue(app.buttons["check-Pflanzen"].waitForExistence(timeout: 5), "Pro Monat hat einen Abhakkreis, keinen Counter")
        app.buttons["check-Pflanzen"].tap()
        XCTAssertTrue(app.buttons["check-Pflanzen"].isSelected)
    }

    @MainActor
    func testNewDailyHabitIsGreen() {
        let app = launchFresh()
        openEditor(named: "Lesen", in: app)
        save("Lesen", in: app)
        XCTAssertTrue(app.staticTexts["Lesen"].waitForExistence(timeout: 5))
        XCTAssertEqual(status(of: "Lesen", in: app), "Grün", "Neu angelegt: grün")
    }

    // MARK: Feste Tage

    @MainActor
    func testWeekdayHabitAppearsOnlyOnItsDays() {
        let app = launchFresh()
        // Nur morgen: heute nicht fällig, also nicht in Heute.
        openEditor(named: "Wäsche", rhythm: "Woche", variant: "Wochentage", in: app)
        app.buttons["weekday-\(weekday(plus: 1))"].tap()
        app.buttons["weekday-\(weekday())"].tap()
        save("Wäsche", in: app)

        XCTAssertTrue(app.staticTexts["progress-text"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Wäsche"].exists, "Heute nicht fällig")
        XCTAssertEqual(app.staticTexts["progress-text"].label, "Heute nichts fällig")

        // Mit Tagesversatz +1 ist morgen heute: der Habit erscheint.
        app.terminate()
        app.launchArguments = ["-HabitusDayOffset", "1"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Wäsche"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["progress-text"].label, "0 von 1 · 0\u{00A0}%")

        // Und am Tag danach ist er wieder weg.
        app.terminate()
        app.launchArguments = ["-HabitusDayOffset", "2"]
        app.launch()
        XCTAssertTrue(app.staticTexts["progress-text"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Wäsche"].exists)
    }

    @MainActor
    func testWeekdayHabitDueTodayAppearsAndCanBeChecked() {
        let app = launchFresh()
        openEditor(named: "Yoga", rhythm: "Woche", variant: "Wochentage", in: app)
        save("Yoga", in: app)

        XCTAssertTrue(app.staticTexts["Yoga"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["progress-text"].label, "0 von 1 · 0\u{00A0}%")
        app.buttons["check-Yoga"].tap()
        XCTAssertEqual(app.staticTexts["progress-text"].label, "1 von 1 · 100\u{00A0}%")
    }

    @MainActor
    func testMonthDayHabit() {
        let app = launchFresh()
        let today = Calendar.current.component(.day, from: .now)
        let other = today == 15 ? 16 : 15

        // Anderer Tag im Monat: heute nicht fällig.
        openEditor(named: "Rechnungen", rhythm: "Monat", variant: "Monatstag", in: app)
        app.buttons["monthday-picker"].tap()
        app.buttons["\(other)."].tap()
        save("Rechnungen", in: app)
        XCTAssertTrue(app.staticTexts["progress-text"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Rechnungen"].exists)

        // Der Tag im Monat ist vorausgewählt (heute): der Habit erscheint.
        openEditor(named: "Miete", rhythm: "Monat", variant: "Monatstag", in: app)
        save("Miete", in: app)
        XCTAssertTrue(app.staticTexts["Miete"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["progress-text"].label, "0 von 1 · 0\u{00A0}%")
    }

    // MARK: Bearbeiten

    @MainActor
    func testChangingTheRhythmOfAnExistingHabit() {
        let app = launchFresh()
        openEditor(named: "Lesen", in: app)
        save("Lesen", in: app)
        XCTAssertTrue(app.buttons["check-Lesen"].waitForExistence(timeout: 5))

        app.staticTexts["Lesen"].press(forDuration: 1.5)
        XCTAssertTrue(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 5))
        let picker = app.otherElements["rhythm-picker"]
        XCTAssertTrue(picker.buttons["Täglich"].isSelected, "Das Sheet zeigt den bisherigen Rhythmus")
        picker.buttons["Woche"].tap()
        app.buttons["target-stepper-Increment"].tap()
        save("Lesen", in: app)

        XCTAssertTrue(app.buttons["check-Lesen"].waitForExistence(timeout: 5))

        // Wieder öffnen: Rhythmus und Anzahl sind gespeichert.
        app.staticTexts["Lesen"].press(forDuration: 1.5)
        XCTAssertTrue(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["rhythm-picker"].buttons["Woche"].isSelected)
        XCTAssertEqual(stepperText(in: app), "2x pro Woche")
        XCTAssertTrue(app.otherElements["variant-picker"].buttons["Anzahl"].isSelected)
        app.otherElements["variant-picker"].buttons["Wochentage"].tap()
        save("Lesen", in: app)
        XCTAssertTrue(app.staticTexts["Lesen"].waitForExistence(timeout: 5), "Heutiger Wochentag ist vorausgewählt")
    }

    @MainActor
    func testRhythmSurvivesRestart() {
        let app = launchFresh()
        openEditor(named: "Sport", rhythm: "Woche", in: app)
        app.buttons["target-stepper-Increment"].tap()
        save("Sport", in: app)
        app.buttons["check-Sport"].tap()
        XCTAssertEqual(app.staticTexts["progress-text"].label, "1 von 1 · 100\u{00A0}%")

        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.buttons["check-Sport"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["check-Sport"].isSelected)

        app.staticTexts["Sport"].press(forDuration: 1.5)
        XCTAssertTrue(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["rhythm-picker"].buttons["Woche"].isSelected)
        XCTAssertEqual(stepperText(in: app), "2x pro Woche")
    }

    // MARK: Entwickler

    @MainActor
    private func openDeveloperSettings(in app: XCUIApplication) {
        app.tabBars.buttons["Einstellungen"].tap()
        XCTAssertTrue(app.buttons["create-sample-data"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSampleDataShowsGreenYellowAndRed() {
        let app = launchFresh()
        openDeveloperSettings(in: app)
        app.buttons["create-sample-data"].tap()
        XCTAssertTrue(app.staticTexts["developer-message"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Heute"].tap()
        XCTAssertTrue(app.staticTexts["Lesen"].waitForExistence(timeout: 5))

        // Entwurf der Testdaten, siehe `DebugData`: grün, gelb und rot an jedem Wochentag.
        XCTAssertEqual(status(of: "Lesen", in: app), "Grün")
        XCTAssertEqual(status(of: "Meditieren", in: app), "Rot")
        XCTAssertEqual(status(of: "Sport", in: app), "Grün")
        XCTAssertEqual(status(of: "Joggen", in: app), "Gelb")
        XCTAssertEqual(status(of: "Gitarre üben", in: app), "Rot")
        XCTAssertEqual(status(of: "Pflanzen düngen", in: app), "Gelb")
        XCTAssertEqual(status(of: "Auto waschen", in: app), "Rot")
        XCTAssertEqual(status(of: "Tagebuch", in: app), "Grün")
        XCTAssertEqual(status(of: "Yoga", in: app), "Rot")

        // Habits an festen Tagen erscheinen nur an ihren Tagen.
        XCTAssertFalse(app.staticTexts["Wäsche waschen"].exists, "Wäsche ist erst morgen fällig")
    }

    @MainActor
    func testResetAllDataAsksForConfirmation() {
        let app = launchFresh(extraArguments: ["-HabitusSampleData"])
        XCTAssertTrue(app.staticTexts["Lesen"].waitForExistence(timeout: 5))

        openDeveloperSettings(in: app)

        // Abbrechen lässt alles unverändert.
        app.buttons["reset-all-data"].tap()
        XCTAssertTrue(app.alerts["Alle Daten zurücksetzen?"].waitForExistence(timeout: 5))
        app.alerts.buttons["Abbrechen"].tap()
        app.tabBars.buttons["Heute"].tap()
        XCTAssertTrue(app.staticTexts["Lesen"].waitForExistence(timeout: 5))

        // Zurücksetzen löscht alles.
        app.tabBars.buttons["Einstellungen"].tap()
        app.buttons["reset-all-data"].tap()
        XCTAssertTrue(app.alerts["Alle Daten zurücksetzen?"].waitForExistence(timeout: 5))
        app.alerts.buttons["Zurücksetzen"].tap()
        app.tabBars.buttons["Heute"].tap()
        XCTAssertTrue(app.staticTexts["progress-text"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["progress-text"].label, "Heute nichts fällig")
        XCTAssertFalse(app.staticTexts["Lesen"].exists)
    }
}
