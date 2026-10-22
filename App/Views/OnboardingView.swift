import SwiftUI
import TodoKit
import TodoUI

/// First-launch pages: what the app does, pick a theme, add the widget. No permission prompts here.
struct OnboardingView: View {
    private enum Page: Int, CaseIterable { case welcome, theme, widget }

    @Environment(AppModel.self) private var model
    @State private var page = Page.welcome

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                WelcomePage().tag(Page.welcome)
                ThemePickerPage().tag(Page.theme)
                AddWidgetPage().tag(Page.widget)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if let next = Page(rawValue: page.rawValue + 1) {
                    withAnimation { page = next }
                } else {
                    model.updatePreferences { $0.hasCompletedOnboarding = true }
                }
            } label: {
                Text(page == .widget ? "Get started" : "Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .interactiveDismissDisabled()
    }
}

private struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checklist")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(.tint)
            Text("Your tasks, right on your Home Screen")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 14) {
                feature("checkmark.circle", "Tick tasks off straight from the widget")
                feature("plus.circle", "Add a task in seconds, or just ask Siri")
                feature("paintpalette", "Make it yours with beautiful themes")
                feature("icloud", "Synced across your devices with iCloud")
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private func feature(_ symbol: String, _ text: String) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: symbol).foregroundStyle(.tint)
        }
        .font(.body)
    }
}

private struct ThemePickerPage: View {
    @Environment(AppModel.self) private var model
    @State private var previewed: Theme?
    @State private var showsPaywall = false

    private var themes: [Theme] { model.catalog.ordered(by: model.entitlements.themeOrder) }

    var body: some View {
        VStack(spacing: 16) {
            Text("Pick a theme")
                .font(.largeTitle.bold())
                .padding(.top, 40)
            Text("It styles the app and your widgets. You can change it any time.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(themes) { theme in
                        let isUnlocked = ThemeAccess.isUnlocked(themeID: theme.id, catalog: model.catalog, state: model.entitlements)
                        Button {
                            if isUnlocked {
                                model.updatePreferences { $0.appThemeID = theme.id }
                            } else {
                                previewed = theme
                            }
                        } label: {
                            ThemeGalleryCell(theme: theme, isLocked: !isUnlocked, isSelected: model.appTheme.id == theme.id)
                                .frame(width: 240)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
            .frame(height: 170)

            if !model.entitlements.isPremium {
                Button("See all Premium themes") { showsPaywall = true }
                    .font(.subheadline.weight(.semibold))
            }
            Spacer()
        }
        .sheet(item: $previewed) { theme in
            NavigationStack {
                ThemePreviewView(theme: theme)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { previewed = nil }
                        }
                    }
            }
        }
        .sheet(isPresented: $showsPaywall) {
            PaywallSheet()
        }
    }
}

private struct AddWidgetPage: View {
    @Environment(AppModel.self) private var model
    @State private var wiggle = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Add the widget")
                .font(.largeTitle.bold())
                .padding(.top, 40)

            ThemeWidgetPreview(theme: model.appTheme, size: .medium)
                .frame(maxWidth: 300)
                .rotationEffect(.degrees(wiggle ? 1.5 : -1.5))
                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.18).repeatForever(autoreverses: true)) { wiggle = true }
                }
                .onDisappear { wiggle = false }
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 14) {
                step(1, "Touch and hold an empty area of your Home Screen until the apps jiggle.")
                step(2, "Tap **Edit** in the top corner, then **Add Widget**.")
                step(3, "Search for this app, choose a size and tap **Add Widget**.")
                step(4, "To pick a list or theme, touch and hold the widget and tap **Edit Widget**.")
            }
            .padding(.horizontal, 28)
            Spacer()
        }
    }

    private func step(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .frame(width: 26, height: 26)
                .background(Circle().fill(.tint).opacity(0.15))
            Text(text)
        }
    }
}
