import SwiftUI
import TodoKit
import TodoUI

/// Every theme rendered as a real widget with sample tasks. Unlocked themes apply on tap; locked ones open a preview.
struct ThemeGalleryView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(model.catalog.ordered(by: model.entitlements.themeOrder)) { theme in
                        cell(for: theme)
                    }
                }
                .padding()

                Label {
                    Text("Each widget can have its own theme: long-press the widget, tap **Edit Widget**, then choose **Theme**.")
                } icon: {
                    Image(systemName: "square.grid.2x2")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding([.horizontal, .bottom])
            }
            .navigationTitle("Themes")
            .navigationDestination(for: Theme.self) { theme in
                ThemePreviewView(theme: theme)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(for theme: Theme) -> some View {
        let isUnlocked = ThemeAccess.isUnlocked(themeID: theme.id, catalog: model.catalog, state: model.entitlements)
        let card = ThemeGalleryCell(theme: theme, isLocked: !isUnlocked, isSelected: model.appTheme.id == theme.id)
        if isUnlocked {
            Button {
                model.updatePreferences { $0.appThemeID = theme.id }
            } label: {
                card
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: theme) {
                card
            }
            .buttonStyle(.plain)
        }
    }
}

/// A gallery card: the widget preview, a lock badge or selection mark, and the theme name.
struct ThemeGalleryCell: View {
    let theme: Theme
    let isLocked: Bool
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ThemeWidgetPreview(theme: theme, size: .medium)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: isSelected ? 3 : 1)
                }
                .overlay(alignment: .topTrailing) {
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption.weight(.semibold))
                            .padding(6)
                            .background(.ultraThinMaterial, in: Circle())
                            .padding(6)
                    } else if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.multicolor)
                            .background(Circle().fill(.background))
                            .padding(6)
                    }
                }
            Text(theme.name)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(.primary)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(theme.name)
        .accessibilityValue(isLocked ? "Locked" : isSelected ? "Selected" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
