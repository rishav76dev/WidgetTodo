import Foundation
import Testing
@testable import TodoKit

@Suite struct TaskCompletionTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test func completingRepeatingTaskAdvancesAndStaysOpen() throws {
        let now = date(2026, 3, 10, 10)
        let due = date(2026, 3, 5)
        let result = TaskCompletion.toggle(isCompleted: false, dueDate: due, repeatRule: .daily, now: now, calendar: calendar)
        #expect(result.isCompleted == false)
        #expect(result.completedAt == nil)
        let next = try #require(result.dueDate)
        #expect(next > now)
        #expect(next == date(2026, 3, 11))
    }

    @Test func completingPlainTaskSetsCompletedAt() {
        let now = date(2026, 3, 10, 10)
        let due = date(2026, 3, 12)
        let result = TaskCompletion.toggle(isCompleted: false, dueDate: due, repeatRule: .none, now: now, calendar: calendar)
        #expect(result == CompletionResult(isCompleted: true, completedAt: now, dueDate: due))
    }

    @Test func uncompletingClearsCompletedAt() {
        let now = date(2026, 3, 10, 10)
        let due = date(2026, 3, 12)
        let result = TaskCompletion.toggle(isCompleted: true, dueDate: due, repeatRule: .daily, now: now, calendar: calendar)
        #expect(result == CompletionResult(isCompleted: false, completedAt: nil, dueDate: due))
    }

    @Test func repeatingWithoutDueDateJustCompletes() {
        let now = date(2026, 3, 10, 10)
        let result = TaskCompletion.toggle(isCompleted: false, dueDate: nil, repeatRule: .weekly, now: now, calendar: calendar)
        #expect(result == CompletionResult(isCompleted: true, completedAt: now, dueDate: nil))
    }
}
