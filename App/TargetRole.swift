import TodoData

/// Shared intents open the store through this; only the app enables CloudKit mirroring.
enum TargetRole {
    static let role: ModelContainerFactory.Role = .app
}
