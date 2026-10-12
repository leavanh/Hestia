import SwiftData
import SwiftUI

/// Einstellungen (Spezifikation 5.5): Pausen, Kalender, Anzeige, in Debug Builds im Simulator der
/// Entwicklerbereich und ganz unten der Fuß.
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.sectionSpacing) {
                    ScreenTitle("Einstellungen")
                    PausesSection()
                    CalendarSection()
                    DisplaySection()
                    #if DEBUG && targetEnvironment(simulator)
                    // Startargument für Store Screenshots: ohne Entwicklerbereich.
                    if !ProcessInfo.processInfo.arguments.contains("-HestiaHideDeveloper") {
                        DeveloperSection()
                    }
                    #endif
                    Footer()
                }
                .padding(Theme.spacing)
            }
            .scrollsToTopOnTabReselect()
            .background { PaperBackground() }
            .toolbarVisibility(.hidden, for: .navigationBar)
        }
    }
}

/// Einstellungen > Kalender: Wochenbeginn (Phase 14) und Zeiträume (Phase 15). Der Wochenbeginn ändert bei
/// rollierenden Zeiträumen nur die Anzeige, bei "Kalender" auch die Rechnung.
private struct CalendarSection: View {
    @AppStorage(SettingsKey.firstWeekday) private var firstWeekday = FirstWeekdaySetting.automatic
    @AppStorage(SettingsKey.periods) private var periods = Periods.rolling

    var body: some View {
        PaperSection(title: "Kalender") {
            VStack(alignment: .leading, spacing: Theme.inlineSpacing) {
                Text("Wochenbeginn")
                    .bodyText()
                SegmentedChoice(
                    options: FirstWeekdaySetting.allCases,
                    selection: $firstWeekday,
                    title: \.title,
                    id: { "settings-first-weekday-\($0.rawValue)" }
                )
                .accessibilityIdentifier("settings-first-weekday")
                Text("Zeiträume")
                    .bodyText()
                    .padding(.top, Theme.inlineSpacing)
                SegmentedChoice(
                    options: Periods.allCases,
                    selection: $periods,
                    title: \.title,
                    id: { "settings-periods-\($0.rawValue)" }
                )
                .accessibilityIdentifier("settings-periods")
                Text(periods.explanation)
                    .metaText()
                    .foregroundStyle(Theme.inkSecondary)
                    .accessibilityIdentifier("settings-periods-explanation")
            }
        }
    }
}

/// Einstellungen > Anzeige: Darstellung System, Hell oder Dunkel (Phase 14).
private struct DisplaySection: View {
    @AppStorage(SettingsKey.appearance) private var appearance = AppearanceSetting.system
    @Environment(\.openURL) private var openURL

    var body: some View {
        PaperSection(title: "Anzeige") {
            VStack(alignment: .leading, spacing: Theme.inlineSpacing) {
                Text("Darstellung")
                    .bodyText()
                SegmentedChoice(
                    options: AppearanceSetting.allCases,
                    selection: $appearance,
                    title: \.title,
                    id: { "settings-appearance-\($0.rawValue)" }
                )
                .accessibilityIdentifier("settings-appearance")
                languageRow
            }
        }
    }

    /// Zeile "Sprache" (Phase 16): rechts die Sprache der App, Tippen öffnet die Seite der App in den iOS Einstellungen.
    /// Die Sprache wählt man dort, es gibt keinen eigenen Umschalter.
    private var languageRow: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
        } label: {
            HStack(spacing: Theme.controlSpacing) {
                Text("Sprache")
                    .bodyText()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(verbatim: AppLanguage.currentName())
                    .bodyText()
                    .foregroundStyle(Theme.inkSecondary)
                    .accessibilityIdentifier("settings-language-name")
                Image(systemName: "arrow.up.right")
                    .font(Theme.Typography.symbolSmall)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Theme.ink)
            .frame(minHeight: Theme.controlSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, Theme.inlineSpacing)
        .accessibilityIdentifier("settings-language")
    }
}

