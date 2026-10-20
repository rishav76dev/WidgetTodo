#if canImport(SwiftUI)
import SwiftUI
import TodoKit

/// The theme's background: a solid colour, a top-to-bottom gradient, or a solid colour with a grid.
public struct ThemedBackground: View {
    let theme: Theme

    public init(theme: Theme) {
        self.theme = theme
    }

    public var body: some View {
        let colors = theme.background.colors.map(\.color)
        let base = colors.first ?? Color.white
        switch theme.background.type {
        case .solid:
            base
        case .gradient:
            LinearGradient(colors: colors.count > 1 ? colors : [base, base], startPoint: .top, endPoint: .bottom)
        case .grid:
            base.overlay {
                GridPattern(color: theme.background.gridColor?.color ?? theme.textSecondary.color.opacity(0.3))
            }
        }
    }
}

/// Thin lines every `step` points, with a thicker line every `majorEvery` steps.
struct GridPattern: View {
    var color: Color
    var step: CGFloat = 12
    var majorEvery = 5

    var body: some View {
        Canvas { context, size in
            var minor = Path()
            var major = Path()
            var index = 0
            var x: CGFloat = 0
            while x <= size.width {
                var line = Path()
                line.move(to: CGPoint(x: x, y: 0))
                line.addLine(to: CGPoint(x: x, y: size.height))
                if index % majorEvery == 0 { major.addPath(line) } else { minor.addPath(line) }
                index += 1
                x += step
            }
            index = 0
            var y: CGFloat = 0
            while y <= size.height {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: size.width, y: y))
                if index % majorEvery == 0 { major.addPath(line) } else { minor.addPath(line) }
                index += 1
                y += step
            }
            context.stroke(minor, with: .color(color.opacity(0.5)), lineWidth: 0.5)
            context.stroke(major, with: .color(color), lineWidth: 1)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
#endif
