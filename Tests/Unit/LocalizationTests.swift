import Foundation
import Testing
@testable import Hestia

/// Texte auf Deutsch und Englisch (Phase 16). Englisch kommt über eine Locale, die Testpläne laufen fest auf Deutsch.
struct LocalizationTests {
    let de = Locale(identifier: "de")
    let en = Locale(identifier: "en_US")

    func snapshot(
        _ rhythm: Rhythm, target: Int = 1, weekdays: [Int] = [], monthDay: Int? = nil, detail: String = ""
    ) -> HabitSnapshot {
        HabitSnapshot(rhythm: rhythm, targetCount: target, weekdays: weekdays, monthDay: monthDay,
                      createdAt: Date(timeIntervalSince1970: 0), counts: [], detail: detail)
    }

    // MARK: Einzahl und Mehrzahl

    @Test func habitCountUsesSingularAndPlural() {
        #expect(HabitCountText.text(1, locale: de) == "1 Habit")
        #expect(HabitCountText.text(3, locale: de) == "3 Habits")
        #expect(HabitCountText.text(1, locale: en) == "1 habit")
        #expect(HabitCountText.text(3, locale: en) == "3 habits")
    }

    @Test func streakDaysUseSingularAndPlural() {
        #expect(StatValue.daysText(1, locale: de) == "1 Tag")
        #expect(StatValue.daysText(3, locale: de) == "3 Tage")
        #expect(StatValue.daysText(1, locale: en) == "1 day")
        #expect(StatValue.daysText(3, locale: en) == "3 days")
    }

    @Test func streakCaptionsUseSingularAndPlural() {
        #expect(StatValue.dayUnitText(1, locale: de) == "Tag")
        #expect(StatValue.dayUnitText(3, locale: de) == "Tage")
        #expect(StatValue.dayUnitText(1, locale: en) == "day")
        #expect(StatValue.dayUnitText(3, locale: en) == "days")
        #expect(StatValue.inARowText(1, locale: de) == "Tag in Folge")
        #expect(StatValue.inARowText(3, locale: de) == "Tage in Folge")
        #expect(StatValue.inARowText(1, locale: en) == "day in a row")
        #expect(StatValue.inARowText(3, locale: en) == "days in a row")
    }

    @Test func rateIsFormattedForTheLanguage() {
        #expect(StatValue.rateText(67, locale: de) == "67\u{00A0}%")
        #expect(StatValue.rateText(67, locale: en) == "67%")
        #expect(StatValue.rateText(nil, locale: en) == "–")
    }

    // MARK: Rhythmus Zeile

    @Test func everyRhythmLineHasGermanAndEnglishText() {
        let window = WindowProgress(done: 1, target: 3)
        let single = WindowProgress(done: 1, target: 1)
        // (Habit, Fenster, Zeiträume, Deutsch, Englisch)
        let cases: [(HabitSnapshot, WindowProgress?, Periods, String, String)] = [
            (snapshot(.daily), nil, .rolling, "Täglich", "Daily"),
            (snapshot(.daily, target: 2), nil, .rolling, "2 pro Tag", "2 per day"),
            (snapshot(.weekly, target: 3), window, .rolling, "1 von 3 in 7 Tagen", "1 of 3 in 7 days"),
            (snapshot(.weekly, target: 3), window, .calendar, "1 von 3 diese Woche", "1 of 3 this week"),
            (snapshot(.monthly), single, .rolling, "1 von 1 in 30 Tagen", "1 of 1 in 30 days"),
            (snapshot(.monthly), single, .calendar, "1 von 1 diesen Monat", "1 of 1 this month"),
            (snapshot(.weekdays, weekdays: [4, 1]), nil, .rolling, "Mo · Do", "Mon · Thu"),
            (snapshot(.monthDay, monthDay: 15), nil, .rolling, "Am 15. des Monats", "Day 15 of the month"),
            (snapshot(.daily, detail: "20 Min"), nil, .rolling, "20 Min · Täglich", "20 Min · Daily"),
        ]
        for (habit, window, periods, german, english) in cases {
            #expect(habit.rhythmText(window: window, periods: periods, locale: de) == german)
            #expect(habit.rhythmText(window: window, periods: periods, locale: en) == english)
        }
    }

    @Test func weekdaysFollowTheFirstWeekdayInBothLanguages() {
        let habit = snapshot(.weekdays, weekdays: [1, 7])
        #expect(habit.rhythmText(window: nil, firstWeekday: 7, locale: de) == "So · Mo")
        #expect(habit.rhythmText(window: nil, firstWeekday: 7, locale: en) == "Sun · Mon")
    }

    @Test func targetTextsExistInBothLanguages() {
        #expect(Rhythm.daily.targetText(3, locale: de) == "3x täglich")
        #expect(Rhythm.weekly.targetText(3, locale: de) == "3x pro Woche")
        #expect(Rhythm.monthly.targetText(3, locale: de) == "3x pro Monat")
        #expect(Rhythm.daily.targetText(3, locale: en) == "3x daily")
        #expect(Rhythm.weekly.targetText(3, locale: en) == "3x per week")
        #expect(Rhythm.monthly.targetText(3, locale: en) == "3x per month")
    }

