import SwiftData
import SwiftUI
import TodoData
import TodoKit
import TodoUI

/// Tasks for the selected filter, grouped Overdue / Today / Tomorrow / Upcoming / No date, with Completed collapsed.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [TaskItem]
    @Query(sort: \TaskList.sortIndex) private var lists: [TaskList]
    @State private var showsCompleted = false
    @State private var deleted: TaskSnapshot?
    @State private var completions = 0

    private var theme: Theme { model.appTheme }
    private var style: ThemeStyle { ThemeStyle(theme) }

    /// The selected filter, or All when its list no longer exists.
    private var filter: TaskFilter {
        if case .list(let id) = model.homeFilter, !lists.contains(where: { $0.id == id }) { return .all }
        return model.homeFilter
    }

    private var title: String {
        var listName: String?
        if case .list(let id) = filter { listName = lists.first { $0.id == id }?.name }
        return WidgetViewModel.title(for: filter, listName: listName)
    }

    var body: some View {
        TimelineView(.everyMinute) { context in
            taskList(now: context.date)
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { model.route = .themes } label: { Label("Themes", systemImage: "paintpalette") }
                Button { model.route = .lists } label: { Label("Lists", systemImage: "list.bullet") }
                Button { model.route = .settings } label: { Label("Settings", systemImage: "gearshape") }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { filterBar }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .task(id: deleted?.id) {
            guard deleted != nil else { return }
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            withAnimation { deleted = nil }
        }
        .sensoryFeedback(.success, trigger: completions)
    }

    // MARK: List

    @ViewBuilder
    private func taskList(now: Date) -> some View {
        let calendar = Calendar.current
        let activeFilter = filter
        let snapshots = items.map(\.snapshot).filter { activeFilter.includes($0, now: now, calendar: calendar) }
        let groups = TaskGrouping.grouped(snapshots, now: now, calendar: calendar)
        List {
            ForEach(groups, id: \.group) { section in
                Section {
                    if section.group != .completed || showsCompleted {
                        ForEach(section.tasks) { task in
                            row(task, now: now)
                        }
                    }
                } header: {
                    header(for: section)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background { ThemedBackground(theme: theme).ignoresSafeArea() }
        .overlay {
            if groups.isEmpty { emptyState }
        }
    }

    private func row(_ task: TaskSnapshot, now: Date) -> some View {
        TaskRowView(task: task, theme: theme, now: now) { toggle(task) }
            .contentShape(Rectangle())
            .onTapGesture { model.route = .task(task.id) }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: CGFloat(theme.row.spacing) / 2, leading: 16, bottom: CGFloat(theme.row.spacing) / 2, trailing: 16))
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button { toggle(task) } label: {
                    Label(task.isCompleted ? "Not Done" : "Done", systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                }
                .tint(.green)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button { delete(task) } label: { Label("Delete", systemImage: "trash") }
                    .tint(.red)
            }
    }

    @ViewBuilder
    private func header(for section: GroupedTasks) -> some View {
        let text = style.cased(section.group.title)
        let color = section.group == .overdue ? style.overdue : style.secondary
        Group {
            if section.group == .completed {
                Button {
                    withAnimation { showsCompleted.toggle() }
                } label: {
                    HStack {
                        Text(verbatim: "\(text) (\(section.tasks.count))")
                        Spacer()
                        Image(systemName: showsCompleted ? "chevron.down" : "chevron.right")
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(showsCompleted ? "Hides completed tasks" : "Shows completed tasks")
            } else {
                Text(verbatim: text)
            }
        }
        .font(style.font(.header))
        .foregroundStyle(color)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text(verbatim: style.cased("All clear"))
                .font(style.font(.display))
                .foregroundStyle(style.primary)
            Text("Tap + to add a task.")
                .font(style.font(.caption))
                .foregroundStyle(style.secondary)
        }
        .multilineTextAlignment(.center)
        .padding()
        .allowsHitTesting(false)
    }

    // MARK: Bars

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All", .all)
                filterChip("Today", .today)
                ForEach(lists) { list in
                    filterChip(list.name, .list(list.id))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func filterChip(_ title: String, _ value: TaskFilter) -> some View {
        Button {
            model.homeFilter = value
        } label: {
            ChipLabel(title: title, isSelected: filter == value, theme: theme)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(filter == value ? .isSelected : [])
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if let deleted {
                UndoBanner(message: "Deleted “\(deleted.title)”", onUndo: undoDelete)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Spacer()
            }
            Button {
                model.route = .quickAdd(filter)
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(ChipLabel.contrast(on: theme.accent))
                    .frame(width: 56, height: 56)
                    .background(style.accent, in: Circle())
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
            }
            .accessibilityLabel("Add task")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: Actions

    private func toggle(_ task: TaskSnapshot) {
        do {
            try TaskRepository(context: modelContext).toggleCompletion(id: task.id)
        } catch {
            return
        }
        if !task.isCompleted { completions += 1 }
        model.tasksDidChange(context: modelContext)
    }

    private func delete(_ task: TaskSnapshot) {
        do {
            try TaskRepository(context: modelContext).deleteTask(id: task.id)
        } catch {
            return
        }
        withAnimation { deleted = task }
        model.tasksDidChange(context: modelContext)
    }

    private func undoDelete() {
        guard let task = deleted else { return }
        _ = try? TaskRepository(context: modelContext).restore(task)
        withAnimation { deleted = nil }
        model.tasksDidChange(context: modelContext)
    }
}
