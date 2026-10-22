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
    /// Bumped on every `reschedule`, so a queued or running older rebuild stops early.
    private var generation = 0
    /// Rebuilds run one after another: an older run's late `add` can't land after a newer run's removal.
    private var lastRun: Task<Void, Never>?

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
        let previous = lastRun
        let current = Task {
            await previous?.value
            await self.rebuild(tasks: tasks, enabled: enabled, run: run)
        }
        lastRun = current
        await current.value
    }

    private func rebuild(tasks: [TaskSnapshot], enabled: Bool, run: Int) async {
        guard run == generation else { return }
        let pending = await center.pendingNotificationRequests()
        guard run == generation else { return }
        let ours = pending.map(\.identifier).filter { $0.hasPrefix(NotificationPlanner.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ours)
        guard enabled else { return }

        let settings = await center.notificationSettings()
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
    // Completion-handler variants: UIKit requires the tap handler's completion on the main thread,
    // which the nonisolated async variant does not guarantee.

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let link = response.notification.request.content.userInfo[Self.deepLinkKey] as? String
        let url = link.flatMap { URL(string: $0) }
        Task { @MainActor in
            if let url {
                self.model?.handle(url: url)
            }
            completionHandler()
        }
    }
}
