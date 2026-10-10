import SwiftUI

/// Die 7 kleinen Punkte unter einem Habit: links der älteste Tag, rechts der angezeigte Tag mit äußerem Ring.
struct WeekDots: View {
    let dots: [WeekDot]
    let color: Color

    var body: some View {
        HStack(spacing: Theme.dotSpacing) {
            ForEach(Array(dots.enumerated()), id: \.offset) { index, dot in
                dotView(dot)
                    .overlay { if index == dots.count - 1 { shownDayRing } }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Letzte 7 Tage")
    }

    /// Der Ring liegt nur als Überlagerung um den Punkt und verändert Abstände und Ausrichtung nicht.
    private var shownDayRing: some View {
        let size = Theme.dotSize + 2 * Theme.dotRingGap + Theme.dotRingWidth
        return Circle()
            .stroke(color.opacity(Theme.dotRingOpacity), lineWidth: Theme.dotRingWidth)
            .frame(width: size, height: size)
    }

    @ViewBuilder
    private func dotView(_ dot: WeekDot) -> some View {
        switch dot {
        case .fill(let value):
            Circle()
                .fill(color.opacity(opacity(for: value)))
                .overlay { Circle().strokeBorder(color, lineWidth: 1) }
                .frame(width: Theme.dotSize, height: Theme.dotSize)
        }
    }

    /// 0 = nur Umriss, 1 = voll gefüllt, dazwischen steigende Deckkraft.
    private func opacity(for value: Double) -> Double {
        if value <= 0 { return 0 }
        if value >= 1 { return 1 }
        let range = Theme.dotPartialOpacity
        return range.lowerBound + (range.upperBound - range.lowerBound) * value
    }
}

#Preview {
    WeekDots(
        dots: [.fill(0), .fill(0), .fill(0.33), .fill(0.66), .fill(1), .fill(0), .fill(1)],
        color: HabitColor.green.color
    )
    .padding()
}
