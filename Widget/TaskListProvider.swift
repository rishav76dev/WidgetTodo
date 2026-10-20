import Foundation
import TodoData
import TodoKit
import WidgetKit

struct TaskListEntry: TimelineEntry {
    let date: Date
    let model: WidgetViewModel
    let theme: Theme
}

struct TaskListProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TaskListEntry {
        Self.sampleEntry(configuration: TaskListConfigurationIntent(), size: WidgetSize(context.family))
    }

    /// The widget gallery gets sample tasks; a placed widget gets its real tasks.
    func snapshot(for configuration: TaskListConfigurationIntent, in context: Context) async -> TaskListEntry {
        if context.isPreview {
            return Self.sampleEntry(configuration: configuration, size: WidgetSize(context.family))
        }
        return await timeline(for: configuration, in: context).entries.first
            ?? Self.sampleEntry(configuration: configuration, size: WidgetSize(context.family))
    }

    func timeline(for configuration: TaskListConfigurationIntent, in context: Context) async -> Timeline<TaskListEntry> {
        let now = Date()
        let calendar = Calendar.current
        let size = WidgetSize(context.family)
        let tasks = await Self.loadSnapshots()
        let entry = Self.entry(
            tasks: tasks ?? [],
            configuration: configuration,
            size: size,
            now: now,
            calendar: calendar,
            titleOverride: tasks == nil ? "Open Todo1 to finish setup" : nil
        )
        let refresh = WidgetLayout.nextRefreshDate(tasks: tasks ?? [], now: now, calendar: calendar)
        return Timeline(entries: [entry], policy: .after(refresh))
    }

    /// Nil when the store can't be opened (e.g. the app has never run).
    @MainActor
    private static func loadSnapshots() -> [TaskSnapshot]? {
        try? IntentSupport.repository().snapshots()
    }

    /// Sample tasks for the gallery and previews. They live in their own list, so a list filter
    /// shows them all under the configured list's name.
    static func sampleEntry(configuration: TaskListConfigurationIntent, size: WidgetSize, now: Date = Date()) -> TaskListEntry {
        let configured = configuration.filter?.filter ?? .all
        let filter: TaskFilter = configured == .today ? .today : .all
        var title = WidgetViewModel.title(for: filter, listName: nil)
        if case .list = configured { title = configuration.filter?.name ?? title }
        return entry(
            tasks: SampleTasks.make(now: now, calendar: .current),
            filter: filter,
            themeID: configuration.theme?.id,
            size: size,
            now: now,
            calendar: .current,
            title: title
        )
    }

    static func entry(
        tasks: [TaskSnapshot],
        configuration: TaskListConfigurationIntent,
        size: WidgetSize,
        now: Date,
        calendar: Calendar,
        titleOverride: String?
    ) -> TaskListEntry {
        let filter = configuration.filter?.filter ?? .all
        var listName: String?
        if case .list(let id) = filter {
            // The stored entity name goes stale after a rename; prefer the live one.
            listName = tasks.first { $0.listID == id }?.listName ?? configuration.filter?.name
        }
        return entry(
            tasks: tasks,
            filter: filter,
            themeID: configuration.theme?.id,
            size: size,
            now: now,
            calendar: calendar,
            title: titleOverride ?? WidgetViewModel.title(for: filter, listName: listName)
        )
    }

    /// A nil `themeID` uses the app's theme; a locked one falls back to a free theme.
    private static func entry(
        tasks: [TaskSnapshot],
        filter: TaskFilter,
        themeID: String?,
        size: WidgetSize,
        now: Date,
        calendar: Calendar,
        title: String
    ) -> TaskListEntry {
        let store = SharedStore.appGroup()
        let resolved = ThemeAccess.effectiveTheme(
            selectedID: themeID ?? store.loadPreferences().appThemeID,
            catalog: .bundled,
            state: store.loadEntitlements()
        )
        // Focus themes show a single task, so count the rest as hidden.
        let rowSize: WidgetSize = resolved.theme.layout == .focus ? .small : size
        let content = WidgetLayout.content(tasks: tasks, filter: filter, size: rowSize, now: now, calendar: calendar)
        let model = WidgetViewModel(
            title: title,
            filter: filter,
            content: content,
            isLockedFallback: resolved.isLockedFallback,
            now: now
        )
        return TaskListEntry(date: now, model: model, theme: resolved.theme)
    }
}

extension WidgetSize {
    init(_ family: WidgetFamily) {
        switch family {
        case .systemSmall: self = .small
        case .systemLarge, .systemExtraLarge: self = .large
        default: self = .medium
        }
    }
}
