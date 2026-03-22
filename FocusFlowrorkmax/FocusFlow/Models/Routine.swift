import SwiftUI
import SwiftData

nonisolated enum RoutineTime: String, Codable, CaseIterable, Sendable {
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    case night = "night"
    case custom = "custom"

    var label: String {
        switch self {
        case .morning: "Matin"
        case .afternoon: "Après-midi"
        case .evening: "Soir"
        case .night: "Nuit"
        case .custom: "Personnalisé"
        }
    }

    var icon: String {
        switch self {
        case .morning: "sunrise.fill"
        case .afternoon: "sun.max.fill"
        case .evening: "sunset.fill"
        case .night: "moon.stars.fill"
        case .custom: "clock.fill"
        }
    }

    var color: Color {
        switch self {
        case .morning: .orange
        case .afternoon: .yellow
        case .evening: .indigo
        case .night: .purple
        case .custom: .blue
        }
    }
}

@Model
class Routine {
    var id: UUID
    var title: String
    var icon: String
    var color: String
    var timeOfDay: RoutineTime
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var steps: [RoutineStep] = []

    @Relationship(deleteRule: .cascade)
    var completions: [RoutineCompletion] = []

    init(
        title: String,
        icon: String = "list.bullet",
        color: String = "indigo",
        timeOfDay: RoutineTime = .evening
    ) {
        self.id = UUID()
        self.title = title
        self.icon = icon
        self.color = color
        self.timeOfDay = timeOfDay
        self.createdAt = Date()
    }

    var routineColor: Color {
        switch color {
        case "blue": .blue
        case "purple": .purple
        case "green": .green
        case "orange": .orange
        case "pink": .pink
        case "red": .red
        case "mint": .mint
        case "indigo": .indigo
        case "teal": .teal
        case "yellow": .yellow
        default: .indigo
        }
    }

    func isCompletedToday() -> Bool {
        let calendar = Calendar.current
        return completions.contains { calendar.isDateInToday($0.completedAt) }
    }

    func todayProgress() -> Double {
        guard !steps.isEmpty else { return 0 }
        let calendar = Calendar.current
        guard let todayCompletion = completions.first(where: { calendar.isDateInToday($0.completedAt) }) else { return 0 }
        let completedIDs = Set(todayCompletion.completedStepIDs.components(separatedBy: ",").filter { !$0.isEmpty })
        let done = steps.filter { completedIDs.contains($0.id.uuidString) }.count
        return Double(done) / Double(steps.count)
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var date = Date()
        for _ in 0..<365 {
            let hasCompletion = completions.contains { calendar.isDate($0.completedAt, inSameDayAs: date) }
            if hasCompletion {
                streak += 1
            } else if !calendar.isDateInToday(date) {
                break
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return streak
    }
}

@Model
class RoutineStep {
    var id: UUID
    var title: String
    var orderIndex: Int
    var estimatedMinutes: Int
    var routine: Routine?

    init(title: String, orderIndex: Int = 0, estimatedMinutes: Int = 5) {
        self.id = UUID()
        self.title = title
        self.orderIndex = orderIndex
        self.estimatedMinutes = estimatedMinutes
    }
}

@Model
class RoutineCompletion {
    var id: UUID
    var completedAt: Date
    var completedStepIDs: String
    var routine: Routine?

    init(completedStepIDs: String = "") {
        self.id = UUID()
        self.completedAt = Date()
        self.completedStepIDs = completedStepIDs
    }
}
