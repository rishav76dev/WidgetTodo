import Foundation
import TodoKit
import UserNotifications

/// Local due-time reminders. Rebuilds the pending set from snapshots and routes taps back into the app.
@MainActor
final class NotificationScheduler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationScheduler()

    nonisolated private static let deepLinkKey = "deepLink"

    private let center = UNUserNotificationCenter.current()
    private weak var model: AppModel?
    /// Bumped on every `reschedule`, so an older run that resumes after a newer one stops adding requests.
    private var generation = 0

    func attach(model: AppModel) {
        self.model = model
        center.delegate = self
    }

    /// Asks once, the first time a task with a time is saved (spec section 6), never at launch.
    func requestAuthorizationIfNeeded(model: AppModel) async {
        guard !model.preferences.hasAskedNotificationPermission else { return }
        model.updatePreferences { $0.hasAskedNotificationPermission = true }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func reschedule(tasks: [TaskSnapshot], enabled: Bool) async {
        generation += 1
        let run = generation

        let pending = await center.pendingNotificationRequests()
        guard run == generation else { return }
        let ours = pending.map(\.identifier).filter { $0.hasPrefix(NotificationPlanner.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ours)
        guard enabled else { return }

        let settings = await center.notificationSettings()
        guard run == generation else { return }
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: break
        default: return
        }

        let calendar = Calendar.current
        for planned in NotificationPlanner.plan(tasks, now: .now) {
            guard run == generation else { return }
            let content = UNMutableNotificationContent()
            content.title = planned.title
            content.body = planned.body
            content.sound = .default
            content.userInfo = [Self.deepLinkKey: DeepLink.task(planned.taskID).url.absoluteString]
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second], from: planned.fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: planned.identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    // MARK: UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let link = response.notification.request.content.userInfo[Self.deepLinkKey] as? String,
              let url = URL(string: link)
        else { return }
        await MainActor.run {
            self.model?.handle(url: url)
        }
    }
}
