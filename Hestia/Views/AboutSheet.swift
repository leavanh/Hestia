import SwiftUI

/// Eine eingebettete Schrift mit Lizenz (Spezifikation 5.5, Über).
struct AboutFont: Identifiable, Hashable {
    let name: String
    let author: String
    /// Name der mitgelieferten Lizenzdatei ohne Endung.
    let licenseFile: String

    var id: String { name }

    static let all = [
        AboutFont(name: "Barlow Condensed", author: "The Barlow Project Authors", licenseFile: "OFL-BarlowCondensed"),
        AboutFont(name: "Antonio", author: "The Antonio Project Authors", licenseFile: "OFL-Antonio"),
        AboutFont(name: "Geist Mono", author: "The Geist Project Authors", licenseFile: "OFL-GeistMono"),
    ]

    static let licenseName = "SIL Open Font License 1.1"

    /// Voller Lizenztext aus der Datei im Bundle. Fehlt sie, steht ein Hinweis da.
    var licenseText: String {
        guard let url = Bundle.main.url(forResource: licenseFile, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "Der Lizenztext liegt nicht in der App."
        }
        return text
    }
}

/// Ein Stich in der App mit Quelle (Branding/QUELLEN.md).
struct AboutImage: Identifiable {
    let title: String
    var id: String { title }

    static let source = "The Metropolitan Museum of Art"
    static let licenseName = "CC0"

    static let all = [
        AboutImage(title: "Man with Torch between Flaming Altar and Statuette"),
        AboutImage(title: "A Vestal Virgin (?)"),
    ]
}

/// Sheet "Über" (Spezifikation 5.5): die Schriften mit Lizenz und die Bildquellen. Tippen auf eine Schrift zeigt den
/// vollen Lizenztext.
struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var shownFont: AboutFont?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.sectionSpacing) {
                    PaperSection(title: "Schriften") {
                        VStack(alignment: .leading, spacing: Theme.spacing) {
                            ForEach(AboutFont.all) { font in
                                fontRow(font)
                            }
                        }
                    }
                    PaperSection(title: "Bilder") {
                        VStack(alignment: .leading, spacing: Theme.spacing) {
                            ForEach(AboutImage.all) { image in
                                imageRow(image)
                            }
                        }
                    }
                }
                .padding(Theme.spacing)
            }
            .background { PaperBackground() }
            .navigationTitle("Über")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig", systemImage: "checkmark", role: .confirm) {
                        dismiss()
                    }
                    .accessibilityIdentifier("about-done")
                }
            }
            .navigationDestination(item: $shownFont) { font in
                LicenseView(font: font)
            }
        }
    }

    private func fontRow(_ font: AboutFont) -> some View {
        Button {
            shownFont = font
        } label: {
            HStack(spacing: Theme.controlSpacing) {
                VStack(alignment: .leading, spacing: Theme.textSpacing) {
                    Text(font.name).titleText()
                    Text("\(font.author) · \(AboutFont.licenseName)")
                        .metaText()
                        .foregroundStyle(Theme.inkSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(Theme.Typography.symbolSmall)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Theme.ink)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("about-font-\(font.name)")
    }

    private func imageRow(_ image: AboutImage) -> some View {
        VStack(alignment: .leading, spacing: Theme.textSpacing) {
            Text(image.title).titleText()
            Text("\(AboutImage.source) · \(AboutImage.licenseName)")
                .metaText()
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("about-image-\(image.title)")
    }
}

/// Voller Lizenztext einer Schrift in Rolle `body`, scrollbar.
private struct LicenseView: View {
    let font: AboutFont

    var body: some View {
        ScrollView {
            Text(font.licenseText)
                .bodyText()
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.spacing)
                .accessibilityIdentifier("about-license-text")
        }
        .background { PaperBackground() }
        .navigationTitle(font.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AboutSheet()
}
