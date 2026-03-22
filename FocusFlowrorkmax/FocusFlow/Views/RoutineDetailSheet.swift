import SwiftUI
import SwiftData

struct RoutineDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let routine: Routine

    @State private var completedStepIDs: Set<String> = []
    @State private var showDeleteConfirm = false

    private var sortedSteps: [RoutineStep] {
        routine.steps.sorted { $0.orderIndex < $1.orderIndex }
    }

    private var progress: Double {
        guard !routine.steps.isEmpty else { return 0 }
        return Double(completedStepIDs.count) / Double(routine.steps.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerCard
                    progressSection
                    stepsSection
                    streakSection
                    deleteButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(routine.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .confirmationDialog("Supprimer cette routine ?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Supprimer", role: .destructive) {
                    modelContext.delete(routine)
                    dismiss()
                }
            }
            .onAppear { loadTodayProgress() }
        }
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(routine.routineColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                Image(systemName: routine.icon)
                    .font(.title2)
                    .foregroundStyle(routine.routineColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(routine.title)
                    .font(.title3.bold())
                Label(routine.timeOfDay.label, systemImage: routine.timeOfDay.icon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Progression")
                    .font(.headline)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.headline)
                    .foregroundStyle(routine.routineColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 10)

                    Capsule()
                        .fill(routine.routineColor)
                        .frame(width: geo.size.width * progress, height: 10)
                        .animation(.spring(duration: 0.4), value: progress)
                }
            }
            .frame(height: 10)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Étapes")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(sortedSteps.enumerated()), id: \.element.id) { index, step in
                    let isCompleted = completedStepIDs.contains(step.id.uuidString)
                    let isLast = index == sortedSteps.count - 1

                    Button {
                        withAnimation(.snappy) {
                            toggleStep(step)
                        }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .stroke(isCompleted ? routine.routineColor : Color(.tertiaryLabel), lineWidth: 2)
                                    .frame(width: 28, height: 28)

                                if isCompleted {
                                    Circle()
                                        .fill(routine.routineColor)
                                        .frame(width: 28, height: 28)
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.title)
                                    .font(.body)
                                    .foregroundStyle(isCompleted ? .secondary : .primary)
                                    .strikethrough(isCompleted)

                                if step.estimatedMinutes > 0 {
                                    Text("~\(step.estimatedMinutes) min")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.success, trigger: isCompleted)

                    if !isLast {
                        Divider().padding(.leading, 58)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 16))
        }
    }

    private var streakSection: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(routine.currentStreak)")
                    .font(.title.bold())
                    .foregroundStyle(routine.routineColor)
                Text("Série actuelle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 16))

            VStack(spacing: 4) {
                Text("\(routine.completions.count)")
                    .font(.title.bold())
                    .foregroundStyle(routine.routineColor)
                Text("Complétées")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 16))
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Text("Supprimer la routine")
                .font(.body)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .tint(.red)
    }

    private func loadTodayProgress() {
        let calendar = Calendar.current
        if let todayCompletion = routine.completions.first(where: { calendar.isDateInToday($0.completedAt) }) {
            completedStepIDs = Set(todayCompletion.completedStepIDs.components(separatedBy: ",").filter { !$0.isEmpty })
        }
    }

    private func toggleStep(_ step: RoutineStep) {
        let stepID = step.id.uuidString
        if completedStepIDs.contains(stepID) {
            completedStepIDs.remove(stepID)
        } else {
            completedStepIDs.insert(stepID)
        }
        saveProgress()
    }

    private func saveProgress() {
        let calendar = Calendar.current
        let idsString = completedStepIDs.joined(separator: ",")

        if let existing = routine.completions.first(where: { calendar.isDateInToday($0.completedAt) }) {
            existing.completedStepIDs = idsString
        } else {
            let completion = RoutineCompletion(completedStepIDs: idsString)
            routine.completions.append(completion)
        }
    }
}
