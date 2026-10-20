import AppIntents
import TodoData
import TodoKit

/// Adds a task from Siri, Shortcuts or the Action button without opening the app.
struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Task"
    static var description = IntentDescription("Adds a task to Todo1 without opening the app.")
    static var openAppWhenRun = false

    @Parameter(title: "Task", requestValueDialog: "What do you need to do?")
    var taskTitle: String

    @Parameter(title: "List")
    var list: ListEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$taskTitle) to \(\.$list)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let title = TaskTitle.normalized(taskTitle) else {
            throw $taskTitle.needsValueError("What do you need to do?")
        }
        _ = try IntentSupport.repository().addTask(
            title: title,
            dueDate: nil,
            hasDueTime: false,
            repeatRule: RepeatRule.none,
            listID: list?.id
        )
        IntentSupport.reloadWidgets()
        return .result(dialog: "Added “\(title)”")
    }
}
