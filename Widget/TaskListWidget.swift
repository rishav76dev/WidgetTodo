import AppIntents
import SwiftUI
import TodoKit
import TodoUI
import WidgetKit

struct TaskListWidget: Widget {
    static let kind = "TaskListWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: TaskListConfigurationIntent.self, provider: TaskListProvider()) { entry in
            TaskListWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    ThemedBackground(theme: entry.theme)
                }
        }
        .configurationDisplayName("Tasks")
        .description("See, add and tick off tasks right from your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct TaskListWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TaskListEntry

    private var size: WidgetSize { WidgetSize(family) }

    /// Small widgets can't hold links, so one URL covers the whole widget.
    /// With a locked theme, taps outside the rows and "+" lead to the theme gallery.
    private var widgetURL: URL? {
        if entry.model.isLockedFallback { return DeepLink.themes.url }
        return size == .small ? DeepLink.quickAdd(entry.model.filter).url : nil
    }

    var body: some View {
        let theme = entry.theme
        let isSmall = size == .small
        TaskListWidgetView(
            model: entry.model,
            theme: theme,
            size: size,
            checkbox: { task in
                AnyView(
                    Button(intent: ToggleTaskIntent(taskID: task.id.uuidString)) {
                        ThemedCheckbox(theme: theme, isCompleted: task.isCompleted)
                    }
                    .buttonStyle(.plain)
                )
            },
            addLink: DeepLink.quickAdd(entry.model.filter).url,
            taskLink: { task in isSmall ? nil : DeepLink.task(task.id).url }
        )
        .widgetURL(widgetURL)
    }
}

#Preview(as: .systemMedium) {
    TaskListWidget()
} timeline: {
    TaskListProvider.sampleEntry(configuration: TaskListConfigurationIntent(), size: .medium)
}
