import CloudKit
import StoreKit
import SwiftData
import SwiftUI
import TodoData
import TodoKit
import UIKit
import UserNotifications

struct SettingsView: View {
    private enum CloudStatus { case checking, available, unavailable }

    @Environment(AppModel.self) private var model
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showsPaywall = false
    @State private var showsManageSubscription = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?
    @State private var cloudStatus = CloudStatus.checking
    @State private var notificationsDenied = false

    var body: some View {
        NavigationStack {
            Form {
                premiumSection
                notificationsSection
                iCloudSection
                widgetSection
                legalSection
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showsPaywall) {
                PaywallSheet()
            }
            .manageSubscriptionsSheet(isPresented: $showsManageSubscription)
            .alert("Restore Purchases", isPresented: restoreAlertBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(restoreMessage ?? "")
            }
            .task { await checkCloudStatus() }
            .task { await checkNotificationAuthorization() }
        }
    }

    // MARK: Sections

    private var premiumSection: some View {
        Section {
            if model.entitlements.isPremium {
                Label("Premium is active", systemImage: "checkmark.seal.fill")
                if purchases.hasActiveSubscription {
                    Button("Manage Subscription") { showsManageSubscription = true }
                }
            } else {
                Label("Free plan", systemImage: "seal")
                Button("Upgrade to Premium") { showsPaywall = true }
            }
            Button {
                restore()
            } label: {
                HStack {
                    Text("Restore Purchases")
                    if isRestoring {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isRestoring)
        } header: {
            Text("Premium")
        } footer: {
            if !model.entitlements.isPremium {
                Text("Premium unlocks every theme for the app and all your widgets.")
            }
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle("Reminders", isOn: notificationsBinding)
        } header: {
            Text("Notifications")
        } footer: {
            if notificationsDenied && model.preferences.notificationsEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifications are turned off for this app in iOS Settings.")
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        Link("Open iOS Settings", destination: url)
                    }
                }
            } else {
                Text("Get a reminder at the due time of tasks that have a time set.")
            }
        }
    }

    private var iCloudSection: some View {
        Section("iCloud") {
            switch cloudStatus {
            case .checking:
                Label("Checking iCloud…", systemImage: "icloud")
            case .available:
                Label("Syncing with iCloud", systemImage: "checkmark.icloud")
            case .unavailable:
                Label("iCloud unavailable — tasks stay on this iPhone", systemImage: "xmark.icloud")
            }
        }
    }

    private var widgetSection: some View {
        Section("Widget") {
            Text("Touch and hold an empty area of your Home Screen, tap **Edit**, then **Add Widget**, and search for this app.")
            Text("To choose a list or theme for a widget, touch and hold it and tap **Edit Widget**.")
        }
        .font(.subheadline)
    }

    private var legalSection: some View {
        Section("About") {
            Link("Privacy Policy", destination: AppConstants.privacyPolicyURL)
            Link("Terms of Use (EULA)", destination: AppConstants.termsURL)
            LabeledContent("Version", value: Self.version)
        }
    }

    // MARK: Actions

    private var restoreAlertBinding: Binding<Bool> {
        Binding(get: { restoreMessage != nil }, set: { if !$0 { restoreMessage = nil } })
    }

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { model.preferences.notificationsEnabled },
            set: { enabled in
                model.updatePreferences { $0.notificationsEnabled = enabled }
                Task { await rescheduleNotifications(enabled: enabled) }
            }
        )
    }

    private func restore() {
        isRestoring = true
        Task {
            restoreMessage = await purchases.restore(model: model)
            isRestoring = false
        }
    }

    private func rescheduleNotifications(enabled: Bool) async {
        if enabled {
            await NotificationScheduler.shared.requestAuthorizationIfNeeded(model: model)
        }
        let tasks = (try? TaskRepository(context: modelContext).snapshots()) ?? []
        await NotificationScheduler.shared.reschedule(tasks: tasks, enabled: enabled)
        await checkNotificationAuthorization()
    }

    private func checkNotificationAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsDenied = settings.authorizationStatus == .denied
    }

    private func checkCloudStatus() async {
        let status = try? await CKContainer(identifier: AppConstants.iCloudContainerID).accountStatus()
        cloudStatus = status == .available ? .available : .unavailable
    }

    private static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}
