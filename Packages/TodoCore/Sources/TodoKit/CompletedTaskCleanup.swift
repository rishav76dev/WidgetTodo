import Foundation

public enum CompletedTaskCleanup {
    /// Completed tasks whose `completedAt` is at least `retentionDays` days before `now`.
    /// A completed task without `completedAt` is never deleted.
    public static func idsToDelete(
        _ tasks: [TaskSnapshot],
        now: Date,
        retentionDays: Int = AppConstants.completedRetentionDays,
        calendar: Calendar
    ) -> [UUID] {
        guard let cutoff = calendar.date(byAdding: .day, value: -retentionDays, to: now) else { return [] }
        return tasks.compactMap { t in
            guard t.isCompleted, let completedAt = t.completedAt, completedAt <= cutoff else { return nil }
            return t.id
        }
    }
}
