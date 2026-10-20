import Foundation

public enum DueDateFormatter {
    /// "Today", "Tomorrow", "Yesterday" or a short localized date, plus ", <time>" for timed tasks.
    public static func label(for t: TaskSnapshot, now: Date, calendar: Calendar, locale: Locale) -> String? {
        guard let due = t.dueDate else { return nil }
        let dayOffset = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: due)
        ).day
        let day: String
        switch dayOffset {
        case 0: day = "Today"
        case 1: day = "Tomorrow"
        case -1: day = "Yesterday"
        default: day = formatter(template: "EEEdMMM", calendar: calendar, locale: locale).string(from: due)
        }
        guard t.hasDueTime else { return day }
        return day + ", " + formatter(template: "jmm", calendar: calendar, locale: locale).string(from: due)
    }

    private static func formatter(template: String, calendar: Calendar, locale: Locale) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter
    }
}
