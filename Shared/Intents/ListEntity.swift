import AppIntents
import Foundation
import TodoData

struct ListEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "List"
    static var defaultQuery = ListEntityQuery()

    var id: UUID
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct ListEntityQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [ListEntity] {
        try Self.allLists().filter { identifiers.contains($0.id) }
    }

    @MainActor
    func suggestedEntities() async throws -> [ListEntity] {
        try Self.allLists()
    }

    /// Every list, in the user's order.
    @MainActor
    static func allLists() throws -> [ListEntity] {
        // Keeps a per-call widget context alive while the fetched models are read.
        let repository = try IntentSupport.repository()
        return try withExtendedLifetime(repository) {
            try repository.lists().map { ListEntity(id: $0.id, name: $0.name) }
        }
    }
}
