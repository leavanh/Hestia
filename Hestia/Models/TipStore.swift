import StoreKit
import SwiftUI

/// Lädt die drei Trinkgeld Produkte und wickelt Käufe ab (Spezifikation Phase 18.1). Es wird nichts gespeichert:
/// Käufe werden sofort abgeschlossen und schalten nichts frei.
@MainActor
@Observable
final class TipStore {
    enum Loading {
        case loading
        case loaded
        case unavailable
    }

    private(set) var loading = Loading.loading
    /// Produkte in der Reihenfolge Klein, Mittel, Groß. Fehlt eines (nicht angelegt), fehlt es hier.
    private(set) var products: [TipTier: Product] = [:]
    /// Wird nach jedem erfolgreichen Kauf hochgezählt.
    private(set) var thanksCount = 0
    private(set) var failed = false
    private(set) var isPurchasing = false

    func load() async {
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let ids = TipTier.allCases.map { $0.productID(bundleID: bundleID) }
        guard let loaded = try? await Product.products(for: ids), !loaded.isEmpty else {
            loading = .unavailable
            return
        }
        for tier in TipTier.allCases {
            products[tier] = loaded.first { $0.id == tier.productID(bundleID: bundleID) }
        }
        loading = .loaded
    }

    func purchase(_ tier: TipTier) async {
        guard let product = products[tier], !isPurchasing else { return }
        isPurchasing = true
        failed = false
        defer { isPurchasing = false }
        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                await transaction.finish()
                thanksCount += 1
            case .success(.unverified):
                failed = true
            case .pending, .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            failed = true
        }
    }

    /// Schließt Käufe ab, die außerhalb des Sheets ankommen (z.B. nach "Kaufen fragen" bei Familien). Läuft, solange die
    /// App läuft.
    nonisolated static func finishUpdates() async {
        for await update in Transaction.updates {
            if case .verified(let transaction) = update {
                await transaction.finish()
            }
        }
    }
}
