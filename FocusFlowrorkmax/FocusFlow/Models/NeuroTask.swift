import SwiftUI
import SwiftData

nonisolated enum TaskPriority: String, Codable, CaseIterable, Sendable {
    case urgent = "urgent"
    case high = "high"
    case medium = "medium"
    case low = "low"

    var label: String {
        switch self {
        case .urgent: "Urgent"
        case .high: "Important"
        case .medium: "Normal"
        case .low: "Faible"
        }
    }

    var color: Color {
        switch self {
        case .urgent: .red
        case .high: .orange
        case .medium: .yellow
        case .low: .green
        }
    }

    var icon: String {
        switch self {
        case .urgent: "exclamationmark.triangle.fill"
        case .high: "arrow.up.circle.fill"
        case .medium: "minus.circle.fill"
        case .low: "arrow.down.circle.fill"
        }
    }
}

nonisolated enum TaskCategory: String, Codable, CaseIterable, Sendable {
    case work = "work"
    case personal = "personal"
    case health = "health"
    case errands = "errands"
    case creative = "creative"
    case admin = "admin"

    var label: String {
        switch self {
        case .work: "Travail"
        case .personal: "Personnel"
        case .health: "Santé"
        case .errands: "Courses"
        case .creative: "Créatif"
        case .admin: "Admin"
        }
    }

    var color: Color {
        switch self {
        case .work: .blue
        case .personal: .purple
        case .health: .green
        case .errands: .orange
        case .creative: .pink
        case .admin: .gray
        }
    }

    var icon: String {
        switch self {
        case .work: "briefcase.fill"
        case .personal: "person.fill"
        case .health: "heart.fill"
        case .errands: "cart.fill"
        case .creative: "paintbrush.fill"
        case .admin: "doc.text.fill"
        }
    }
}

@Model
class NeuroTask {
    var id: UUID
    var title: String
    var taskDescription: String
    var isCompleted: Bool
    var priority: TaskPriority
    var category: TaskCategory
    var dueDate: Date?
    var scheduledStart: Date?
    var scheduledEnd: Date?
    var estimatedMinutes: Int
    var createdAt: Date
    var completedAt: Date?
    var orderIndex: Int

    @Relationship(deleteRule: .cascade)
    var subtasks: [SubTask] = []

    init(
        title: String,
        taskDescription: String = "",
        priority: TaskPriority = .medium,
        category: TaskCategory = .personal,
        dueDate: Date? = nil,
        scheduledStart: Date? = nil,
        scheduledEnd: Date? = nil,
        estimatedMinutes: Int = 30,
        orderIndex: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescription = taskDescription
        self.isCompleted = false
        self.priority = priority
        self.category = category
        self.dueDate = dueDate
        self.scheduledStart = scheduledStart
        self.scheduledEnd = scheduledEnd
        self.estimatedMinutes = estimatedMinutes
        self.createdAt = Date()
        self.orderIndex = orderIndex
    }

    var completionPercentage: Double {
        guard !subtasks.isEmpty else { return isCompleted ? 1.0 : 0.0 }
        let completed = subtasks.filter(\.isCompleted).count
        return Double(completed) / Double(subtasks.count)
    }
}

@Model
class SubTask {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var orderIndex: Int
    var task: NeuroTask?

    init(title: String, orderIndex: Int = 0) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.orderIndex = orderIndex
    }
}
