import Foundation

public enum ThemeColorScheme: String, Codable, CaseIterable, Sendable { case light, dark }
public enum BackgroundType: String, Codable, CaseIterable, Sendable { case solid, gradient, grid }
public enum FontFamily: String, Codable, CaseIterable, Sendable { case system, serif, mono, rounded, custom }
public enum FontWeightSpec: String, Codable, CaseIterable, Sendable { case light, regular, medium, semibold, bold, heavy, black }
public enum TextCaseSpec: String, Codable, CaseIterable, Sendable { case none, upper, lower }
public enum HeaderStyle: String, Codable, CaseIterable, Sendable { case plain, bold, prompt, stamp }
public enum RowStyle: String, Codable, CaseIterable, Sendable { case plain, divider, card, dashed }
public enum CheckboxStyle: String, Codable, CaseIterable, Sendable { case circle, square, bracket, strike, dot }
public enum FooterStyle: String, Codable, CaseIterable, Sendable { case none, count, receipt }
public enum LayoutStyle: String, Codable, CaseIterable, Sendable { case list, focus }

public struct ThemeBackground: Codable, Hashable, Sendable {
    public var type: BackgroundType
    /// One colour for `solid` and `grid`, two or more for `gradient`; never empty after decoding.
    public var colors: [HexColor]
    /// Line colour for the `grid` pattern.
    public var gridColor: HexColor?

    public init(type: BackgroundType = .solid, colors: [HexColor] = [HexColor(red: 1, green: 1, blue: 1)], gridColor: HexColor? = nil) {
        self.type = type
        self.colors = colors
        self.gridColor = gridColor
    }

    private enum CodingKeys: String, CodingKey { case type, colors, gridColor }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = ThemeBackground()
        type = c.decodeEnum(.type, default: defaults.type)
        // Invalid entries are dropped one by one instead of discarding the whole list.
        let parsed = ((try? c.decodeIfPresent([String].self, forKey: .colors)) ?? nil)?.compactMap(HexColor.init) ?? []
        colors = parsed.isEmpty ? defaults.colors : parsed
        gridColor = (try? c.decodeIfPresent(HexColor.self, forKey: .gridColor)) ?? nil
    }
}

public struct FontSpec: Codable, Hashable, Sendable {
    public var family: FontFamily
    /// PostScript name of a bundled font; used when `family` is `custom`.
    public var customName: String?
    public var weight: FontWeightSpec
    public var scale: Double
    public var textCase: TextCaseSpec

    public init(family: FontFamily = .system, customName: String? = nil, weight: FontWeightSpec = .regular, scale: Double = 1, textCase: TextCaseSpec = .none) {
        self.family = family
        self.customName = customName
        self.weight = weight
        self.scale = scale
        self.textCase = textCase
    }

    private enum CodingKeys: String, CodingKey {
        case family, customName, weight, scale
        case textCase = "case"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = FontSpec()
        family = c.decodeEnum(.family, default: defaults.family)
        customName = (try? c.decodeIfPresent(String.self, forKey: .customName)) ?? nil
        weight = c.decodeEnum(.weight, default: defaults.weight)
        scale = c.decode(.scale, default: defaults.scale)
        textCase = c.decodeEnum(.textCase, default: defaults.textCase)
    }
}

public struct HeaderSpec: Codable, Hashable, Sendable {
    public var style: HeaderStyle
    /// Text drawn before the list name, such as Terminal's `"> "`.
    public var prefix: String

    public init(style: HeaderStyle = .plain, prefix: String = "") {
        self.style = style
        self.prefix = prefix
    }

    private enum CodingKeys: String, CodingKey { case style, prefix }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = HeaderSpec()
        style = c.decodeEnum(.style, default: defaults.style)
        prefix = c.decode(.prefix, default: defaults.prefix)
    }
}

public struct RowSpec: Codable, Hashable, Sendable {
    public var style: RowStyle
    public var spacing: Double

    public init(style: RowStyle = .plain, spacing: Double = 6) {
        self.style = style
        self.spacing = spacing
    }

    private enum CodingKeys: String, CodingKey { case style, spacing }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = RowSpec()
        style = c.decodeEnum(.style, default: defaults.style)
        spacing = c.decode(.spacing, default: defaults.spacing)
    }
}

