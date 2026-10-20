import Foundation

/// An sRGB colour with components in 0...1, stored in theme files as `#RGB`, `#RRGGBB` or `#RRGGBBAA`.
public struct HexColor: Codable, Hashable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public init?(_ hex: String) {
        var digits = hex.trimmingCharacters(in: .whitespaces)
        if digits.hasPrefix("#") { digits.removeFirst() }
        guard digits.allSatisfy(\.isHexDigit) else { return nil }
        if digits.count == 3 { digits = digits.map { "\($0)\($0)" }.joined() }
        guard digits.count == 6 || digits.count == 8, let value = UInt32(digits, radix: 16) else { return nil }
        let rgba = digits.count == 6 ? value << 8 | 0xFF : value
        func component(_ shift: UInt32) -> Double { Double(rgba >> shift & 0xFF) / 255 }
        self.init(red: component(24), green: component(16), blue: component(8), alpha: component(0))
    }

    /// `#RRGGBB`, or `#RRGGBBAA` when the colour is not fully opaque.
    public var hexString: String {
        let parts = alpha < 1 ? [red, green, blue, alpha] : [red, green, blue]
        return "#" + parts.map { String(format: "%02X", Int(($0 * 255).rounded())) }.joined()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let color = HexColor(string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid hex colour \"\(string)\"")
        }
        self = color
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hexString)
    }
}
