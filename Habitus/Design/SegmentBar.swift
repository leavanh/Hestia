import SwiftUI

/// Aufbau der `SegmentBar` ohne Oberfläche: immer ein durchgehender Balken mit Füllung nach Prozent. Bei 0 Punkten
/// gibt es keinen Balken.
nonisolated enum SegmentBarModel: Equatable {
    case none
    case continuous(percent: Int)

    init(done: Int, total: Int) {
        if total <= 0 {
            self = .none
        } else {
            self = .continuous(percent: DayProgress(done: done, total: total).percent)
        }
    }
}

/// Fortschritt als durchgehender Balken (3 pt hoch): der gefüllte Teil nach Prozent, der offene mit 25 %. Ändert sich der
/// Fortschritt, wächst bzw. schrumpft die Füllung kurz animiert. Die Farbe kommt aus der Umgebung (`foregroundStyle`):
/// `ink` auf Papier, `onBand` auf dem Kopfband.
struct SegmentBar: View {
    let done: Int
    let total: Int

    var body: some View {
        Group {
            switch SegmentBarModel(done: done, total: total) {
            case .none:
                EmptyView()
            case .continuous(let percent):
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Rectangle().opacity(Theme.segmentOpenOpacity)
                        Rectangle()
                            .frame(width: proxy.size.width * Double(percent) / 100)
                            .animation(.easeInOut(duration: Theme.segmentBarFillDuration), value: percent)
                    }
                }
            }
        }
        .frame(height: Theme.segmentBarHeight)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: Theme.spacing) {
        SegmentBar(done: 4, total: 6)
        SegmentBar(done: 5, total: 16)
        SegmentBar(done: 0, total: 0)
    }
    .foregroundStyle(Theme.ink)
    .padding()
    .background { PaperBackground() }
}
