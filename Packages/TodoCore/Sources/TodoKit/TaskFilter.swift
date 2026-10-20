import Foundation

public enum TaskFilter: Hashable, Codable, Sendable {
    case all, today, list(UUID)

    /// `today` covers open overdue tasks and anything due on `now`'s day.
    public func includes(_ t: TaskSnapshot, now: Date, calendar: Calendar) -> Bool {
        switch self {
        case .all:
            return true
        case .today:
            guard let due = t.dueDate else { return false }
            return calendar.isDate(due, inSameDayAs: now) || TaskGrouping.isOverdue(t, now: now, calendar: calendar)
        case .list(let id):
            return t.listID == id
        }
    }

    public var rawValue: String {
        switch self {
        case .all: "all"
        case .today: "today"
        case .list(let id): id.uuidString
        }
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "all": self = .all
        case "today": self = .today
        default:
            guard let id = UUID(uuidString: rawValue) else { return nil }
            self = .list(id)
        }
    }

    /// Encoded as its `rawValue` string, so stored filters stay readable across versions.
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard let filter = TaskFilter(rawValue: raw) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown filter \(raw)"))
        }
        self = filter
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
