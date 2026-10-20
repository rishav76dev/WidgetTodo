import Foundation

public struct PlannedNotification: Equatable, Sendable {
    public var taskID: UUID
    public var fireDate: Date
    public var title: String
    public var body: String

    public init(taskID: UUID, fireDate: Date, title: String, body: String) {
        self.taskID = taskID
        self.fireDate = fireDate
        self.title = title
        self.body = body
    }

    public var identifier: String { NotificationPlanner.identifierPrefix + taskID.uuidString }
}

public enum NotificationPlanner {
    public static let identifierPrefix = "task-"

    /// The soonest `limit` reminders for open timed tasks due after `now` (iOS keeps at most 64 pending).
    public static func plan(
        _ tasks: [TaskSnapshot],
        now: Date,
        limit: Int = AppConstants.maxScheduledNotifications
    ) -> [PlannedNotification] {
        let planned = tasks.compactMap { t -> PlannedNotification? in
            guard !t.isCompleted, t.hasDueTime, let due = t.dueDate, due > now else { return nil }
            return PlannedNotification(
                taskID: t.id, fireDate: due, title: t.title, body: t.listName.isEmpty ? "Reminder" : t.listName
            )
        }
        .sorted { ($0.fireDate, $0.taskID.uuidString) < ($1.fireDate, $1.taskID.uuidString) }
        return Array(planned.prefix(max(0, limit)))
    }
}
