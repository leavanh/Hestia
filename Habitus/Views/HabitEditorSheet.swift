import SwiftData
import SwiftUI

/// Sheet "Habit anlegen / bearbeiten". Ohne `habit` wird ein neuer Habit angelegt.
struct HabitEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let habit: Habit?

    @State private var name: String
    @State private var iconName: String
    @State private var habitColor: HabitColor
    @State private var rhythm: Rhythm
    @State private var targetCount: Int
    @State private var weekdays: Set<Int>
    @State private var monthDay: Int
    @State private var isConfirmingEnd = false
    @FocusState private var isNameFocused: Bool

    init(habit: Habit? = nil) {
        self.habit = habit
        _name = State(initialValue: habit?.name ?? "")
        _iconName = State(initialValue: habit?.iconName ?? HabitIcons.default)
        _habitColor = State(initialValue: habit.map { HabitColor(key: $0.colorKey) } ?? .blue)
        _rhythm = State(initialValue: habit?.rhythm ?? .daily)
        _targetCount = State(initialValue: habit?.targetCount ?? 1)
        // Neue Habits starten mit dem heutigen Wochentag bzw. Tag im Monat.
        let storedWeekdays = Set(habit?.weekdays ?? [])
        _weekdays = State(initialValue: storedWeekdays.isEmpty ? [HabitEngine().weekday(of: AppClock.now)] : storedWeekdays)
        _monthDay = State(initialValue: habit?.monthDay ?? Calendar.current.component(.day, from: AppClock.now))
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.sectionSpacing) {
                    GlassSection(title: "Name") {
                        TextField("z.B. Sport", text: $name)
                            .font(.body)
                            .focused($isNameFocused)
                            .accessibilityIdentifier("name-field")
                            .submitLabel(.done)
                    }
                    GlassSection(title: "Icon") {
                        iconGrid
                    }
                    GlassSection(title: "Farbe") {
                        colorRow
                    }
                    GlassSection(title: "Rhythmus") {
                        rhythmSection
                    }
                    if let habit, habit.isAlive, habit.endedAt == nil {
                        endButton
                    }
                }
                .padding(Theme.spacing)
            }
            .background { GlassBackground() }
            .navigationTitle(habit == nil ? "Neuer Habit" : "Habit bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen", systemImage: "xmark", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern", systemImage: "checkmark", role: .confirm) {
                        save()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
            .alert("Habit beenden?", isPresented: $isConfirmingEnd) {
                Button("Historie behalten") { endHabit(keepingHistory: true) }
                Button("Historie löschen", role: .destructive) { endHabit(keepingHistory: false) }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Der Habit erscheint nicht mehr in Heute. Soll seine Historie in Kalender und Statistik bleiben oder gelöscht werden? Gelöscht ist sie unwiderruflich weg.")
            }
            .onAppear { isNameFocused = habit == nil }
            .onChange(of: rhythm) { _, new in
                // Die Anzahl bleibt, soweit der neue Rhythmus sie erlaubt.
                if let range = new.targetRange {
                    targetCount = min(max(targetCount, range.lowerBound), range.upperBound)
                }
            }
        }
    }

    /// "Habit beenden", ganz unten und nur beim Bearbeiten (Spezifikation 5.3). Beendet wird erst nach Bestätigung.
    private var endButton: some View {
        Button(role: .destructive) {
            isConfirmingEnd = true
        } label: {
            Text("Habit beenden")
                .font(.body)
                .frame(maxWidth: .infinity)
                .glassCard()
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .accessibilityIdentifier("end-habit")
    }

    /// Behalten: der Habit ist ab heute beendet, seine Historie bleibt. Löschen: Habit, Erledigungen und Pausen
    /// Zuordnung sind weg (Spezifikation 3.9).
    private func endHabit(keepingHistory: Bool) {
        guard let habit else { return }
        dismiss()
        if keepingHistory {
            habit.end(on: AppClock.now, engine: HabitEngine(), in: context)
        } else {
            habit.deleteWithHistory(in: context)
        }
    }

    /// Segment Täglich / Woche / Monat. Beim Wechsel gilt die Variante "Anzahl".
    private var groupBinding: Binding<RhythmGroup> {
        Binding(
            get: { rhythm.group },
            set: { group in
                if group != rhythm.group { rhythm = group.rhythms[0] }
            }
        )
    }

    private var rhythmSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SegmentedChoice(
                options: RhythmGroup.allCases,
                selection: groupBinding,
                title: \.title,
                id: { "rhythm-\($0)" }
            )
            .accessibilityIdentifier("rhythm-picker")

            // Unter Woche und Monat: Anzahl oder feste Tage.
            if rhythm.group.rhythms.count > 1 {
                SegmentedChoice(
                    options: rhythm.group.rhythms,
                    selection: $rhythm,
                    title: { $0.variantTitle ?? "" },
                    id: { "variant-\($0.rawValue)" }
                )
                .accessibilityIdentifier("variant-picker")
            }

            rhythmSetting
        }
    }

    /// Die zum Rhythmus passende Einstellung: Anzahl, Wochentage oder Tag im Monat.
    @ViewBuilder
    private var rhythmSetting: some View {
        switch rhythm {
        case .daily, .weekly, .monthly:
            if let range = rhythm.targetRange {
                Stepper(value: $targetCount, in: range) {
                    Text(rhythm.targetText(targetCount))
                }
                .accessibilityIdentifier("target-stepper")
            }
        case .weekdays:
            WeekdayPicker(selection: $weekdays, color: habitColor.color)
            Text("Mindestens einen Wochentag auswählen.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .monthDay:
            HStack {
                Text("Jeden Monat am")
                    .font(.body)
                Spacer()
                Picker("Tag im Monat", selection: $monthDay) {
                    ForEach(1...31, id: \.self) { day in
                        Text("\(day).").tag(day)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accessibilityIdentifier("monthday-picker")
            }
            Text("Hat ein Monat weniger Tage, ist der letzte Tag des Monats fällig.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var iconGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(HabitIcons.all, id: \.self) { icon in
                Button {
                    iconName = icon
                } label: {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(icon == iconName ? habitColor.mutedColor : .secondary)
                        .frame(width: Theme.iconSize, height: Theme.iconSize)
                        .background(
                            habitColor.mutedColor.opacity(icon == iconName ? Theme.iconBackgroundOpacity : 0),
                            in: Circle()
                        )
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("icon-\(icon)")
            }
        }
    }

    private var colorRow: some View {
        HStack {
            ForEach(HabitColor.allCases) { option in
                Button {
                    habitColor = option
                } label: {
                    Circle()
                        .fill(option.color)
                        .frame(width: Theme.swatchSize, height: Theme.swatchSize)
                        .padding(4)
                        .overlay {
                            if option == habitColor {
                                Circle().strokeBorder(option.color, lineWidth: Theme.strokeWidth)
                            }
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("color-\(option.rawValue)")
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        // Anzahl nur bei täglich / Woche / Monat, sonst 1. Wochentage und Monatstag nur beim passenden Rhythmus.
        let target = rhythm.targetRange.map { min(max(targetCount, $0.lowerBound), $0.upperBound) } ?? 1
        let days = rhythm == .weekdays ? weekdays.sorted() : []
        let dayOfMonth = rhythm == .monthDay ? monthDay : nil

        if let habit {
            habit.name = trimmedName
            habit.iconName = iconName
            habit.colorKey = habitColor.rawValue
            habit.rhythm = rhythm
            habit.targetCount = target
            habit.weekdays = days
            habit.monthDay = dayOfMonth
        } else {
            context.insert(Habit(
                name: trimmedName,
                iconName: iconName,
                colorKey: habitColor.rawValue,
                rhythm: rhythm,
                targetCount: target,
                weekdays: days,
                monthDay: dayOfMonth,
                createdAt: AppClock.now
            ))
        }
        try? context.save()
        dismiss()
    }
}

#Preview {
    HabitEditorSheet()
        .modelContainer(for: [Habit.self, Completion.self, Pause.self], inMemory: true)
}
