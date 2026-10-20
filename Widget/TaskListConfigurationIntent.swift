import AppIntents
import WidgetKit

struct TaskListConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Tasks"
    static var description = IntentDescription("Choose which tasks and theme this widget shows.")

    /// Nil means All.
    @Parameter(title: "Show")
    var filter: WidgetFilterEntity?

    /// Nil means the app's current theme.
    @Parameter(title: "Theme")
    var theme: ThemeEntity?

    init() {}
}
