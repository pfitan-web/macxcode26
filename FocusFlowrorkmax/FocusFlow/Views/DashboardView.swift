import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<NeuroTask> { !$0.isCompleted }, sort: \NeuroTask.createdAt, order: .reverse) private var activeTasks: [NeuroTask]
    @Query(sort: \MoodEntry.createdAt, order: .reverse) private var moodEntries: [MoodEntry]
    @Query(sort: \HabitItem.createdAt) private var habits: [HabitItem]
    @Query(filter: #Predicate<FocusSession> { $0.isCompleted }, sort: \FocusSession.startedAt, order: .reverse) private var completedSessions: [FocusSession]
    @Query(sort: \Routine.createdAt) private var routines: [Routine]
    @Query(sort: \AIInsightSnapshot.createdAt, order: .reverse) private var insights: [AIInsightSnapshot]
    @State private var showMoodCheckIn = false
    @State private var showBrainDump = false
    @State private var showAddTask = false
    @State private var showAICoach = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Bonjour"
        case 12..<18: return "Bon après-midi"
        case 18..<22: return "Bonsoir"
        default: return "Bonne nuit"
        }
    }

    private var todayTasks: [NeuroTask] {
        let calendar = Calendar.current
        return activeTasks.filter { task in
            if let due = task.dueDate { return calendar.isDateInToday(due) }
            if let start = task.scheduledStart { return calendar.isDateInToday(start) }
            return false
        }
    }

    private var todayFocusMinutes: Int {
        let calendar = Calendar.current
        return completedSessions
            .filter { calendar.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + $1.actualMinutes }
    }

    private var todayMood: MoodEntry? {
        let calendar = Calendar.current
        return moodEntries.first { calendar.isDateInToday($0.createdAt) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    quickActionsSection
                    moodWidget
                    aiCoachSection
                    todayTasksSection
                    routinesSection
                    habitsSection
                    focusStatsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showMoodCheckIn) {
                MoodCheckInSheet()
            }
            .sheet(isPresented: $showBrainDump) {
                BrainDumpSheet()
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskSheet()
            }
            .sheet(isPresented: $showAICoach) {
                AICoachSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationContentInteraction(.scrolls)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)

            Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "fr_FR"))))
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
    }

    private var quickActionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickActionButton(icon: "face.smiling", title: "Humeur", color: .orange) {
                    showMoodCheckIn = true
                }
                QuickActionButton(icon: "brain", title: "Brain Dump", color: .purple) {
                    showBrainDump = true
                }
                QuickActionButton(icon: "plus.circle.fill", title: "Tâche", color: .blue) {
                    showAddTask = true
                }
                QuickActionButton(icon: "sparkles", title: "Coach IA", color: .indigo) {
                    showAICoach = true
                }
            }
        }
        .contentMargins(.horizontal, 0)
    }

    private var moodWidget: some View {
        Group {
            if let mood = todayMood {
                HStack(spacing: 16) {
                    Text(mood.mood.emoji)
                        .font(.system(size: 44))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Aujourd'hui")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(mood.mood.label)
                            .font(.headline)
                        HStack(spacing: 8) {
                            Label(mood.energy.label, systemImage: mood.energy.icon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 16))
            } else {
                Button { showMoodCheckIn = true } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.orange.opacity(0.15))
                                .frame(width: 48, height: 48)
                            Image(systemName: "face.smiling")
                                .font(.title2)
                                .foregroundStyle(.orange)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Comment allez-vous ?")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("Enregistrez votre humeur du jour")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var aiCoachSection: some View {
        Button {
            showAICoach = true
        } label: {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.indigo.opacity(0.14))
                        .frame(width: 48, height: 48)
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(.indigo)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Coach IA")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(insights.first?.summary ?? "Analyse ta completion, ton énergie et tes brain dumps pour obtenir des suggestions concrètes.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Aujourd'hui")
                    .font(.title3.bold())
                Spacer()
                if !todayTasks.isEmpty {
                    Text("\(todayTasks.count) tâche\(todayTasks.count > 1 ? "s" : "")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if todayTasks.isEmpty && activeTasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)
                    Text("Aucune tâche pour aujourd'hui")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 16))
            } else {
                let displayTasks = todayTasks.isEmpty ? Array(activeTasks.prefix(3)) : Array(todayTasks.prefix(5))
                VStack(spacing: 1) {
                    ForEach(displayTasks, id: \.id) { task in
                        TaskRowCompact(task: task)
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 16))
            }
        }
    }

    private var routinesSection: some View {
        Group {
            if !routines.isEmpty {
                let pending = routines.filter { !$0.isCompletedToday() }
                if !pending.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Routines")
                            .font(.title3.bold())

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(pending, id: \.id) { routine in
                                    RoutineDashboardCard(routine: routine)
                                }
                            }
                        }
                        .contentMargins(.horizontal, 0)
                    }
                }
            }
        }
    }

    private var habitsSection: some View {
        Group {
            if !habits.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Habitudes")
                        .font(.title3.bold())

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(habits, id: \.id) { habit in
                                HabitCard(habit: habit)
                            }
                        }
                    }
                    .contentMargins(.horizontal, 0)
                }
            }
        }
    }

    private var focusStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Concentration")
                .font(.title3.bold())

            HStack(spacing: 12) {
                StatCard(
                    icon: "timer",
                    value: "\(todayFocusMinutes)",
                    unit: "min",
                    label: "Focus aujourd'hui",
                    color: .red
                )

                StatCard(
                    icon: "flame.fill",
                    value: "\(completedSessions.count)",
                    unit: "",
                    label: "Sessions totales",
                    color: .orange
                )
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color.opacity(0.12))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct TaskRowCompact: View {
    let task: NeuroTask
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.snappy) {
                    task.isCompleted = true
                    task.completedAt = Date()
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .green : task.category.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                if let due = task.dueDate {
                    Text(due, format: .dateTime.hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Circle()
                    .fill(task.priority.color)
                    .frame(width: 8, height: 8)

                Image(systemName: task.category.icon)
                    .font(.caption)
                    .foregroundStyle(task.category.color)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .sensoryFeedback(.success, trigger: task.isCompleted)
    }
}

struct HabitCard: View {
    let habit: HabitItem
    @Environment(\.modelContext) private var modelContext
    @State private var justCompleted = false

    var body: some View {
        Button {
            guard !habit.isCompletedToday() else { return }
            let completion = HabitCompletion()
            habit.completions.append(completion)
            habit.currentStreak += 1
            if habit.currentStreak > habit.bestStreak {
                habit.bestStreak = habit.currentStreak
            }
            justCompleted = true
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(habit.habitColor.opacity(0.3), lineWidth: 3)
                        .frame(width: 52, height: 52)

                    if habit.isCompletedToday() {
                        Circle()
                            .fill(habit.habitColor.opacity(0.15))
                            .frame(width: 52, height: 52)
                    }

                    Image(systemName: habit.icon)
                        .font(.title3)
                        .foregroundStyle(habit.habitColor)
                        .symbolEffect(.bounce, value: justCompleted)
                }

                Text(habit.title)
                    .font(.caption2)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if habit.currentStreak > 0 {
                    Text("\(habit.currentStreak)🔥")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: justCompleted)
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title.bold())
                if !unit.isEmpty {
                    Text(unit)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }
}

struct RoutineDashboardCard: View {
    let routine: Routine
    @State private var showDetail = false

    var body: some View {
        Button { showDetail = true } label: {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(routine.routineColor.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: routine.icon)
                        .font(.title3)
                        .foregroundStyle(routine.routineColor)
                }

                Text(routine.title)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                let progress = routine.todayProgress()
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 60, height: 4)
                    Capsule()
                        .fill(routine.routineColor)
                        .frame(width: 60 * progress, height: 4)
                }
            }
            .frame(width: 88)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            RoutineDetailSheet(routine: routine)
        }
    }
}
