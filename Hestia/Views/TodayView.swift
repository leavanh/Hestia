import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @State private var today = AppClock.now
    /// Der Tag, den die Ansicht zeigt: heute oder ein vergangener Tag (Spezifikation 5.2).
    @State private var shownDay = AppClock.now
    @State private var isCreating = false
    /// Sortiermodus: die offenen Habits lassen sich per Drag and Drop verschieben (Spezifikation 5.2).
    @State private var isSorting = false
    @State private var editingHabit: Habit?
    /// Kante, von der der neue Tag hereingleitet (Wischen nach rechts = von links).
    @State private var slideEdge: Edge = .leading
    /// Kante, von der Kopf und Karten beim Tageswechsel nacheinander hereinfedern. `nil` heißt ohne Kaskade.
    @State private var entranceEdge: Edge?
    /// Versatz des Inhalts beim Zurückfedern, wenn über heute hinaus gewischt wird.
    @State private var bounceOffset: CGFloat = 0
    /// Ob das Kopfband aus dem Bild gescrollt ist und oben die kleine Leiste steht.
    @State private var showsCompactBar = false
    /// Höhe des Kopfbands, für die Schwelle der kleinen Leiste.
    @State private var bandHeight: CGFloat = 0

    @Environment(\.habitEngine) private var engine

    /// Habits der Hauptliste am angezeigten Tag (Spezifikation 3.2): offene zuerst, dann erledigte.
    private var dueHabits: [Habit] {
        Habit.mainInTodayOrder(habits, on: shownDay, engine: engine)
    }

    /// Habits in Weitere am angezeigten Tag: gespeicherte Reihenfolge, pausierte ausgegraut am Ende.
    private var otherHabits: [Habit] {
        Habit.otherInSavedOrder(habits, on: shownDay, engine: engine)
    }

    /// Ob es noch keinen aktiven Habit gibt. Dann zeigt Heute statt der Liste den Leerzustand.
    private var hasNoActiveHabits: Bool {
        !habits.contains { $0.isAlive && $0.endedAt == nil }
    }

    var body: some View {
        let due = dueHabits
        Group {
            if isSorting {
                HabitSortList(habits: habits, day: shownDay) { isSorting = false }
            } else {
                dayScroll(for: due, other: otherHabits)
            }
        }
        .background { PaperBackground() }
        .sheet(isPresented: $isCreating) {
            HabitEditorSheet()
        }
        .sheet(item: $editingHabit) { habit in
            HabitEditorSheet(habit: habit)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { showToday() }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .NSCalendarDayChanged) {
                showToday()
            }
        }
    }

    /// Die Tagesansicht: Kopfband, Listenkopf und Liste, mit Wischen zum Wechseln des Tages. Ist das Band aus dem
    /// Bild gescrollt, steht oben die kleine Leiste.
    private func dayScroll(for due: [Habit], other: [Habit]) -> some View {
        let progress = engine.dayProgress(due.map(\.snapshot), on: shownDay)
        return ScrollView {
            VStack(spacing: 0) {
                DayHeader(
                    day: shownDay,
                    today: today,
                    progress: progress,
                    engine: engine,
                    transition: dayTransition,
                    entranceEdge: entranceEdge,
                    onAdd: { isCreating = true },
                    onBackToToday: { show(today) },
                    onSelectDay: { show($0) }
                )
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { bandHeight = $0 }
                VStack(alignment: .leading, spacing: 0) {
                    listHeader(count: due.count)
                    ZStack(alignment: .top) {
                        dayList(due, other: other, isEmpty: hasNoActiveHabits && due.isEmpty && other.isEmpty)
                            .id(engine.startOfDay(shownDay))
                            .transition(dayTransition)
                    }
                }
                .padding(.horizontal, Theme.spacing)
                .padding(.bottom, Theme.spacing)
            }
            .offset(x: bounceOffset)
        }
        .accessibilityIdentifier("today-list")
        .scrollsToTopOnTabReselect()
        .simultaneousGesture(
            DragGesture(minimumDistance: Theme.swipeDistance)
                .onEnded { swipe(by: $0.translation) }
        )
        .onScrollGeometryChange(for: Bool.self) { geometry in
            bandHeight > 0
                && geometry.contentOffset.y + geometry.contentInsets.top > bandHeight - Theme.compactBarScrollOffset
        } action: { _, isScrolledOut in
            showsCompactBar = isScrolledOut
        }
        .overlay(alignment: .top) {
            if showsCompactBar {
                compactBar(progress: progress)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: Theme.compactBarFadeDuration), value: showsCompactBar)
        .sensoryFeedback(.selection, trigger: engine.startOfDay(shownDay))
    }

    /// Anzahl der Zeilen links, "Sortieren" rechts (Spezifikation 5.2).
    private func listHeader(count: Int) -> some View {
        HStack {
            Text(HabitCountText.text(count))
                .metaText()
                .foregroundStyle(Theme.inkSecondary)
                .accessibilityIdentifier("habit-count")
            Spacer()
            HermesButton("Sortieren", variant: .text) {
                isSorting = true
            }
            .fixedSize()
            .disabled(hasNoActiveHabits)
            .accessibilityIdentifier("sort-toggle")
        }
    }

    /// Die Karten des angezeigten Tags, ohne aktive Habits der Leerzustand. Sie federn nach dem Kopfband herein.
    private func dayList(_ rows: [Habit], other: [Habit], isEmpty: Bool) -> some View {
        VStack(spacing: Theme.sectionSpacing) {
            if isEmpty {
                EmptyState(
                    engraving: .vestal,
                    title: "Noch keine Habits",
                    message: "Habits erscheinen hier an jedem Tag, an dem sie fällig sind.",
                    identifier: "today-empty",
                    actionTitle: "Ersten Habit anlegen",
                    action: { isCreating = true }
                )
                .dayEntrance(from: entranceEdge, index: 3)
            }
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, habit in
                    DayHabitCard(habit: habit, day: shownDay) { editingHabit = habit }
                        .dayEntrance(from: entranceEdge, index: index + 3)
                }
                OtherHabitsSection(
                    habits: other, day: shownDay, entranceEdge: entranceEdge, entranceIndex: rows.count + 3
                ) { editingHabit = $0 }
            }
            .animation(reduceMotion ? nil : .smooth, value: rows.map(\.id))
        }
    }

    /// Schmale Leiste in `band`, solange das Kopfband aus dem Bild gescrollt ist: "Heute · 4/6" und Plus.
    private func compactBar(progress: DayProgress) -> some View {
        let title = RelativeDay.text(daysAgo: daysAgo)
        return HStack(spacing: Theme.inlineSpacing) {
            Text(progress.total == 0 ? title : "\(title) · \(progress.done)/\(progress.total)")
                .labelText()
                .lineLimit(1)
            Spacer(minLength: 0)
            PlusButton { isCreating = true }
        }
        .foregroundStyle(Theme.onBand)
        .padding(.horizontal, Theme.spacing)
        .padding(.vertical, Theme.compactBarPadding)
        .background { Theme.band.ignoresSafeArea(edges: .top) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("compact-bar")
    }

    /// Beim Start, beim Zurückkehren in die App und um Mitternacht zeigt die Ansicht wieder heute, ohne Animation.
    private func showToday() {
        today = AppClock.now
        entranceEdge = nil
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            shownDay = today
        }
    }

    /// Wischen nach rechts zeigt den vorherigen Tag, nach links den nächsten. Über heute hinaus geht es nicht,
    /// der Inhalt federt dann nur kurz zurück.
    private func swipe(by translation: CGSize) {
        guard abs(translation.width) > Theme.swipeDistance,
              abs(translation.width) > abs(translation.height) else { return }
        let step = translation.width > 0 ? -1 : 1
        guard let day = engine.calendar.date(byAdding: .day, value: step, to: shownDay) else { return }

        if engine.startOfDay(day) <= engine.startOfDay(today) {
            show(day)
        } else {
            bounce()
        }
    }

    /// Wechselt den Tag animiert (Wischen, Wochenstreifen, "Heute ›"). Ein früherer Tag kommt von links, ein späterer
    /// von rechts. Die Richtung wird zuerst gesetzt und der Tag erst im nächsten Durchlauf, damit auch der abgehende
    /// Inhalt in die richtige Richtung herausgleitet.
    private func show(_ day: Date) {
        let target = engine.startOfDay(day)
        let current = engine.startOfDay(shownDay)
        guard target != current, target <= engine.startOfDay(today) else { return }
        let edge: Edge = target < current ? .leading : .trailing
        slideEdge = edge
        entranceEdge = reduceMotion ? nil : edge
        Task { @MainActor in
            withAnimation(.easeInOut(duration: Theme.dayChangeDuration)) {
                shownDay = day
            }
            // Später erscheinende Karten (z.B. ein neuer Habit) sollen nicht mehr hereinfedern.
            try? await Task.sleep(for: .seconds(1))
            entranceEdge = nil
        }
    }

    private func bounce() {
        guard !reduceMotion else { return }
        withAnimation(.easeOut(duration: 0.1)) {
            bounceOffset = -Theme.swipeBounceDistance
        } completion: {
            withAnimation(.spring(duration: 0.35, bounce: 0.5)) {
                bounceOffset = 0
            }
        }
    }

    /// Der alte Tag gleitet in Wischrichtung heraus, der neue federt Kopf und Karten nacheinander von der
    /// anderen Seite herein (`dayEntrance`). Bei Bewegung reduzieren wird nur überblendet.
    private var dayTransition: AnyTransition {
        if reduceMotion { return .opacity }
        let opposite: Edge = slideEdge == .leading ? .trailing : .leading
        return .asymmetric(
            insertion: .opacity,
            removal: .move(edge: opposite).combined(with: .scale(scale: Theme.dayChangeScale)).combined(with: .opacity)
        )
    }

    private var daysAgo: Int {
        engine.calendar.dateComponents([.day], from: engine.startOfDay(shownDay), to: engine.startOfDay(today)).day ?? 0
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Habit.self, Completion.self, Pause.self], inMemory: true)
}
