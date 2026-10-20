import SwiftUI
import TodoKit
import TodoUI

/// Full preview of one theme as a large widget, with "Use" for unlocked themes and "Unlock" for locked ones.
struct ThemePreviewView: View {
    let theme: Theme

    @Environment(AppModel.self) private var model
    @State private var showsPaywall = false

    private var isUnlocked: Bool {
        ThemeAccess.isUnlocked(themeID: theme.id, catalog: model.catalog, state: model.entitlements)
    }

    private var isSelected: Bool { model.appTheme.id == theme.id }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ThemeWidgetPreview(theme: theme, size: .large)
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                    .frame(maxWidth: 380)

                if isUnlocked {
                    Button {
                        model.updatePreferences { $0.appThemeID = theme.id }
                    } label: {
                        Label(isSelected ? "In use" : "Use this theme", systemImage: isSelected ? "checkmark" : "paintbrush")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isSelected)
                } else {
                    VStack(spacing: 8) {
                        Button {
                            showsPaywall = true
                        } label: {
                            Label("Unlock all themes", systemImage: "lock.open")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        Text("Premium unlocks every theme for the app and all your widgets.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(theme.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsPaywall) {
            PaywallSheet()
        }
    }
}

/// A non-interactive widget rendering of `theme` with sample tasks, scaled to the available width.
struct ThemeWidgetPreview: View {
    let theme: Theme
    var size: WidgetSize = .medium

    /// Approximate home-screen widget sizes on a 6.1" iPhone, in points.
    private var canvas: CGSize {
        switch size {
        case .small: CGSize(width: 158, height: 158)
        case .medium: CGSize(width: 338, height: 158)
        case .large: CGSize(width: 338, height: 354)
        }
    }

    var body: some View {
        let canvas = self.canvas
        Color.clear
            .aspectRatio(canvas.width / canvas.height, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    widget
                        .frame(width: canvas.width, height: canvas.height)
                        .scaleEffect(proxy.size.width / canvas.width, anchor: .topLeading)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(theme.name) theme preview")
    }

    private var widget: some View {
        let now = Date()
        let calendar = Calendar.current
        let tasks = SampleTasks.make(now: now, calendar: calendar)
        let model = WidgetViewModel(
            title: WidgetViewModel.title(for: .all, listName: nil),
            filter: .all,
            content: WidgetLayout.content(tasks: tasks, filter: .all, size: size, now: now, calendar: calendar),
            isLockedFallback: false,
            now: now
        )
        let theme = self.theme
        return ZStack {
            ThemedBackground(theme: theme)
            TaskListWidgetView(
                model: model,
                theme: theme,
                size: size,
                checkbox: { task in AnyView(ThemedCheckbox(theme: theme, isCompleted: task.isCompleted)) },
                addLink: DeepLink.quickAdd(nil).url,
                taskLink: { _ in nil }
            )
            // Matches the system's default widget content margins.
            .padding(16)
        }
        .environment(\.colorScheme, theme.colorScheme == .dark ? .dark : .light)
    }
}
