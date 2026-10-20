import AppIntents
import TodoKit

/// A widget theme option. Locked themes stay selectable; the widget then shows its unlock fallback.
struct ThemeEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Theme"
    static var defaultQuery = ThemeEntityQuery()

    var id: String
    var name: String
    var isLocked: Bool

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)\(isLocked ? " 🔒" : "")")
    }
}

struct ThemeEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ThemeEntity] {
        let themes = Self.allThemes()
        return identifiers.compactMap { id in themes.first { $0.id == id } }
    }

    func suggestedEntities() async throws -> [ThemeEntity] {
        Self.allThemes()
    }

    /// The app's current theme, so new widgets match the app.
    func defaultResult() async -> ThemeEntity? {
        let themes = Self.allThemes()
        let selected = SharedStore.appGroup().loadPreferences().appThemeID
        return themes.first { $0.id == selected }
            ?? themes.first { $0.id == AppConstants.defaultThemeID }
            ?? themes.first
    }

    /// The catalogue in the remote display order, with lock state from the cached entitlements.
    static func allThemes() -> [ThemeEntity] {
        let catalog = ThemeCatalog.bundled
        let state = SharedStore.appGroup().loadEntitlements()
        let free = Set(ThemeAccess.freeThemeIDs(catalog: catalog, state: state))
        return catalog.ordered(by: state.themeOrder).map { theme in
            ThemeEntity(id: theme.id, name: theme.name, isLocked: !state.isPremium && !free.contains(theme.id))
        }
    }
}
