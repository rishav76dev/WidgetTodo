#if canImport(SwiftData)
import Foundation
import SwiftData
import TodoKit

// CloudKit rules: every attribute has a default or is optional, relationships are optional, no `.unique`.

@Model
public final class TaskList {
    public var id: UUID = UUID()
    public var name: String = ""
    public var sortIndex: Int = 0
    public var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \TaskItem.list)
    public var tasks: [TaskItem]? = []

    public init(id: UUID = UUID(), name: String, sortIndex: Int = 0, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.sortIndex = sortIndex
        self.createdAt = createdAt
    }
}

@Model
public final class TaskItem {
    public var id: UUID = UUID()
    public var title: String = ""
    public var notes: String = ""
    public var dueDate: Date?
    /// `false` means the task is all-day on `dueDate`'s calendar day.
    public var hasDueTime: Bool = false
    /// A `RepeatRule` raw value; read and write it through `repeatRule`.
    public var repeatRuleRaw: String = "none"
    public var isCompleted: Bool = false
    public var completedAt: Date?
    public var sortIndex: Int = 0
    public var createdAt: Date = Date()
    public var list: TaskList?

    /// Set `list` after inserting the item into a context, not here.
    public init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        hasDueTime: Bool = false,
        repeatRule: RepeatRule = .none,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        sortIndex: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.hasDueTime = hasDueTime
        self.repeatRuleRaw = repeatRule.rawValue
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.sortIndex = sortIndex
        self.createdAt = createdAt
    }

    public var repeatRule: RepeatRule {
        get { RepeatRule(rawOrNone: repeatRuleRaw) }
        set { repeatRuleRaw = newValue.rawValue }
    }

    public var snapshot: TaskSnapshot {
        TaskSnapshot(
            id: id,
            title: title,
            notes: notes,
            dueDate: dueDate,
            hasDueTime: hasDueTime,
            repeatRule: repeatRule,
            isCompleted: isCompleted,
            completedAt: completedAt,
            listID: list?.id,
            listName: list?.name ?? "",
            sortIndex: sortIndex,
            createdAt: createdAt
        )
    }
}
#endif
