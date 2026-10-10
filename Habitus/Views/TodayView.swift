import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @State private var today = AppClock.now
    /// Der Tag, den die Ansicht zeigt: heute oder ein vergangener Tag (Spezifikation 5.2).
    @State private var shownDay = AppClock.now
    @State private var isCreating = false
    @State private var editingHabit: Habit?
    /// Kante, von der der neue Tag hereingleitet (Wischen nach rechts = von links).
    @State private var slideEdge: Edge = .leading
    /// Kante, von der Kopf und Karten beim Tageswechsel nacheinander hereinfedern. `nil` heißt ohne Kaskade.
    @State private var entranceEdge: Edge?
    /// Versatz des Inhalts beim Zurückfedern, wenn über heute hinaus gewischt wird.
    @State private var bounceOffset: CGFloat = 0
    /// Ob der Titel schon aus dem Sichtbereich gescrollt ist und klein in der Leiste steht.
    @State private var showsBarTitle = false

    private let engine = HabitEngine()

    /// Habits, die am angezeigten Tag fällig sind (Spezifikation 3.2): offene zuerst, dann erledigte.
    private var dueHabits: [Habit] {
        Habit.inTodayOrder(habits.filter { $0.isAlive && engine.isDue($0.snapshot, on: shownDay) }) {
            engine.isCompleted($0.snapshot, on: shownDay)
        }
    }

    var body: some View {
        let due = dueHabits
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                    header(for: due)
                        .dayEntrance(from: entranceEdge, index: 0)
                    VStack(spacing: Theme.spacing) {
                        ForEach(Array(due.enumerated()), id: \.element.id) { index, habit in
                            card(for: habit)
                                .dayEntrance(from: entranceEdge, index: index + 1)
                        }
                    }
                    .animation(reduceMotion ? nil : .smooth, value: due.map(\.id))
                }
                .padding(.horizontal, Theme.spacing)
                .padding(.top, Theme.headerTopSpacing)
                .padding(.bottom, Theme.spacing)
                .offset(x: bounceOffset)
                .id(engine.startOfDay(shownDay))
                .transition(dayTransition)
            }
            .accessibilityIdentifier("today-list")
            .background { GlassBackground() }
            .simultaneousGesture(
                DragGesture(minimumDistance: Theme.swipeDistance)
                    .onEnded { swipe(by: $0.translation) }
            )
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top > Theme.barTitleScrollOffset
            } action: { _, isScrolled in
                showsBarTitle = isScrolled
            }
            .sensoryFeedback(.selection, trigger: engine.startOfDay(shownDay))
            .scrollEdgeEffectStyle(.hard, for: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    barTitle
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Neuer Habit", systemImage: "plus") {
                        isCreating = true
                    }
                }
            }
            .sheet(isPresented: $isCreating) {
                HabitEditorSheet()
            }
            .sheet(item: $editingHabit) { habit in
                HabitEditorSheet(habit: habit)
            }
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
            show(day, enteringFrom: step < 0 ? .leading : .trailing)
        } else {
            bounce()
        }
    }

    /// Wechselt den Tag animiert. Die Richtung wird zuerst gesetzt und der Tag erst im nächsten Durchlauf,
    /// damit auch der abgehende Inhalt in die richtige Richtung herausgleitet.
    private func show(_ day: Date, enteringFrom edge: Edge) {
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

    private var weekdayText: String {
        shownDay.formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "de_DE")))
    }

    private var dateText: String {
        shownDay.formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "de_DE")))
    }

    private var daysAgo: Int {
        engine.calendar.dateComponents([.day], from: engine.startOfDay(shownDay), to: engine.startOfDay(today)).day ?? 0
    }

    private var dayLabel: String {
        RelativeDay.text(daysAgo: daysAgo)
    }

    /// Springt auf der Datumszeile animiert zu heute zurück. Das Chevron zeigt vorwärts in Richtung heute.
    private var backToTodayButton: some View {
        Button {
            show(today, enteringFrom: .trailing)
        } label: {
            HStack(spacing: 2) {
                Text("Heute")
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
            }
            .font(.subheadline.weight(.semibold))
        }
        .accessibilityIdentifier("back-to-today")
    }

    /// Kopfbereich ohne Karte: Wochentag als großer Titel, Datum als Untertitel, darunter der Fortschritt.
    private func header(for due: [Habit]) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            VStack(alignment: .leading, spacing: 2) {
                Text(weekdayText)
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("today-title")
                HStack(spacing: 8) {
                    Text(dateText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("today-subtitle")
                    DayBadge(text: dayLabel, isToday: daysAgo == 0)
                        .accessibilityIdentifier("today-badge")
                    Spacer(minLength: 0)
                    if daysAgo > 0 {
                        backToTodayButton
                    }
                }
            }
            ProgressHeader(progress: engine.dayProgress(due.map(\.snapshot), on: shownDay))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("today-header")
    }

    /// Kleiner Titel in der Leiste, sobald der große aus dem Bild gescrollt ist.
    private var barTitle: some View {
        VStack(spacing: 0) {
            Text(weekdayText)
                .font(.headline)
            Text("\(dateText) · \(dayLabel)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .opacity(showsBarTitle ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: showsBarTitle)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func card(for habit: Habit) -> some View {
        // Ein eben gelöschter Habit kann hier noch einmal ankommen, bevor die Liste neu aufgebaut ist.
        if habit.isAlive {
            let habitColor = HabitColor(key: habit.colorKey)
            let color = habitColor.color
            let snapshot = habit.snapshot

            HabitCard(
                name: habit.name,
                iconName: habit.iconName,
                habitColor: habitColor,
                status: engine.status(snapshot, on: shownDay),
                rhythmText: snapshot.rhythmText(window: engine.windowProgress(snapshot, on: shownDay)),
                dots: engine.weekDots(snapshot, on: shownDay),
                onEdit: { editingHabit = habit }
            ) {
                control(for: habit, snapshot: snapshot, color: color)
            }
        }
    }

    /// Counter bei täglich mit Anzahl größer 1, sonst Abhakkreis. Abgehakt wird für den angezeigten Tag.
    @ViewBuilder
    private func control(for habit: Habit, snapshot: HabitSnapshot, color: Color) -> some View {
        let target = engine.dailyTarget(snapshot)
        let count = min(engine.count(on: shownDay, in: snapshot.counts), target)

        if engine.usesCounter(snapshot) {
            CounterControl(
                count: count,
                target: target,
                color: color,
                id: "counter-\(habit.name)",
                onDecrement: {
                    habit.setCount(engine.decrementedCount(count), on: shownDay, engine: engine, in: context)
                },
                onIncrement: {
                    habit.setCount(engine.incrementedCount(count, target: target), on: shownDay, engine: engine, in: context)
                }
            )
        } else {
            CheckCircle(isChecked: count >= 1, color: color) {
                habit.setCount(engine.toggledCount(count), on: shownDay, engine: engine, in: context)
            }
            .accessibilityIdentifier("check-\(habit.name)")
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Habit.self, Completion.self, Pause.self], inMemory: true)
}
