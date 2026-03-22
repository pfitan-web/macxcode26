import SwiftUI
import SwiftData

nonisolated enum HabitFrequency: String, Codable, CaseIterable, Sendable {
    case daily = "daily"
    case weekly = "weekly"
    case custom = "custom"

    var label: String {
        switch self {
        case .daily: "Quotidien"
        case .weekly: "Hebdomadaire"
        case .custom: "Personnalisé"
        }
    }
}

@Model
class HabitItem {
    var id: UUID
    var title: String
    var icon: String
    var color: String
    var frequency: HabitFrequency
    var targetCount: Int
    var currentStreak: Int
    var bestStreak: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var completions: [HabitCompletion] = []

    init(
        title: String,
        icon: String = "star.fill",
        color: String = "blue",
        frequency: HabitFrequency = .daily,
        targetCount: Int = 1
    ) {
        self.id = UUID()
        self.title = title
        self.icon = icon
        self.color = color
        self.frequency = frequency
        self.targetCount = targetCount
        self.currentStreak = 0
        self.bestStreak = 0
        self.createdAt = Date()
    }

    var habitColor: Color {
        switch color {
        case "blue": .blue
        case "purple": .purple
        case "green": .green
        case "orange": .orange
        case "pink": .pink
        case "red": .red
        case "mint": .mint
        case "indigo": .indigo
        default: .blue
        }
    }

    func isCompletedToday() -> Bool {
        let calendar = Calendar.current
        return completions.contains { calendar.isDateInToday($0.completedAt) }
    }
}

@Model
class HabitCompletion {
    var id: UUID
    var completedAt: Date
    var habit: HabitItem?

    init() {
        self.id = UUID()
        self.completedAt = Date()
    }
}
