import StoreKit
import SwiftUI

/// Sheet "Unterstützen" (Spezifikation Phase 18.1): Trinkgeld Klein, Mittel, Groß als In-App-Kauf. Das Trinkgeld
/// schaltet nichts frei.
struct SupportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = TipStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                    Text("Hestia ist kostenlos, ohne Werbung und ohne Konto. Wer die Entwicklung unterstützen möchte, kann ein Trinkgeld geben. Es schaltet nichts frei.")
                        .bodyText()
                    PaperSection(title: "Trinkgeld") {
                        ForEach(TipTier.allCases, id: \.self) { tier in
                            row(tier)
                        }
                        status
                            .padding(.top, Theme.inlineSpacing)
                    }
                }
                .padding(Theme.spacing)
            }
            .background { PaperBackground() }
            .navigationTitle("Unterstützen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen", systemImage: "xmark", role: .cancel) {
                        dismiss()
                    }
                    .accessibilityIdentifier("support-close")
                }
            }
            .sensoryFeedback(.success, trigger: store.thanksCount)
        }
        .task { await store.load() }
    }

    private func row(_ tier: TipTier) -> some View {
        let product = store.products[tier]
        return HStack(spacing: Theme.controlSpacing) {
            Text(verbatim: tier.title)
                .bodyText()
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                Task { await store.purchase(tier) }
            } label: {
                Text(verbatim: product?.displayPrice ?? "–").labelText()
            }
            .buttonStyle(.hermes(.quiet))
            .disabled(product == nil || store.isPurchasing)
            .accessibilityLabel(Text(verbatim: "\(tier.title) \(product?.displayPrice ?? "")"))
            .accessibilityIdentifier("support-tip-\(tier.rawValue)")
        }
        .frame(minHeight: Theme.controlSize)
        .padding(.vertical, Theme.textSpacing)
    }

    /// Meldung unter den Zeilen: Danke nach einem Kauf, sonst ein Hinweis bei Fehler oder fehlenden Produkten.
    @ViewBuilder
    private var status: some View {
        if store.thanksCount > 0 && !store.failed {
            VStack(alignment: .leading, spacing: Theme.textSpacing) {
                Text("Danke!")
                    .titleText()
                Text("Vielen Dank für die Unterstützung von Hestia.")
                    .bodyText()
                    .foregroundStyle(Theme.inkSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("support-done")
        } else if store.failed {
            Text("Der Kauf hat nicht geklappt.")
                .metaText()
                .foregroundStyle(Theme.inkSecondary)
                .accessibilityIdentifier("support-error")
        } else if store.loading == .unavailable {
            Text("Gerade nicht verfügbar")
                .metaText()
                .foregroundStyle(Theme.inkSecondary)
                .accessibilityIdentifier("support-unavailable")
        }
    }
}

#Preview {
    SupportSheet()
}
