import Foundation
import TodoKit
import UserNotifications

/// Due-time reminder requests, compiled into the app and the widget so a task ticked in the widget
/// updates its own reminder without waiting for the app's next full reschedule.
enum TaskReminders {
    /// Holds the task's deep link; the app's notification delegate opens it on tap.
    static let deepLinkKey = "deepLink"

    static func request(for planned: PlannedNotification, calendar: Calendar = .current) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = planned.title
        content.body = planned.body
        content.sound = .default
        content.userInfo = [deepLinkKey: DeepLink.task(planned.taskID).url.absoluteString]
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: planned.fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: planned.identifier, content: content, trigger: trigger)
    }

    /// Replaces the pending reminder of task `id` with one for `task`'s current state (none when it is
    /// completed, deleted or untimed). Never asks for permission.
    static func update(id: UUID, task: TaskSnapshot?) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [NotificationPlanner.identifierPrefix + id.uuidString])
        guard let task,
              SharedStore.appGroup().loadPreferences().notificationsEnabled,
              let planned = NotificationPlanner.plan([task], now: .now).first
        else { return }

        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral: break
        default: return
        }
        try? await center.add(request(for: planned))
    }
}
