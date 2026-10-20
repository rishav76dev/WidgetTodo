#if canImport(SwiftUI)
import SwiftUI
import WidgetKit
import TodoKit

/// The widget's content for every size, also used for in-app theme previews.
/// It draws no background and no outer padding: widgets use `containerBackground` and the system
/// content margins, other callers add `ThemedBackground` and their own padding.
public struct TaskListWidgetView: View {
    let model: WidgetViewModel
    let theme: Theme
    let size: WidgetSize
    let checkbox: (TaskSnapshot) -> AnyView
    let addLink: URL
    let taskLink: (TaskSnapshot) -> URL?

    @Environment(\.widgetRenderingMode) private var renderingMode

    public init(
        model: WidgetViewModel,
        theme: Theme,
        size: WidgetSize,
        checkbox: @escaping (TaskSnapshot) -> AnyView,
        addLink: URL,
        taskLink: @escaping (TaskSnapshot) -> URL?
    ) {
        self.model = model
        self.theme = theme
        self.size = size
        self.checkbox = checkbox
        self.addLink = addLink
        self.taskLink = taskLink
    }

    private var style: ThemeStyle { ThemeStyle(theme) }
    private var isFullColor: Bool { renderingMode == .fullColor }
    private var isFocus: Bool { theme.layout == .focus }
    /// Widget rows sit closer together than the theme's in-app spacing.
    private var rowSpacing: CGFloat { CGFloat(min(max(theme.row.spacing, 0), 4)) }

    /// Row counts to try, most first. Themes with large fonts or card rows show fewer rows
    /// rather than have the "+N more" line and footer clipped off the bottom.
    private var rowCounts: [Int] {
        let available = min(model.content.visible.count, isFocus ? 1 : size.maxRows)
        return available > 1 ? Array((1...available).reversed()) : [available]
    }

    public var body: some View {
        ViewThatFits(in: .vertical) {
            ForEach(rowCounts, id: \.self) { count in
                content(rowCount: count)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .shadow(color: theme.glow && isFullColor ? style.accent.opacity(0.8) : .clear, radius: theme.glow && isFullColor ? 4 : 0)
    }

    private func content(rowCount: Int) -> some View {
        let rows = Array(model.content.visible.prefix(rowCount))
        // Open tasks not shown, including any the focus layout leaves out.
        let hiddenCount = model.content.openCount - rows.count
        // The focus layout with a count footer already says how many tasks there are.
        let showsMore = hiddenCount > 0 && !(isFocus && theme.footer == .count)
        return VStack(alignment: .leading, spacing: 4) {
            header
            if rows.isEmpty {
                caption("All clear", font: style.font(.title))
            } else {
                if isFocus { Spacer(minLength: 0) }
                VStack(alignment: .leading, spacing: rowSpacing) {
                    ForEach(rows) { task in
                        row(task)
                    }
                }
            }
            if showsMore {
                caption("+\(hiddenCount) more")
            }
            Spacer(minLength: 0)
            footer
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 6) {
            headerTitle
                .widgetAccentable(!isFullColor)
            Spacer(minLength: 4)
            if size == .small {
                Text("\(model.content.openCount)")
                    .font(style.font(.caption))
                    .foregroundStyle(style.secondary)
            }
            Link(destination: addLink) {
                Image(systemName: "plus")
                    .font(style.font(.header))
                    .foregroundStyle(style.accent)
                    .frame(minWidth: 20, minHeight: 20)
                    .contentShape(Rectangle())
            }
            .widgetAccentable(!isFullColor)
            .accessibilityLabel("Add task")
        }
    }

    @ViewBuilder
    private var headerTitle: some View {
        let title = Text(style.cased(theme.header.prefix + model.title))
            .font(style.font(.header))
            .foregroundStyle(style.primary)
            .lineLimit(1)
        if theme.header.style == .stamp {
            title
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .overlay { Rectangle().strokeBorder(style.primary, lineWidth: 2) }
        } else {
            title
        }
    }

    private func row(_ task: TaskSnapshot) -> some View {
        ThemedTaskRow(
            task: task,
            theme: theme,
            now: model.now,
            checkbox: AnyView(checkbox(task).widgetAccentable(!isFullColor)),
            titleRole: isFocus ? .display : .title,
            link: taskLink(task),
            compact: true
        )
    }

    /// A locked theme's notice replaces the footer, so it is never the line that gets clipped.
    @ViewBuilder
    private var footer: some View {
        if model.isLockedFallback {
            Link(destination: DeepLink.themes.url) {
                caption("Theme locked · tap to unlock")
            }
        } else {
            themeFooter
        }
    }

    @ViewBuilder
    private var themeFooter: some View {
        let count = model.content.openCount
        switch theme.footer {
        case .none:
            EmptyView()
        case .count:
            caption(count == 1 ? "1 task" : "\(count) tasks")
        case .receipt:
            VStack(alignment: .leading, spacing: 4) {
                HorizontalLine()
                    .stroke(style.secondary, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .frame(height: 1)
                caption("TOTAL: \(count) " + (count == 1 ? "ITEM" : "ITEMS"), font: style.font(.caption).bold())
            }
        }
    }

    private func caption(_ text: String, font: Font? = nil) -> some View {
        Text(style.cased(text))
            .font(font ?? style.font(.caption))
            .foregroundStyle(style.secondary)
            .lineLimit(1)
    }
}

#Preview("Terminal, medium") {
    let now = Date()
    let calendar = Calendar.current
    let theme = ThemeCatalog.bundled.theme(id: "terminal")
    let tasks = SampleTasks.make(now: now, calendar: calendar)
    let content = WidgetLayout.content(tasks: tasks, filter: .all, size: .medium, now: now, calendar: calendar)
    let model = WidgetViewModel(
        title: WidgetViewModel.title(for: .all, listName: nil),
        filter: .all,
        content: content,
        isLockedFallback: false,
        now: now
    )
    TaskListWidgetView(
        model: model,
        theme: theme,
        size: .medium,
        checkbox: { AnyView(ThemedCheckbox(theme: theme, isCompleted: $0.isCompleted)) },
        addLink: DeepLink.quickAdd(.all).url,
        taskLink: { DeepLink.task($0.id).url }
    )
    .padding(16)
    .frame(width: 338, height: 158)
    .background { ThemedBackground(theme: theme) }
}
#endif
