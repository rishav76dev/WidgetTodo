import Foundation
import Testing
@testable import TodoKit

@Suite struct SharedStoreTests {
    @Test func missingDataReturnsDefaults() {
        let store = SharedStore(store: InMemoryKeyValueStore())
        #expect(store.loadEntitlements() == .default)
        #expect(store.loadPreferences() == AppPreferences())
    }

    @Test func roundTripsEntitlementsAndPreferences() {
        let backing = InMemoryKeyValueStore()
        let store = SharedStore(store: backing)
        let entitlements = EntitlementState(
            isPremium: true, premiumExpiresAt: Date(timeIntervalSince1970: 1_800_000_000), freeThemeCount: 5, themeOrder: ["neon", "zen"]
        )
        let preferences = AppPreferences(appThemeID: "midnight", hasCompletedOnboarding: true, notificationsEnabled: false, hasAskedNotificationPermission: true)
        store.saveEntitlements(entitlements)
        store.savePreferences(preferences)

        #expect(backing.readData(forKey: "entitlements.v1") != nil)
        #expect(backing.readData(forKey: "preferences.v1") != nil)

        let reopened = SharedStore(store: backing)
        #expect(reopened.loadEntitlements() == entitlements)
        #expect(reopened.loadPreferences() == preferences)
    }

    @Test func corruptStoredDataReturnsDefaults() {
        let backing = InMemoryKeyValueStore()
        backing.writeData(Data("{oops".utf8), forKey: "entitlements.v1")
        backing.writeData(Data("{oops".utf8), forKey: "preferences.v1")
        let store = SharedStore(store: backing)
        #expect(store.loadEntitlements() == .default)
        #expect(store.loadPreferences() == AppPreferences())
    }

    @Test func partialPreferencesUseDefaults() throws {
        let backing = InMemoryKeyValueStore()
        backing.writeData(Data(#"{"hasCompletedOnboarding":true,"notificationsEnabled":"yes"}"#.utf8), forKey: "preferences.v1")
        backing.writeData(Data(#"{"isPremium":true,"premiumExpiresAt":"soon"}"#.utf8), forKey: "entitlements.v1")
        let store = SharedStore(store: backing)
        let preferences = store.loadPreferences()
        #expect(preferences.hasCompletedOnboarding)
        #expect(preferences.appThemeID == AppConstants.defaultThemeID)
        #expect(preferences.notificationsEnabled)
        #expect(!preferences.hasAskedNotificationPermission)
        #expect(store.loadEntitlements() == EntitlementState(isPremium: true, freeThemeCount: AppConstants.defaultFreeThemeCount, themeOrder: []))
    }

    @Test func writingNilRemovesValue() {
        let backing = InMemoryKeyValueStore()
        backing.writeData(Data("x".utf8), forKey: "k")
        backing.writeData(nil, forKey: "k")
        #expect(backing.readData(forKey: "k") == nil)
    }
}
