import SwiftData
import TodoData
import WidgetKit

/// Helpers shared by the intents, which run in the app or the widget depending on who triggers them.
enum IntentSupport {
    /// The context the app's UI currently reads and writes. The app sets it at launch and whenever it swaps in a
    /// fresh context, so intents run in the app share one context with @Query views. Unused in the widget.
    @MainActor static var appContext: ModelContext?

    /// A repository on the current process's shared container (CloudKit-mirrored in the app, local in the widget).
    /// The app uses the UI's context so @Query views see the change at once. The long-lived widget process
    /// gets a fresh context per call, so it reads what the app saved since instead of objects cached earlier.
    @MainActor
    static func repository() throws -> TaskRepository {
        let container = try ModelContainerFactory.shared(role: TargetRole.role)
        switch TargetRole.role {
        case .app: return TaskRepository(context: appContext ?? container.mainContext)
        case .widget: return TaskRepository(context: ModelContext(container))
        }
    }

    static func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
