import SwiftData
import SwiftUI
import TodoData
import TodoKit

/// Edits every field of one task. Changes are saved with Save; Cancel or swiping down discards them.
struct TaskEditorView: View {
    let taskID: UUID

    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskList.sortIndex) private var lists: [TaskList]
    @State private var draft = Draft()
    @State private var isLoaded = false
    @State private var isMissing = false
    @State private var confirmsDelete = false

    private struct Draft {
        var title = ""
        var notes = ""
        var hasDate = false
        var date = Date.now
        var hasTime = false
        var repeatRule: RepeatRule = .none
        var listID: UUID?
    }

    var body: some View {
        Group {
            if isMissing {
                ContentUnavailableView(
                    "Task not found",
                    systemImage: "questionmark.circle",
                    description: Text("It may have been deleted on another device.")
                )
            } else {
                form
            }
        }
        .navigationTitle("Edit Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(isMissing || TaskTitle.normalized(draft.title) == nil)
            }
        }
        .onAppear(perform: load)
        .confirmationDialog("Delete this task?", isPresented: $confirmsDelete, titleVisibility: .visible) {
            Button("Delete Task", role: .destructive, action: deleteTask)
        }
    }

    private var form: some View {
        Form {
            Section {
                TextField("Title", text: $draft.title, axis: .vertical)
                    .font(.headline)
                TextField("Notes", text: $draft.notes, axis: .vertical)
                    .lineLimit(3...8)
            }
            Section {
                Toggle("Date", isOn: $draft.hasDate.animation())
                if draft.hasDate {
                    DatePicker("Day", selection: $draft.date, displayedComponents: .date)
                    Toggle("Time", isOn: Binding(get: { draft.hasTime }, set: setHasTime).animation())
                    if draft.hasTime {
                        DatePicker("Time", selection: $draft.date, displayedComponents: .hourAndMinute)
                    }
                    Picker("Repeat", selection: $draft.repeatRule) {
                        ForEach(RepeatRule.allCases, id: \.self) { rule in
                            Text(rule.displayName).tag(rule)
                        }
                    }
                }
            }
            if !lists.isEmpty {
                Section {
                    Picker("List", selection: $draft.listID) {
                        ForEach(lists) { list in
                            Text(list.name).tag(Optional(list.id))
                        }
                    }
                }
            }
            Section {
                Button("Delete Task", role: .destructive) { confirmsDelete = true }
            }
        }
    }

    /// Turning the time on for an all-day task (stored at midnight) starts at 9:00.
    private func setHasTime(_ on: Bool) {
        draft.hasTime = on
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.hour, .minute], from: draft.date)
        if on, parts.hour == 0, parts.minute == 0 {
            draft.date = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: draft.date) ?? draft.date
        }
    }

    private func load() {
        guard !isLoaded else { return }
        isLoaded = true
        guard let item = try? TaskRepository(context: modelContext).task(id: taskID) else {
            isMissing = true
            return
        }
        let task = item.snapshot
        draft = Draft(
            title: task.title,
            notes: task.notes,
            hasDate: task.dueDate != nil,
            date: task.dueDate ?? Calendar.current.startOfDay(for: .now),
            hasTime: task.dueDate != nil && task.hasDueTime,
            repeatRule: task.repeatRule,
            listID: task.listID ?? lists.first?.id
        )
    }

    private func save() {
        let calendar = Calendar.current
        let dueDate: Date? = draft.hasDate ? (draft.hasTime ? draft.date : calendar.startOfDay(for: draft.date)) : nil
        let hasTime = dueDate != nil && draft.hasTime
        do {
            try TaskRepository(context: modelContext).updateTask(
                id: taskID,
                title: draft.title,
                notes: draft.notes,
                dueDate: dueDate,
                hasDueTime: hasTime,
                repeatRule: dueDate == nil ? .none : draft.repeatRule,
                listID: draft.listID
            )
        } catch RepositoryError.notFound {
            isMissing = true
            return
        } catch {
            return
        }
        model.tasksDidChange(context: modelContext, savedTimedTask: hasTime)
        dismiss()
    }

    private func deleteTask() {
        try? TaskRepository(context: modelContext).deleteTask(id: taskID)
        model.tasksDidChange(context: modelContext)
        dismiss()
    }
}
