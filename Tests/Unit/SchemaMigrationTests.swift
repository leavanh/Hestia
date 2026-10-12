import Foundation
import SwiftData
import Testing
@testable import Hestia

/// Phase 17: Das Modell ist versioniert. Ein Datenbestand, der ohne Schema Version angelegt wurde (alle Fassungen
/// bis Phase 16), lässt sich mit `HestiaSchemaV1` öffnen. Die Datenbank liegt im App Ordner und ist nicht vom Backup
/// ausgenommen.
@MainActor
struct SchemaMigrationTests {
    @Test func unversionedStoreOpensWithSchemaV1WithoutDataLoss() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("Hestia.store")
        let day = HabitEngine().startOfDay(.now)

        do {
            let old = try ModelContainer(for: Habit.self, Completion.self, Pause.self,
                                         configurations: ModelConfiguration(url: url))
            let context = old.mainContext
            context.autosaveEnabled = false
            let sport = Habit(name: "Sport", iconName: "figure.run", colorKey: HabitColor.orange.rawValue,
                              rhythm: .weekly, targetCount: 3, detail: "20 Min", sortOrder: 4)
            let lesen = Habit(name: "Lesen", iconName: "book.fill", colorKey: HabitColor.green.rawValue)
            context.insert(sport)
            context.insert(lesen)
            context.insert(Completion(day: day, count: 2, habit: sport))
            context.insert(Pause(startDay: day, endDay: day.addingTimeInterval(86_400 * 2), habits: [sport, lesen]))
            try context.save()
        }

        let container = try ModelContainer.hestia(configuration: ModelConfiguration(url: url))
        let context = container.mainContext
        context.autosaveEnabled = false

        let habits = try context.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.name)]))
        #expect(habits.map(\.name) == ["Lesen", "Sport"])
        let sport = try #require(habits.last)
        #expect(sport.rhythm == .weekly)
        #expect(sport.targetCount == 3)
        #expect(sport.detail == "20 Min")
        #expect(sport.sortOrder == 4)

        let completions = try context.fetch(FetchDescriptor<Completion>())
        #expect(completions.count == 1)
        #expect(completions.first?.count == 2)
        #expect(completions.first?.day == day)
        #expect(completions.first?.habit?.name == "Sport")

        let pauses = try context.fetch(FetchDescriptor<Pause>())
        #expect(pauses.count == 1)
        #expect(Set(pauses[0].habits.map(\.name)) == ["Sport", "Lesen"])
    }

    @Test func schemaV1ListsAllModels() {
        #expect(HestiaSchemaV1.models.count == 3)
        #expect(HestiaMigrationPlan.schemas.count == 1)
        #expect(HestiaMigrationPlan.stages.isEmpty)
    }

    @Test func databaseLivesInApplicationSupportAndIsNotExcludedFromBackup() throws {
        let url = ModelConfiguration().url
        let support = try #require(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first)
        #expect(url.path.hasPrefix(support.path), "Datenbank liegt in Application Support")

        // Die Datenbank muss dafür existieren: der Container legt sie an.
        let container = try ModelContainer.hestia()
        container.mainContext.autosaveEnabled = false
        for file in [url, support] where FileManager.default.fileExists(atPath: file.path) {
            let values = try file.resourceValues(forKeys: [.isExcludedFromBackupKey])
            #expect(values.isExcludedFromBackup != true, "\(file.lastPathComponent) ist nicht vom Backup ausgenommen")
        }
    }

    @Test func privacyManifestAndEncryptionFlag() throws {
        let manifest = try #require(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let plist = try #require(NSDictionary(contentsOf: manifest))
        #expect(plist["NSPrivacyTracking"] as? Bool == false)
        #expect((plist["NSPrivacyCollectedDataTypes"] as? [Any])?.isEmpty == true)
        let apis = try #require(plist["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        #expect(apis.first?["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults")
        #expect(Bundle.main.object(forInfoDictionaryKey: "ITSAppUsesNonExemptEncryption") as? Bool == false)
    }
}
