import Foundation
import Testing
@testable import TodoKit

@Suite struct TaskGroupingTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 9, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func task(
        _ title: String = "t", due: Date?, timed: Bool = true, completedAt: Date? = nil,
        sortIndex: Int = 0, createdAt: Date? = nil
    ) -> TaskSnapshot {
        TaskSnapshot(
            id: UUID(), title: title, dueDate: due, hasDueTime: timed,
            isCompleted: completedAt != nil, completedAt: completedAt,
            sortIndex: sortIndex, createdAt: createdAt ?? date(2026, 1, 1)
        )
    }

    @Test func timedTaskOverdueAfterDueInstant() {
        let t = task(due: date(2026, 3, 10, 9))
        #expect(!TaskGrouping.isOverdue(t, now: date(2026, 3, 10, 8, 59), calendar: calendar))
        #expect(!TaskGrouping.isOverdue(t, now: date(2026, 3, 10, 9), calendar: calendar))
        #expect(TaskGrouping.isOverdue(t, now: date(2026, 3, 10, 9, 1), calendar: calendar))
        #expect(TaskGrouping.group(of: t, now: date(2026, 3, 10, 9, 1), calendar: calendar) == .overdue)
        let done = task(due: date(2026, 3, 10, 9), completedAt: date(2026, 3, 10, 8))
        #expect(!TaskGrouping.isOverdue(done, now: date(2026, 3, 11), calendar: calendar))
    }

    @Test func allDayTaskNotOverdueOnItsDay() {
        let t = task(due: date(2026, 3, 10, 0), timed: false)
        #expect(!TaskGrouping.isOverdue(t, now: date(2026, 3, 10, 23, 59), calendar: calendar))
        #expect(TaskGrouping.group(of: t, now: date(2026, 3, 10, 23, 59), calendar: calendar) == .today)
        #expect(TaskGrouping.isOverdue(t, now: date(2026, 3, 11, 0, 1), calendar: calendar))
    }

    @Test func groupingOrderAndEmptyGroupsOmitted() {
        let now = date(2026, 3, 10, 12)
        let noDate = task("none", due: nil)
        let tomorrow = task("tomorrow", due: date(2026, 3, 11))
        let overdue = task("overdue", due: date(2026, 3, 9))
        let groups = TaskGrouping.grouped([noDate, tomorrow, overdue], now: now, calendar: calendar)
        #expect(groups.map(\.group) == [.overdue, .tomorrow, .noDate])
        #expect(groups.map { $0.tasks.map(\.title) } == [["overdue"], ["tomorrow"], ["none"]])
        #expect(TaskGrouping.group(of: task(due: date(2026, 3, 12)), now: now, calendar: calendar) == .upcoming)
        #expect(TaskGrouping.group(of: task(due: date(2026, 3, 10, 18)), now: now, calendar: calendar) == .today)
    }

    @Test func completedSortedNewestFirst() throws {
        let now = date(2026, 3, 10, 12)
        let older = task("older", due: nil, completedAt: date(2026, 3, 8))
        let newer = task("newer", due: date(2026, 3, 1), completedAt: date(2026, 3, 9))
        let groups = TaskGrouping.grouped([older, task("open", due: nil), newer], now: now, calendar: calendar)
        let completed = try #require(groups.last)
        #expect(completed.group == .completed)
        #expect(completed.tasks.map(\.title) == ["newer", "older"])
    }

    @Test func sortedOpenPutsNilDueLast() {
        let now = date(2026, 3, 10, 12)
        let tasks = [
            task("nil-b", due: nil, sortIndex: 1),
            task("late", due: date(2026, 3, 20)),
            task("nil-a", due: nil, sortIndex: 0),
            task("done", due: date(2026, 3, 1), completedAt: date(2026, 3, 2)),
            task("early-new", due: date(2026, 3, 5), createdAt: date(2026, 2, 2)),
            task("early-old", due: date(2026, 3, 5), createdAt: date(2026, 2, 1)),
        ]
        #expect(TaskGrouping.sortedOpen(tasks, now: now, calendar: calendar).map(\.title)
            == ["early-old", "early-new", "late", "nil-a", "nil-b"])
    }
}
