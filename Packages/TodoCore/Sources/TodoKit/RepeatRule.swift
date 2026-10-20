import Foundation

public enum RepeatRule: String, CaseIterable, Codable, Sendable {
    case none, daily, weekdays, weekly, monthly, yearly

    /// Unknown raw values (e.g. from a newer app version via sync) fall back to `.none`.
    public init(rawOrNone raw: String) {
        self = RepeatRule(rawValue: raw) ?? .none
    }

    public var displayName: String {
        switch self {
        case .none: "Never"
        case .daily: "Daily"
        case .weekdays: "Weekdays"
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }

    private var step: (unit: Calendar.Component, value: Int)? {
        switch self {
        case .none: nil
        case .daily, .weekdays: (.day, 1)
        case .weekly: (.day, 7)
        case .monthly: (.month, 1)
        case .yearly: (.year, 1)
        }
    }

    /// The first occurrence strictly after `now`, keeping `due`'s time of day.
    /// Each candidate is offset from the original `due` (not chained), so month-end and leap-day dates don't drift.
    public func nextOccurrence(after due: Date, now: Date, calendar: Calendar) -> Date? {
        guard let step else { return nil }
        for k in 1...10_000 {
            guard let candidate = calendar.date(byAdding: step.unit, value: k * step.value, to: due) else { return nil }
            if self == .weekdays && calendar.isDateInWeekend(candidate) { continue }
            if candidate > now { return candidate }
        }
        return nil
    }
}
