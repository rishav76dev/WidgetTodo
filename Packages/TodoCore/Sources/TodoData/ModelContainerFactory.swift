#if canImport(SwiftData)
import Foundation
import SwiftData
import TodoKit

public enum ModelContainerFactory {
    /// The app syncs through CloudKit; the widget opens the same App Group store locally.
    public enum Role { case app, widget }

    public static let schema = Schema([TaskList.self, TaskItem.self])

    private static let lock = NSLock()
    private static var containers: [Role: ModelContainer] = [:]

    /// The store in the App Group container, or Application Support when the group is unavailable.
    public static var storeURL: URL {
        let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID)
            ?? URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("Todo1.store")
    }

    public static func make(role: Role, inMemory: Bool = false) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        } else {
            let database: ModelConfiguration.CloudKitDatabase = switch role {
            case .app: .private(AppConstants.iCloudContainerID)
            case .widget: .none
            }
            configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: database)
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// One container per role for the lifetime of the process.
    public static func shared(role: Role) throws -> ModelContainer {
        lock.lock()
        defer { lock.unlock() }
        if let container = containers[role] { return container }
        let container = try make(role: role)
        containers[role] = container
        return container
    }
}
#endif
