import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NeuroTask.createdAt, order: .reverse) private var allTasks: [NeuroTask]
    @State private var showAddTask = false
    @State private var selectedFilter: TaskFilter = .all
    @State private var searchText = ""
    @State private var selectedTask: NeuroTask?

    private var filteredTasks: [NeuroTask] {
        var tasks = allTasks

        switch selectedFilter {
        case .all: break
        case .active: tasks = tasks.filter { !$0.isCompleted }
        case .completed: tasks = tasks.filter(\.isCompleted)
        case .urgent: tasks = tasks.filter { $0.priority == .urgent || $0.priority == .high }
        }

        if !searchText.isEmpty {
            tasks = tasks.filter { $0.title.localizedStandardContains(searchText) }
        }

        return tasks
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar

                List {
                    if filteredTasks.isEmpty {
                        ContentUnavailableView(
                            "Aucune tâche",
                            systemImage: "checkmark.circle",
                            description: Text("Appuyez sur + pour créer une tâche")
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(filteredTasks, id: \.id) { task in
                            TaskRow(task: task)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation { modelContext.delete(task) }
                                    } label: {
                                        Label("Supprimer", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        withAnimation(.snappy) {
                                            task.isCompleted.toggle()
                                            task.completedAt = task.isCompleted ? Date() : nil
                                        }
                                    } label: {
                                        Label(
                                            task.isCompleted ? "Réouvrir" : "Terminer",
                                            systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark"
                                        )
                                    }
                                    .tint(.green)
                                }
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Rechercher une tâche...")
            }
            .navigationTitle("Tâches")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddTask = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskSheet()
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailSheet(task: task)
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.snappy) { selectedFilter = filter }
                    } label: {
                        Text(filter.label)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? .indigo : Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(selectedFilter == filter ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .contentMargins(.horizontal, 0)
    }
}

nonisolated enum TaskFilter: String, CaseIterable, Sendable {
    case all, active, urgent, completed

    var label: String {
        switch self {
        case .all: "Toutes"
        case .active: "Actives"
        case .urgent: "Urgentes"
        case .completed: "Terminées"
        }
    }
}

struct TaskRow: View {
    let task: NeuroTask
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.snappy) {
                    task.isCompleted.toggle()
                    task.completedAt = task.isCompleted ? Date() : nil
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : task.priority.color)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    Label(task.category.label, systemImage: task.category.icon)
                        .font(.caption)
                        .foregroundStyle(task.category.color)

                    if !task.subtasks.isEmpty {
                        let completed = task.subtasks.filter(\.isCompleted).count
                        Text("\(completed)/\(task.subtasks.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let due = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(due, format: .dateTime.month(.abbreviated).day())
                        }
                        .font(.caption)
                        .foregroundStyle(due < Date() && !task.isCompleted ? .red : .secondary)
                    }
                }

                if !task.subtasks.isEmpty {
                    ProgressView(value: task.completionPercentage)
                        .tint(task.category.color)
                }
            }

            Spacer()

            Image(systemName: task.priority.icon)
                .font(.caption)
                .foregroundStyle(task.priority.color)
        }
        .padding(.vertical, 4)
        .sensoryFeedback(.success, trigger: task.isCompleted)
    }
}
