import Foundation

public struct CompletionResult: Equatable, Sendable {
    public var isCompleted: Bool
    public var completedAt: Date?
    public var dueDate: Date?

    public init(isCompleted: Bool, completedAt: Date?, dueDate: Date?) {
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.dueDate = dueDate
    }
}

public enum TaskCompletion {
    /// Completing a repeating task with a due date advances it to the next occurrence and leaves it open,
    /// so no new record is created under sync.
    public static func toggle(isCompleted: Bool, dueDate: Date?, repeatRule: RepeatRule, now: Date, calendar: Calendar) -> CompletionResult {
        if isCompleted {
            return CompletionResult(isCompleted: false, completedAt: nil, dueDate: dueDate)
        }
        if let dueDate, let next = repeatRule.nextOccurrence(after: dueDate, now: now, calendar: calendar) {
            return CompletionResult(isCompleted: false, completedAt: nil, dueDate: next)
        }
        return CompletionResult(isCompleted: true, completedAt: now, dueDate: dueDate)
    }
}