/// A visual theme for the app and the widget, decoded from `Resources/Themes/<id>.json`.
/// Decoding never fails on content: missing, mistyped or unknown values fall back to the defaults below.
public struct Theme: Codable, Identifiable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var colorScheme: ThemeColorScheme
    public var background: ThemeBackground
    public var textPrimary: HexColor
    public var textSecondary: HexColor
    public var accent: HexColor
    public var overdue: HexColor
    public var font: FontSpec
    public var header: HeaderSpec
    public var row: RowSpec
    public var checkbox: CheckboxStyle
    public var footer: FooterStyle
    public var layout: LayoutStyle
    public var glow: Bool
    public var cornerRadius: Double
    public var padding: Double

    public init(
        id: String = AppConstants.defaultThemeID,
        name: String = "Paper",
        colorScheme: ThemeColorScheme = .light,
        background: ThemeBackground = ThemeBackground(),
        textPrimary: HexColor = HexColor(red: 0x11 / 255, green: 0x11 / 255, blue: 0x11 / 255),
        textSecondary: HexColor = HexColor(red: 0x6B / 255, green: 0x6B / 255, blue: 0x6B / 255),
        accent: HexColor = HexColor(red: 0x11 / 255, green: 0x11 / 255, blue: 0x11 / 255),
        overdue: HexColor = HexColor(red: 0xD9 / 255, green: 0x30 / 255, blue: 0x25 / 255),
        font: FontSpec = FontSpec(),
        header: HeaderSpec = HeaderSpec(),
        row: RowSpec = RowSpec(),
        checkbox: CheckboxStyle = .circle,
        footer: FooterStyle = .none,
        layout: LayoutStyle = .list,
        glow: Bool = false,
        cornerRadius: Double = 16,
        padding: Double = 14
    ) {
        self.id = id
        self.name = name
        self.colorScheme = colorScheme
        self.background = background
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.accent = accent
        self.overdue = overdue
        self.font = font
        self.header = header
        self.row = row
        self.checkbox = checkbox
        self.footer = footer
        self.layout = layout
        self.glow = glow
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    /// Paper, built in code so the app and widget can always render even if every theme file is unreadable.
    /// Kept identical to `paper.json` (checked by `ThemeCatalogTests`).
    public static let fallback = Theme(
        background: ThemeBackground(colors: [HexColor(red: 0xFA / 255, green: 0xF8 / 255, blue: 0xF3 / 255)]),
        textPrimary: HexColor(red: 0x1A / 255, green: 0x1A / 255, blue: 0x1A / 255),
        accent: HexColor(red: 0x1A / 255, green: 0x1A / 255, blue: 0x1A / 255),
        font: FontSpec(family: .serif),
        header: HeaderSpec(style: .bold),
        row: RowSpec(style: .divider)
    )

    private enum CodingKeys: String, CodingKey {
        case id, name, colorScheme, background, textPrimary, textSecondary, accent, overdue
        case font, header, row, checkbox, footer, layout, glow, cornerRadius, padding
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Theme()
        id = c.decode(.id, default: d.id)
        name = c.decode(.name, default: d.name)
        colorScheme = c.decodeEnum(.colorScheme, default: d.colorScheme)
        background = c.decode(.background, default: d.background)
        textPrimary = c.decode(.textPrimary, default: d.textPrimary)
        textSecondary = c.decode(.textSecondary, default: d.textSecondary)
        accent = c.decode(.accent, default: d.accent)
        overdue = c.decode(.overdue, default: d.overdue)
        font = c.decode(.font, default: d.font)
        header = c.decode(.header, default: d.header)
        row = c.decode(.row, default: d.row)
        checkbox = c.decodeEnum(.checkbox, default: d.checkbox)
        footer = c.decodeEnum(.footer, default: d.footer)
        layout = c.decodeEnum(.layout, default: d.layout)
        glow = c.decode(.glow, default: d.glow)
        cornerRadius = c.decode(.cornerRadius, default: d.cornerRadius)
        padding = c.decode(.padding, default: d.padding)
    }
}

extension KeyedDecodingContainer {
    /// The value for `key`, or `value` when it is missing or cannot be decoded.
    func decode<T: Decodable>(_ key: Key, default value: T) -> T {
        ((try? decodeIfPresent(T.self, forKey: key)) ?? nil) ?? value
    }

    /// The enum case named by the string at `key`, or `value` when it is missing, not a string or unknown.
    func decodeEnum<E: RawRepresentable>(_ key: Key, default value: E) -> E where E.RawValue == String {
        ((try? decodeIfPresent(String.self, forKey: key)) ?? nil).flatMap(E.init(rawValue:)) ?? value
    }
}
