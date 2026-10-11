import XCTest

/// Prüft die Definition of Done von Phase 9 direkt in der Oberfläche: Tag im Wochenstreifen antippen.
/// Jeder Test startet mit leerem Datenbestand (`-HabitusResetData`).
final class Phase9UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private let calendar = Calendar.current

    private func identifier(for day: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "week-strip-%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }

    private func fullDate(_ day: Date) -> String {
        day.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE")))
    }

    /// Wartet, bis die Datumszeile `day` zeigt und nur noch ein Kopf im Bild ist (nach der Animation).
    @MainActor
    private func waitForShownDay(_ day: Date, in app: XCUIApplication) -> Bool {
        let date = app.staticTexts.matching(identifier: "today-date")
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if date.count == 1, date.firstMatch.label == fullDate(day) { return true }
            Thread.sleep(forTimeInterval: 0.1)
        }
        return false
    }

    @MainActor
    func testTappingADayInTheWeekStripShowsThatDay() {
        let app = XCUIApplication()
        app.launchArguments = ["-HabitusResetData", "-HabitusSampleData"]
        app.launch()
        let today = calendar.startOfDay(for: .now)
        XCTAssertTrue(app.scrollViews["today-list"].waitForExistence(timeout: 5))
        XCTAssertTrue(waitForShownDay(today, in: app))

        // Ein zukünftiger Tag der Woche (gibt es nur, wenn heute nicht Sonntag ist) ändert nichts.
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let future = app.buttons[identifier(for: tomorrow)]
        if future.exists {
            XCTAssertFalse(future.isEnabled, "Zukünftige Tage sind nicht antippbar")
            future.tap()
            XCTAssertTrue(waitForShownDay(today, in: app), "Tippen auf einen zukünftigen Tag ändert nichts")
        }

        // Am Montag gibt es in dieser Woche keinen früheren Tag: dann erst zu gestern (Sonntag der Vorwoche) wischen.
        var shown = today
        if calendar.component(.weekday, from: today) == 2 {
            app.scrollViews["today-list"].swipeRight()
            shown = calendar.date(byAdding: .day, value: -1, to: today)!
            XCTAssertTrue(waitForShownDay(shown, in: app), "Wischen über die Wochengrenze")
        }
        let daysSinceMonday = (calendar.component(.weekday, from: shown) + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: shown)!
        let mondayButton = app.buttons[identifier(for: monday)]
        XCTAssertTrue(mondayButton.exists, "Der Wochenstreifen zeigt die Woche des angezeigten Tags")
        XCTAssertFalse(mondayButton.isSelected)

        let stripX = mondayButton.frame.minX
        mondayButton.tap()
        XCTAssertTrue(waitForShownDay(monday, in: app), "Tippen auf Montag zeigt diesen Tag")
        // Innerhalb der Woche bleibt der Streifen stehen, nur die Markierung wandert. Er ist nicht versetzt oder ausgeblendet.
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertEqual(app.buttons[identifier(for: monday)].frame.minX, stripX, accuracy: 2, "Der Wochenstreifen bleibt an seinem Platz")
        let daysAgo = calendar.dateComponents([.day], from: monday, to: today).day!
        let expectedTitle = daysAgo == 1 ? "Gestern" : daysAgo == 2 ? "Vorgestern" : "Vor \(daysAgo) Tagen"
        XCTAssertEqual(app.staticTexts["today-title"].label, expectedTitle)
        XCTAssertTrue(app.buttons[identifier(for: monday)].isSelected, "Der angezeigte Tag ist markiert")
        XCTAssertTrue(app.buttons["back-to-today"].exists)
    }
}
