import SwiftUI
import SwiftData

nonisolated enum AISuggestionKind: String, Codable, CaseIterable, Sendable {
    case task = "task"
    case routine = "routine"

    var label: String {
        switch self {
        case .task: "Tâche"
        case .routine: "Routine"
        }
    }

    var icon: String {
        switch self {
        case .task: "checklist"
        case .routine: "repeat.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .task: .indigo
        case .routine: .orange
        }
    }
}

nonisolated enum AISuggestionStatus: String, Codable, CaseIterable, Sendable {
    case pending = "pending"
    case accepted = "accepted"
    case dismissed = "dismissed"
}

@Model
class AISuggestion {
    var id: UUID
    var kind: AISuggestionKind
    var status: AISuggestionStatus
    var title: String
    var suggestionDescription: String
    var sourceText: String
    var taskCategory: TaskCategory
    var taskPriority: TaskPriority
    var routineTime: RoutineTime
    var estimatedMinutes: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var steps: [AISuggestionStep] = []

    init(
        kind: AISuggestionKind,
        title: String,
        suggestionDescription: String,
        sourceText: String,
        taskCategory: TaskCategory = .personal,
        taskPriority: TaskPriority = .medium,
        routineTime: RoutineTime = .custom,
        estimatedMinutes: Int = 15
    ) {
        self.id = UUID()
        self.kind = kind
        self.status = .pending
        self.title = title
        self.suggestionDescription = suggestionDescription
        self.sourceText = sourceText
        self.taskCategory = taskCategory
        self.taskPriority = taskPriority
        self.routineTime = routineTime
        self.estimatedMinutes = estimatedMinutes
        self.createdAt = Date()
    }
}

@Model
class AISuggestionStep {
    var id: UUID
    var title: String
    var orderIndex: Int
    var estimatedMinutes: Int
    var suggestion: AISuggestion?

    init(title: String, orderIndex: Int, estimatedMinutes: Int = 5) {
        self.id = UUID()
        self.title = title
        self.orderIndex = orderIndex
        self.estimatedMinutes = estimatedMinutes
    }
}
