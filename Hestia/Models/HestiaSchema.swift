import SwiftData

/// Das Datenmodell in seiner heutigen Fassung (Spezifikation 6). Jede spätere Änderung an `Habit`, `Completion`
/// oder `Pause` kommt als neue Version (`HestiaSchemaV2` usw.) mit einer Migrationsstufe in `HestiaMigrationPlan`,
/// damit nach einem Update keine Daten verloren gehen.
enum HestiaSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Habit.self, Completion.self, Pause.self]
    }
}

enum HestiaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [HestiaSchemaV1.self] }

    /// Noch keine Stufen: es gibt nur Version 1.
    static var stages: [MigrationStage] { [] }
}

extension ModelContainer {
    /// Der Container der App: aktuelles Schema samt Migrationsplan.
    static func hestia(configuration: ModelConfiguration = ModelConfiguration()) throws -> ModelContainer {
        try ModelContainer(
            for: Schema(versionedSchema: HestiaSchemaV1.self),
            migrationPlan: HestiaMigrationPlan.self,
            configurations: configuration
        )
    }
}
