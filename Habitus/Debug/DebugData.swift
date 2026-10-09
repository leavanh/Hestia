#if DEBUG
import Foundation
import SwiftData

/// Entwicklerwerkzeuge (Einstellungen > Entwickler), nur in Debug Builds.
enum DebugData {
    /// Tage Historie, die `insertSampleHabits` anlegt.
    static let historyDays = 60

    /// Löscht alle Habits, Erledigungen und Pausen. Einzeln statt per Batch, weil ein Batch Delete
    /// an der Beziehung zwischen Pausen und Habits scheitert, sobald eine Pause existiert.
    static func resetAll(in context: ModelContext) throws {
        for pause in try context.fetch(FetchDescriptor<Pause>()) { context.delete(pause) }
        for habit in try context.fetch(FetchDescriptor<Habit>()) { context.delete(habit) }
        for completion in try context.fetch(FetchDescriptor<Completion>()) { context.delete(completion) }
        try context.save()
    }

    /// Beispielhabits für alle Rhythmen mit 60 Tagen Historie. Die Historie ist relativ zu `now`
    /// aufgebaut, damit "Heute" an jedem Wochentag grüne, gelbe und rote Habits zeigt:
    ///
    /// - täglich: Lesen und Vitamine grün, Meditieren rot, Wasser trinken zählt hoch
    /// - pro Woche: Sport grün, Joggen gelb, Gitarre üben rot
    /// - pro Monat: Fenster putzen grün, Pflanzen düngen gelb, Auto waschen rot
    /// - feste Wochentage: Tagebuch grün und Yoga rot (beide heute fällig), Wäsche waschen erst morgen
    /// - fester Monatstag: Miete überweisen grün (heute fällig), Rechnungen prüfen nur am 1.
    @discardableResult
    static func insertSampleHabits(
        into context: ModelContext,
        now: Date = AppClock.now,
        engine: HabitEngine = HabitEngine()
    ) -> [Habit] {
        let today = engine.startOfDay(now)
        let created = engine.calendar.date(byAdding: .day, value: -historyDays, to: today) ?? today
        let samples = samples(today: today, created: created, engine: engine)

        var habits: [Habit] = []
        for (index, sample) in samples.enumerated() {
            let habit = Habit(
                name: sample.name,
                iconName: sample.iconName,
                colorKey: sample.color.rawValue,
                rhythm: sample.rhythm,
                targetCount: sample.target,
                weekdays: sample.weekdays,
                monthDay: sample.monthDay,
                // Eine Sekunde Abstand, damit die Reihenfolge in "Heute" fest ist.
                createdAt: created.addingTimeInterval(TimeInterval(index))
            )
            context.insert(habit)

            for entry in sample.history {
                guard let day = engine.calendar.date(byAdding: .day, value: -entry.daysAgo, to: today) else { continue }
                let completion = Completion(day: engine.startOfDay(day), count: entry.count)
                context.insert(completion)
                habit.completions.append(completion)
            }
            habits.append(habit)
        }
        try? context.save()
        return habits
    }

    // MARK: Beispiele

    private typealias Entry = (daysAgo: Int, count: Int)

    private struct Sample {
        var name: String
        var iconName: String
        var color: HabitColor
        var rhythm: Rhythm
        var target = 1
        var weekdays: [Int] = []
        var monthDay: Int? = nil
        /// Erledigungen als (Tage zurück, Wert).
        var history: [Entry]
    }

