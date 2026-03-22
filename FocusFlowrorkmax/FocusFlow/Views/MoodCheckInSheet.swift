import SwiftUI
import SwiftData

struct MoodCheckInSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedMood: MoodLevel = .okay
    @State private var selectedEnergy: EnergyLevel = .moderate
    @State private var stressLevel: Double = 3
    @State private var focusLevel: Double = 3
    @State private var notes = ""
    @State private var selectedTags: Set<String> = []
    @State private var currentStep: Int = 0

    private let availableTags = [
        "Bien dormi", "Mal dormi", "Exercice", "Café",
        "Médicament", "Stressé", "Social", "Seul",
        "Productif", "Créatif", "Anxieux", "Calme",
        "Surstimulé", "Sous-stimulé", "Hyperfocus", "Dispersé"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: Double(currentStep + 1), total: 4)
                    .tint(.indigo)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                TabView(selection: $currentStep) {
                    moodStep.tag(0)
                    energyStep.tag(1)
                    tagsStep.tag(2)
                    notesStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)

                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button {
                            withAnimation { currentStep -= 1 }
                        } label: {
                            Text("Précédent")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.bordered)
                    }

                    Button {
                        if currentStep < 3 {
                            withAnimation { currentStep += 1 }
                        } else {
                            saveMood()
                            dismiss()
                        }
                    } label: {
                        Text(currentStep < 3 ? "Suivant" : "Enregistrer")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .navigationTitle("Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
    }

    private var moodStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Comment vous sentez-vous ?")
                .font(.title2.bold())

            HStack(spacing: 16) {
                ForEach(MoodLevel.allCases, id: \.self) { mood in
                    Button {
                        withAnimation(.bouncy) { selectedMood = mood }
                    } label: {
                        VStack(spacing: 8) {
                            Text(mood.emoji)
                                .font(.system(size: selectedMood == mood ? 48 : 36))
                            Text(mood.label)
                                .font(.caption)
                                .foregroundStyle(selectedMood == mood ? .primary : .secondary)
                        }
                        .scaleEffect(selectedMood == mood ? 1.1 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: selectedMood)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var energyStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Votre niveau d'énergie ?")
                .font(.title2.bold())

            VStack(spacing: 16) {
                ForEach(EnergyLevel.allCases, id: \.self) { energy in
                    Button {
                        withAnimation(.snappy) { selectedEnergy = energy }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: energy.icon)
                                .font(.title2)
                                .frame(width: 36)
                            Text(energy.label)
                                .font(.body)
                            Spacer()
                            if selectedEnergy == energy {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.indigo)
                            }
                        }
                        .padding(14)
                        .background(selectedEnergy == energy ? .indigo.opacity(0.1) : Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(.primary)
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedEnergy == energy ? .indigo : .clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var tagsStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Qu'est-ce qui décrit votre journée ?")
                .font(.title2.bold())

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(availableTags, id: \.self) { tag in
                    Button {
                        withAnimation(.snappy) {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        }
                    } label: {
                        Text(tag)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(selectedTags.contains(tag) ? .indigo.opacity(0.15) : Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(selectedTags.contains(tag) ? .indigo : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var notesStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Notes supplémentaires")
                .font(.title2.bold())

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Stress")
                            .font(.caption.bold())
                        Slider(value: $stressLevel, in: 1...5, step: 1)
                            .tint(.orange)
                        Text("\(Int(stressLevel))/5")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Focus")
                            .font(.caption.bold())
                        Slider(value: $focusLevel, in: 1...5, step: 1)
                            .tint(.purple)
                        Text("\(Int(focusLevel))/5")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                TextField("Comment s'est passée votre journée ?", text: $notes, axis: .vertical)
                    .lineLimit(4...8)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 12))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private func saveMood() {
        let entry = MoodEntry(
            mood: selectedMood,
            energy: selectedEnergy,
            stressLevel: Int(stressLevel),
            focusLevel: Int(focusLevel),
            notes: notes,
            tags: Array(selectedTags)
        )
        modelContext.insert(entry)
    }
}
