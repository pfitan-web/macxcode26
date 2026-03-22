import SwiftUI
import SwiftData

struct AICoachSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NeuroTask.createdAt, order: .reverse) private var tasks: [NeuroTask]
    @Query(sort: \MoodEntry.createdAt, order: .reverse) private var moods: [MoodEntry]
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var focusSessions: [FocusSession]
    @Query(sort: \Routine.createdAt, order: .reverse) private var routines: [Routine]
    @Query(sort: \BrainDump.createdAt, order: .reverse) private var brainDumps: [BrainDump]
    @Query(sort: \AISuggestion.createdAt, order: .reverse) private var suggestions: [AISuggestion]
    @Query(sort: \AIInsightSnapshot.createdAt, order: .reverse) private var insights: [AIInsightSnapshot]
    @State private var isAnalyzing = false

    private var latestInsight: AIInsightSnapshot? {
        insights.first
    }

    private var pendingSuggestions: [AISuggestion] {
        suggestions.filter { $0.status == .pending }
    }

    var body: some View {
        NavigationStack {
            List {
                insightSection
                suggestionsSection
                storageSection
            }
            .navigationTitle("Coach IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await runAnalysis() }
                    } label: {
                        if isAnalyzing {
                            ProgressView()
                        } else {
                            Text("Analyser")
                                .bold()
                        }
                    }
                    .disabled(isAnalyzing)
                }
            }
        }
    }

    private var insightSection: some View {
        Section("Analyse") {
            if let latestInsight {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Dernière synthèse", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(latestInsight.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        CoachMetricChip(
                            icon: latestInsight.bestTimeOfDay.icon,
                            title: latestInsight.bestTimeOfDay.label,
                            subtitle: "Meilleur créneau"
                        )
                        CoachMetricChip(
                            icon: latestInsight.bestEnergy.icon,
                            title: latestInsight.bestEnergy.label,
                            subtitle: "Énergie"
                        )
                        CoachMetricChip(
                            icon: latestInsight.recommendedFocusType.icon,
                            title: "\(latestInsight.recommendedFocusMinutes) min",
                            subtitle: latestInsight.recommendedFocusType.label
                        )
                    }
                }
                .padding(.vertical, 6)
            } else {
                Label("Lance une première analyse pour générer des recommandations personnalisées.", systemImage: "brain.head.profile")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            }
        }
    }

    private var suggestionsSection: some View {
        Section("Suggestions") {
            if pendingSuggestions.isEmpty {
                Label("Aucune suggestion en attente pour le moment.", systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                ForEach(pendingSuggestions, id: \.id) { suggestion in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: suggestion.kind.icon)
                                .font(.title3)
                                .foregroundStyle(suggestion.kind.color)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.title)
                                    .font(.headline)
                                Text(suggestion.suggestionDescription)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if !suggestion.steps.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(suggestion.steps.sorted(by: { $0.orderIndex < $1.orderIndex }), id: \.id) { step in
                                    HStack(spacing: 8) {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 5))
                                            .foregroundStyle(.tertiary)
                                        Text(step.title)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }

                        HStack(spacing: 10) {
                            Button {
                                NeuroAIService.applySuggestion(suggestion, to: modelContext)
                            } label: {
                                Label("Ajouter", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)

                            Button {
                                suggestion.status = .dismissed
                            } label: {
                                Label("Ignorer", systemImage: "xmark")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    private var storageSection: some View {
        Section("Stockage") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Les analyses, historiques et suggestions sont stockés localement avec SwiftData.")
                    .font(.subheadline)
                Text("\(insights.count) synthèse·s • \(suggestions.filter { $0.status == .accepted }.count) suggestion·s appliquée·s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private func runAnalysis() async {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        let service = NeuroAIService(modelContext: modelContext)
        _ = service.refreshInsights(tasks: tasks, moods: moods, focusSessions: focusSessions, routines: routines)

        let existingSuggestions = suggestions
        for dump in brainDumps where !dump.isProcessed {
            _ = await service.analyzeBrainDump(
                dump,
                existingTasks: tasks,
                existingRoutines: routines,
                existingSuggestions: existingSuggestions
            )
        }
        isAnalyzing = false
    }
}

struct CoachMetricChip: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(.indigo)
            Text(title)
                .font(.subheadline.bold())
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }
}
