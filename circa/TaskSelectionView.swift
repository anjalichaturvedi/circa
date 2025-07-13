import SwiftUI

struct SelectedDateWrapper: Identifiable {
    let id = UUID()
    let date: Date
}

struct TaskSelectionView: View {
    let date: Date
    @Binding var taskCompletions: [String: [String]]
    let allTasks: [String]
    @Environment(\.dismiss) var dismiss

    private let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    var body: some View {
        VStack {
            Text("Tasks on \(formatter.string(from: date))")
                .font(.headline)

            if allTasks.isEmpty {
                Text("No tasks defined.")
            } else {
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(allTasks, id: \.self) { task in
                            Toggle(task, isOn: Binding(
                                get: {
                                    let dateStr = formatter.string(from: date)
                                    return taskCompletions[dateStr]?.contains(task) ?? false
                                },
                                set: { newValue in
                                    let dateStr = formatter.string(from: date)
                                    var completions = taskCompletions[dateStr] ?? []
                                    if newValue {
                                        if !completions.contains(task) {
                                            completions.append(task)
                                        }
                                    } else {
                                        completions.removeAll { $0 == task }
                                    }
                                    taskCompletions[dateStr] = completions.isEmpty ? nil : completions
                                }
                            ))
                        }
                    }
                }
            }

            Button("Done") {
                UserDefaults.standard.set(taskCompletions, forKey: "taskCompletions")
                dismiss()
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 250, height: 300)
    }
}
