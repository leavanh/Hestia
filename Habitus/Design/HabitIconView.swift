import SwiftUI

/// Icon in Habitfarbe auf zarter Fläche derselben Farbe.
struct HabitIconView: View {
    let iconName: String
    let color: Color

    var body: some View {
        Image(systemName: iconName)
            .font(.title3)
            .foregroundStyle(color)
            .frame(width: Theme.iconSize, height: Theme.iconSize)
            .background(color.opacity(Theme.iconBackgroundOpacity), in: Circle())
    }
}
