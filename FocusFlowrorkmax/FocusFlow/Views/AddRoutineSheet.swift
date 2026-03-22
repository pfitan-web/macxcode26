import SwiftUI
import SwiftData

struct AddRoutineSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var selectedIcon: String = "list.bullet"
    @State private var selectedColor: String = "indigo"
    @State private var selectedTime: RoutineTime = .evening
    @State private var steps: [String] = [""]

    private let icons = [
        "list.bullet", "moon.stars.fill", "sunrise.fill", "sun.max.fill",
        "bed.double.fill", "cup.and.saucer.fill", "figure.walk",
        "book.fill", "dumbbell.fill", "drop.fill",
        "heart.fill", "leaf.fill", "sparkles", "star.fill"
    ]

    private let colors = [
        ("indigo", Color.indigo), ("blue", Color.blue), ("purple", Color.purple),
        ("green", Color.green), ("orange", Color.orange), ("pink", Color.pink),
        ("red", Color.red), ("mint", Color.mint), ("teal", Color.teal), ("yellow", Color.yellow)
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nom de la routine", text: $title)
                        .font(.body)
                }

                Section("Moment") {
                    Picker("Moment de la journée", selection: $selectedTime) {
                        ForEach(RoutineTime.allCases, id: \.self) { time in
                            Label(time.label, systemImage: time.icon).tag(time)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Icône") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            let isSelected = selectedIcon == icon
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .frame(width: 44, height: 44)
                                    .background(isSelected ? selectedColorValue : Color(.tertiarySystemFill))
                                    .clipShape(.rect(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Couleur") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                        ForEach(colors, id: \.0) { name, color in
                            let isSelected = selectedColor == name
                            Button {
                                selectedColor = name
                            } label: {
                                Circle()
                                    .fill(color)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Étapes") {
                    ForEach(steps.indices, id: \.self) { index in
                        HStack(spacing: 10) {
                            Image(systemName: "\(index + 1).circle.fill")
                                .foregroundStyle(selectedColorValue)
                                .font(.title3)

                            TextField("Étape \(index + 1)", text: $steps[index])
                                .font(.body)

                            if steps.count > 1 {
                                Button {
                                    steps.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button {
                        steps.append("")
                    } label: {
                        Label("Ajouter une étape", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Nouvelle routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") { saveRoutine() }
                        .bold()
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var selectedColorValue: Color {
        colors.first { $0.0 == selectedColor }?.1 ?? .indigo
    }

    private func saveRoutine() {
        let routine = Routine(
            title: title.trimmingCharacters(in: .whitespaces),
            icon: selectedIcon,
            color: selectedColor,
            timeOfDay: selectedTime
        )

        let validSteps = steps.enumerated().compactMap { index, text -> RoutineStep? in
            let trimmed = text.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            return RoutineStep(title: trimmed, orderIndex: index)
        }
        routine.steps = validSteps

        modelContext.insert(routine)
        dismiss()
    }
}
