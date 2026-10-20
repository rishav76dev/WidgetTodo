import Foundation
import Testing
@testable import TodoKit

@Suite struct TaskTitleTests {
    @Test func blankTitleRejected() {
        #expect(TaskTitle.normalized("   \n ") == nil)
        #expect(TaskTitle.normalized("") == nil)
    }

    @Test func titleTrimmedAndCapped() {
        #expect(TaskTitle.normalized("  a\nb  ") == "a b")
        #expect(TaskTitle.normalized("a\r\nb") == "a b")
        #expect(TaskTitle.normalized(String(repeating: "x", count: 600))?.count == 500)
        #expect(TaskTitle.normalized("hello", maxLength: 3) == "hel")
    }
}
