import Foundation
import Testing
@testable import Hestia

/// Phase 18.1: Bewertungs-URL aus der App ID und Produkt IDs des Trinkgelds.
struct SupportTests {
    @Test func reviewURLIsBuiltFromAppID() {
        #expect(ReviewLink.url(appID: "1234567890")?.absoluteString
                == "https://apps.apple.com/app/id1234567890?action=write-review")
    }

    @Test func noAppIDMeansNoReviewURL() {
        #expect(ReviewLink.url(appID: "") == nil)
        #expect(ReviewLink.url(appID: "abc") == nil)
        // Solange die App nicht in App Store Connect angelegt ist, ist die Konstante leer.
        #expect(ReviewLink.url() == ReviewLink.url(appID: ReviewLink.appID))
    }

    @Test func tipProductIDsMatchBundleIDInOrder() throws {
        let bundleID = try #require(Bundle.main.bundleIdentifier)
        #expect(TipTier.allCases == [.small, .medium, .large])
        #expect(TipTier.allCases.map { $0.productID(bundleID: bundleID) } == [
            "de.vanheyden.Hestia.tip.small", "de.vanheyden.Hestia.tip.medium", "de.vanheyden.Hestia.tip.large",
        ])
        #expect(bundleID == "de.vanheyden.Hestia")
    }
}
