import SwiftUI
import TodoKit

/// Home inside a navigation stack, with every `Route` presented as a sheet and onboarding as a full-screen cover.
struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let isOnboarding = !model.preferences.hasCompletedOnboarding
        NavigationStack {
            HomeView()
        }
        .sheet(item: routeBinding(model, presentedDuringOnboarding: false)) { destination($0) }
        .fullScreenCover(isPresented: .constant(isOnboarding)) {
            // While onboarding covers Home, deep links (e.g. a widget tap) present over the cover instead.
            OnboardingView()
                .sheet(item: routeBinding(model, presentedDuringOnboarding: true)) { destination($0) }
        }
    }

    private func routeBinding(_ model: AppModel, presentedDuringOnboarding: Bool) -> Binding<Route?> {
        Binding(
            get: { model.preferences.hasCompletedOnboarding != presentedDuringOnboarding ? model.route : nil },
            set: { model.route = $0 }
        )
    }

    /// Theme gallery, settings and the paywall bring their own navigation stacks and close buttons.
    @ViewBuilder
    private func destination(_ route: Route) -> some View {
        switch route {
        case .quickAdd(let filter):
            QuickAddSheet(filter: filter)
        case .task(let id):
            NavigationStack { TaskEditorView(taskID: id) }
        case .lists:
            NavigationStack { ListsView() }
        case .themes:
            ThemeGalleryView()
        case .settings:
            SettingsView()
        case .paywall:
            PaywallSheet()
        }
    }
}
