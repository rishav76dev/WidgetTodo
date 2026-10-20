import Foundation
import Testing
@testable import TodoKit

@Suite struct ThemeCatalogTests {
    @Test func bundledCatalogHas12UniqueThemesPaperFirst() throws {
        let catalog = ThemeCatalog.bundled
        let ids = catalog.themes.map(\.id)
        #expect(ids.count == 12)
        #expect(Set(ids).count == 12)
        #expect(ids.first == "paper")
        #expect(Array(ids.prefix(3)) == ["paper", "midnight", "mono-mint"])

        let indexIDs = ThemeCatalog.indexIDs(in: .module)
        #expect(indexIDs == ids)
        for id in indexIDs {
            let url = try #require(ThemeCatalog.url(forResource: id, in: .module), "missing \(id).json")
            let theme = try JSONDecoder().decode(Theme.self, from: Data(contentsOf: url))
            #expect(theme.id == id)
        }
    }

    @Test func bundledThemesMatchSpecSettings() {
        let catalog = ThemeCatalog.bundled
        #expect(catalog.theme(id: "paper") == Theme.fallback)
        #expect(catalog.theme(id: "terminal").font.customName == "IBMPlexMono-Regular")
        #expect(catalog.theme(id: "terminal").checkbox == .bracket)
        #expect(catalog.theme(id: "terminal").header == HeaderSpec(style: .prompt, prefix: "> "))
        #expect(catalog.theme(id: "terminal").font.textCase == .lower)
        #expect(catalog.theme(id: "receipt").footer == .receipt)
        #expect(catalog.theme(id: "receipt").row.style == .dashed)
        #expect(catalog.theme(id: "blueprint").background.type == .grid)
        #expect(catalog.theme(id: "zen").layout == .focus)
        #expect(catalog.theme(id: "zen").footer == .count)
        #expect(catalog.theme(id: "neon").glow)
        #expect(catalog.theme(id: "neon").colorScheme == .dark)
        #expect(catalog.theme(id: "neon").font.family == .rounded)
        #expect(catalog.theme(id: "brutalist").font.weight == .black)
        #expect(catalog.theme(id: "brutalist").font.textCase == .upper)
        #expect(catalog.theme(id: "swiss").font == FontSpec(family: .system, weight: .bold))
        #expect(catalog.theme(id: "pocket-8bit").font.customName == "PressStart2P-Regular")
        #expect(catalog.theme(id: "sticky-note").font.customName == "Caveat-Regular")
        #expect(catalog.theme(id: "mono-mint").font.family == .mono)
        #expect(catalog.theme(id: "zen").font.family == .serif)
    }

    @Test func unknownIdReturnsPaper() {
        let catalog = ThemeCatalog.bundled
        #expect(catalog.theme(id: "does-not-exist").id == "paper")
        #expect(catalog.theme(id: nil).id == "paper")
        #expect(catalog.theme(id: "neon").id == "neon")
    }

    @Test func orderedByRemoteOrder() {
        let ordered = ThemeCatalog.bundled.ordered(by: ["neon", "bogus", "paper", "neon"])
        #expect(ordered.prefix(2).map(\.id) == ["neon", "paper"])
        #expect(ordered.count == 12)
        #expect(Set(ordered.map(\.id)).count == 12)
        #expect(ordered[2].id == "midnight")
    }

    @Test func emptyCatalogStillHasFallback() {
        #expect(ThemeCatalog(themes: []).theme(id: "x").id == "paper")
        #expect(ThemeCatalog(themes: []).theme(id: nil) == Theme.fallback)
    }

    @Test func loadSkipsUnreadableFilesAndAddsFallback() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ThemeCatalogTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        try Data(#"["neon","missing","broken"]"#.utf8).write(to: dir.appendingPathComponent("index.json"))
        try Data(#"{"id":"neon","name":"Neon","glow":true}"#.utf8).write(to: dir.appendingPathComponent("neon.json"))
        try Data("not json".utf8).write(to: dir.appendingPathComponent("broken.json"))

        let bundle = try #require(Bundle(path: dir.path))
        let catalog = ThemeCatalog.load(bundle: bundle)
        #expect(catalog.themes.map(\.id) == ["paper", "neon"])
        #expect(catalog.themes.first == Theme.fallback)
    }
}
