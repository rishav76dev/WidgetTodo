#if canImport(SwiftUI)
import SwiftUI
import TodoKit

/// One task: the checkbox, the cased title and the due label (in the overdue colour once overdue).
/// Completed tasks are struck through.
public struct ThemedTaskRow: View {
    let task: TaskSnapshot
    let theme: Theme
    let now: Date
    let checkbox: AnyView
    let titleRole: FontRole
    let link: URL?
    let compact: Bool

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    /// `link` wraps the title and due label, not the checkbox, so a checkbox `Button` stays tappable in widgets.
    /// `compact` puts the due label on the title's line, trailing, so widget rows take one line.
    public init(
        task: TaskSnapshot, theme: Theme, now: Date, checkbox: AnyView,
        titleRole: FontRole = .title, link: URL? = nil, compact: Bool = false
    ) {
        self.task = task
        self.theme = theme
        self.now = now
        self.checkbox = checkbox
        self.titleRole = titleRole
        self.link = link
        self.compact = compact
    }

    public var body: some View {
        let style = ThemeStyle(theme)
        HStack(alignment: .center, spacing: 8) {
            checkbox
            if let link {
                Link(destination: link) { label(style) }
            } else {
                label(style)
            }
        }
        .modifier(RowDecoration(theme: theme, compact: compact))
    }

    private func label(_ style: ThemeStyle) -> some View {
        let due = DueDateFormatter.label(for: task, now: now, calendar: calendar, locale: locale)
        return Group {
            if compact && titleRole != .display {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    title(style)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let due {
                        dueLabel(due, style: style)
                            .layoutPriority(1)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    title(style)
                    if let due {
                        dueLabel(due, style: style)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func title(_ style: ThemeStyle) -> some View {
        let isDisplay = titleRole == .display
        return Text(style.cased(task.title))
            .font(style.font(titleRole))
            .strikethrough(task.isCompleted)
            .foregroundStyle(task.isCompleted ? style.secondary : style.primary)
            .lineLimit(isDisplay ? 3 : 1)
            .minimumScaleFactor(isDisplay ? 0.6 : 1)
    }

    private func dueLabel(_ due: String, style: ThemeStyle) -> some View {
        let isOverdue = TaskGrouping.isOverdue(task, now: now, calendar: calendar)
        return Text(style.cased(due))
            .font(style.font(.caption))
            .foregroundStyle(isOverdue ? style.overdue : style.secondary)
            .lineLimit(1)
    }
}

/// Row chrome per `row.style`: nothing, a hairline divider, a dashed rule, or a bordered card.
struct RowDecoration: ViewModifier {
    let theme: Theme
    var compact = false

    @ViewBuilder
    func body(content: Content) -> some View {
        let style = ThemeStyle(theme)
        switch theme.row.style {
        case .plain:
            content
        case .divider:
            content
                .padding(.bottom, 4)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(style.secondary.opacity(0.35)).frame(height: 0.5)
                }
        case .dashed:
            content
                .padding(.bottom, 4)
                .overlay(alignment: .bottom) {
                    HorizontalLine()
                        .stroke(style.secondary, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .frame(height: 1)
                }
        case .card:
            let shape = RoundedRectangle(cornerRadius: CGFloat(min(max(theme.cornerRadius, 0), 12)))
            content
                .padding(.horizontal, 8)
                .padding(.vertical, compact ? 4 : 6)
                .background { shape.fill(style.primary.opacity(0.06)) }
                .overlay { shape.strokeBorder(style.primary, lineWidth: 2) }
        }
    }
}
#endif
