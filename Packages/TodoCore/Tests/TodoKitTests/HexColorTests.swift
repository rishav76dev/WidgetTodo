import Foundation
import Testing
@testable import TodoKit

@Suite struct HexColorTests {
    @Test func parsesSixAndEightDigit() throws {
        let six = try #require(HexColor("#FF8000"))
        #expect(six.red == 1)
        #expect(abs(six.green - 128.0 / 255) < 0.0001)
        #expect(six.blue == 0)
        #expect(six.alpha == 1)

        let eight = try #require(HexColor("#ff800080"))
        #expect(abs(eight.alpha - 128.0 / 255) < 0.0001)
        #expect(eight.hexString == "#FF800080")
        #expect(six.hexString == "#FF8000")
    }

    @Test func parsesThreeDigit() throws {
        let short = try #require(HexColor("#fA0"))
        #expect(short == HexColor("#FFAA00"))
        #expect(short.hexString == "#FFAA00")
    }

    @Test func rejectsGarbage() {
        #expect(HexColor("#GG0000") == nil)
        #expect(HexColor("red") == nil)
        #expect(HexColor("#12345") == nil)
        #expect(HexColor("") == nil)
        #expect(HexColor("#+12") == nil)
    }

    @Test func codableRoundTripAndInvalidStringThrows() throws {
        let data = try JSONEncoder().encode([HexColor("#123456")!])
        #expect(String(decoding: data, as: UTF8.self) == "[\"#123456\"]")
        #expect(try JSONDecoder().decode([HexColor].self, from: data) == [HexColor("#123456")!])
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([HexColor].self, from: Data("[\"nope\"]".utf8))
        }
    }
}
