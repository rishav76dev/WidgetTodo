import Foundation
import Testing
@testable import TodoKit

@Suite struct NotificationPlannerTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func task(
        _ title: String = "t", due: Date?, timed: Bool = true, completed: Bool = false, listName: String = "Work"
    ) -> TaskSnapshot {
        TaskSnapshot(
            id: UUID(), title: title, dueDate: due, hasDueTime: timed, isCompleted: completed,
            listName: listName, createdAt: date(2026, 1, 1)
        )
    }

    @Test func plansOnlyFutureTimedOpenTasks() {
        let now = date(2026, 3, 10, 12)
        let future = task("Call", due: date(2026, 3, 11, 9))
        let tasks = [
            future,
            task(due: date(2026, 3, 9, 9)),
            task(due: now),
            task(due: date(2026, 3, 12, 0), timed: false),
            task(due: date(2026, 3, 12, 9), completed: true),
            task(due: nil),
        ]
        let planned = NotificationPlanner.plan(tasks, now: now)
        #expect(planned == [PlannedNotification(taskID: future.id, fireDate: date(2026, 3, 11, 9), title: "Call", body: "Work")])
        #expect(planned[0].identifier == "task-\(future.id.uuidString)")
        #expect(planned[0].identifier.hasPrefix(NotificationPlanner.identifierPrefix))
    }

    @Test func respectsLimitSoonestFirst() {
        let now = date(2026, 3, 10, 12)
        let tasks = (1...100).reversed().map { task(due: now.addingTimeInterval(Double($0) * 3600)) }
        let planned = NotificationPlanner.plan(tasks, now: now, limit: 60)
        #expect(planned.count == 60)
        #expect(planned.map(\.fireDate) == planned.map(\.fireDate).sorted())
        #expect(planned.first?.fireDate == now.addingTimeInterval(3600))
        #expect(planned.last?.fireDate == now.addingTimeInterval(60 * 3600))
        #expect(NotificationPlanner.plan(tasks, now: now).count == AppConstants.maxScheduledNotifications)
    }

    @Test func emptyListNameBodyIsReminder() {
        let now = date(2026, 3, 10, 12)
        let planned = NotificationPlanner.plan([task(due: date(2026, 3, 11), listName: "")], now: now)
        #expect(planned.map(\.body) == ["Reminder"])
    }
}
