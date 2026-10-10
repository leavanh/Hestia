import SwiftUI

extension View {
    /// Lässt die Ansicht beim Erscheinen von der Seite hereinfedern, jede um `index` später als die davor,
    /// damit beim Tageswechsel ein sichtbarer Kaskadeneffekt entsteht. Ohne `edge` erscheint sie ganz normal.
    func dayEntrance(from edge: Edge?, index: Int) -> some View {
        modifier(DayEntrance(edge: edge, index: index))
    }
}

private struct DayEntrance: ViewModifier {
    let edge: Edge?
    let index: Int
    @State private var arrived = false

    func body(content: Content) -> some View {
        let hidden = edge != nil && !arrived
        content
            .offset(x: hidden ? (edge == .leading ? -Theme.entranceOffset : Theme.entranceOffset) : 0)
            .opacity(hidden ? 0 : 1)
            .onAppear {
                guard edge != nil else { return }
                let delay = Double(min(index, Theme.entranceMaxStaggeredItems)) * Theme.entranceStagger
                withAnimation(.spring(duration: 0.5, bounce: 0.3).delay(delay)) {
                    arrived = true
                }
            }
    }
}
