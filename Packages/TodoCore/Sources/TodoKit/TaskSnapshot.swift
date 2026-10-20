import Foundation

/// A plain value copy of a task, so logic, the widget and intents never touch SwiftData objects.
public struct TaskSnapshot: Identifiable, Hashable, Codable, Sendable {
    public var id: UUID
    public var title: String
    public var notes: String
    public var dueDate: Date?
    /// `false` means the task is all-day on `dueDate`'s calendar day.
    public var hasDueTime: Bool
    public var repeatRule: RepeatRule
    public var isCompleted: Bool
    public var completedAt: Date?
    public var listID: UUID?
    public var listName: String
    public var sortIndex: Int
    public var createdAt: Date

    public init(
        id: UUID,
        title: String,
        notes: String = "",
        dueDate: Date?,
        hasDueTime: Bool = false,
        repeatRule: RepeatRule = .none,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        listID: UUID? = nil,
        listName: String = "",
        sortIndex: Int = 0,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.hasDueTime = hasDueTime
        self.repeatRule = repeatRule
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.listID = listID
        self.listName = listName
        self.sortIndex = sortIndex
        self.createdAt = createdAt
    }
}
