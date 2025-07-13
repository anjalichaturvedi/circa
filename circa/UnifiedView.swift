import SwiftUI

// MARK: - Task Model

struct TaskItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var color: String
    var priority: String
}

struct UnifiedView: View {
    @State private var taskCompletions: [String: [UUID]] = [:]
    @State private var tasks: [TaskItem] = []

    @State private var newTaskName = ""
    @State private var selectedColor = "Blue"
    @State private var selectedPriority = "Medium"

    @State private var displayedMonth: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedDate: Date? = nil

    private let calendar = Calendar.current
    private let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Calendar")
                .font(.title3)
                .bold()
                .padding(.bottom, 2)

            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(monthYearTitle)
                    .font(.headline)
                Spacer()
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(1...daysInMonth(for: displayedMonth), id: \.self) { day in
                    let date = dateFor(day: day, in: displayedMonth)
                    let dateStr = formatter.string(from: date)
                    let completed = taskCompletions[dateStr] ?? []

                    Button(action: {
                        if !tasks.isEmpty {
                            withAnimation {
                                selectedDate = date
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(!completed.isEmpty ? Color.orange.opacity(0.2) : Color.clear)

                            Text("\(day)")
                                .foregroundColor(!completed.isEmpty ? .orange : .primary)
                                .fontWeight(!completed.isEmpty ? .bold : .regular)
                        }
                        .frame(width: 28, height: 28)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
            }

            if let selected = selectedDate {
                FloatingTaskPanel(
                    date: selected,
                    taskCompletions: $taskCompletions,
                    tasks: tasks,
                    onClose: {
                        withAnimation { selectedDate = nil }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: selectedDate)
            }

            Divider()

            Text("Your Tasks")
                .font(.headline)
                .padding(.top, 8)

            // Task input section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("New task", text: $newTaskName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button(action: addTask) {
                        Label("Add", systemImage: "plus.circle.fill")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundColor(.accentColor)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                HStack(spacing: 10) {
                    Menu {
                        ForEach(["Blue", "Green", "Red", "Orange", "Purple"], id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Text(color)
                            }
                        }
                    } label: {
                        HStack {
                            Text("Color: \(selectedColor)")
                            Image(systemName: "chevron.down")
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    }

                    Menu {
                        ForEach(["High", "Medium", "Low"], id: \.self) { level in
                            Button(action: { selectedPriority = level }) {
                                Text(level)
                            }
                        }
                    } label: {
                        HStack {
                            Text("Priority: \(selectedPriority)")
                            Image(systemName: "chevron.down")
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    }
                }
                .font(.caption)

                ScrollView {
                    ForEach(tasks) { task in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Circle()
                                    .fill(Color(task.color.lowercased()))
                                    .frame(width: 8, height: 8)

                                Text(task.name)
                                    .fontWeight(.medium)

                                Text(task.priority)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(priorityColor(task.priority).opacity(0.15))
                                    .foregroundColor(priorityColor(task.priority))
                                    .cornerRadius(6)

                                Spacer()

                                let streak = streakForTask(task.id)
                                if streak > 0 {
                                    Text("🔥 x\(streak)")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }

                            HStack(spacing: 10) {
                                styledButton("Done Today", systemIcon: "checkmark") {
                                    markTaskDoneToday(task.id)
                                }

                                styledButton("Edit", systemIcon: "pencil") {
                                    // Handle editing
                                }

                                styledButton("Delete", systemIcon: "trash", color: .red) {
                                    deleteTask(task)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }

            Spacer()

            Text("made during a ✨ focus sprint by anjali chaturvedi")
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .frame(width: 320, height: 530)
        .onAppear { loadTasks() }
        .onChange(of: taskCompletions) { _ in saveAndNotify() }
        .onChange(of: tasks) { _ in saveAndNotify() }
    }

    // MARK: - Shared Helpers

    func styledButton(_ title: String, systemIcon: String, color: Color = .accentColor, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemIcon)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .foregroundColor(color)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    func priorityColor(_ priority: String) -> Color {
        switch priority {
        case "High": return .red
        case "Medium": return .orange
        case "Low": return .gray
        default: return .gray
        }
    }

    func changeMonth(by offset: Int) {
        if let newDate = calendar.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = newDate
        }
    }

    var monthYearTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    func dateFor(day: Int, in month: Date) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: month)
        return calendar.date(from: DateComponents(year: comps.year, month: comps.month, day: day))!
    }

    func daysInMonth(for date: Date) -> Int {
        calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    func streakForTask(_ taskId: UUID) -> Int {
        var count = 0
        var date = calendar.startOfDay(for: Date())
        while true {
            let dateStr = formatter.string(from: date)
            if let completed = taskCompletions[dateStr], completed.contains(taskId) {
                count += 1
            } else {
                break
            }
            date = calendar.date(byAdding: .day, value: -1, to: date)!
        }
        return count
    }

    func markTaskDoneToday(_ id: UUID) {
        let today = formatter.string(from: Date())
        var completions = taskCompletions[today] ?? []
        if !completions.contains(id) {
            completions.append(id)
        }
        taskCompletions[today] = completions
    }

    func addTask() {
        let trimmed = newTaskName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let new = TaskItem(id: UUID(), name: trimmed, color: selectedColor, priority: selectedPriority)
        tasks.append(new)
        newTaskName = ""
    }

    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        for key in taskCompletions.keys {
            taskCompletions[key]?.removeAll { $0 == task.id }
        }
    }

    func saveAndNotify() {
        if let encodedTasks = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encodedTasks, forKey: "tasks")
        }
        if let encodedCompletions = try? JSONEncoder().encode(taskCompletions) {
            UserDefaults.standard.set(encodedCompletions, forKey: "taskCompletions")
        }

        let streaks = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id.uuidString, streakForTask($0.id)) })
        NotificationCenter.default.post(name: .streakCountUpdated, object: nil, userInfo: ["taskStreaks": streaks])
    }

    func loadTasks() {
        if let taskData = UserDefaults.standard.data(forKey: "tasks"),
           let loaded = try? JSONDecoder().decode([TaskItem].self, from: taskData) {
            tasks = loaded
        }
        if let compData = UserDefaults.standard.data(forKey: "taskCompletions"),
           let loaded = try? JSONDecoder().decode([String: [UUID]].self, from: compData) {
            taskCompletions = loaded
        }

        let streaks = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id.uuidString, streakForTask($0.id)) })
        NotificationCenter.default.post(name: .streakCountUpdated, object: nil, userInfo: ["taskStreaks": streaks])
    }
}

// MARK: - FloatingTaskPanel stays unchanged

struct FloatingTaskPanel: View {
    let date: Date
    @Binding var taskCompletions: [String: [UUID]]
    let tasks: [TaskItem]
    let onClose: () -> Void

    private let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Tasks on \(formatter.string(from: date))")
                    .font(.subheadline)
                    .bold()
                Spacer()
                Button(action: { onClose() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(tasks) { task in
                        Toggle(isOn: Binding(
                            get: {
                                let dateStr = formatter.string(from: date)
                                return taskCompletions[dateStr]?.contains(task.id) ?? false
                            },
                            set: { newValue in
                                let dateStr = formatter.string(from: date)
                                var completions = taskCompletions[dateStr] ?? []
                                if newValue {
                                    if !completions.contains(task.id) {
                                        completions.append(task.id)
                                    }
                                } else {
                                    completions.removeAll { $0 == task.id }
                                }
                                taskCompletions[dateStr] = completions.isEmpty ? nil : completions
                            }
                        )) {
                            HStack {
                                Circle()
                                    .fill(Color(task.color.lowercased()))
                                    .frame(width: 6, height: 6)
                                Text(task.name)
                                Spacer()
                                Text(task.priority)
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding(.top, 4)
    }
}
