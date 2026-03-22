import SwiftUI
import SwiftData

nonisolated enum MoodLevel: Int, Codable, CaseIterable, Sendable {
    case terrible = 1
    case bad = 2
    case okay = 3
    case good = 4
    case great = 5

    var emoji: String {
        switch self {
        case .terrible: "😫"
        case .bad: "😔"
        case .okay: "😐"
        case .good: "😊"
        case .great: "🤩"
        }
    }

    var label: String {
        switch self {
        case .terrible: "Terrible"
        case .bad: "Pas bien"
        case .okay: "Correct"
        case .good: "Bien"
        case .great: "Super"
        }
    }

    var color: Color {
        switch self {
        case .terrible: .red
        case .bad: .orange
        case .okay: .yellow
        case .good: .mint
        case .great: .green
        }
    }
}

nonisolated enum EnergyLevel: Int, Codable, CaseIterable, Sendable {
    case depleted = 1
    case low = 2
    case moderate = 3
    case high = 4
    case overflowing = 5

    var icon: String {
        switch self {
        case .depleted: "battery.0percent"
        case .low: "battery.25percent"
        case .moderate: "battery.50percent"
        case .high: "battery.75percent"
        case .overflowing: "battery.100percent"
        }
    }

    var label: String {
        switch self {
        case .depleted: "Épuisé"
        case .low: "Faible"
        case .moderate: "Modéré"
        case .high: "Bon"
        case .overflowing: "Débordant"
        }
    }
}

@Model
class MoodEntry {
    var id: UUID
    var mood: MoodLevel
    var energy: EnergyLevel
    var stressLevel: Int
    var focusLevel: Int
    var notes: String
    var tags: [String]
    var createdAt: Date

    init(
        mood: MoodLevel = .okay,
        energy: EnergyLevel = .moderate,
        stressLevel: Int = 3,
        focusLevel: Int = 3,
        notes: String = "",
        tags: [String] = []
    ) {
        self.id = UUID()
        self.mood = mood
        self.energy = energy
        self.stressLevel = stressLevel
        self.focusLevel = focusLevel
        self.notes = notes
        self.tags = tags
        self.createdAt = Date()
    }
}