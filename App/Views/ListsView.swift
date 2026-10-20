import SwiftData
import SwiftUI
import TodoData
import TodoKit

/// Create, rename, reorder and delete lists. Deleting a list deletes its tasks too.
struct ListsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskList.sortIndex) private var lists: [TaskList]
    @State private var newListName = ""
    @State private var renaming: TaskList?
    @State private var renameText = ""
    @State private var deleting: TaskList?

    var body: some View {
        List {
            Section {
                ForEach(lists) { list in
                    HStack {
                        Text(list.name)
                        Spacer()
                        Text("\(openCount(list))")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .swipeActions(edge: .trailing) {
                        Button { deleting = list } label: { Label("Delete", systemImage: "trash") }
                            .tint(.red)
                        Button { startRenaming(list) } label: { Label("Rename", systemImage: "pencil") }
                            .tint(.orange)
                    }
                    .contextMenu {
                        Button { startRenaming(list) } label: { Label("Rename", systemImage: "pencil") }
                        Button(role: .destructive) { deleting = list } label: { Label("Delete", systemImage: "trash") }
                    }
                }
                .onMove(perform: move)
            } footer: {
                Text("Swipe a list to rename or delete it.")
            }
            Section {
                HStack {
                    TextField("New list", text: $newListName)
                        .submitLabel(.done)
                        .onSubmit(addList)
                    Button("Add", action: addList)
                        .disabled(TaskTitle.normalized(newListName) == nil)
                }
            }
        }
        .navigationTitle("Lists")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .alert("Rename List", isPresented: isRenaming, presenting: renaming) { list in
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Save") { rename(list) }
        }
        .confirmationDialog(deleteTitle, isPresented: isDeleting, titleVisibility: .visible, presenting: deleting) { list in
            Button("Delete", role: .destructive) { delete(list) }
        }
    }

    private var isRenaming: Binding<Bool> {
        Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })
    }

    private var isDeleting: Binding<Bool> {
        Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })
    }

    private var deleteTitle: String {
        let count = deleting?.tasks?.count ?? 0
        return count == 1 ? "Delete list and its 1 task?" : "Delete list and its \(count) tasks?"
    }

    private func openCount(_ list: TaskList) -> Int {
        (list.tasks ?? []).filter { !$0.isCompleted }.count
    }

    private func addList() {
        guard TaskTitle.normalized(newListName) != nil else { return }
        guard (try? TaskRepository(context: modelContext).addList(name: newListName)) != nil else { return }
        newListName = ""
        model.tasksDidChange(context: modelContext)
    }

    private func startRenaming(_ list: TaskList) {
        renameText = list.name
        renaming = list
    }

    private func rename(_ list: TaskList) {
        renaming = nil
        guard (try? TaskRepository(context: modelContext).renameList(id: list.id, name: renameText)) != nil else { return }
        model.tasksDidChange(context: modelContext)
    }

    private func move(from source: IndexSet, to destination: Int) {
        var ids = lists.map(\.id)
        ids.move(fromOffsets: source, toOffset: destination)
        try? TaskRepository(context: modelContext).reorderLists(ids)
        IntentSupport.reloadWidgets()
    }

    private func delete(_ list: TaskList) {
        let id = list.id
        deleting = nil
        guard (try? TaskRepository(context: modelContext).deleteList(id: id)) != nil else { return }
        if model.homeFilter == .list(id) { model.homeFilter = .all }
        model.tasksDidChange(context: modelContext)
    }
}
