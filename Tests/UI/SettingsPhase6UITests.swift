import XCTest

/// Prüft die Definition of Done von Phase 6 direkt in der Oberfläche: Pausen, Beenden mit Historie behalten oder
/// löschen und Sortieren. Jeder Test startet mit leerem Datenbestand (`-HabitusResetData`).
final class SettingsPhase6UITests: XCTestCase {
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

    @MainActor
    private func createHabit(named name: String, in app: XCUIApplication) {
        app.buttons["Neuer Habit"].tap()
        let field = app.textFields["name-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(name + "\n")
        app.buttons["Speichern"].tap()
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
    }

    @MainActor
    private func openSettings(in app: XCUIApplication) {
        app.openTab(.settings)
        XCTAssertTrue(app.buttons["new-pause"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func openToday(in app: XCUIApplication) {
        app.openTab(.today)
        XCTAssertTrue(app.scrollViews["today-list"].waitForExistence(timeout: 5))
    }

    /// Beendet einen Habit über das Bearbeiten Sheet (langes Drücken, "Habit beenden", Antwort im Dialog).
    @MainActor
    private func endHabit(named name: String, answer: String, in app: XCUIApplication) {
        app.staticTexts[name].press(forDuration: 1.5)
        XCTAssertTrue(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 5))
        let end = app.buttons["end-habit"]
        for _ in 0..<4 where !end.isHittable { app.swipeUp() }
        end.tap()
        let alert = app.alerts["Habit beenden?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons[answer].tap()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
    }

    /// Wartet, bis die Namen in dieser Reihenfolge von oben nach unten stehen (nach der Animation).
    @MainActor
    private func assertOrder(_ names: [String], in app: XCUIApplication, _ message: String) {
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            let positions = names.map { app.staticTexts[$0].frame.minY }
            if positions == positions.sorted(), Set(positions).count == positions.count { return }
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTFail("\(message): erwartete Reihenfolge \(names)")
    }

    // MARK: Pausen

    @MainActor
    func testPausedHabitsStayInTheListGreyedOutAndEndingThePauseReactivatesThem() {
        let app = launchFresh()
        createHabit(named: "Lesen", in: app)
        createHabit(named: "Sport", in: app)
        createHabit(named: "Yoga", in: app)

        openSettings(in: app)
        XCTAssertTrue(app.staticTexts["no-pauses"].exists)
        app.buttons["new-pause"].tap()
        let save = app.buttons["pause-save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertFalse(save.isEnabled, "Ohne Habit keine Pause")
        app.buttons["pause-habit-Lesen"].tap()
        app.buttons["pause-habit-Sport"].tap()
        XCTAssertTrue(save.isEnabled)
        save.tap()

        let row = app.otherElements["pause-row-Lesen, Sport"]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Die Pause steht in der Liste")
        XCTAssertTrue(app.staticTexts["Läuft"].exists)

        // Im Sheet sind die schon pausierten Habits deutlich markiert, bleiben aber auswählbar.
        app.buttons["new-pause"].tap()
        XCTAssertTrue(app.buttons["pause-save"].waitForExistence(timeout: 5))
        for name in ["Lesen", "Sport"] {
            let state = app.descendants(matching: .any)["pause-state-\(name)"].firstMatch
            XCTAssertTrue(state.exists, name)
            XCTAssertTrue(state.label.contains("Pausiert"), "\(name) ist als pausiert markiert: \(state.label)")
        }
        XCTAssertFalse(app.descendants(matching: .any)["pause-state-Yoga"].firstMatch.label.contains("Pausiert"))
        XCTAssertTrue(app.buttons["pause-habit-Lesen"].isEnabled, "Auswählen bleibt möglich")
        app.buttons["Abbrechen"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))

        openToday(in: app)
        XCTAssertTrue(app.staticTexts["Yoga"].exists)
        // Pausierte Habits bleiben in der Liste: ausgegraut, mit Kapsel "Pausiert", unten, nicht abhakbar.
        XCTAssertTrue(app.staticTexts["Lesen"].exists)
        XCTAssertTrue(app.staticTexts["Sport"].exists)
        XCTAssertTrue(app.staticTexts["paused-Lesen"].exists)
        XCTAssertTrue(app.staticTexts["paused-Sport"].exists)
        XCTAssertFalse(app.staticTexts["paused-Yoga"].exists)
        XCTAssertLessThan(app.staticTexts["Yoga"].frame.minY, app.staticTexts["Lesen"].frame.minY, "Pausierte unten")
        XCTAssertLessThan(app.staticTexts["Yoga"].frame.minY, app.staticTexts["Sport"].frame.minY)
        XCTAssertFalse(app.buttons["check-Lesen"].isEnabled, "Pausierte lassen sich nicht abhaken")
        XCTAssertTrue(app.buttons["check-Yoga"].isEnabled)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "von 1")).firstMatch.exists, "Nur Yoga zählt im Fortschritt")

        openSettings(in: app)
        app.buttons["end-pause-Lesen, Sport"].tap()
        XCTAssertTrue(app.staticTexts["no-pauses"].waitForExistence(timeout: 5), "Die Pause ist beendet")

        openToday(in: app)
        XCTAssertTrue(app.staticTexts["Lesen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Sport"].exists)
        XCTAssertFalse(app.staticTexts["paused-Lesen"].exists, "Nicht mehr pausiert")
        XCTAssertTrue(app.buttons["check-Lesen"].isEnabled)
    }

    // MARK: Beenden

    @MainActor
    private func scrollToExist(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        for _ in 0..<8 where !element.exists { app.scrollViews["calendar-scroll"].swipeUp() }
        return element.exists
    }

    @MainActor
    func testEndingAndKeepingTheHistoryRemovesTheHabitFromTodayButNotFromTheCalendar() {
        let app = launchFresh()
        createHabit(named: "Lesen", in: app)
        createHabit(named: "Sport", in: app)

        endHabit(named: "Lesen", answer: "Historie behalten", in: app)
        XCTAssertFalse(app.staticTexts["Lesen"].exists, "Beendet: weg aus Heute")
        XCTAssertTrue(app.staticTexts["Sport"].exists)

        app.openTab(.calendar)
        XCTAssertTrue(app.buttons["calendar-previous"].waitForExistence(timeout: 5))
        XCTAssertTrue(scrollToExist(app.buttons["habit-row-Lesen"], in: app), "Die Historie bleibt im Kalender")
    }

    @MainActor
    func testEndingAndDeletingTheHistoryRemovesTheHabitEverywhere() {
        let app = launchFresh()
        createHabit(named: "Lesen", in: app)
        createHabit(named: "Sport", in: app)

        endHabit(named: "Lesen", answer: "Historie löschen", in: app)
        XCTAssertFalse(app.staticTexts["Lesen"].exists, "Gelöscht: weg aus Heute")
        XCTAssertTrue(app.staticTexts["Sport"].exists)

        app.openTab(.calendar)
        XCTAssertTrue(app.buttons["calendar-previous"].waitForExistence(timeout: 5))
        XCTAssertTrue(scrollToExist(app.buttons["habit-row-Sport"], in: app))
        XCTAssertFalse(app.buttons["habit-row-Lesen"].exists, "Auch im Kalender ist er weg")
    }

    @MainActor
    func testTheEndDialogAsksOnlyForKeepingOrDeletingTheHistory() {
        let app = launchFresh()
        createHabit(named: "Lesen", in: app)
        app.staticTexts["Lesen"].press(forDuration: 1.5)
        XCTAssertTrue(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 5))
        let end = app.buttons["end-habit"]
        for _ in 0..<4 where !end.isHittable { app.swipeUp() }
        end.tap()
        let alert = app.alerts["Habit beenden?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.buttons["Historie behalten"].exists)
        XCTAssertTrue(alert.buttons["Historie löschen"].exists)
        XCTAssertTrue(alert.buttons["Abbrechen"].exists)
    }

    @MainActor
    func testSettingsHaveNoListOfEndedHabits() {
        let app = launchFresh()
        createHabit(named: "Lesen", in: app)
        endHabit(named: "Lesen", answer: "Historie behalten", in: app)

        openSettings(in: app)
        XCTAssertFalse(app.staticTexts["Beendete Habits"].exists)
        XCTAssertFalse(app.buttons["Wieder aktivieren"].exists)
        XCTAssertFalse(app.buttons["Löschen"].exists)
    }

    @MainActor
    func testCancellingTheEndDialogKeepsTheHabit() {
        let app = launchFresh()
        createHabit(named: "Lesen", in: app)
        app.staticTexts["Lesen"].press(forDuration: 1.5)
        XCTAssertTrue(app.navigationBars["Habit bearbeiten"].waitForExistence(timeout: 5))
        let end = app.buttons["end-habit"]
        for _ in 0..<4 where !end.isHittable { app.swipeUp() }
        end.tap()
        app.alerts["Habit beenden?"].buttons["Abbrechen"].tap()
        XCTAssertTrue(app.navigationBars["Habit bearbeiten"].exists, "Das Sheet bleibt offen")
        app.buttons["Abbrechen"].tap()
        XCTAssertTrue(app.staticTexts["Lesen"].waitForExistence(timeout: 5))
    }

    // MARK: Sortieren

    @MainActor
    func testSortingMovesOpenHabitsAndKeepsDoneOnesBelowAndSurvivesRestart() {
        let app = launchFresh()
        createHabit(named: "Eins", in: app)
        createHabit(named: "Zwei", in: app)
        createHabit(named: "Drei", in: app)
        app.buttons["check-Eins"].tap()
        assertOrder(["Zwei", "Drei", "Eins"], in: app, "Ausgangslage mit einem erledigten Habit")

        app.buttons["sort-toggle"].tap()
        XCTAssertTrue(app.collectionViews["sort-list"].waitForExistence(timeout: 5))
        assertOrder(["Zwei", "Drei", "Eins"], in: app, "Sortiermodus: erledigte unten")

        // Den zweiten offenen Habit (Drei) per Griff vor den ersten (Zwei) ziehen.
        let handles = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "neu anordnen"))
        XCTAssertEqual(handles.count, 2, "Nur die offenen Habits haben einen Griff, die erledigten nicht")
        let from = handles.element(boundBy: 1)
        let to = handles.element(boundBy: 0)
        from.press(forDuration: 0.6, thenDragTo: to)
        assertOrder(["Drei", "Zwei", "Eins"], in: app, "Neue Reihenfolge im Sortiermodus")