/// Fuß der Einstellungen (Phase 12): Wortmarke mit kleiner Figur und Version. Der einzige Ort der Wortmarke in der App.
private struct Footer: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "–"
        let build = info?["CFBundleVersion"] as? String ?? "–"
        return localized("Version \(short) (\(build))")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.inlineSpacing) {
            HStack(alignment: .lastTextBaseline, spacing: Theme.spacing) {
                // Zwei Texte statt Zeilenumbruch: negativer Zeilenabstand greift bei `Text` nicht.
                VStack(alignment: .leading, spacing: Theme.wordmarkLineSpacing) {
                    Text("Hestia")
                    Text("Habits")
                }
                .font(Theme.Typography.wordmark)
                .textCase(.uppercase)
                .tracking(Theme.Typography.wordmarkTracking)
                .foregroundStyle(Theme.inkSecondary)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Hestia Habits")
                .accessibilityIdentifier("settings-wordmark")
                // Dieselbe Figur wie in Heute ohne Habits, klein neben der Wortmarke. Dekorativ.
                Image(EngravingImage.Motif.vestal.rawValue)
                    .resizable()
                    .scaledToFit()
                    .frame(height: Theme.footerFigureHeight)
                    .accessibilityHidden(true)
                    .accessibilityIdentifier("settings-figure")
            }
            Text(version)
                .metaText()
                .foregroundStyle(Theme.inkSecondary)
                .accessibilityIdentifier("settings-version")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Theme.sectionSpacing)
    }
}

/// Einstellungen > Pausen: laufende und geplante Pausen. Eine laufende lässt sich beenden, eine geplante entfernen.
private struct PausesSection: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Pause.startDay) private var pauses: [Pause]

    @State private var isCreating = false

    private let engine = HabitEngine()

    /// Nur laufende und geplante Pausen, die laufenden zuerst. Vergangene Pausen stehen nicht in der Liste.
    private func listedPauses(today: Date) -> [Pause] {
        pauses.filter { engine.phase(of: $0.range, today: today) != .over && !$0.habits.isEmpty }
    }

    var body: some View {
        let today = AppClock.now
        let listed = listedPauses(today: today)

        PaperSection(title: "Pausen") {
            if listed.isEmpty {
                EmptyState(
                    title: "Keine Pausen",
                    message: "Keine laufenden oder geplanten Pausen. Pausierte Tage zählen nicht mit und unterbrechen keinen Streak.",
                    identifier: "no-pauses",
                    showsHairline: false
                )
            }
            ForEach(listed) { pause in
                PauseRow(
                    habitNames: pause.habits.map(\.name).sorted().joined(separator: ", "),
                    rangeText: pause.range.text(today: today, calendar: engine.calendar),
                    phase: engine.phase(of: pause.range, today: today)
                ) {
                    pause.endEarly(today: today, engine: engine, in: context)
                }
            }
            HermesButton("Neue Pause") {
                isCreating = true
            }
            .padding(.top, Theme.inlineSpacing)
            .accessibilityIdentifier("new-pause")
        }
        .sheet(isPresented: $isCreating) {
            PauseEditorSheet()
        }
    }
}

#if DEBUG && targetEnvironment(simulator)
/// Einstellungen > Entwickler: Testdaten erzeugen und alle Daten zurücksetzen. Nur in Debug Builds im Simulator,
/// nicht auf dem iPhone.
private struct DeveloperSection: View {
    @Environment(\.modelContext) private var context

    @State private var isConfirmingReset = false
    @State private var message: String?

    var body: some View {
        PaperSection(title: "Entwickler") {
            VStack(alignment: .leading, spacing: Theme.spacing) {
                HermesButton("Testdaten erzeugen", variant: .quiet) {
                    let habits = DebugData.insertSampleHabits(into: context)
                    message = "\(habits.count) Beispielhabits mit \(DebugData.historyDays) Tagen Historie angelegt."
                }
                .accessibilityIdentifier("create-sample-data")

                HermesButton("Alle Daten zurücksetzen", variant: .destructive, role: .destructive) {
                    isConfirmingReset = true
                }
                .accessibilityIdentifier("reset-all-data")

                if let message {
                    Text(message)
                        .bodyText()
                        .foregroundStyle(Theme.inkSecondary)
                        .accessibilityIdentifier("developer-message")
                }
            }
        }
        .alert("Alle Daten zurücksetzen?", isPresented: $isConfirmingReset) {
            Button("Abbrechen", role: .cancel) {}
            Button("Zurücksetzen", role: .destructive) {
                try? DebugData.resetAll(in: context)
                message = "Alle Daten wurden gelöscht."
            }
        } message: {
            Text("Alle Habits, Erledigungen und Pausen werden unwiderruflich gelöscht.")
        }
    }
}
#endif

#Preview {
    SettingsView()
        .modelContainer(for: [Habit.self, Completion.self, Pause.self], inMemory: true)
}
