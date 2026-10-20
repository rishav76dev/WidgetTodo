import AppIntents
import TodoKit

/// The widget's "Show" option: All, Today or one list. `id` is the `TaskFilter.rawValue`.
struct WidgetFilterEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Tasks to Show"
    static var defaultQuery = WidgetFilterEntityQuery()

    var id: String
    var name: String

    var filter: TaskFilter {
        TaskFilter(rawValue: id) ?? .all
    }

    init(filter: TaskFilter, name: String) {
        self.id = filter.rawValue
        self.name = name
    }

    static let allTasks = WidgetFilterEntity(filter: .all, name: "All")
    static let today = WidgetFilterEntity(filter: .today, name: "Today")

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct WidgetFilterEntityQuery: EntityQuery {
    /// Ids of lists deleted since the widget was configured resolve to nothing, so the widget falls back to All.
    @MainActor
    func entities(for identifiers: [String]) async throws -> [WidgetFilterEntity] {
        let options = Self.options()
        return identifiers.compactMap { id in options.first { $0.id == id } }
    }

    @MainActor
    func suggestedEntities() async throws -> [WidgetFilterEntity] {
        Self.options()
    }

    func defaultResult() async -> WidgetFilterEntity? {
        .allTasks
    }

    /// All, Today, then every list. If the store cannot be opened, only All and Today.
    @MainActor
    static func options() -> [WidgetFilterEntity] {
        let lists = (try? ListEntityQuery.allLists()) ?? []
        return [WidgetFilterEntity.allTasks, .today] + lists.map { WidgetFilterEntity(filter: .list($0.id), name: $0.name) }
    }
}
