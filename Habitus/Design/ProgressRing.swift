import SwiftUI

/// Ring, der sich mit dem Fortschritt füllt. Grundlage für `CounterControl` und `ProgressHeader`.
struct ProgressRing: View {
    /// Anteil von 0 bis 1.
    let fraction: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .inset(by: Theme.ringWidth / 2)
                .stroke(color.opacity(Theme.ringTrackOpacity), lineWidth: Theme.ringWidth)
            Circle()
                .inset(by: Theme.ringWidth / 2)
                .trim(from: 0, to: min(max(fraction, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: Theme.ringWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

#Preview {
    HStack {
        ProgressRing(fraction: 0, color: HabitColor.blue.color)
        ProgressRing(fraction: 0.33, color: HabitColor.blue.color)
        ProgressRing(fraction: 1, color: HabitColor.blue.color)
    }
    .frame(width: 120, height: 40)
    .padding()
}
