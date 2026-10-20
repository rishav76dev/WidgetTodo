import Foundation

/// `todo1://quick-add?list=<filter>`, `todo1://task/<id>` and `todo1://themes`.
public enum DeepLink: Equatable, Sendable {
    case quickAdd(TaskFilter?)
    case task(UUID)
    case themes

    private static let quickAddHost = "quick-add"
    private static let taskHost = "task"
    private static let themesHost = "themes"
    private static let listQueryItem = "list"

    public init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == AppConstants.urlScheme
        else { return nil }
        switch components.host?.lowercased() {
        case Self.quickAddHost:
            let raw = components.queryItems?.first { $0.name == Self.listQueryItem }?.value
            self = .quickAdd(raw.flatMap(TaskFilter.init(rawValue:)))
        case Self.taskHost:
            let segments = components.path.split(separator: "/")
            guard segments.count == 1, let id = UUID(uuidString: String(segments[0])) else { return nil }
            self = .task(id)
        case Self.themesHost:
            self = .themes
        default:
            return nil
        }
    }

    public var url: URL {
        var components = URLComponents()
        components.scheme = AppConstants.urlScheme
        switch self {
        case .quickAdd(let filter):
            components.host = Self.quickAddHost
            if let filter {
                components.queryItems = [URLQueryItem(name: Self.listQueryItem, value: filter.rawValue)]
            }
        case .task(let id):
            components.host = Self.taskHost
            components.path = "/" + id.uuidString
        case .themes:
            components.host = Self.themesHost
        }
        return components.url!
    }
}
