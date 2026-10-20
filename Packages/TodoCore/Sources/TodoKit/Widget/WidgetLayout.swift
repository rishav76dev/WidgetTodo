import Foundation

public enum WidgetSize: String, Sendable {
    case small, medium, large

    public var maxRows: Int {
        switch self {
        case .small: 1
        case .medium: 3
        case .large: 7
        }
    }
}

public struct WidgetContent: Equatable, Sendable {
    public var visible: [TaskSnapshot]
    /// Open tasks that matched the filter but didn't fit; shown as "+N more".
    public var hiddenCount: Int
    public var openCount: Int

    public init(visible: [TaskSnapshot], hiddenCount: Int, openCount: Int) {
        self.visible = visible
        self.hiddenCount = hiddenCount
        self.openCount = openCount
    }
}

public enum WidgetLayout {
    /// Open tasks matching `filter`, in `sortedOpen` order, cut to `size.maxRows`.
    public static func content(
        tasks: [TaskSnapshot], filter: TaskFilter, size: WidgetSize, now: Date, calendar: Calendar
    ) -> WidgetContent {
        let matching = tasks.filter { filter.includes($0, now: now, calendar: calendar) }
        let open = TaskGrouping.sortedOpen(matching, now: now, calendar: calendar)
        let visible = Array(open.prefix(size.maxRows))
        return WidgetContent(visible: visible, hiddenCount: open.count - visible.count, openCount: open.count)
    }

    /// The earliest of the next midnight (day groups shift), the next open timed due instant
    /// (the task turns overdue) and one hour from `now`.
    public static func nextRefreshDate(tasks: [TaskSnapshot], now: Date, calendar: Calendar) -> Date {
        var candidates = [now.addingTimeInterval(3600)]
        if let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) {
            candidates.append(midnight)
        }
        let nextDue = tasks
            .filter { !$0.isCompleted && $0.hasDueTime }
            .compactMap(\.dueDate)
            .filter { $0 > now }
            .min()
        if let nextDue { candidates.append(nextDue) }
        return candidates.min()!
    }
}