        app.buttons["sort-toggle"].tap()
        XCTAssertTrue(app.scrollViews["today-list"].waitForExistence(timeout: 5))
        assertOrder(["Drei", "Zwei", "Eins"], in: app, "Neue Reihenfolge in Heute, Erledigte bleiben unten")

        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.staticTexts["Drei"].waitForExistence(timeout: 5))
        assertOrder(["Drei", "Zwei", "Eins"], in: app, "Nach dem Neustart")
    }
}

/// Pausen mit Beispieldaten: eine vergangene Pause für "Lesen" (vorgestern und gestern) und eine geplante für "Sport".
final class PausesWithSampleDataUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-HabitusResetData", "-HabitusSampleData", "-HabitusSamplePauses"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Lesen"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor
    func testPausedDaysAreDashesInTheWeekDots() {
        let app = launch()
        // Lesen war vorgestern und gestern pausiert: heute stehen zwei Striche in den 7 Punkten.
        let dots = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@ AND value == %@", "Letzte 7 Tage", "2 Tage pausiert"))
        XCTAssertEqual(dots.count, 1, "Nur Lesen hat pausierte Tage")
    }

    @MainActor
    func testSettingsListOnlyTheUpcomingPauseNotThePastOne() {
        let app = launch()
        app.openTab(.settings)
        XCTAssertTrue(app.otherElements["pause-row-Sport"].waitForExistence(timeout: 5), "Geplante Pause")
        XCTAssertTrue(app.staticTexts["Geplant"].exists)
        XCTAssertFalse(app.otherElements["pause-row-Lesen"].exists, "Vergangene Pausen stehen nicht in der Liste")
        XCTAssertFalse(app.staticTexts["Vorbei"].exists)
        XCTAssertEqual(app.buttons["end-pause-Sport"].label, "Pause entfernen")

        app.buttons["end-pause-Sport"].tap()
        XCTAssertTrue(app.staticTexts["no-pauses"].waitForExistence(timeout: 5), "Geplante Pause entfernt")
    }

    @MainActor
    func testPausedDayIsGreyInTheHabitDetailCalendar() {
        let app = launch()
        app.openTab(.calendar)
        let row = app.buttons["habit-row-Lesen"]
        for _ in 0..<12 where !row.exists || !row.isHittable {
            app.scrollViews["calendar-scroll"].swipeUp()
        }
        row.tap()
        XCTAssertTrue(app.scrollViews["habit-detail"].waitForExistence(timeout: 5))

        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: .now)!
        let parts = calendar.dateComponents([.year, .month, .day], from: yesterday)
        let id = String(format: "habit-calendar-day-%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
        let day = app.descendants(matching: .any)[id].firstMatch
        if !day.exists {
            // Gestern liegt im Vormonat.
            app.buttons["habit-calendar-previous"].tap()
        }
        XCTAssertTrue(day.waitForExistence(timeout: 5))
        XCTAssertEqual(day.value as? String, "Pausiert")
    }
}
