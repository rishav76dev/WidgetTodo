import Foundation
import Observation
import SwiftData
import TodoData
import TodoKit

/// A screen presented over Home. Deep links, the toolbar and notification taps all set `AppModel.route`.
enum Route: Identifiable, Hashable {
    case quickAdd(TaskFilter?)
    case task(UUID)
    case themes, paywall, settings, lists

    var id: Self { self }
}

/// App-wide state: preferences and entitlements mirrored to the App Group, plus navigation.
@MainActor @Observable
final class AppModel {
    let catalog = ThemeCatalog.bundled
    let store: SharedStore
    var preferences: AppPreferences
    var entitlements: EntitlementState
    var route: Route?
    var homeFilter: TaskFilter = .all

    init(store: SharedStore = .appGroup()) {
        self.store = store
        preferences = store.loadPreferences()
        entitlements = store.loadEntitlements()
    }

    var appTheme: Theme {
        ThemeAccess.effectiveTheme(selectedID: preferences.appThemeID, catalog: catalog, state: entitlements).theme
    }

    func updatePreferences(_ change: (inout AppPreferences) -> Void) {
        var updated = preferences
        change(&updated)
        preferences = updated
        store.savePreferences(updated)
        IntentSupport.reloadWidgets()
    }

    func handle(url: URL) {
        guard let link = DeepLink(url: url) else { return }
        switch link {
        case .quickAdd(let filter): route = .quickAdd(filter)
        case .task(let id): route = .task(id)
        case .themes: route = .themes
        }
    }

    func applyEntitlements(_ s: EntitlementState) {
        store.saveEntitlements(s)
        guard s != entitlements else { return }
        entitlements = s
        IntentSupport.reloadWidgets()
    }

    /// Call after any task or list change: reloads widgets and rebuilds reminders.
    /// `savedTimedTask` asks for notification permission first (only the first time a task with a time is saved).
    func tasksDidChange(context: ModelContext, savedTimedTask: Bool = false) {
        IntentSupport.reloadWidgets()
        let tasks = (try? TaskRepository(context: context).snapshots()) ?? []
        Task {
            if savedTimedTask {
                await NotificationScheduler.shared.requestAuthorizationIfNeeded(model: self)
            }
            await NotificationScheduler.shared.reschedule(tasks: tasks, enabled: preferences.notificationsEnabled)
        }
    }
}
