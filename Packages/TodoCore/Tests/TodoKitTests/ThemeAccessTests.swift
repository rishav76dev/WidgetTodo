import Foundation
import Testing
@testable import TodoKit

@Suite struct ThemeAccessTests {
    let catalog = ThemeCatalog.bundled

    private func state(premium: Bool = false, free: Int = 3, order: [String] = []) -> EntitlementState {
        EntitlementState(isPremium: premium, freeThemeCount: free, themeOrder: order)
    }

    @Test func freeCountClamped() {
        #expect(ThemeAccess.freeThemeIDs(catalog: catalog, state: state(free: -5)) == ["paper"])
        #expect(ThemeAccess.freeThemeIDs(catalog: catalog, state: state(free: 0)) == ["paper"])
        #expect(ThemeAccess.freeThemeIDs(catalog: catalog, state: state(free: 99)).count == 12)
        #expect(ThemeAccess.freeThemeIDs(catalog: ThemeCatalog(themes: []), state: state(free: 3)) == [])
    }

    @Test func premiumUnlocksAll() {
        let premium = state(premium: true, free: 0)
        for theme in catalog.themes {
            #expect(ThemeAccess.isUnlocked(themeID: theme.id, catalog: catalog, state: premium))
        }
    }

    @Test func firstThreeFreeByDefault() {
        #expect(ThemeAccess.freeThemeIDs(catalog: catalog, state: .default) == ["paper", "midnight", "mono-mint"])
        for id in ["paper", "midnight", "mono-mint"] {
            #expect(ThemeAccess.isUnlocked(themeID: id, catalog: catalog, state: .default))
        }
        #expect(!ThemeAccess.isUnlocked(themeID: "terminal", catalog: catalog, state: .default))
        #expect(!ThemeAccess.isUnlocked(themeID: "bogus", catalog: catalog, state: .default))
    }

    @Test func remoteOrderChangesWhichAreFree() {
        let remote = state(free: 2, order: ["neon", "bogus", "zen"])
        #expect(ThemeAccess.freeThemeIDs(catalog: catalog, state: remote) == ["neon", "zen"])
        #expect(ThemeAccess.isUnlocked(themeID: "neon", catalog: catalog, state: remote))
        #expect(!ThemeAccess.isUnlocked(themeID: "paper", catalog: catalog, state: remote))
    }

    @Test func lockedSelectionFallsBackWithFlag() {
        let result = ThemeAccess.effectiveTheme(selectedID: "neon", catalog: catalog, state: .default)
        #expect(result.theme.id == "paper")
        #expect(result.isLockedFallback)

        let premium = ThemeAccess.effectiveTheme(selectedID: "neon", catalog: catalog, state: state(premium: true))
        #expect(premium.theme.id == "neon")
        #expect(!premium.isLockedFallback)

        let free = ThemeAccess.effectiveTheme(selectedID: "midnight", catalog: catalog, state: .default)
        #expect(free.theme.id == "midnight")
        #expect(!free.isLockedFallback)
    }

    @Test func nilSelectionNoFlag() {
        let result = ThemeAccess.effectiveTheme(selectedID: nil, catalog: catalog, state: .default)
        #expect(result.theme.id == "paper")
        #expect(!result.isLockedFallback)

        let remote = ThemeAccess.effectiveTheme(selectedID: nil, catalog: catalog, state: state(order: ["zen"]))
        #expect(remote.theme.id == "zen")
        #expect(!remote.isLockedFallback)

        let unknown = ThemeAccess.effectiveTheme(selectedID: "deleted-theme", catalog: catalog, state: .default)
        #expect(unknown.theme.id == "paper")
        #expect(!unknown.isLockedFallback)

        let empty = ThemeAccess.effectiveTheme(selectedID: "neon", catalog: ThemeCatalog(themes: []), state: .default)
        #expect(empty.theme == Theme.fallback)
    }
}
