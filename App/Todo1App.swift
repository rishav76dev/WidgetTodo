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
    /// The context the UI reads and writes. Replaced after the widget writes the store (see `refreshIfExternallyChanged`).
    @State private var context: ModelContext?
    @State private var seenExternalWrite: Double
    private let container: ModelContainer?

    private static let didWaitForInitialSyncKey = "didWaitForInitialSync"
    /// Written by the widget's intents (seconds since 1970) after they change the store.
    private static let lastExternalWriteKey = "lastExternalWriteAt"
    private static let groupDefaults = UserDefaults(suiteName: AppConstants.appGroupID) ?? .standard

    init() {
        FontRegistration.registerBundledFonts()
        let container = try? ModelContainerFactory.shared(role: TargetRole.role)
        self.container = container
        _context = State(initialValue: container?.mainContext)
        _seenExternalWrite = State(initialValue: Self.groupDefaults.double(forKey: Self.lastExternalWriteKey))
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
                        guard phase == .active else { return }
                        Task { await becameActive(container) }
                    }
            } else {
                StartupErrorView()
            }
        }
    }

    @MainActor
    private func becameActive(_ container: ModelContainer) async {
        refreshIfExternallyChanged(container)
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

    /// Another process (the widget) wrote the store. Objects already loaded in a context keep their old values,
    /// so swap in a fresh context: the UI refetches current data, and toggling a stale row can't overwrite the widget's change.
    @MainActor
    private func refreshIfExternallyChanged(_ container: ModelContainer) {
        let lastWrite = Self.groupDefaults.double(forKey: Self.lastExternalWriteKey)
        guard lastWrite > seenExternalWrite else { return }
        seenExternalWrite = lastWrite
        let fresh = ModelContext(container)
        fresh.autosaveEnabled = true
        context = fresh
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
