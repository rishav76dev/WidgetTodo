import Foundation

public enum TaskGroup: String, CaseIterable, Sendable {
    case overdue, today, tomorrow, upcoming, noDate, completed

    public var title: String {
        switch self {
        case .overdue: "Overdue"
        case .today: "Today"
        case .tomorrow: "Tomorrow"
        case .upcoming: "Upcoming"
        case .noDate: "No date"
        case .completed: "Completed"
        }
    }
}

public struct GroupedTasks: Equatable, Sendable {
    public var group: TaskGroup
    public var tasks: [TaskSnapshot]

    public init(group: TaskGroup, tasks: [TaskSnapshot]) {
        self.group = group
        self.tasks = tasks
    }
}

public enum TaskGrouping {
    /// Timed tasks are overdue once their instant passes; all-day tasks only from the day after.
    public static func isOverdue(_ t: TaskSnapshot, now: Date, calendar: Calendar) -> Bool {
        guard !t.isCompleted, let due = t.dueDate else { return false }
        if t.hasDueTime { return due < now }
        return calendar.startOfDay(for: due) < calendar.startOfDay(for: now)
    }

    public static func group(of t: TaskSnapshot, now: Date, calendar: Calendar) -> TaskGroup {
        if t.isCompleted { return .completed }
        guard let due = t.dueDate else { return .noDate }
        if isOverdue(t, now: now, calendar: calendar) { return .overdue }
        if calendar.isDate(due, inSameDayAs: now) { return .today }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)),
           calendar.isDate(due, inSameDayAs: tomorrow) {
            return .tomorrow
        }
        return .upcoming
    }

    /// Non-empty groups in `TaskGroup` case order; open groups use `sortedOpen` order, completed is newest first.
    public static func grouped(_ tasks: [TaskSnapshot], now: Date, calendar: Calendar) -> [GroupedTasks] {
        let open = sortedOpen(tasks, now: now, calendar: calendar)
        let completed = tasks.filter(\.isCompleted).sorted { lhs, rhs in
            (lhs.completedAt ?? .distantPast) > (rhs.completedAt ?? .distantPast)
        }
        var buckets: [TaskGroup: [TaskSnapshot]] = [.completed: completed]
        for t in open {
            buckets[group(of: t, now: now, calendar: calendar), default: []].append(t)
        }
        return TaskGroup.allCases.compactMap { group in
            guard let tasks = buckets[group], !tasks.isEmpty else { return nil }
            return GroupedTasks(group: group, tasks: tasks)
        }
    }

    /// Open tasks by due date (undated last), then `sortIndex`, then `createdAt`.
    public static func sortedOpen(_ tasks: [TaskSnapshot], now: Date, calendar: Calendar) -> [TaskSnapshot] {
        tasks.filter { !$0.isCompleted }.sorted { lhs, rhs in
            switch (lhs.dueDate, rhs.dueDate) {
            case let (l?, r?) where l != r: return l < r
            case (.some, nil): return true
            case (nil, .some): return false
            default: break
            }
            if lhs.sortIndex != rhs.sortIndex { return lhs.sortIndex < rhs.sortIndex }
            return lhs.createdAt < rhs.createdAt
        }
    }
}