    // MARK: Relativer Tag, Pause, Datum

    @Test func relativeDaysExistInBothLanguages() {
        #expect(RelativeDay.text(daysAgo: 0, locale: de) == "Heute")
        #expect(RelativeDay.text(daysAgo: 1, locale: de) == "Gestern")
        #expect(RelativeDay.text(daysAgo: 2, locale: de) == "Vorgestern")
        #expect(RelativeDay.text(daysAgo: 3, locale: de) == "Vor 3 Tagen")
        #expect(RelativeDay.text(daysAgo: 0, locale: en) == "Today")
        #expect(RelativeDay.text(daysAgo: 1, locale: en) == "Yesterday")
        #expect(RelativeDay.text(daysAgo: 2, locale: en) == "2 days ago")
        #expect(RelativeDay.text(daysAgo: 30, locale: en) == "30 days ago")
    }

    @Test func pauseRangesFollowTheLanguage() {
        let engine = HabitEngine()
        let calendar = engine.calendar
        let today = calendar.date(from: DateComponents(year: 2026, month: 10, day: 12))!
        func day(_ number: Int) -> Date { calendar.date(from: DateComponents(year: 2026, month: 10, day: number))! }

        let one = PauseRange(start: day(8), end: day(8))
        let several = PauseRange(start: day(8), end: day(10))
        #expect(one.text(today: today, calendar: calendar, locale: de) == "8. Okt.")
        #expect(several.text(today: today, calendar: calendar, locale: de) == "8. Okt. – 10. Okt.")
        #expect(one.text(today: today, calendar: calendar, locale: en) == "Oct 8")
        #expect(several.text(today: today, calendar: calendar, locale: en) == "Oct 8 – Oct 10")
    }

    @Test func datesFollowTheLanguage() {
        let engine = HabitEngine()
        let day = engine.calendar.date(from: DateComponents(year: 2026, month: 10, day: 11))!
        #expect(DayText.dateLine(day, engine: engine, locale: de) == "So · 11. Okt")
        #expect(DayText.dateLine(day, engine: engine, locale: en) == "Sun · Oct 11")
        #expect(DayText.dateWithYear(day, engine: engine, locale: de) == "11. Okt 2026")
        #expect(DayText.dateWithYear(day, engine: engine, locale: en) == "Oct 11, 2026")
        #expect(DayText.fullDate(day, locale: de) == "Sonntag, 11. Oktober")
        #expect(DayText.fullDate(day, locale: en) == "Sunday, October 11")
        #expect(DayText.weekNumber(day, engine: engine, locale: de) == "KW 41")
        #expect(DayText.weekNumber(day, engine: engine, locale: en) == "W41")
        #expect(DayText.weekNumberSpoken(day, engine: engine, locale: de) == "Kalenderwoche 41")
        #expect(DayText.weekNumberSpoken(day, engine: engine, locale: en) == "Week 41")
    }

    @Test func iconAndColorNamesExistInBothLanguages() {
        #expect(HabitIcons.title(for: "figure.run", locale: de) == "Laufen")
        #expect(HabitIcons.title(for: "figure.run", locale: en) == "Running")
        #expect(HabitIcons.title(for: "iphone.slash", locale: en) == "Less phone")
        for icon in HabitIcons.all {
            let english = HabitIcons.title(for: icon, locale: en)
            #expect(english != icon, "\(icon) hat einen englischen Namen")
            #expect(english != HabitIcons.title(for: icon, locale: de) || ["figure.yoga", "figure.mind.and.body"].contains(icon),
                    "\(icon) ist übersetzt")
        }
    }

    // MARK: Katalog

    /// Der Katalog liegt als Quelldatei neben dem Code. Jeder Schlüssel braucht eine fertige englische Übersetzung.
    @Test func catalogHasAnEnglishTranslationForEveryKey() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Hestia/Localizable.xcstrings")
        let data = try Data(contentsOf: url)
        let root = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try #require(root["strings"] as? [String: [String: Any]])
        #expect(strings.count > 100)

        func values(of localization: [String: Any]) -> [(state: String?, value: String?)] {
            if let unit = localization["stringUnit"] as? [String: Any] {
                return [(unit["state"] as? String, unit["value"] as? String)]
            }
            let variations = (localization["variations"] as? [String: Any])?["plural"] as? [String: [String: Any]] ?? [:]
            return variations.values.flatMap { values(of: $0) }
        }

        for (key, entry) in strings {
            if entry["shouldTranslate"] as? Bool == false { continue }
            let localizations = entry["localizations"] as? [String: [String: Any]] ?? [:]
            let english = values(of: localizations["en"] ?? [:])
            #expect(!english.isEmpty, "\(key) hat keine englische Übersetzung")
            for (state, value) in english {
                #expect(state == "translated", "\(key) ist nicht fertig übersetzt (\(state ?? "ohne Status"))")
                #expect(!(value ?? "").isEmpty, "\(key) hat einen leeren englischen Text")
            }
            let german = values(of: localizations["de"] ?? [:])
            #expect(!german.isEmpty, "\(key) hat keinen deutschen Text")
        }
    }
}
