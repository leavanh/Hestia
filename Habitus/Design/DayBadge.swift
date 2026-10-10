import SwiftUI

/// Kleine Kapsel neben dem Datum: "Heute" in Akzentfarbe, vergangene Tage ("Gestern", "Vor 3 Tagen") neutral.
struct DayBadge: View {
    let text: String
    let isToday: Bool

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isToday ? Theme.accent : Color.secondary)
            .padding(.horizontal, Theme.badgePaddingHorizontal)
            .padding(.vertical, Theme.badgePaddingVertical)
            .background(isToday ? Theme.accent.opacity(Theme.badgeOpacity) : Theme.segmentTrack, in: Capsule())
    }
}

#Preview {
    HStack {
        DayBadge(text: "Heute", isToday: true)
        DayBadge(text: "Gestern", isToday: false)
        DayBadge(text: "Vor 3 Tagen", isToday: false)
    }
    .padding()
}
