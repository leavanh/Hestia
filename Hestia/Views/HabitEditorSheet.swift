import SwiftData
import SwiftUI

/// Sheet "Habit anlegen / bearbeiten". Ohne `habit` wird ein neuer Habit angelegt.
struct HabitEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let habit: Habit?

    @State private var name: String
    @State private var detail: String
    @State private var iconName: String
    @State private var habitColor: HabitColor
    @State private var rhythm: Rhythm
    @State private var targetCount: Int
    @State private var weekdays: Set<Int>
    @State private var monthDay: Int
    @FocusState private var isNameFocused: Bool

    init(habit: Habit? = nil) {
        self.habit = habit
        _name = State(initialValue: habit?.name ?? "")
        _detail = State(initialValue: habit?.detail ?? "")
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
                    PaperSection(title: "Name") {
                        TextField("z.B. Sport", text: $name)
                            .bodyText()
                            .focused($isNameFocused)
                            .accessibilityIdentifier("name-field")
                            .submitLabel(.done)
                    }
                    PaperSection(title: "Zusatz") {
                        TextField("z.B. 20 Min", text: $detail)
                            .bodyText()
                            .accessibilityIdentifier("detail-field")
                            .submitLabel(.done)
                            .onChange(of: detail) { _, new in
                                if new.count > HabitDetail.maxLength { detail = String(new.prefix(HabitDetail.maxLength)) }
                            }
                    }
                    PaperSection(title: "Icon") {
                        iconGrid
                    }
                    PaperSection(title: "Farbe") {
                        colorRow
                    }
                    PaperSection(title: "Rhythmus") {
                        rhythmSection
                    }
                }
                .padding(Theme.spacing)
                .padding(.bottom, Theme.sheetBottomSpace)
            }
            .background { PaperBackground() }
            .navigationTitle(habit == nil ? LocalizedStringKey("Neuer Habit") : LocalizedStringKey("Habit bearbeiten"))
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
            .onAppear { isNameFocused = habit == nil }
            .onChange(of: rhythm) { _, new in
                // Die Anzahl bleibt, soweit der neue Rhythmus sie erlaubt.
                if let range = new.targetRange {
                    targetCount = min(max(targetCount, range.lowerBound), range.upperBound)
                }
            }
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
        VStack(alignment: .leading, spacing: Theme.spacing) {
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
                StepperControl(
                    title: rhythm.targetText(targetCount),
                    value: $targetCount,
                    range: range,
                    id: "target-stepper"
                )
            }
        case .weekdays:
            WeekdayPicker(selection: $weekdays, habitColor: habitColor)
            Text("Mindestens einen Wochentag auswählen.")
                .bodyText()
                .foregroundStyle(Theme.inkSecondary)
        case .monthDay:
            MonthDayPicker(selection: $monthDay)
        }
    }

    private var iconGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(HabitIcons.all, id: \.self) { icon in
                Button {
                    iconName = icon
                } label: {
                    Image(systemName: icon)
                        .font(Theme.Typography.icon)
                        .fixedControlTypeSize()
                        .foregroundStyle(icon == iconName ? habitColor.color : Theme.inkSecondary)
                        .frame(width: Theme.iconSize, height: Theme.iconSize)
                        .background(icon == iconName ? habitColor.tint : Color.clear)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(HabitIcons.title(for: icon))
                .accessibilityAddTraits(icon == iconName ? .isSelected : [])
                .accessibilityIdentifier("icon-\(icon)")
            }
        }
    }

    private var colorRow: some View {
        HabitColorPicker(selection: $habitColor)
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
            habit.detail = HabitDetail.normalized(detail)
        } else {
            context.insert(Habit(
                name: trimmedName,
                iconName: iconName,
                colorKey: habitColor.rawValue,
                rhythm: rhythm,
                targetCount: target,
                weekdays: days,
                monthDay: dayOfMonth,
                detail: detail,
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
