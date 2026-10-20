import Foundation

/// Decides which themes are free, which are locked, and what to show for a locked selection.
public enum ThemeAccess {
    /// The first `freeThemeCount` themes along the remote order, clamped to the catalogue size.
    /// At least one theme is always free so the app stays usable.
    public static func freeThemeIDs(catalog: ThemeCatalog, state: EntitlementState) -> [String] {
        let ordered = catalog.ordered(by: state.themeOrder)
        let count = max(1, min(state.freeThemeCount, ordered.count))
        return ordered.prefix(count).map(\.id)
    }

    public static func isUnlocked(themeID: String, catalog: ThemeCatalog, state: EntitlementState) -> Bool {
        state.isPremium || freeThemeIDs(catalog: catalog, state: state).contains(themeID)
    }

    /// The theme to render for `selectedID`. A locked selection gives the first free theme with
    /// `isLockedFallback` set (the widget then shows its unlock footer); nil or an id no longer in the
    /// catalogue gives the first free theme without the flag.
    public static func effectiveTheme(selectedID: String?, catalog: ThemeCatalog, state: EntitlementState) -> (theme: Theme, isLockedFallback: Bool) {
        let firstFree = freeThemeIDs(catalog: catalog, state: state).first.map { catalog.theme(id: $0) } ?? .fallback
        guard let selectedID, let selected = catalog.themes.first(where: { $0.id == selectedID }) else {
            return (firstFree, false)
        }
        if isUnlocked(themeID: selectedID, catalog: catalog, state: state) {
            return (selected, false)
        }
        return (firstFree, true)
    }
}
