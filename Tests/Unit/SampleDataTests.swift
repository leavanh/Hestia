import Foundation
import SwiftData
import Testing
@testable import Habitus

/// Einstellungen > Entwickler: Testdaten und Zurücksetzen (Spezifikation 5.5, Phase 3).
@MainActor
struct SampleDataTests {
    let engine: HabitEngine = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return HabitEngine(calendar: calendar)
    }()
    let container: ModelContainer
    let context: ModelContext

    init() throws {
        container = try ModelContainer(
            for: Habit.self, Completion.self, Pause.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
    }

    func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        engine.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    func days(from start: Date, count: Int) -> [Date] {
        (0..<count).map { engine.calendar.date(byAdding: .day, value: $0, to: start)! }
    }

    /// Startdaten für die Prüfung: ein ganzer Monat, Monatsenden, Februar und ein Schaltjahr.
    var startDays: [Date] {
        days(from: date(2026, 10, 8), count: 35)
            + days(from: date(2027, 2, 20), count: 12)
            + days(from: date(2028, 2, 25), count: 8)
    }

    func habit(_ name: String, in habits: [Habit]) throws -> Habit {
        try #require(habits.first { $0.name == name }, "Beispielhabit \(name) fehlt")
    }

    // MARK: Testdaten

    @Test func sampleHabitsCoverAllRhythms() throws {
        let habits = DebugData.insertSampleHabits(into: context, now: date(2026, 10, 8), engine: engine)
        #expect(Set(habits.map(\.rhythm)) == Set(Rhythm.allCases))
        #expect(try context.fetch(FetchDescriptor<Habit>()).count == habits.count)
    }

    @Test func sampleHabitsHaveSixtyDaysOfHistory() throws {
        let today = date(2026, 10, 8)
        let habits = DebugData.insertSampleHabits(into: context, now: today, engine: engine)

        for habit in habits {
            let created = engine.startOfDay(habit.createdAt)
            #expect(engine.calendar.dateComponents([.day], from: created, to: engine.startOfDay(today)).day == 60)
            #expect(!habit.completions.isEmpty, "\(habit.name) hat Historie")

            let completionDays = habit.completions.map(\.day)
            #expect(Set(completionDays).count == completionDays.count, "\(habit.name): höchstens ein Eintrag pro Tag")
            #expect(completionDays.allSatisfy { $0 >= created && $0 <= engine.startOfDay(today) })
            #expect(habit.completions.allSatisfy { $0.count > 0 })
        }
        #expect(try context.fetch(FetchDescriptor<Completion>()).count == habits.reduce(0) { $0 + $1.completions.count })
    }

    @Test func todayShowsGreenYellowAndRedOnEveryStartDay() throws {
        for today in startDays {
            let habits = DebugData.insertSampleHabits(into: context, now: today, engine: engine)
            let due = habits.filter { engine.isDue($0.snapshot, on: today) }
            let statuses = Set(due.map { engine.status($0.snapshot, on: today) })
            #expect(statuses == [.green, .yellow, .red], "\(today.formatted(date: .abbreviated, time: .omitted))")
            try DebugData.resetAll(in: context)
        }
    }

    @Test func sampleStatusesAreAsDesigned() throws {
        for today in startDays {
            let habits = DebugData.insertSampleHabits(into: context, now: today, engine: engine)
            func status(_ name: String) throws -> HabitStatus {
                engine.status(try habit(name, in: habits).snapshot, on: today)
            }
            let day = today.formatted(date: .abbreviated, time: .omitted)

            #expect(try status("Lesen") == .green, "Lesen \(day)")
            #expect(try status("Vitamine") == .green, "Vitamine \(day)")
            #expect(try status("Meditieren") == .red, "Meditieren \(day)")
            #expect(try status("Wasser trinken") == .green, "Wasser \(day)")
            #expect(try status("Sport") == .green, "Sport \(day)")
            #expect(try status("Joggen") == .yellow, "Joggen \(day)")
            #expect(try status("Gitarre üben") == .red, "Gitarre \(day)")
            #expect(try status("Fenster putzen") == .green, "Fenster \(day)")
            #expect(try status("Pflanzen düngen") == .yellow, "Pflanzen \(day)")
            #expect(try status("Auto waschen") == .red, "Auto \(day)")
            #expect(try status("Tagebuch") == .green, "Tagebuch \(day)")
            #expect(try status("Yoga") == .red, "Yoga \(day)")
            #expect(try status("Miete überweisen") == .green, "Miete \(day)")
            try DebugData.resetAll(in: context)
        }
    }

    @Test func fixedDayHabitsAppearOnlyOnTheirDays() throws {
        for today in startDays {
            let habits = DebugData.insertSampleHabits(into: context, now: today, engine: engine)
            func isDue(_ name: String) throws -> Bool {
                engine.isDue(try habit(name, in: habits).snapshot, on: today)
            }
            let tomorrow = engine.calendar.date(byAdding: .day, value: 1, to: today)!
            let laundry = try habit("Wäsche waschen", in: habits).snapshot

            #expect(try isDue("Tagebuch"))
            #expect(try isDue("Yoga"))
            #expect(try isDue("Miete überweisen"))
            #expect(!(try isDue("Wäsche waschen")), "Wäsche erscheint erst morgen")
            #expect(engine.isDue(laundry, on: tomorrow))
            #expect(try isDue("Rechnungen prüfen") == (engine.calendar.component(.day, from: today) == 1))
        }
    }

    @Test func sampleWindowsShowTheirProgress() throws {
        let today = date(2026, 10, 8)
        let habits = DebugData.insertSampleHabits(into: context, now: today, engine: engine)
        let sport = try habit("Sport", in: habits).snapshot
        let guitar = try habit("Gitarre üben", in: habits).snapshot
        #expect(engine.windowProgress(sport, on: today) == WindowProgress(done: 2, target: 2))
        #expect(engine.windowProgress(guitar, on: today) == WindowProgress(done: 1, target: 3))
    }

    @Test func sampleProgressMixesRhythms() throws {
        let today = date(2026, 10, 8) // Donnerstag
        let habits = DebugData.insertSampleHabits(into: context, now: today, engine: engine)
        let progress = engine.dayProgress(habits.map(\.snapshot), on: today)
        #expect(progress.total > 0)
        #expect(progress.done > 0)
        #expect(progress.done < progress.total)
    }

    // MARK: Zurücksetzen

    @Test func resetRemovesEverything() throws {
        let habits = DebugData.insertSampleHabits(into: context, now: date(2026, 10, 8), engine: engine)
        let pause = Pause(startDay: date(2026, 10, 8), endDay: date(2026, 10, 10), habits: [habits[0]])
        context.insert(pause)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<Habit>()) > 0)
        #expect(try context.fetchCount(FetchDescriptor<Completion>()) > 0)
        #expect(try context.fetchCount(FetchDescriptor<Pause>()) == 1)

        try DebugData.resetAll(in: context)
        #expect(try context.fetchCount(FetchDescriptor<Habit>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Completion>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Pause>()) == 0)
    }

    @Test func resetOnEmptyDatabaseIsHarmless() throws {
        try DebugData.resetAll(in: context)
        #expect(try context.fetchCount(FetchDescriptor<Habit>()) == 0)
    }

    // MARK: Modell und Engine

    @Test func snapshotCarriesWeekdaysAndMonthDay() {
        let yoga = Habit(name: "Yoga", iconName: "figure.yoga", colorKey: "violet", rhythm: .weekdays, weekdays: [1, 4])
        let rent = Habit(name: "Miete", iconName: "creditcard.fill", colorKey: "green", rhythm: .monthDay, monthDay: 31)
        #expect(yoga.snapshot.rhythm == .weekdays)
        #expect(yoga.snapshot.weekdays == [1, 4])
        #expect(rent.snapshot.monthDay == 31)
    }

    @Test func rhythmTargetRanges() {
        #expect(Rhythm.daily.targetRange == 1...10)
        #expect(Rhythm.weekly.targetRange == 1...7)
        #expect(Rhythm.monthly.targetRange == 1...30)
        #expect(Rhythm.weekdays.targetRange == nil)
        #expect(Rhythm.monthDay.targetRange == nil)
    }

    @Test func rhythmGroupsMatchTheSheetSegments() {
        #expect(RhythmGroup.allCases.map(\.title) == ["Täglich", "Woche", "Monat"])
        #expect(RhythmGroup.allCases.map(\.rhythms) == [[.daily], [.weekly, .weekdays], [.monthly, .monthDay]])
        #expect(Set(RhythmGroup.allCases.flatMap(\.rhythms)) == Set(Rhythm.allCases))
        for rhythm in Rhythm.allCases {
            #expect(rhythm.group.rhythms.contains(rhythm))
        }
    }

    @Test func rhythmTitlesAreGerman() {
        #expect(Rhythm.allCases.map(\.variantTitle) == [nil, "Anzahl", "Anzahl", "Wochentage", "Monatstag"])
        #expect(Rhythm.daily.targetText(3) == "3x täglich")
        #expect(Rhythm.weekly.targetText(2) == "2x pro Woche")
        #expect(Rhythm.monthly.targetText(1) == "1x pro Monat")
    }
}
