import Foundation
import Testing
@testable import TodoKit

@Suite struct WidgetLayoutTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 9, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func task(
        _ title: String = "t", due: Date?, timed: Bool = true, completed: Bool = false,
        listID: UUID? = nil, sortIndex: Int = 0
    ) -> TaskSnapshot {
        TaskSnapshot(
            id: UUID(), title: title, dueDate: due, hasDueTime: timed,
            isCompleted: completed, completedAt: completed ? date(2026, 3, 1) : nil,
            listID: listID, sortIndex: sortIndex, createdAt: date(2026, 1, 1)
        )
    }

    @Test func mediumShowsThreeAndCountsHidden() {
        let now = date(2026, 3, 10, 12)
        let tasks = [
            task("e", due: nil),
            task("a", due: date(2026, 3, 10, 13)),
            task("done", due: date(2026, 3, 10, 8), completed: true),
            task("c", due: date(2026, 3, 12)),
            task("b", due: date(2026, 3, 11)),
            task("d", due: date(2026, 3, 20)),
        ]
        let content = WidgetLayout.content(tasks: tasks, filter: .all, size: .medium, now: now, calendar: calendar)
        #expect(content.visible.map(\.title) == ["a", "b", "c"])
        #expect(content.hiddenCount == 2)
        #expect(content.openCount == 5)
        #expect(WidgetSize.small.maxRows == 1)
        #expect(WidgetSize.medium.maxRows == 3)
        #expect(WidgetSize.large.maxRows == 7)
    }

    @Test func smallShowsOne() {
        let now = date(2026, 3, 10, 12)
        let tasks = [task("later", due: date(2026, 3, 12)), task("first", due: date(2026, 3, 9)), task("none", due: nil)]
        let content = WidgetLayout.content(tasks: tasks, filter: .all, size: .small, now: now, calendar: calendar)
        #expect(content.visible.map(\.title) == ["first"])
        #expect(content.hiddenCount == 2)
        #expect(content.openCount == 3)

        let large = WidgetLayout.content(tasks: tasks, filter: .all, size: .large, now: now, calendar: calendar)
        #expect(large.visible.count == 3)
        #expect(large.hiddenCount == 0)
    }

    @Test func filterApplied() {
        let now = date(2026, 3, 10, 12)
        let work = UUID()
        let home = UUID()
        let tasks = [
            task("work-1", due: date(2026, 3, 11), listID: work),
            task("home-1", due: date(2026, 3, 10, 18), listID: home),
            task("work-2", due: nil, listID: work),
            task("work-done", due: nil, completed: true, listID: work),
        ]
        let byList = WidgetLayout.content(tasks: tasks, filter: .list(work), size: .large, now: now, calendar: calendar)
        #expect(byList.visible.map(\.title) == ["work-1", "work-2"])
        #expect(byList.openCount == 2)
        #expect(byList.hiddenCount == 0)

        let today = WidgetLayout.content(tasks: tasks, filter: .today, size: .large, now: now, calendar: calendar)
        #expect(today.visible.map(\.title) == ["home-1"])
        #expect(today.openCount == 1)
    }

    @Test func refreshAtNextDueTime() {
        let now = date(2026, 3, 10, 12)
        let tasks = [
            task("past", due: date(2026, 3, 10, 11)),
            task("done-soon", due: date(2026, 3, 10, 12, 5), completed: true),
            task("all-day", due: date(2026, 3, 10, 0), timed: false),
            task("later", due: date(2026, 3, 10, 12, 40)),
            task("soon", due: date(2026, 3, 10, 12, 20)),
        ]
        #expect(WidgetLayout.nextRefreshDate(tasks: tasks, now: now, calendar: calendar) == now.addingTimeInterval(20 * 60))
    }

    @Test func refreshCappedAtOneHour() {
        let now = date(2026, 3, 10, 12)
        let tasks = [task("later", due: date(2026, 3, 10, 15)), task("none", due: nil)]
        #expect(WidgetLayout.nextRefreshDate(tasks: tasks, now: now, calendar: calendar) == now.addingTimeInterval(3600))
        #expect(WidgetLayout.nextRefreshDate(tasks: [], now: now, calendar: calendar) == now.addingTimeInterval(3600))
    }

    @Test func refreshAtMidnightWhenSooner() {
        let now = date(2026, 3, 10, 23, 30)
        #expect(WidgetLayout.nextRefreshDate(tasks: [], now: now, calendar: calendar) == date(2026, 3, 11, 0))
        let dueAfterMidnight = [task("early", due: date(2026, 3, 11, 0, 10))]
        #expect(WidgetLayout.nextRefreshDate(tasks: dueAfterMidnight, now: now, calendar: calendar) == date(2026, 3, 11, 0))
    }

    @Test func sampleTasksCoverAllGroupsExceptCompleted() {
        for now in [date(2026, 3, 10, 12), date(2026, 3, 10, 23, 50), date(2026, 3, 10, 0, 0)] {
            let samples = SampleTasks.make(now: now, calendar: calendar)
            #expect(samples.count == 6)
            #expect(Set(samples.map(\.id)).count == 6)
            #expect(samples.allSatisfy { !$0.isCompleted && $0.listName == "Personal" && $0.listID != nil })
            #expect(Set(samples.compactMap(\.listID)).count == 1)
            let groups = samples.map { TaskGrouping.group(of: $0, now: now, calendar: calendar) }
            #expect(groups.filter { $0 == .overdue }.count == 1)
            #expect(groups.filter { $0 == .today }.count == 2)
            #expect(groups.filter { $0 == .tomorrow }.count == 1)
            #expect(groups.filter { $0 == .upcoming }.count == 1)
            #expect(groups.filter { $0 == .noDate }.count == 1)
            let today = samples.filter { TaskGrouping.group(of: $0, now: now, calendar: calendar) == .today }
            #expect(today.filter(\.hasDueTime).count == 1)
        }
    }

    @Test func viewModelTitles() {
        #expect(WidgetViewModel.title(for: .all, listName: nil) == "All Tasks")
        #expect(WidgetViewModel.title(for: .today, listName: "Work") == "Today")
        #expect(WidgetViewModel.title(for: .list(UUID()), listName: "Work") == "Work")
        #expect(WidgetViewModel.title(for: .list(UUID()), listName: nil) == "Tasks")
    }
}
