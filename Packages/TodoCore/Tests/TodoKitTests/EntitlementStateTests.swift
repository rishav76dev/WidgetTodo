import Foundation
import Testing
@testable import TodoKit

@Suite struct EntitlementStateTests {
    @Test func remoteMetadataParsed() {
        let state = EntitlementState.from(isPremium: true, offeringMetadata: ["free_theme_count": 4, "theme_order": ["neon"]])
        #expect(state.isPremium)
        #expect(state.freeThemeCount == 4)
        #expect(state.themeOrder == ["neon"])
    }

    @Test func remoteMetadataGarbageFallsBack() {
        let garbage = EntitlementState.from(isPremium: false, offeringMetadata: ["free_theme_count": "lots", "theme_order": 7])
        #expect(garbage.freeThemeCount == 3)
        #expect(garbage.themeOrder == [])
        #expect(!garbage.isPremium)

        #expect(EntitlementState.from(isPremium: false, offeringMetadata: ["free_theme_count": 3.0]).freeThemeCount == 3)
        #expect(EntitlementState.from(isPremium: false, offeringMetadata: ["free_theme_count": 4.5]).freeThemeCount == 3)
        #expect(EntitlementState.from(isPremium: false, offeringMetadata: ["theme_order": ["neon", 7]]).themeOrder == [])
        #expect(EntitlementState.from(isPremium: false, offeringMetadata: [:]) == .default)
    }

    @Test func premiumExpiry() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let expiring = EntitlementState.from(isPremium: true, premiumExpiresAt: now, offeringMetadata: [:])
        #expect(expiring.premiumExpiresAt == now)
        #expect(expiring.hasPremium(at: now.addingTimeInterval(-1)))
        #expect(!expiring.hasPremium(at: now))
        #expect(EntitlementState(isPremium: true, freeThemeCount: 3, themeOrder: []).hasPremium(at: .distantFuture))
        #expect(!EntitlementState(isPremium: false, premiumExpiresAt: .distantFuture, freeThemeCount: 3, themeOrder: []).hasPremium(at: now))
    }

    @Test func defaultUsesBundledConstants() {
        #expect(EntitlementState.default == EntitlementState(isPremium: false, freeThemeCount: AppConstants.defaultFreeThemeCount, themeOrder: []))
    }
}
