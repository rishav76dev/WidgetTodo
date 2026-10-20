import Foundation
import Testing
@testable import TodoKit

@Suite struct DeepLinkTests {
    @Test func quickAddRoundTrip() {
        let listID = UUID()
        for link in [DeepLink.quickAdd(.today), .quickAdd(.list(listID)), .quickAdd(nil), .quickAdd(.all)] {
            #expect(DeepLink(url: link.url) == link)
        }
        #expect(DeepLink.quickAdd(.today).url.absoluteString == "todo1://quick-add?list=today")
        #expect(DeepLink.quickAdd(nil).url.absoluteString == "todo1://quick-add")
    }

    @Test func taskRoundTrip() {
        let id = UUID()
        let link = DeepLink.task(id)
        #expect(link.url.absoluteString == "todo1://task/\(id.uuidString)")
        #expect(DeepLink(url: link.url) == link)
    }

    @Test func themesRoundTrip() {
        #expect(DeepLink.themes.url.absoluteString == "todo1://themes")
        #expect(DeepLink(url: DeepLink.themes.url) == .themes)
    }

    @Test func wrongSchemeRejected() {
        #expect(DeepLink(url: URL(string: "https://quick-add")!) == nil)
        #expect(DeepLink(url: URL(string: "todo1://unknown")!) == nil)
    }

    @Test func badTaskIDRejected() {
        #expect(DeepLink(url: URL(string: "todo1://task/nope")!) == nil)
        #expect(DeepLink(url: URL(string: "todo1://task")!) == nil)
    }

    @Test func invalidListParamGivesNilFilter() {
        #expect(DeepLink(url: URL(string: "todo1://quick-add?list=bogus")!) == .quickAdd(nil))
        #expect(DeepLink(url: URL(string: "todo1://quick-add?list=")!) == .quickAdd(nil))
    }
}
