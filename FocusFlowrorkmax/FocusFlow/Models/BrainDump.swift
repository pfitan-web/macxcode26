import SwiftUI
import SwiftData

@Model
class BrainDump {
    var id: UUID
    var content: String
    var isProcessed: Bool
    var createdAt: Date
    var convertedTaskId: UUID?

    init(content: String) {
        self.id = UUID()
        self.content = content
        self.isProcessed = false
        self.createdAt = Date()
    }
}