import TodoData

/// Shared intents open the store through this, so the widget never enables CloudKit mirroring.
enum TargetRole {
    static let role: ModelContainerFactory.Role = .widget
}
