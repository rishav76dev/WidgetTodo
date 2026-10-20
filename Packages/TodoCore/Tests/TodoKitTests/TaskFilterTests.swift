import Foundation
import Testing
@testable import TodoKit

@Suite struct TaskFilterTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func task(due: Date?, timed: Bool = true, listID: UUID? = nil) -> TaskSnapshot {
        TaskSnapshot(id: UUID(), title: "t", dueDate: due, hasDueTime: timed, listID: listID, createdAt: date(2026, 1, 1))
    }

    @Test func todayFilterIncludesOverdueAndToday() {
        let now = date(2026, 3, 10, 12)
        #expect(TaskFilter.today.includes(task(due: date(2026, 3, 8)), now: now, calendar: calendar))
        #expect(TaskFilter.today.includes(task(due: date(2026, 3, 10, 18)), now: now, calendar: calendar))
        #expect(TaskFilter.today.includes(task(due: date(2026, 3, 10, 0), timed: false), now: now, calendar: calendar))
        #expect(!TaskFilter.today.includes(task(due: date(2026, 3, 11)), now: now, calendar: calendar))
        #expect(!TaskFilter.today.includes(task(due: nil), now: now, calendar: calendar))
        #expect(TaskFilter.all.includes(task(due: nil), now: now, calendar: calendar))
    }

    @Test func listFilterMatchesListID() {
        let now = date(2026, 3, 10, 12)
        let listID = UUID()
        #expect(TaskFilter.list(listID).includes(task(due: nil, listID: listID), now: now, calendar: calendar))
        #expect(!TaskFilter.list(listID).includes(task(due: nil, listID: UUID()), now: now, calendar: calendar))
        #expect(!TaskFilter.list(listID).includes(task(due: nil), now: now, calendar: calendar))
    }

    @Test func filterRawValueRoundTrips() throws {
        let listID = UUID()
        for filter in [TaskFilter.all, .today, .list(listID)] {
            #expect(TaskFilter(rawValue: filter.rawValue) == filter)
            let data = try JSONEncoder().encode([filter])
            #expect(try JSONDecoder().decode([TaskFilter].self, from: data) == [filter])
        }
        #expect(TaskFilter.all.rawValue == "all")
        #expect(TaskFilter.today.rawValue == "today")
        #expect(TaskFilter.list(listID).rawValue == listID.uuidString)
        #expect(TaskFilter(rawValue: "bogus") == nil)
    }
}
