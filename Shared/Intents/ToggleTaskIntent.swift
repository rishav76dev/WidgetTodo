import AppIntents
import Foundation
import TodoData

/// The widget's checkbox action. Not shown in Shortcuts.
struct ToggleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task"
    static var isDiscoverable = false

    @Parameter(title: "Task ID")
    var taskID: String

    init() {}

    init(taskID: String) {
        self.taskID = taskID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: taskID) {
            let repository = try IntentSupport.repository()
            do {
                try repository.toggleCompletion(id: id)
            } catch RepositoryError.notFound {
                // Deleted elsewhere since the widget last refreshed; the reload below drops the row.
            }
            // Cancels the reminder of a completed task, or moves it to a repeating task's next occurrence.
            await TaskReminders.update(id: id, task: try? repository.task(id: id)?.snapshot)
        }
        IntentSupport.reloadWidgets()
        return .result()
    }
}
