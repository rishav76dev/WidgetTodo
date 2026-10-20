import Foundation
import Testing
@testable import TodoKit

@Suite struct ThemeDecodingTests {
    private func decode(_ json: String) throws -> Theme {
        try JSONDecoder().decode(Theme.self, from: Data(json.utf8))
    }

    @Test func missingFieldsUseDefaults() throws {
        let theme = try decode(#"{"id":"x","name":"X"}"#)
        #expect(theme.id == "x")
        #expect(theme.name == "X")
        #expect(theme.checkbox == .circle)
        #expect(theme.padding == 14)
        #expect(theme.background.type == .solid)
        #expect(theme.background.colors == [HexColor("#FFFFFF")!])
        #expect(theme.colorScheme == .light)
        #expect(theme.font == FontSpec())
        #expect(theme.row.spacing == 6)
        #expect(theme.cornerRadius == 16)
        #expect(theme.glow == false)
    }

    @Test func emptyObjectIsPaperDefaults() throws {
        let theme = try decode("{}")
        #expect(theme.id == "paper")
        #expect(theme.name == "Paper")
        #expect(theme == Theme())
    }

    @Test func unknownEnumValuesUseDefaults() throws {
        let theme = try decode(#"""
        {"id":"x","checkbox":"hexagon","row":{"style":"zigzag"},
         "font":{"family":"comic","weight":"ultra","case":"title"},
         "colorScheme":"sepia","footer":42,"layout":"grid","header":{"style":"fancy","prefix":"# "}}
        """#)
        #expect(theme.checkbox == .circle)
        #expect(theme.row.style == .plain)
        #expect(theme.row.spacing == 6)
        #expect(theme.font.family == .system)
        #expect(theme.font.weight == .regular)
        #expect(theme.font.textCase == .none)
        #expect(theme.colorScheme == .light)
        #expect(theme.footer == FooterStyle.none)
        #expect(theme.layout == .list)
        #expect(theme.header == HeaderSpec(style: .plain, prefix: "# "))
    }

    @Test func invalidColorUsesDefault() throws {
        let theme = try decode(#"""
        {"textPrimary":"#ZZZZZZ","accent":12,"overdue":"#00FF00",
         "background":{"type":"gradient","colors":["#000","bogus","#FFF"],"gridColor":"nope"}}
        """#)
        #expect(theme.textPrimary == HexColor("#111111"))
        #expect(theme.accent == HexColor("#111111"))
        #expect(theme.overdue == HexColor("#00FF00"))
        #expect(theme.background.type == .gradient)
        #expect(theme.background.colors == [HexColor("#000000")!, HexColor("#FFFFFF")!])
        #expect(theme.background.gridColor == nil)
    }

    @Test func backgroundWithNoValidColorsUsesDefault() throws {
        let theme = try decode(#"{"background":{"type":"grid","colors":["x"]}}"#)
        #expect(theme.background.type == .grid)
        #expect(theme.background.colors == [HexColor("#FFFFFF")!])
    }

    @Test func caseKeyAndRoundTrip() throws {
        let theme = try decode(#"{"id":"t","font":{"family":"custom","customName":"IBMPlexMono-Regular","case":"lower","scale":0.9}}"#)
        #expect(theme.font.textCase == .lower)
        #expect(theme.font.customName == "IBMPlexMono-Regular")
        #expect(theme.font.scale == 0.9)

        let encoded = try JSONEncoder().encode(theme)
        let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        let font = try #require(object["font"] as? [String: Any])
        #expect(font["case"] as? String == "lower")
        #expect(try JSONDecoder().decode(Theme.self, from: encoded) == theme)
    }

    @Test func fallbackIsPaper() {
        #expect(Theme.fallback.id == AppConstants.defaultThemeID)
        #expect(Theme.fallback.name == "Paper")
    }
}
