import SwiftUI

/// Die drei Tabs der App (Spezifikation 5.1).
enum AppTab: String, CaseIterable, Identifiable {
    case today, calendar, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: localized("Heute")
        case .calendar: localized("Kalender")
        case .settings: localized("Einstellungen")
        }
    }

    var systemImage: String {
        switch self {
        case .today: "checkmark.circle"
        case .calendar: "calendar"
        case .settings: "gearshape"
        }
    }

    var identifier: String { "tab-\(rawValue)" }
}

/// Eigene Tab Bar statt der des Systems, als schwebende Liquid Glass Leiste: eine Kapsel mit Abstand zum Rand, der
/// gewählte Tab liegt auf einer eigenen Glaskapsel, die beim Wechsel zum neuen Tab gleitet. Der gewählte Tab steht in
/// `ink`, die anderen in `inkSecondary`.
struct PaperTabBar: View {
    @Binding var selection: AppTab
    /// Wird mit dem Tab aufgerufen, wenn der gerade gewählte Tab nochmals angetippt wird.
    var onReselect: (AppTab) -> Void = { _ in }

    @Namespace private var indicator

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 0) {
                ForEach(AppTab.allCases) { tab in
                    item(tab)
                }
            }
            .padding(Theme.textSpacing)
            .glassEffect(.clear.interactive(), in: .capsule)
        }
        // Die Glaskapsel gleitet zum neuen Tab, Symbol und Label wechseln die Farbe weich mit.
        .animation(.easeInOut(duration: Theme.tabChangeDuration), value: selection)
        .padding(.horizontal, Theme.spacing)
        .padding(.bottom, Theme.textSpacing)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isTabBar)
    }

    private func item(_ tab: AppTab) -> some View {
        let isSelected = tab == selection
        return Button {
            if isSelected {
                onReselect(tab)
            } else {
                selection = tab
            }
        } label: {
            VStack(spacing: Theme.textSpacing) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 20, weight: .regular))
                    .frame(height: 24)
                Text(tab.title)
                    .labelText(small: true)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .fixedControlTypeSize()
            .foregroundStyle(isSelected ? Theme.ink : Theme.inkSecondary)
            .padding(.vertical, Theme.textSpacing)
            .frame(maxWidth: .infinity, minHeight: Theme.buttonMinHeight)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Theme.ink.opacity(Theme.fillOpacity))
                        .matchedGeometryEffect(id: "indicator", in: indicator)
                }
            }
            .contentShape(Capsule())
            .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityRemoveTraits(isSelected ? [] : .isSelected)
        .accessibilityShowsLargeContentViewer {
            Label(tab.title, systemImage: tab.systemImage)
        }
        .accessibilityIdentifier(tab.identifier)
    }
}

#Preview {
    @Previewable @State var tab = AppTab.today
    VStack(spacing: 0) {
        Spacer()
        PaperTabBar(selection: $tab)
    }
    .background { PaperBackground() }
}
