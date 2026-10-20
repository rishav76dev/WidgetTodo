import Foundation

/// Minimal data store so `SharedStore` can run on App Group `UserDefaults` or in memory for tests.
public protocol KeyValueStore: AnyObject {
    func readData(forKey key: String) -> Data?
    /// Writing nil removes the value.
    func writeData(_ data: Data?, forKey key: String)
}

extension UserDefaults: KeyValueStore {
    public func readData(forKey key: String) -> Data? {
        data(forKey: key)
    }

    public func writeData(_ data: Data?, forKey key: String) {
        if let data {
            set(data, forKey: key)
        } else {
            removeObject(forKey: key)
        }
    }
}

public final class InMemoryKeyValueStore: KeyValueStore, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: Data] = [:]

    public init() {}

    public func readData(forKey key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return values[key]
    }

    public func writeData(_ data: Data?, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        values[key] = data
    }
}

/// App settings shared by the app and the widget.
public struct AppPreferences: Codable, Equatable, Sendable {
    public var appThemeID: String
    public var hasCompletedOnboarding: Bool
    public var notificationsEnabled: Bool
    public var hasAskedNotificationPermission: Bool

    public init(
        appThemeID: String = AppConstants.defaultThemeID,
        hasCompletedOnboarding: Bool = false,
        notificationsEnabled: Bool = true,
        hasAskedNotificationPermission: Bool = false
    ) {
        self.appThemeID = appThemeID
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.notificationsEnabled = notificationsEnabled
        self.hasAskedNotificationPermission = hasAskedNotificationPermission
    }

    private enum CodingKeys: String, CodingKey {
        case appThemeID, hasCompletedOnboarding, notificationsEnabled, hasAskedNotificationPermission
    }

    /// Missing or mistyped keys keep their defaults, so older or newer builds can read each other's data.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppPreferences()
        appThemeID = (try? c.decodeIfPresent(String.self, forKey: .appThemeID)) ?? defaults.appThemeID
        hasCompletedOnboarding = (try? c.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding)) ?? defaults.hasCompletedOnboarding
        notificationsEnabled = (try? c.decodeIfPresent(Bool.self, forKey: .notificationsEnabled)) ?? defaults.notificationsEnabled
        hasAskedNotificationPermission = (try? c.decodeIfPresent(Bool.self, forKey: .hasAskedNotificationPermission)) ?? defaults.hasAskedNotificationPermission
    }
}

/// JSON-encoded entitlements and preferences in a `KeyValueStore`. Missing or corrupt data reads as defaults.
public final class SharedStore: @unchecked Sendable {
    static let entitlementsKey = "entitlements.v1"
    static let preferencesKey = "preferences.v1"

    private let store: KeyValueStore

    public init(store: KeyValueStore) {
        self.store = store
    }

    /// The App Group defaults shared with the widget, or standard defaults if the group is unavailable.
    public static func appGroup() -> SharedStore {
        SharedStore(store: UserDefaults(suiteName: AppConstants.appGroupID) ?? .standard)
    }

    public func loadEntitlements() -> EntitlementState {
        load(EntitlementState.self, forKey: Self.entitlementsKey) ?? .default
    }

    public func saveEntitlements(_ state: EntitlementState) {
        save(state, forKey: Self.entitlementsKey)
    }

    public func loadPreferences() -> AppPreferences {
        load(AppPreferences.self, forKey: Self.preferencesKey) ?? AppPreferences()
    }

    public func savePreferences(_ preferences: AppPreferences) {
        save(preferences, forKey: Self.preferencesKey)
    }

    private func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = store.readData(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        store.writeData(data, forKey: key)
    }
}
