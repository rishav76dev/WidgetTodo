#if canImport(SwiftUI)
import SwiftUI
import TodoKit

/// The theme's checkbox glyph. It is not interactive; callers wrap it in a `Button`.
public struct ThemedCheckbox: View {
    let theme: Theme
    let isCompleted: Bool

    public init(theme: Theme, isCompleted: Bool) {
        self.theme = theme
        self.isCompleted = isCompleted
    }

    public var body: some View {
        let style = ThemeStyle(theme)
        glyph(style)
            .foregroundStyle(style.accent)
            .frame(minWidth: 18, minHeight: 18)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isCompleted ? "Completed" : "Not completed")
            .accessibilityAddTraits(isCompleted ? .isSelected : [])
    }

    @ViewBuilder
    private func glyph(_ style: ThemeStyle) -> some View {
        switch theme.checkbox {
        case .circle:
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(style.font(.title))
        case .square:
            Image(systemName: isCompleted ? "checkmark.square.fill" : "square")
                .font(style.font(.title))
        case .bracket:
            Text(isCompleted ? "[x]" : "[ ]")
                .font(style.font(.title))
        case .strike:
            Capsule()
                .frame(width: 12, height: 2)
                .opacity(isCompleted ? 0.4 : 1)
        case .dot:
            Circle()
                .fill(isCompleted ? style.accent : Color.clear)
                .overlay { Circle().strokeBorder(style.accent, lineWidth: 1.5) }
                .frame(width: 10, height: 10)
        }
    }
}
#endif
