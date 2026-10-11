import SwiftUI

/// Die 7 kleinen Quadrate unter einem Habit: links der älteste Tag, rechts der angezeigte Tag mit äußerem Rahmen.
/// Vor dem angezeigten Tag steht mehr Abstand (`Theme.dotRingClearance`), damit sein Rahmen das Nachbarquadrat nicht berührt.
/// Ein pausierter Tag ist ein kurzer waagrechter Strich statt eines Quadrats.
struct WeekDots: View {
    let dots: [WeekDot]
    let color: Color

    var body: some View {
        HStack(spacing: Theme.dotSpacing) {
            ForEach(Array(dots.enumerated()), id: \.offset) { index, dot in
                let isShown = index == dots.count - 1
                dotView(dot)
                    .overlay { if isShown { shownDayFrame } }
                    .padding(.leading, isShown && index > 0 ? Theme.dotRingClearance : 0)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Letzte 7 Tage")
        .accessibilityValue(pausedText)
    }

    /// Für VoiceOver und Tests: wie viele der 7 Tage pausiert sind.
    private var pausedText: String {
        let count = dots.filter { $0 == .paused }.count
        switch count {
        case 0: return ""
        case 1: return "1 Tag pausiert"
        default: return "\(count) Tage pausiert"
        }
    }

    /// Der Rahmen liegt nur als Überlagerung um das Quadrat und verändert Abstände und Ausrichtung nicht.
    private var shownDayFrame: some View {
        let size = Theme.dotSize + 2 * Theme.dotRingGap + Theme.dotRingWidth
        return Rectangle()
            .stroke(color.opacity(Theme.dotRingOpacity), lineWidth: Theme.dotRingWidth)
            .frame(width: size, height: size)
    }

    @ViewBuilder
    private func dotView(_ dot: WeekDot) -> some View {
        switch dot {
        case .fill(let value):
            Rectangle()
                .fill(color.opacity(opacity(for: value)))
                .frame(width: Theme.dotSize, height: Theme.dotSize)
        case .paused:
            Rectangle()
                .fill(Theme.ink.opacity(Theme.pausedOpacity))
                .frame(width: Theme.dotSize, height: Theme.pausedDashHeight)
                .frame(width: Theme.dotSize, height: Theme.dotSize)
        }
    }

    /// 0 = Habitfarbe mit 22 %, 1 = voll gefüllt, dazwischen steigende Deckkraft.
    private func opacity(for value: Double) -> Double {
        if value <= 0 { return Theme.dotEmptyOpacity }
        if value >= 1 { return 1 }
        let range = Theme.dotPartialOpacity
        return range.lowerBound + (range.upperBound - range.lowerBound) * value
    }
}

#Preview {
    VStack(spacing: Theme.spacing) {
        WeekDots(
            dots: [.fill(0), .fill(0), .fill(0.33), .fill(0.66), .fill(1), .fill(0), .fill(1)],
            color: HabitColor.green.color
        )
        WeekDots(
            dots: [.fill(1), .fill(1), .paused, .paused, .paused, .fill(0), .paused],
            color: HabitColor.green.color
        )
    }
    .padding()
    .background { PaperBackground() }
}
