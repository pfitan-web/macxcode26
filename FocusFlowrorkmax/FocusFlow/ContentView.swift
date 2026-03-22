import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .dashboard
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            TabView(selection: $selectedTab) {
                Tab("Accueil", systemImage: "house.fill", value: .dashboard) {
                    DashboardView()
                }
                Tab("Planning", systemImage: "calendar", value: .timeline) {
                    TimelineView()
                }
                Tab("Tâches", systemImage: "checkmark.circle.fill", value: .tasks) {
                    TaskListView()
                }
                Tab("Routines", systemImage: "repeat.circle.fill", value: .routines) {
                    RoutinesView()
                }
                Tab("Focus", systemImage: "brain.head.profile.fill", value: .focus) {
                    FocusTimerView()
                }
                Tab("Moi", systemImage: "person.crop.circle.fill", value: .profile) {
                    ProfileView()
                }
            }
            .tint(.indigo)
        } else {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
    }
}

nonisolated enum AppTab: String, Sendable {
    case dashboard
    case timeline
    case tasks
    case routines
    case focus
    case profile
}
