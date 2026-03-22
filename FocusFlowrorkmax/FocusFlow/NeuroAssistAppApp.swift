import SwiftUI
import SwiftData

@main
struct NeuroAssistAppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            NeuroTask.self,
            SubTask.self,
            MoodEntry.self,
            HabitItem.self,
            HabitCompletion.self,
            FocusSession.self,
            BrainDump.self,
            Routine.self,
            RoutineStep.self,
            RoutineCompletion.self,
            AIInsightSnapshot.self,
            AISuggestion.self,
            AISuggestionStep.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}