import SwiftUI
import TodoKit
import TodoUI

/// A themed task row whose checkbox toggles completion; the rest of the row is left for the caller's tap.
struct TaskRowView: View {
    let task: TaskSnapshot
    let theme: Theme
    let now: Date
    let onToggle: () -> Void

    var body: some View {
        ThemedTaskRow(task: task, theme: theme, now: now, checkbox: AnyView(checkbox))
    }

    private var checkbox: some View {
        Button(action: onToggle) {
            ThemedCheckbox(theme: theme, isCompleted: task.isCompleted)
                .frame(minWidth: 32, minHeight: 32)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(task.isCompleted ? "Mark as not done" : "Mark as done")
    }
}
