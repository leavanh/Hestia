import Foundation
import StoreKit
import StoreKitTest
import Testing
@testable import Hestia

/// Phase 18.1: Kauf eines Trinkgelds gegen die StoreKit Testumgebung (`Hestia/Store.storekit`), ohne App Store Connect
/// und ohne System Dialog.
@MainActor
struct TipPurchaseTests {
    /// Startet die Testumgebung und wartet, bis sie die Produkte ausliefert (der erste Aufruf kommt manchmal leer zurück).
    private func makeSession() async throws -> SKTestSession {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Hestia/Store.storekit")
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        session.askToBuyEnabled = false
        let ids = TipTier.allCases.map { $0.productID(bundleID: Bundle.main.bundleIdentifier ?? "") }
        for _ in 0..<10 {
            if let products = try? await Product.products(for: ids), products.count == ids.count { break }
            try await Task.sleep(for: .milliseconds(200))
        }
        return session
    }

    @Test func loadsAllThreeTiersWithPrices() async throws {
        let session = try await makeSession()
        let store = TipStore()
        await store.load()
        withExtendedLifetime(session) {}
        // Der Test läuft fest auf Deutsch/Deutschland (Testplan), die App zeigt immer `displayPrice`.
        #expect(store.loading == .loaded)
        #expect(store.products[.small]?.displayPrice.contains("2,99") == true)
        #expect(store.products[.medium]?.displayPrice.contains("5,99") == true)
        #expect(store.products[.large]?.displayPrice.contains("9,99") == true)
    }

    @Test func purchaseThanksAndFinishesTheTransaction() async throws {
        let session = try await makeSession()
        let store = TipStore()
        await store.load()
        await store.purchase(.medium)
        #expect(store.thanksCount == 1)
        #expect(!store.failed)
        // Die Transaktion liegt in der Testumgebung vor und ist abgeschlossen.
        #expect(session.allTransactions().count == 1)
        var unfinished = 0
        for await result in Transaction.unfinished { _ = result; unfinished += 1 }
        #expect(unfinished == 0)
    }

    @Test func failedPurchaseShowsErrorAndNoThanks() async throws {
        let session = try await makeSession()
        let store = TipStore()
        await store.load()
        session.failTransactionsEnabled = true
        await store.purchase(.small)
        #expect(store.thanksCount == 0)
        #expect(store.failed)
    }
}
