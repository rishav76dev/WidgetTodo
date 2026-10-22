import SwiftData
import SwiftUI
import TodoData
import TodoKit
import TodoUI

@main
struct Todo1App: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: AppModel
    @State private var purchases: PurchaseManager
    @State private var isRefreshing = false
    /// The context the UI reads and writes. Replaced when the store changed while the app was in the background
    /// (see `refreshIfChangedInBackground`). Mirrored in `IntentSupport.appContext` so intents run here share it.
    @State private var context: ModelContext?
    /// The tasks as the UI saw them when the app last went to the background.
    @State private var backgroundSnapshot: [TaskSnapshot]?
    private let container: ModelContainer?

    private static let didWaitForInitialSyncKey = "didWaitForInitialSync"

    init() {
        FontRegistration.registerBundledFonts()
        let container = try? ModelContainerFactory.shared(role: TargetRole.role)
        self.container = container
        _context = State(initialValue: container?.mainContext)
        IntentSupport.appContext = container?.mainContext
        let model = AppModel()
        let purchases = PurchaseManager()
        purchases.configure()
        // The delegate must be set before launch finishes so a notification tap that launched the app is delivered.
        NotificationScheduler.shared.attach(model: model)
        _model = State(initialValue: model)
        _purchases = State(initialValue: purchases)
    }

    var body: some Scene {
        WindowGroup {
            if let container, let context {
                RootView()
                    .modelContext(context)
                    .environment(model)
                    .environment(purchases)
                    .preferredColorScheme(model.appTheme.colorScheme == .dark ? ColorScheme.dark : ColorScheme.light)
                    .tint(model.appTheme.accent.color)
                    .onOpenURL { model.handle(url: $0) }
                    .task { purchases.start(model: model) }
                    .onChange(of: scenePhase, initial: true) { _, phase in
                        switch phase {
                        case .active:
                            Task { await becameActive(container) }
                        case .background:
                            backgroundSnapshot = try? TaskRepository(context: context).snapshots()
                        default:
                            break
                        }
                    }
            } else {
                StartupErrorView()
            }
        }
    }

    @MainActor
    private func becameActive(_ container: ModelContainer) async {
        refreshIfChangedInBackground(container)
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        guard let context else { return }
        let repository = TaskRepository(context: context)
        _ = try? repository.purgeCompleted()
        let tasks = (try? repository.snapshots()) ?? []
        await NotificationScheduler.shared.reschedule(tasks: tasks, enabled: model.preferences.notificationsEnabled)
        await purchases.refresh(model: model)
        IntentSupport.reloadWidgets()
        await ensureDefaultList(repository)
    }

    /// The widget writes the store from its own process while the app is in the background, and objects already
    /// loaded in a context keep their old values. If a fresh read differs from what the UI last saw, swap in a fresh
    /// context: the UI refetches current data, and toggling a stale row can't overwrite the widget's change.
    @MainActor
    private func refreshIfChangedInBackground(_ container: ModelContainer) {
        guard let before = backgroundSnapshot else { return }
        backgroundSnapshot = nil
        let fresh = ModelContext(container)
        fresh.autosaveEnabled = true
        guard let current = try? TaskRepository(context: fresh).snapshots(), current != before else { return }
        context = fresh
        IntentSupport.appContext = fresh
    }

    /// On first launch, waits up to 5 s for iCloud to import existing lists, so a second device
    /// doesn't create a duplicate "Personal" list (spec section 5).
    @MainActor
    private func ensureDefaultList(_ repository: TaskRepository) async {
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: Self.didWaitForInitialSyncKey) {
            try? await Task.sleep(for: .seconds(5))
            defaults.set(true, forKey: Self.didWaitForInitialSyncKey)
        }
        guard (try? repository.lists())?.isEmpty ?? true else { return }
        _ = try? repository.ensureDefaultList()
        IntentSupport.reloadWidgets()
    }
}

/// Shown when the task store can't be opened (for example, the device is out of space).
private struct StartupErrorView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Couldn't open your tasks", systemImage: "exclamationmark.triangle")
        } description: {
            Text("Restart the app. If this keeps happening, free up some storage on your iPhone and try again.")
        }
    }
}
