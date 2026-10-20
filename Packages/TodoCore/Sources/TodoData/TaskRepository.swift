#if canImport(SwiftData)
import Foundation
import SwiftData
import TodoKit

public enum RepositoryError: Error, Equatable {
    case emptyTitle, notFound
}

/// All task and list mutations go through here; every mutating method saves the context.
@MainActor
public final class TaskRepository {
    public let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    // MARK: Lists

    public func lists() throws -> [TaskList] {
        try context.fetch(FetchDescriptor<TaskList>(sortBy: [SortDescriptor(\TaskList.sortIndex), SortDescriptor(\TaskList.createdAt)]))
    }

    /// The first list, creating one named `name` when none exist.
    @discardableResult
    public func ensureDefaultList(name: String = "Personal") throws -> TaskList {
        if let first = try lists().first { return first }
        let list = TaskList(name: name, sortIndex: 0)
        context.insert(list)
        try context.save()
        return list
    }

    @discardableResult
    public func addList(name: String) throws -> TaskList {
        guard let name = TaskTitle.normalized(name) else { throw RepositoryError.emptyTitle }
        let existing = try lists()
        let nextIndex = (existing.map(\.sortIndex).max() ?? -1) + 1
        let list = TaskList(name: name, sortIndex: nextIndex)
        context.insert(list)
        try context.save()
        return list
    }

    public func renameList(id: UUID, name: String) throws {
        guard let name = TaskTitle.normalized(name) else { throw RepositoryError.emptyTitle }
        guard let list = try findList(id: id) else { throw RepositoryError.notFound }
        list.name = name
        try context.save()
    }

    /// Deletes the list and its tasks. Deleting a missing list does nothing.
    public func deleteList(id: UUID) throws {
        guard let list = try findList(id: id) else { return }
        // Delete tasks explicitly rather than relying on the cascade rule alone.
        for task in list.tasks ?? [] {
            context.delete(task)
        }
        context.delete(list)
        try context.save()
    }

    /// Gives the lists in `ids` the sort order of their position; unknown ids are ignored.
    public func reorderLists(_ ids: [UUID]) throws {
        let all = try lists()
        let byID = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for (index, id) in ids.enumerated() {
            byID[id]?.sortIndex = index
        }
        try context.save()
    }

    // MARK: Tasks

    public func snapshots() throws -> [TaskSnapshot] {
        try context.fetch(FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\TaskItem.sortIndex), SortDescriptor(\TaskItem.createdAt)]))
            .map(\.snapshot)
    }

    public func task(id: UUID) throws -> TaskItem? {
        let taskID = id
        var descriptor = FetchDescriptor<TaskItem>(predicate: #Predicate<TaskItem> { $0.id == taskID })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// A nil or unknown `listID` puts the task in the default list.
    @discardableResult
    public func addTask(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        hasDueTime: Bool = false,
        repeatRule: RepeatRule = .none,
        listID: UUID? = nil
    ) throws -> TaskItem {
        guard let title = TaskTitle.normalized(title) else { throw RepositoryError.emptyTitle }
        let list = try resolvedList(listID)
        let sortIndex = try nextTaskSortIndex()
        let item = TaskItem(
            title: title,
            notes: notes,
            dueDate: dueDate,
            hasDueTime: dueDate != nil && hasDueTime,
            repeatRule: repeatRule,
            sortIndex: sortIndex
        )
        context.insert(item)
        item.list = list
        try context.save()
        return item
    }

    /// Replaces the editable fields. A nil or unknown `listID` keeps the current list
    /// (or uses the default list when the task has none).
    public func updateTask(
        id: UUID,
        title: String,
        notes: String,
        dueDate: Date?,
        hasDueTime: Bool,
        repeatRule: RepeatRule,
        listID: UUID?
    ) throws {
        guard let title = TaskTitle.normalized(title) else { throw RepositoryError.emptyTitle }
        guard let item = try task(id: id) else { throw RepositoryError.notFound }
        item.title = title
        item.notes = notes
        item.dueDate = dueDate
        item.hasDueTime = dueDate != nil && hasDueTime
        item.repeatRule = repeatRule
        if let listID, let list = try findList(id: listID) {
            item.list = list
        } else if item.list == nil {
            item.list = try ensureDefaultList()
        }
        try context.save()
    }

    /// Completing a repeating task with a due date advances it instead (see `TaskCompletion`).
    public func toggleCompletion(id: UUID, now: Date = .now, calendar: Calendar = .current) throws {
        guard let item = try task(id: id) else { throw RepositoryError.notFound }
        let result = TaskCompletion.toggle(
            isCompleted: item.isCompleted,
            dueDate: item.dueDate,
            repeatRule: item.repeatRule,
            now: now,
            calendar: calendar
        )
        item.isCompleted = result.isCompleted
        item.completedAt = result.completedAt
        item.dueDate = result.dueDate
        try context.save()
    }

    /// Deleting a missing task (e.g. already removed by sync) does nothing.
    public func deleteTask(id: UUID) throws {
        guard let item = try task(id: id) else { return }
        context.delete(item)
        try context.save()
    }

    /// Undo: recreates the task from `snapshot`, or overwrites it if it still exists.
    /// A missing list falls back to the default list.
    @discardableResult
    public func restore(_ snapshot: TaskSnapshot) throws -> TaskItem {
        let item: TaskItem
        if let existing = try task(id: snapshot.id) {
            item = existing
        } else {
            item = TaskItem(id: snapshot.id, title: snapshot.title, createdAt: snapshot.createdAt)
            context.insert(item)
        }
        item.title = snapshot.title
        item.notes = snapshot.notes
        item.dueDate = snapshot.dueDate
        item.hasDueTime = snapshot.hasDueTime
        item.repeatRule = snapshot.repeatRule
        item.isCompleted = snapshot.isCompleted
        item.completedAt = snapshot.completedAt
        item.sortIndex = snapshot.sortIndex
        item.createdAt = snapshot.createdAt
        item.list = try resolvedList(snapshot.listID)
        try context.save()
        return item
    }

    /// Deletes tasks completed at least `AppConstants.completedRetentionDays` ago; returns how many.
    @discardableResult
    public func purgeCompleted(now: Date = .now, calendar: Calendar = .current) throws -> Int {
        let completed = try context.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate<TaskItem> { $0.isCompleted == true }))
        let ids = Set(CompletedTaskCleanup.idsToDelete(completed.map(\.snapshot), now: now, calendar: calendar))
        guard !ids.isEmpty else { return 0 }
        for item in completed where ids.contains(item.id) {
            context.delete(item)
        }
        try context.save()
        return ids.count
    }

    // MARK: Helpers

    private func findList(id: UUID) throws -> TaskList? {
        let listID = id
        var descriptor = FetchDescriptor<TaskList>(predicate: #Predicate<TaskList> { $0.id == listID })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func resolvedList(_ id: UUID?) throws -> TaskList {
        if let id, let list = try findList(id: id) { return list }
        return try ensureDefaultList()
    }

    private func nextTaskSortIndex() throws -> Int {
        var descriptor = FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\TaskItem.sortIndex, order: .reverse)])
        descriptor.fetchLimit = 1
        let last = try context.fetch(descriptor).first
        return (last?.sortIndex ?? -1) + 1
    }
}
#endif
