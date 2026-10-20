import Foundation

/// What the user may use, cached in the App Group so the widget can read it without RevenueCat.
public struct EntitlementState: Codable, Equatable, Sendable {
    public var isPremium: Bool
    /// Number of themes, counted along `themeOrder`, that are free. Not clamped here; see `ThemeAccess`.
    public var freeThemeCount: Int
    /// Remote display order; ids missing from the catalogue are ignored.
    public var themeOrder: [String]

    public init(isPremium: Bool, freeThemeCount: Int, themeOrder: [String]) {
        self.isPremium = isPremium
        self.freeThemeCount = freeThemeCount
        self.themeOrder = themeOrder
    }

    public static let `default` = EntitlementState(isPremium: false, freeThemeCount: AppConstants.defaultFreeThemeCount, themeOrder: [])

    /// Builds the state from RevenueCat offering metadata (`free_theme_count`, `theme_order`).
    /// Values of the wrong type, or non-integral counts, fall back to the bundled defaults.
    public static func from(isPremium: Bool, offeringMetadata: [String: Any]) -> EntitlementState {
        EntitlementState(
            isPremium: isPremium,
            freeThemeCount: integer(offeringMetadata["free_theme_count"]) ?? AppConstants.defaultFreeThemeCount,
            themeOrder: offeringMetadata["theme_order"] as? [String] ?? []
        )
    }

    private static func integer(_ value: Any?) -> Int? {
        switch value {
        case let int as Int: int
        case let double as Double: Int(exactly: double)
        default: nil
        }
    }

    private enum CodingKeys: String, CodingKey { case isPremium, freeThemeCount, themeOrder }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = EntitlementState.default
        isPremium = (try? c.decodeIfPresent(Bool.self, forKey: .isPremium)) ?? defaults.isPremium
        freeThemeCount = (try? c.decodeIfPresent(Int.self, forKey: .freeThemeCount)) ?? defaults.freeThemeCount
        themeOrder = (try? c.decodeIfPresent([String].self, forKey: .themeOrder)) ?? defaults.themeOrder
    }
}
