import Testing
@testable import TodoKit

@Suite struct AppConstantsTests {
    @Test func identifiersMatchSpec() {
        #expect(AppConstants.appGroupID == "group.ai.shavastudios.todo1")
        #expect(AppConstants.defaultFreeThemeCount == 3)
        #expect(AppConstants.maxScheduledNotifications == 60)
    }
}
