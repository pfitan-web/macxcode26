import SwiftUI
import SwiftData

struct TaskDetailSheet: View {
    let task: NeuroTask
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var newSubtask = ""
    @State private var isDecomposing = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label(task.category.label, systemImage: task.category.icon)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(task.category.color.opacity(0.12))
                                .foregroundStyle(task.category.color)
                                .clipShape(Capsule())

                            Label(task.priority.label, systemImage: task.priority.icon)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(task.priority.color.opacity(0.12))
                                .foregroundStyle(task.priority.color)
                                .clipShape(Capsule())
                        }

                        if !task.taskDescription.isEmpty {
                            Text(task.taskDescription)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let due = task.dueDate {
                    Section("Échéance") {
                        HStack {
                            Image(systemName: "calendar")
                            Text(due, format: .dateTime.weekday(.wide).day().month().hour().minute())
                        }
                        .font(.subheadline)
                    }
                }

                if let start = task.scheduledStart, let end = task.scheduledEnd {
                    Section("Créneau planifié") {
                        HStack {
                            Image(systemName: "clock")
                            Text("\(start, format: .dateTime.hour().minute()) → \(end, format: .dateTime.hour().minute())")
                        }
                        .font(.subheadline)
                    }
                }

                Section("Sous-tâches (\(task.subtasks.filter(\.isCompleted).count)/\(task.subtasks.count))") {
                    ForEach(task.subtasks.sorted(by: { $0.orderIndex < $1.orderIndex }), id: \.id) { subtask in
                        HStack {
                            Button {
                                withAnimation { subtask.isCompleted.toggle() }
                            } label: {
                                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(subtask.isCompleted ? .green : .secondary)
                            }
                            .buttonStyle(.plain)

                            Text(subtask.title)
                                .strikethrough(subtask.isCompleted)
                                .foregroundStyle(subtask.isCompleted ? .secondary : .primary)
                        }
                    }

                    HStack {
                        TextField("Nouvelle sous-tâche", text: $newSubtask)
                            .onSubmit { addSubtask() }
                        Button { addSubtask() } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.indigo)
                        }
                        .buttonStyle(.plain)
                        .disabled(newSubtask.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                if !task.subtasks.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            ProgressView(value: task.completionPercentage)
                                .tint(task.category.color)
                            Text("\(Int(task.completionPercentage * 100))% terminé")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    if task.subtasks.isEmpty {
                        Button {
                            Task { await decomposeTask() }
                        } label: {
                            HStack {
                                Label("Décomposer en sous-tâches", systemImage: "wand.and.stars")
                                Spacer()
                                if isDecomposing {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(isDecomposing)
                    }

                    Button {
                        withAnimation {
                            task.isCompleted.toggle()
                            task.completedAt = task.isCompleted ? Date() : nil
                        }
                    } label: {
                        Label(
                            task.isCompleted ? "Marquer comme non terminée" : "Marquer comme terminée",
                            systemImage: task.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle"
                        )
                        .foregroundStyle(task.isCompleted ? .orange : .green)
                    }

                    Button(role: .destructive) {
                        modelContext.delete(task)
                        dismiss()
                    } label: {
                        Label("Supprimer la tâche", systemImage: "trash")
                    }
                }
            }
            .navigationTitle(task.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    private func addSubtask() {
        let text = newSubtask.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let subtask = SubTask(title: text, orderIndex: task.subtasks.count)
        task.subtasks.append(subtask)
        newSubtask = ""
    }

    private func decomposeTask() async {
        guard !isDecomposing else { return }
        isDecomposing = true
        let service = NeuroAIService(modelContext: modelContext)
        await service.decomposeTask(task)
        isDecomposing = false
    }
}