import Foundation

/// Fixed English tasks for previews, the widget gallery and screenshots.
public enum SampleTasks {
    public static let listID = UUID(uuidString: "5A3B1E0C-0000-4000-8000-000000000001")!
    public static let listName = "Personal"

    /// One overdue, two today (one timed), one tomorrow, one upcoming and one undated task, relative to `now`.
    public static func make(now: Date, calendar: Calendar) -> [TaskSnapshot] {
        let today = calendar.startOfDay(for: now)
        func day(_ offset: Int, hour: Int = 0) -> Date {
            let start = calendar.date(byAdding: .day, value: offset, to: today)!
            return calendar.date(byAdding: .hour, value: hour, to: start)!
        }
        // Later today, but never past midnight or before `now`, so it stays in the Today group.
        let endOfToday = day(1).addingTimeInterval(-1)
        let todayTimed = max(now, min(now.addingTimeInterval(3600), endOfToday))
        let specs: [(title: String, due: Date?, timed: Bool)] = [
            ("Renew passport", day(-1), false),
            ("Buy groceries", day(0), false),
            ("Call the dentist", todayTimed, true),
            ("Team lunch", day(1, hour: 12), true),
            ("Plan weekend trip", day(4), false),
            ("Read a book", nil, false),
        ]
        return specs.enumerated().map { index, spec in
            TaskSnapshot(
                id: UUID(uuidString: String(format: "5A3B1E0C-0000-4000-8000-%012d", index + 2))!,
                title: spec.title,
                dueDate: spec.due,
                hasDueTime: spec.timed,
                listID: listID,
                listName: listName,
                sortIndex: index,
                createdAt: day(-7)
            )
        }
    }
}
