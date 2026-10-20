import Foundation
import Testing
@testable import TodoKit

@Suite struct DueDateFormatterTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()
    private let locale = Locale(identifier: "en_US")

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func task(due: Date?, timed: Bool) -> TaskSnapshot {
        TaskSnapshot(id: UUID(), title: "t", dueDate: due, hasDueTime: timed, createdAt: date(2026, 1, 1))
    }

    private func label(_ t: TaskSnapshot, now: Date) -> String? {
        DueDateFormatter.label(for: t, now: now, calendar: calendar, locale: locale)
    }

    @Test func labelTodayWithTime() throws {
        let result = try #require(label(task(due: date(2026, 3, 10, 15), timed: true), now: date(2026, 3, 10, 8)))
        #expect(result.hasPrefix("Today, "))
        #expect(result.contains("3:00"))
    }

    @Test func labelTomorrowAllDay() {
        #expect(label(task(due: date(2026, 3, 11, 0), timed: false), now: date(2026, 3, 10, 22)) == "Tomorrow")
    }

    @Test func labelYesterdayAndOtherDates() throws {
        #expect(label(task(due: date(2026, 3, 9, 0), timed: false), now: date(2026, 3, 10)) == "Yesterday")
        let other = try #require(label(task(due: date(2026, 3, 20, 0), timed: false), now: date(2026, 3, 10)))
        #expect(other.contains("Mar"))
        #expect(other.contains("20"))
        #expect(other.contains("Fri"))
    }

    @Test func labelNilWithoutDueDate() {
        #expect(label(task(due: nil, timed: false), now: date(2026, 3, 10)) == nil)
    }
}
