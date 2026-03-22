import SwiftUI
import SwiftData

nonisolated enum DayMoment: String, Codable, CaseIterable, Sendable {
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    case night = "night"

    var label: String {
        switch self {
        case .morning: "Matin"
        case .afternoon: "Après-midi"
        case .evening: "Soir"
        case .night: "Nuit"
        }
    }

    var icon: String {
        switch self {
        case .morning: "sunrise.fill"
        case .afternoon: "sun.max.fill"
        case .evening: "sunset.fill"
        case .night: "moon.stars.fill"
        }
    }
}

@Model
class AIInsightSnapshot {
    var id: UUID
    var periodDays: Int
    var completionRate: Double
    var overdueRate: Double
    var bestMood: MoodLevel
    var bestEnergy: EnergyLevel
    var bestTimeOfDay: DayMoment
    var recommendedFocusType: FocusType
    var recommendedFocusMinutes: Int
    var summary: String
    var createdAt: Date

    init(
        periodDays: Int,
        completionRate: Double,
        overdueRate: Double,
        bestMood: MoodLevel,
        bestEnergy: EnergyLevel,
        bestTimeOfDay: DayMoment,
        recommendedFocusType: FocusType,
        recommendedFocusMinutes: Int,
        summary: String
    ) {
        self.id = UUID()
        self.periodDays = periodDays
        self.completionRate = completionRate
        self.overdueRate = overdueRate
        self.bestMood = bestMood
        self.bestEnergy = bestEnergy
        self.bestTimeOfDay = bestTimeOfDay
        self.recommendedFocusType = recommendedFocusType
        self.recommendedFocusMinutes = recommendedFocusMinutes
        self.summary = summary
        self.createdAt = Date()
    }
}