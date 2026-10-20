import Foundation
import Testing
@testable import TodoKit

@Suite struct CompletedTaskCleanupTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func task(completed: Bool, completedAt: Date?) -> TaskSnapshot {
        TaskSnapshot(id: UUID(), title: "t", dueDate: nil, isCompleted: completed, completedAt: completedAt, createdAt: date(2026, 1, 1))
    }

    @Test func deletesOnlyOlderThan30Days() {
        let now = date(2026, 4, 15, 12)
        let old = task(completed: true, completedAt: calendar.date(byAdding: .day, value: -31, to: now)!)
        let exactlyThirty = task(completed: true, completedAt: calendar.date(byAdding: .day, value: -30, to: now)!)
        let recent = task(completed: true, completedAt: calendar.date(byAdding: .day, value: -29, to: now)!)
        let open = task(completed: false, completedAt: nil)
        let ids = CompletedTaskCleanup.idsToDelete([old, exactlyThirty, recent, open], now: now, calendar: calendar)
        #expect(ids == [old.id, exactlyThirty.id])
    }

    @Test func nilCompletedAtKept() {
        let now = date(2026, 4, 15, 12)
        #expect(CompletedTaskCleanup.idsToDelete([task(completed: true, completedAt: nil)], now: now, calendar: calendar).isEmpty)
    }
}
