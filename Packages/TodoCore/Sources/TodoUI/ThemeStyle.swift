#if canImport(SwiftUI)
import SwiftUI
import TodoKit

extension HexColor {
    public var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha) }
}

public enum FontRole: CaseIterable, Sendable {
    case header, title, caption, display

    /// Point size before the theme's `font.scale`.
    public var baseSize: CGFloat {
        switch self {
        case .header: 15
        case .title: 14
        case .caption: 11
        case .display: 28
        }
    }
}

/// Resolves a `Theme` into SwiftUI fonts, colours and text casing.
public struct ThemeStyle {
    public let theme: Theme

    public init(_ theme: Theme) {
        self.theme = theme
    }

    public var primary: Color { theme.textPrimary.color }
    public var secondary: Color { theme.textSecondary.color }
    public var accent: Color { theme.accent.color }
    public var overdue: Color { theme.overdue.color }
    public var colorScheme: ColorScheme { theme.colorScheme == .dark ? .dark : .light }

    /// Headers are at least bold for the `bold` and `stamp` header styles.
    public func font(_ role: FontRole) -> Font {
        let size = role.baseSize * scale
        var weight = Self.weight(theme.font.weight)
        if role == .header, theme.header.style == .bold || theme.header.style == .stamp,
           theme.font.weight.rank < FontWeightSpec.bold.rank {
            weight = .bold
        }
        switch theme.font.family {
        case .system: return .system(size: size, weight: weight)
        case .serif: return .system(size: size, weight: weight, design: .serif)
        case .mono: return .system(size: size, weight: weight, design: .monospaced)
        case .rounded: return .system(size: size, weight: weight, design: .rounded)
        case .custom:
            guard let name = theme.font.customName, !name.isEmpty else { return .system(size: size, weight: weight) }
            return Font.custom(name, size: size).weight(weight)
        }
    }

    public func cased(_ s: String) -> String {
        switch theme.font.textCase {
        case .none: s
        case .upper: s.uppercased()
        case .lower: s.lowercased()
        }
    }

    /// `font.scale`, kept within 0.5...3 so a bad theme file cannot make text vanish or explode.
    private var scale: CGFloat {
        let value = theme.font.scale
        guard value.isFinite else { return 1 }
        return CGFloat(min(max(value, 0.5), 3))
    }

    private static func weight(_ spec: FontWeightSpec) -> Font.Weight {
        switch spec {
        case .light: .light
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        case .heavy: .heavy
        case .black: .black
        }
    }
}

private extension FontWeightSpec {
    var rank: Int { FontWeightSpec.allCases.firstIndex(of: self) ?? 0 }
}

/// A horizontal line through the middle of its frame, used for dashed rules.
struct HorizontalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
#endif
