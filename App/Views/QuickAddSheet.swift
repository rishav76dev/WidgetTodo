import SwiftData
import SwiftUI
import TodoData
import TodoKit
import TodoUI

/// Rapid entry: Return adds the task, clears the field and keeps the keyboard up. Chips stay set between tasks.
struct QuickAddSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.sortIndex) private var lists: [TaskList]
    @FocusState private var isTitleFocused: Bool
    @State private var title = ""
    /// Start of the due day; nil means no date (unless a time is set, which implies today).
    @State private var day: Date? = nil
    @State private var time: Date? = nil
    @State private var repeatRule: RepeatRule = .none
    @State private var listID: UUID? = nil
    @State private var showsDatePicker = false
    @State private var showsTimePicker = false
    @State private var lastAdded: String? = nil
    @State private var addedCount = 0

    /// `.today` preselects Today and `.list(id)` preselects that list.
    init(filter: TaskFilter?) {
        switch filter {
        case .today?:
            _day = State(initialValue: Calendar.current.startOfDay(for: .now))
        case .list(let id)?:
            _listID = State(initialValue: id)
        default:
            break
        }
    }

    private var theme: Theme { model.appTheme }
    private var canAdd: Bool { TaskTitle.normalized(title) != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                TextField("New task", text: $title)
                    .font(.title3)
                    .focused($isTitleFocused)
                    .submitLabel(.done)
                    .onSubmit(add)
                Button(action: add) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                }
                .disabled(!canAdd)
                .accessibilityLabel("Add task")
            }
            chips
            if let lastAdded {
                Text("Added “\(lastAdded)”")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(190), .medium])
        .presentationDragIndicator(.visible)
        .sensoryFeedback(.success, trigger: addedCount)
        .onAppear { isTitleFocused = true }
        .onChange(of: showsDatePicker) { _, shown in if !shown { isTitleFocused = true } }
        .onChange(of: showsTimePicker) { _, shown in if !shown { isTitleFocused = true } }
    }

    // MARK: Chips

    private var chips: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let isOtherDay = day.map { $0 != today && $0 != tomorrow } ?? false
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button { toggleDay(today) } label: {
                    ChipLabel(title: "Today", isSelected: day == today, theme: theme)
                }
                Button { toggleDay(tomorrow) } label: {
                    ChipLabel(title: "Tomorrow", isSelected: day == tomorrow, theme: theme)
                }
                Button { showsDatePicker = true } label: {
                    ChipLabel(
                        title: isOtherDay ? (day ?? today).formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)) : "Date…",
                        systemImage: "calendar",
                        isSelected: isOtherDay,
                        theme: theme
                    )
                }
                .popover(isPresented: $showsDatePicker) { datePicker }
                Button { showsTimePicker = true } label: {
                    ChipLabel(
                        title: time?.formatted(date: .omitted, time: .shortened) ?? "Time…",
                        systemImage: "clock",
                        isSelected: time != nil,
                        theme: theme
                    )
                }
                .popover(isPresented: $showsTimePicker) { timePicker }
                repeatMenu
                listMenu
            }
            .buttonStyle(.plain)
            .padding(.vertical, 2)
        }
    }

    private var repeatMenu: some View {
        Menu {
            Picker("Repeat", selection: $repeatRule) {
                ForEach(RepeatRule.allCases, id: \.self) { rule in
                    Text(rule.displayName).tag(rule)
                }
            }
        } label: {
            ChipLabel(
                title: repeatRule == .none ? "Repeat" : repeatRule.displayName,
                systemImage: "repeat",
                isSelected: repeatRule != .none,
                theme: theme
            )
        }
    }

    private var listMenu: some View {
        let selected = lists.first { $0.id == listID } ?? lists.first
        return Menu {
            Picker("List", selection: Binding(get: { selected?.id }, set: { listID = $0 })) {
                ForEach(lists) { list in
                    Text(list.name).tag(Optional(list.id))
                }
            }
        } label: {
            ChipLabel(title: selected?.name ?? "List", systemImage: "list.bullet", isSelected: false, theme: theme)
        }
        .disabled(lists.isEmpty)
    }

    private var datePicker: some View {
        let today = Calendar.current.startOfDay(for: .now)
        return VStack(spacing: 8) {
            DatePicker(
                "Date",
                selection: Binding(get: { day ?? today }, set: { day = Calendar.current.startOfDay(for: $0) }),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            HStack {
                Button("No Date", role: .destructive) {
                    day = nil
                    time = nil
                    showsDatePicker = false
                }
                Spacer()
                Button("Done") { showsDatePicker = false }
                    .bold()
            }
        }
        .padding()
        .frame(minWidth: 320)
        .presentationCompactAdaptation(.popover)
    }

    private var timePicker: some View {
        VStack(spacing: 8) {
            DatePicker(
                "Time",
                selection: Binding(get: { time ?? Self.nextHour() }, set: { time = $0 }),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            HStack {
                Button("No Time", role: .destructive) {
                    time = nil
                    showsTimePicker = false
                }
                Spacer()
                Button("Done") {
                    if time == nil { time = Self.nextHour() }
                    showsTimePicker = false
                }
                .bold()
            }
        }
        .padding()
        .frame(minWidth: 280)
        .presentationCompactAdaptation(.popover)
    }

    // MARK: Actions

    private func toggleDay(_ value: Date) {
        day = day == value ? nil : value
        if day == nil { time = nil }
    }

    /// A time without a day means today. All-day tasks are stored at the start of their day.
    private var due: (date: Date?, hasTime: Bool) {
        guard day != nil || time != nil else { return (nil, false) }
        let calendar = Calendar.current
        let base = day ?? calendar.startOfDay(for: .now)
        guard let time else { return (base, false) }
        let parts = calendar.dateComponents([.hour, .minute], from: time)
        let date = calendar.date(bySettingHour: parts.hour ?? 9, minute: parts.minute ?? 0, second: 0, of: base) ?? base
        return (date, true)
    }

    private func add() {
        guard let normalized = TaskTitle.normalized(title) else {
            isTitleFocused = true
            return
        }
        let due = self.due
        do {
            try TaskRepository(context: modelContext).addTask(
                title: normalized,
                notes: "",
                dueDate: due.date,
                hasDueTime: due.hasTime,
                repeatRule: due.date == nil ? .none : repeatRule,
                listID: listID
            )
        } catch {
            isTitleFocused = true
            return
        }
        title = ""
        lastAdded = normalized
        addedCount += 1
        isTitleFocused = true
        model.tasksDidChange(context: modelContext, savedTimedTask: due.hasTime)
    }

    private static func nextHour() -> Date {
        let calendar = Calendar.current
        let now = Date.now
        let hour = calendar.component(.hour, from: now)
        return calendar.date(bySettingHour: min(hour + 1, 23), minute: 0, second: 0, of: now) ?? now
    }
}

/// A capsule chip used by Home's filter bar and Quick Add.
struct ChipLabel: View {
    let title: String
    var systemImage: String?
    var isSelected = false
    let theme: Theme

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(verbatim: title)
                .lineLimit(1)
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .foregroundStyle(isSelected ? Self.contrast(on: theme.accent) : theme.textPrimary.color)
        .background(isSelected ? theme.accent.color : theme.textSecondary.color.opacity(0.15), in: Capsule())
        .contentShape(Capsule())
    }

    /// Black or white, whichever reads better on `fill`.
    static func contrast(on fill: HexColor) -> Color {
        let luminance = 0.299 * fill.red + 0.587 * fill.green + 0.114 * fill.blue
        return luminance > 0.6 ? .black : .white
    }
}
