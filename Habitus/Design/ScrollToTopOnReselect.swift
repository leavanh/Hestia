import SwiftUI

private struct ReselectCountKey: EnvironmentKey {
    static let defaultValue = 0
}

extension EnvironmentValues {
    /// Zählt, wie oft der Tab dieser Ansicht erneut angetippt wurde, während er schon gewählt war (`PaperTabBar`).
    var tabReselectCount: Int {
        get { self[ReselectCountKey.self] }
        set { self[ReselectCountKey.self] = newValue }
    }
}

private struct ScrollToTopOnReselect: ViewModifier {
    @Environment(\.tabReselectCount) private var reselectCount
    @State private var position = ScrollPosition()

    func body(content: Content) -> some View {
        content
            .scrollPosition($position)
            .onChange(of: reselectCount) {
                withAnimation { position.scrollTo(edge: .top) }
            }
    }
}

extension View {
    /// Scrollt eine `ScrollView` nach oben, wenn der Tab, in dem sie steht, erneut angetippt wird (Spezifikation 5.1).
    func scrollsToTopOnTabReselect() -> some View {
        modifier(ScrollToTopOnReselect())
    }
}
