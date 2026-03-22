mport SwiftUI
import SwiftData

nonisolated enum FocusType: String, Codable, CaseIterable, Sendable {
    case pomodoro = "pomodoro"
    case deepWork = "deepWork"
    case shortBreak = "shortBreak"
    case longBreak = "longBreak"

    var label: String {
        switch self {
        case .pomodoro: "Pomodoro"
        case .deepWork: "Focus Profond"
        case .shortBreak: "Pause Courte"
        case .longBreak: "Pause Longue"
        }
    }

    var defaultMinutes: Int {
        switch self {
        case .pomodoro: 25
        case .deepWork: 50
        case .shortBreak: 5
        case .longBreak: 15
        }
    }

    var icon: String {
        switch self {
        case .pomodoro: "timer"
        case .deepWork: "brain.head.profile.fill"
        case .shortBreak: "cup.and.saucer.fill"
        case .longBreak: "figure.walk"
        }
    }

    var color: Color {
        switch self {
        case .pomodoro: .red
        case .deepWork: .purple
        case .shortBreak: .green
        case .longBreak: .blue
        }
    }
}

nonisolated enum AmbientSound: String, Codable, CaseIterable, Sendable {
    case none = "none"
    case rain = "rain"
    case forest = "forest"
    case ocean = "ocean"
    case cafe = "cafe"
    case whiteNoise = "whiteNoise"
    case fireplace = "fireplace"

    var label: String {
        switch self {
        case .none: "Silence"
        case .rain: "Pluie"
        case .forest: "Forêt"
        case .ocean: "Océan"
        case .cafe: "Café"
        case .whiteNoise: "Bruit Blanc"
        case .fireplace: "Cheminée"
        }
    }

    var icon: String {
        switch self {
        case .none: "speaker.slash.fill"
        case .rain: "cloud.rain.fill"
        case .forest: "leaf.fill"
        case .ocean: "water.waves"
        case .cafe: "cup.and.saucer.fill"
        case .whiteNoise: "waveform"
        case .fireplace: "flame.fill"
        }
    }
}

@Model
class FocusSession {
    var id: UUID
    var focusType: FocusType
    var durationMinutes: Int
    var actualMinutes: Int
    var isCompleted: Bool
    var startedAt: Date
    var endedAt: Date?
    var ambientSound: AmbientSound
    var taskTitle: String?

    init(
        focusType: FocusType = .pomodoro,
        durationMinutes: Int? = nil,
        ambientSound: AmbientSound = .none,
        taskTitle: String? = nil
    ) {
        self.id = UUID()
        self.focusType = focusType
        self.durationMinutes = durationMinutes ?? focusType.defaultMinutes
        self.actualMinutes = 0
        self.isCompleted = false
        self.startedAt = Date()
        self.ambientSound = ambientSound
        self.taskTitle = taskTitle
    }
}
