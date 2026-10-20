import Foundation

/// Identifiers and product limits shared by the app, the widget and the tests.
public enum AppConstants {
    public static let appGroupID = "group.ai.shavastudios.todo1"
    public static let iCloudContainerID = "iCloud.ai.shavastudios.todo1"
    public static let urlScheme = "todo1"
    public static let entitlementID = "premium"
    public static let defaultThemeID = "paper"
    public static let defaultFreeThemeCount = 3
    public static let maxScheduledNotifications = 60
    public static let completedRetentionDays = 30
    public static let maxTitleLength = 500
    public static let privacyPolicyURL = URL(string: "https://shavastudios.ai/todo1/privacy")!
    public static let termsURL = URL(string: "https://shavastudios.ai/todo1/terms")!
}
