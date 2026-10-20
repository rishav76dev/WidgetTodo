import Foundation

/// The bundled themes, in the default display order from `index.json`.
public struct ThemeCatalog: Sendable {
    public let themes: [Theme]

    public init(themes: [Theme]) {
        self.themes = themes
    }

    public static let bundled = load(bundle: .module)

    /// Reads `index.json` (an array of theme ids) and then each `<id>.json`, skipping files that are
    /// missing or unreadable. Paper is always present: if its file is missing, `Theme.fallback` is put first.
    public static func load(bundle: Bundle) -> ThemeCatalog {
        let decoder = JSONDecoder()
        var themes: [Theme] = []
        for id in indexIDs(in: bundle) where !themes.contains(where: { $0.id == id }) {
            guard let url = url(forResource: id, in: bundle),
                  let data = try? Data(contentsOf: url),
                  let theme = try? decoder.decode(Theme.self, from: data) else { continue }
            themes.append(theme)
        }
        if !themes.contains(where: { $0.id == Theme.fallback.id }) {
            themes.insert(.fallback, at: 0)
        }
        return ThemeCatalog(themes: themes)
    }

    /// The theme with `id`; unknown or nil ids give this catalogue's Paper, or `Theme.fallback`.
    public func theme(id: String?) -> Theme {
        if let id, let match = themes.first(where: { $0.id == id }) { return match }
        return themes.first { $0.id == Theme.fallback.id } ?? .fallback
    }

    /// Themes whose ids appear in `order` first (in that order, unknown ids ignored), then the rest in bundled order.
    public func ordered(by order: [String]) -> [Theme] {
        var seen = Set<String>()
        var result: [Theme] = []
        for id in order {
            guard !seen.contains(id), let theme = themes.first(where: { $0.id == id }) else { continue }
            seen.insert(id)
            result.append(theme)
        }
        return result + themes.filter { !seen.contains($0.id) }
    }

    static func indexIDs(in bundle: Bundle) -> [String] {
        guard let url = url(forResource: "index", in: bundle),
              let data = try? Data(contentsOf: url),
              let ids = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return ids
    }

    /// SwiftPM's `.process` rule flattens resource folders, so look in `Themes/` and at the bundle root.
    static func url(forResource name: String, in bundle: Bundle) -> URL? {
        bundle.url(forResource: name, withExtension: "json", subdirectory: "Themes")
            ?? bundle.url(forResource: name, withExtension: "json")
    }
}
