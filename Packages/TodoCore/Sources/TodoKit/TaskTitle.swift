import Foundation

public enum TaskTitle {
    /// Trims the title, joins its lines with spaces and caps it at `maxLength` characters.
    /// Returns nil for blank input (e.g. from Quick Add or Siri).
    public static func normalized(_ raw: String, maxLength: Int = AppConstants.maxTitleLength) -> String? {
        let joined = raw
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        guard !joined.isEmpty else { return nil }
        return String(joined.prefix(max(maxLength, 0)))
    }
}