    private static func samples(today: Date, created: Date, engine: HabitEngine) -> [Sample] {
        let todayWeekday = engine.weekday(of: today)
        let dayOfMonth = engine.calendar.component(.day, from: today)
        /// Wochentag `offset` Tage nach heute, im Bereich 1 bis 7.
        func weekday(plus offset: Int) -> Int { (todayWeekday - 1 + offset) % 7 + 1 }

        func fixedDays(
            _ name: String, _ iconName: String, _ color: HabitColor,
            weekdays: [Int] = [], monthDay: Int? = nil, skipMostRecent: Bool = false
        ) -> Sample {
            let rhythm: Rhythm = monthDay == nil ? .weekdays : .monthDay
            let snapshot = HabitSnapshot(
                rhythm: rhythm, targetCount: 1, weekdays: weekdays, monthDay: monthDay, createdAt: created, counts: []
            )
            return Sample(
                name: name, iconName: iconName, color: color, rhythm: rhythm,
                weekdays: weekdays, monthDay: monthDay,
                history: fixedDayHistory(snapshot, today: today, skipMostRecent: skipMostRecent, engine: engine)
            )
        }

        return [
            // Täglich
            Sample(name: "Wasser trinken", iconName: "drop.fill", color: .teal, rhythm: .daily, target: 3,
                   history: dailyHistory(target: 3, seed: 1, yesterday: 3, today: 1)),
            Sample(name: "Lesen", iconName: "book.fill", color: .violet, rhythm: .daily,
                   history: dailyHistory(target: 1, seed: 2, yesterday: 1, today: 0)),
            Sample(name: "Meditieren", iconName: "brain.head.profile", color: .pink, rhythm: .daily,
                   history: dailyHistory(target: 1, seed: 3, yesterday: 0, today: 0)),
            Sample(name: "Vitamine", iconName: "pills.fill", color: .orange, rhythm: .daily,
                   history: dailyHistory(target: 1, seed: 4, yesterday: 1, today: 1)),
            // Pro Woche
            Sample(name: "Sport", iconName: "dumbbell.fill", color: .orange, rhythm: .weekly, target: 2,
                   history: once(every(3, from: 1))),
            Sample(name: "Joggen", iconName: "figure.run", color: .green, rhythm: .weekly,
                   history: once(every(7, from: 5))),
            Sample(name: "Gitarre üben", iconName: "music.note", color: .red, rhythm: .weekly, target: 3,
                   history: once([2] + every(2, from: 9))),
            // Pro Monat
            Sample(name: "Fenster putzen", iconName: "house.fill", color: .blue, rhythm: .monthly,
                   history: once([10, 40])),
            Sample(name: "Pflanzen düngen", iconName: "leaf.fill", color: .green, rhythm: .monthly,
                   history: once([26, 56])),
            Sample(name: "Auto waschen", iconName: "cart.fill", color: .yellow, rhythm: .monthly,
                   history: once([35])),
            // Feste Wochentage
            fixedDays("Tagebuch", "pencil", .blue, weekdays: [todayWeekday, weekday(plus: 3)].sorted()),
            fixedDays("Yoga", "figure.yoga", .violet, weekdays: [todayWeekday, weekday(plus: 4)].sorted(), skipMostRecent: true),
            fixedDays("Wäsche waschen", "house.fill", .teal, weekdays: [weekday(plus: 1)]),
            // Fester Monatstag
            fixedDays("Miete überweisen", "creditcard.fill", .green, monthDay: dayOfMonth),
            fixedDays("Rechnungen prüfen", "envelope.fill", .orange, monthDay: 1),
        ]
    }

    // MARK: Historie

    /// Jeweils eine Erledigung an den angegebenen Tagen zurück.
    private static func once(_ daysAgo: [Int]) -> [Entry] {
        daysAgo.map { ($0, 1) }
    }

    /// Alle `step` Tage ab `start` Tagen zurück bis zum Beginn der Historie.
    private static func every(_ step: Int, from start: Int) -> [Int] {
        Array(stride(from: start, through: historyDays, by: step))
    }

    /// Festes, aber unregelmäßig wirkendes Muster für die Tage davor. Gestern und heute sind
    /// vorgegeben, weil sie Status und Fortschritt bestimmen.
    private static func dailyHistory(target: Int, seed: Int, yesterday: Int, today: Int) -> [Entry] {
        var entries: [Entry] = (2...historyDays).compactMap { daysAgo in
            let value = (daysAgo * 7 + seed * 3) % 5
            return value > 0 ? (daysAgo, min(value, target)) : nil
        }
        if yesterday > 0 { entries.append((1, yesterday)) }
        if today > 0 { entries.append((0, today)) }
        return entries
    }

    /// Bei festen Tagen jeder fällige Tag der Historie, auf Wunsch ohne den letzten (dann rot).
    private static func fixedDayHistory(
        _ habit: HabitSnapshot, today: Date, skipMostRecent: Bool, engine: HabitEngine
    ) -> [Entry] {
        var entries: [Entry] = []
        var skipped = !skipMostRecent
        for daysAgo in 1...historyDays {
            guard let day = engine.calendar.date(byAdding: .day, value: -daysAgo, to: today),
                  engine.isDue(habit, on: day) else { continue }
            if !skipped {
                skipped = true
                continue
            }
            entries.append((daysAgo, 1))
        }
        return entries
    }
}
#endif
