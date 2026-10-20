import AppIntents

/// Siri, Shortcuts and Action button phrases. String parameters can't appear in phrases, so Siri asks for the title.
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "Add a task in \(.applicationName)",
                "Add a task to \(.applicationName)",
                "New \(.applicationName) task",
            ],
            shortTitle: "Add Task",
            systemImageName: "plus.circle"
        )
    }
}
