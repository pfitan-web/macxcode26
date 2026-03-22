import SwiftUI
import SwiftData

struct BrainDumpSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<BrainDump> { !$0.isProcessed }, sort: \BrainDump.createdAt, order: .reverse) private var unprocessedDumps: [BrainDump]
    @State private var newThought = ""
    @State private var isAnalyzing = false
    @State private var showAICoach = false
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Image(systemName: "brain")
                        .font(.largeTitle)
                        .foregroundStyle(.purple)

                    Text("Videz votre esprit")
                        .font(.title3.bold())

                    Text("Notez tout ce qui vous passe par la tête. On triera plus tard.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
                .padding(.horizontal, 24)

                HStack(spacing: 8) {
                    TextField("Une pensée, une tâche, une idée...", text: $newThought, axis: .vertical)
                        .lineLimit(1...4)
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 12))
                        .focused($isFocused)
                        .onSubmit { addThought() }

                    Button { addThought() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundStyle(.purple)
                    }
                    .disabled(newThought.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                if unprocessedDumps.isEmpty {
                    ContentUnavailableView(
                        "Votre esprit est vide",
                        systemImage: "sparkles",
                        description: Text("Commencez à noter vos pensées")
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(unprocessedDumps, id: \.id) { dump in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(.purple)
                                    .padding(.top, 6)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dump.content)
                                        .font(.body)

                                    Text(dump.createdAt, format: .dateTime.hour().minute())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button {
                                    convertToTask(dump)
                                } label: {
                                    Image(systemName: "arrow.right.circle")
                                        .foregroundStyle(.indigo)
                                }
                                .buttonStyle(.plain)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(dump)
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    convertToTask(dump)
                                } label: {
                                    Label("Tâche", systemImage: "checkmark.circle")
                                }
                                .tint(.indigo)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Brain Dump")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await analyzePendingDumps() }
                    } label: {
                        if isAnalyzing {
                            ProgressView()
                        } else {
                            Label("Analyser", systemImage: "sparkles")
                        }
                    }
                    .disabled(isAnalyzing || unprocessedDumps.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .sheet(isPresented: $showAICoach) {
                AICoachSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationContentInteraction(.scrolls)
            }
            .onAppear { isFocused = true }
        }
    }

    private func addThought() {
        let text = newThought.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let dump = BrainDump(content: text)
        modelContext.insert(dump)
        newThought = ""
    }

    private func convertToTask(_ dump: BrainDump) {
        let task = NeuroTask(title: dump.content)
        modelContext.insert(task)
        dump.isProcessed = true
        dump.convertedTaskId = task.id
    }

    private func analyzePendingDumps() async {
        guard !isAnalyzing else { return }
        isAnalyzing = true

        let service = NeuroAIService(modelContext: modelContext)
        let tasks = (try? modelContext.fetch(FetchDescriptor<NeuroTask>())) ?? []
        let routines = (try? modelContext.fetch(FetchDescriptor<Routine>())) ?? []
        let suggestions = (try? modelContext.fetch(FetchDescriptor<AISuggestion>())) ?? []

        for dump in unprocessedDumps {
            _ = await service.analyzeBrainDump(
                dump,
                existingTasks: tasks,
                existingRoutines: routines,
                existingSuggestions: suggestions
            )
        }

        isAnalyzing = false
        showAICoach = true
    }
}
