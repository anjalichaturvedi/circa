import SwiftUI

struct UnifiedView: View {
    @State private var taskCompletions: [String: [String]] = UserDefaults.standard.dictionary(forKey: "taskCompletions") as? [String: [String]] ?? [:]
    @State private var tasks: [String] = UserDefaults.standard.stringArray(forKey: "tasks") ?? []
    @State private var newTaskName = ""
    @State private var editingTask: String? = nil
    @State private var editedTaskName = ""
    @State private var displayedMonth: Date = Calendar.current.startOfDay(for: Date())

    private let calendar = Calendar.current
    private let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
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
                        toggleAllTasksOnDate(date)
                    }) {
                        ZStack {
                            if completed.isEmpty {
                                Text("\(day)")
                                    .foregroundColor(.primary)
                            } else {
                                Text(String(repeating: "🔥", count: completed.count))
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            }
                        }
                        .frame(width: 28, height: 28)
                        .background(completed.isEmpty ? Color.clear : Color.orange.opacity(0.2))
                        .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            Divider()

            // Task Section
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    TextField("Add new task", text: $newTaskName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Add") {
                        addTask()
                    }
                }

                ScrollView {
                    ForEach(tasks, id: \.self) { task in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                if editingTask == task {
                                    TextField("Edit task", text: $editedTaskName)
                                    Button("Save") {
                                        saveEditedTask(original: task)
                                    }
                                } else {
                                    Text(task)
                                    Spacer()
                                    Text("Streak: \(streakForTask(task))")
                                        .foregroundColor(.gray)
                                }
                            }

                            HStack(spacing: 12) {
                                Button("Delete") {
                                    deleteTask(task)
                                }
                                Button("Edit") {
                                    editingTask = task
                                    editedTaskName = task
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .frame(width: 300, height: 420)
        .onDisappear {
            saveTasks()
        }
        .onChange(of: taskCompletions) {
            UserDefaults.standard.set(taskCompletions, forKey: "taskCompletions")
            NotificationCenter.default.post(name: .streakCountUpdated, object: nil, userInfo: ["streakCount": calculateGeneralStreak()])
        }

        Spacer()

        Text("made during a ✨ focus sprint by anjali chaturvedi")
            .font(.footnote)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 10)

    }

    // MARK: - Calendar Logic

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

    func toggleAllTasksOnDate(_ date: Date) {
        let dateStr = formatter.string(from: date)
        var completions = taskCompletions[dateStr] ?? []

        // Toggle logic: mark all tasks if none are completed, else clear all
        if completions.isEmpty {
            completions = tasks
        } else {
            completions = []
        }

        taskCompletions[dateStr] = completions.isEmpty ? nil : completions
    }

    // MARK: - Task Logic

    func streakForTask(_ task: String) -> Int {
        var count = 0
        var date = calendar.startOfDay(for: Date())
        while true {
            let dateStr = formatter.string(from: date)
            if let completions = taskCompletions[dateStr], completions.contains(task) {
                count += 1
            } else {
                break
            }
            date = calendar.date(byAdding: .day, value: -1, to: date)!
        }
        return count
    }

    func calculateGeneralStreak() -> Int {
        var count = 0
        var date = calendar.startOfDay(for: Date())
        while let completions = taskCompletions[formatter.string(from: date)], !completions.isEmpty {
            count += 1
            date = calendar.date(byAdding: .day, value: -1, to: date)!
        }
        return count
    }

    func changeMonth(by offset: Int) {
        if let newDate = calendar.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = newDate
        }
    }

    func addTask() {
        let trimmed = newTaskName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !tasks.contains(trimmed) {
            tasks.append(trimmed)
            newTaskName = ""
        }
    }

    func deleteTask(_ task: String) {
        tasks.removeAll { $0 == task }
        for key in taskCompletions.keys {
            taskCompletions[key]?.removeAll { $0 == task }
        }
    }

    func saveTasks() {
        UserDefaults.standard.set(tasks, forKey: "tasks")
        UserDefaults.standard.set(taskCompletions, forKey: "taskCompletions")
    }

    func saveEditedTask(original: String) {
        let trimmed = editedTaskName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && trimmed != original {
            if let index = tasks.firstIndex(of: original) {
                tasks[index] = trimmed
            }
            for (key, values) in taskCompletions {
                if values.contains(original) {
                    var updated = values
                    updated.removeAll { $0 == original }
                    updated.append(trimmed)
                    taskCompletions[key] = updated
                }
            }
            editingTask = nil
            editedTaskName = ""
        }
    }
    
}
