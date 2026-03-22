import SwiftUI
import SwiftData

struct AddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var taskDescription = ""
    @State private var priority: TaskPriority = .medium
    @State private var category: TaskCategory = .personal
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var hasSchedule = false
    @State private var scheduledStart = Date()
    @State private var scheduledEnd = Date().addingTimeInterval(1800)
    @State private var estimatedMinutes: Int = 30
    @State private var subtaskTexts: [String] = []
    @State private var newSubtask = ""
    @FocusState private var titleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Titre de la tâche", text: $title)
                        .font(.headline)
                        .focused($titleFocused)

                    TextField("Description (optionnel)", text: $taskDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Catégorie & Priorité") {
                    Picker("Catégorie", selection: $category) {
                        ForEach(TaskCategory.allCases, id: \.self) { cat in
                            Label(cat.label, systemImage: cat.icon).tag(cat)
                        }
                    }

                    Picker("Priorité", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            Label(p.label, systemImage: p.icon).tag(p)
                        }
                    }
                }

                Section("Planification") {
                    Toggle("Date limite", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Date limite", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }

                    Toggle("Planifier un créneau", isOn: $hasSchedule)
                    if hasSchedule {
                        DatePicker("Début", selection: $scheduledStart, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("Fin", selection: $scheduledEnd, displayedComponents: [.date, .hourAndMinute])
                    }

                    Stepper("Durée estimée: \(estimatedMinutes) min", value: $estimatedMinutes, in: 5...480, step: 5)
                }

                Section("Sous-tâches") {
                    ForEach(Array(subtaskTexts.enumerated()), id: \.offset) { index, text in
                        HStack {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            Text(text)
                            Spacer()
                            Button {
                                subtaskTexts.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack {
                        TextField("Ajouter une sous-tâche", text: $newSubtask)
                            .onSubmit { addSubtask() }
                        Button { addSubtask() } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.indigo)
                        }
                        .buttonStyle(.plain)
                        .disabled(newSubtask.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("Nouvelle Tâche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") {
                        createTask()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .bold()
                }
            }
            .onAppear { titleFocused = true }
        }
    }

    private func addSubtask() {
        let text = newSubtask.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        subtaskTexts.append(text)
        newSubtask = ""
    }

    private func createTask() {
        let task = NeuroTask(
            title: title.trimmingCharacters(in: .whitespaces),
            taskDescription: taskDescription,
            priority: priority,
            category: category,
            dueDate: hasDueDate ? dueDate : nil,
            scheduledStart: hasSchedule ? scheduledStart : nil,
            scheduledEnd: hasSchedule ? scheduledEnd : nil,
            estimatedMinutes: estimatedMinutes
        )

        for (index, text) in subtaskTexts.enumerated() {
            let subtask = SubTask(title: text, orderIndex: index)
            task.subtasks.append(subtask)
        }

        modelContext.insert(task)
    }
}