import Foundation
import Testing
@testable import TodoKit

@Suite struct RepeatRuleTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 9, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    @Test func dailyNext() {
        let next = RepeatRule.daily.nextOccurrence(after: date(2026, 3, 10), now: date(2026, 3, 10, 8), calendar: calendar)
        #expect(next == date(2026, 3, 11))
    }

    @Test func overdueDailyJumpsPastNow() {
        let next = RepeatRule.daily.nextOccurrence(after: date(2026, 3, 5), now: date(2026, 3, 10, 10), calendar: calendar)
        #expect(next == date(2026, 3, 11))
    }

    @Test func weekdaysSkipsWeekend() {
        let friday = date(2026, 3, 13)
        let next = RepeatRule.weekdays.nextOccurrence(after: friday, now: friday, calendar: calendar)
        #expect(next == date(2026, 3, 16))
    }

    @Test func weeklyNext() {
        let due = date(2026, 3, 10)
        #expect(RepeatRule.weekly.nextOccurrence(after: due, now: due, calendar: calendar) == date(2026, 3, 17))
    }

    @Test func monthlyFrom31stDoesNotDrift() {
        let due = date(2026, 1, 31)
        #expect(RepeatRule.monthly.nextOccurrence(after: due, now: due, calendar: calendar) == date(2026, 2, 28))
        #expect(RepeatRule.monthly.nextOccurrence(after: due, now: date(2026, 3, 1), calendar: calendar) == date(2026, 3, 31))
    }

    @Test func yearlyLeapDay() {
        let next = RepeatRule.yearly.nextOccurrence(after: date(2028, 2, 29), now: date(2028, 3, 1), calendar: calendar)
        #expect(next == date(2029, 2, 28))
    }

    @Test func dailyAcrossDSTKeepsWallClock() {
        let due = date(2026, 3, 7)
        let next = RepeatRule.daily.nextOccurrence(after: due, now: due, calendar: calendar)
        #expect(next == date(2026, 3, 8))
        #expect(next.map { calendar.component(.hour, from: $0) } == 9)
    }

    @Test func noneReturnsNil() {
        let due = date(2026, 3, 10)
        #expect(RepeatRule.none.nextOccurrence(after: due, now: due, calendar: calendar) == nil)
    }

    @Test func unknownRawIsNone() {
        #expect(RepeatRule(rawOrNone: "fortnightly") == .none)
        #expect(RepeatRule(rawOrNone: "weekly") == .weekly)
    }

    @Test func displayNames() {
        #expect(RepeatRule.allCases.map(\.displayName) == ["Never", "Daily", "Weekdays", "Weekly", "Monthly", "Yearly"])
    }
}
