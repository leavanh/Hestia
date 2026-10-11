import SwiftUI

/// Aufbau der `SegmentBar` ohne Oberfläche: bis `Theme.segmentBarMaxSegments` Punkte ein Segment pro Punkt, darüber ein
/// durchgehender Balken mit Füllung nach Prozent. Bei 0 Punkten gibt es keinen Balken.
nonisolated enum SegmentBarModel: Equatable {
    case none
    case segments(total: Int, done: Int)
    case continuous(percent: Int)

    init(done: Int, total: Int) {
        if total <= 0 {
            self = .none
        } else if total <= Theme.segmentBarMaxSegments {
            self = .segments(total: total, done: min(max(done, 0), total))
        } else {
            self = .continuous(percent: DayProgress(done: done, total: total).percent)
        }
    }
}

/// Fortschritt als Reihe kurzer Balken (3 pt hoch, 3 pt Abstand): erledigte Punkte voll, offene mit 25 %.
/// Bei mehr als 12 Punkten ein durchgehender Balken mit Füllung nach Prozent. Die Farbe kommt aus der Umgebung
/// (`foregroundStyle`): `ink` auf Papier, `onBand` auf dem Kopfband.
struct SegmentBar: View {
    let done: Int
    let total: Int

    var body: some View {
        Group {
            switch SegmentBarModel(done: done, total: total) {
            case .none:
                EmptyView()
            case .segments(let total, let done):
                HStack(spacing: Theme.segmentBarSpacing) {
                    ForEach(0..<total, id: \.self) { index in
                        Rectangle()
                            .opacity(index < done ? 1 : Theme.segmentOpenOpacity)
                    }
                }
            case .continuous(let percent):
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Rectangle().opacity(Theme.segmentOpenOpacity)
                        Rectangle().frame(width: proxy.size.width * Double(percent) / 100)
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
