import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [NeuroTask]
    @Query private var moodEntries: [MoodEntry]
    @Query(filter: #Predicate<FocusSession> { $0.isCompleted }) private var focusSessions: [FocusSession]
    @Query private var habits: [HabitItem]
    @Query(sort: \AIInsightSnapshot.createdAt, order: .reverse) private var insights: [AIInsightSnapshot]
    @AppStorage("userName") private var userName = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = false
    @AppStorage("pomodoroMinutes") private var pomodoroMinutes = 25
    @AppStorage("shortBreakMinutes") private var shortBreakMinutes = 5
    @AppStorage("longBreakMinutes") private var longBreakMinutes = 15
    @State private var showAddHabit = false
    @State private var showResetAlert = false
    @State private var showMoodHistory = false

    private var completedTasks: Int {
        allTasks.filter(\.isCompleted).count
    }

    private var totalFocusMinutes: Int {
        focusSessions.reduce(0) { $0 + $1.actualMinutes }
    }

    private var bestHabitStreak: Int {
        habits.map(\.bestStreak).max() ?? 0
    }

    var body: some View {
        NavigationStack {
            List {
                profileHeader

                Section("Statistiques") {
                    statsGrid
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section("Habitudes") {
                    if habits.isEmpty {
                        Button { showAddHabit = true } label: {
                            Label("Créer votre première habitude", systemImage: "plus.circle")
                        }
                    } else {
                        ForEach(habits, id: \.id) { habit in
                            HStack(spacing: 12) {
                                Image(systemName: habit.icon)
                                    .foregroundStyle(habit.habitColor)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(habit.title)
                                        .font(.body)
                                    Text("Streak: \(habit.currentStreak) jours")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if habit.isCompletedToday() {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                modelContext.delete(habits[index])
                            }
                        }

                        Button { showAddHabit = true } label: {
                            Label("Nouvelle habitude", systemImage: "plus.circle")
                        }
                    }
                }

                Section("Journal d'humeur") {
                    Button { showMoodHistory = true } label: {
                        Label("Voir l'historique", systemImage: "chart.line.uptrend.xyaxis")
                    }

                    if let lastMood = moodEntries.first {
                        HStack {
                            Text("Dernier check-in")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(lastMood.mood.emoji) \(lastMood.mood.label)")
                            Text(lastMood.createdAt, format: .relative(presentation: .named))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }

                Section("Paramètres Focus") {
                    Stepper("Pomodoro: \(pomodoroMinutes) min", value: $pomodoroMinutes, in: 15...60, step: 5)
                    Stepper("Pause courte: \(shortBreakMinutes) min", value: $shortBreakMinutes, in: 3...15)
                    Stepper("Pause longue: \(longBreakMinutes) min", value: $longBreakMinutes, in: 10...30, step: 5)
                }

                if let latestInsight = insights.first {
                    Section("Coach IA") {
                        Label("\(latestInsight.recommendedFocusType.label) · \(latestInsight.recommendedFocusMinutes) min", systemImage: latestInsight.recommendedFocusType.icon)
                            .foregroundStyle(.primary)
                        Text(latestInsight.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Paramètres") {
                    Toggle("Rappels quotidiens", isOn: $dailyReminderEnabled)

                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Réinitialiser l'onboarding", systemImage: "arrow.counterclockwise")
                    }
                }

                Section {
                    VStack(spacing: 4) {
                        Text("NeuroAssist v1.0")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("Conçu pour les esprits neuroatypiques")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Profil")
            .sheet(isPresented: $showAddHabit) {
                AddHabitSheet()
            }
            .sheet(isPresented: $showMoodHistory) {
                MoodHistorySheet()
            }
            .alert("Réinitialiser ?", isPresented: $showResetAlert) {
                Button("Réinitialiser", role: .destructive) {
                    hasCompletedOnboarding = false
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Cela relancera l'onboarding au prochain démarrage.")
            }
        }
    }

    private var profileHeader: some View {
        Section {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.indigo.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Image(systemName: "brain.head.profile.fill")
                        .font(.title)
                        .foregroundStyle(.indigo)
                }

                VStack(alignment: .leading, spacing: 4) {
                    if userName.isEmpty {
                        TextField("Votre prénom", text: $userName)
                            .font(.title3.bold())
                    } else {
                        Text(userName)
                            .font(.title3.bold())
                    }
                    Text("Membre NeuroAssist")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MiniStatCard(icon: "checkmark.circle.fill", value: "\(completedTasks)", label: "Tâches terminées", color: .green)
            MiniStatCard(icon: "timer", value: "\(totalFocusMinutes)", label: "Minutes de focus", color: .red)
            MiniStatCard(icon: "flame.fill", value: "\(bestHabitStreak)", label: "Meilleur streak", color: .orange)
            MiniStatCard(icon: "face.smiling", value: "\(moodEntries.count)", label: "Check-ins humeur", color: .purple)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct MiniStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
    }
}
