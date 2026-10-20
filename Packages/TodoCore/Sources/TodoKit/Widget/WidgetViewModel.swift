import Foundation

/// Everything one widget timeline entry renders, already resolved from storage and entitlements.
public struct WidgetViewModel: Equatable, Sendable {
    public var title: String
    public var filter: TaskFilter
    public var content: WidgetContent
    /// The configured theme is locked, so the widget shows the default theme and an unlock footer.
    public var isLockedFallback: Bool
    public var now: Date

    public init(title: String, filter: TaskFilter, content: WidgetContent, isLockedFallback: Bool, now: Date) {
        self.title = title
        self.filter = filter
        self.content = content
        self.isLockedFallback = isLockedFallback
        self.now = now
    }

    /// `listName` is only used for `.list`; nil (e.g. the list was deleted) falls back to "Tasks".
    public static func title(for filter: TaskFilter, listName: String?) -> String {
        switch filter {
        case .all: "All Tasks"
        case .today: "Today"
        case .list: listName ?? "Tasks"
        }
    }
}
