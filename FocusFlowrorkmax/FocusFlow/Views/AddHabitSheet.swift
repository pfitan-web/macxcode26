import SwiftUI
import SwiftData

struct AddHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor = "blue"
    @State private var frequency: HabitFrequency = .daily
    @FocusState private var titleFocused: Bool

    private let icons = [
        "star.fill", "heart.fill", "bolt.fill", "flame.fill",
        "drop.fill", "leaf.fill", "moon.fill", "sun.max.fill",
        "figure.run", "dumbbell.fill", "book.fill", "pencil",
        "pills.fill", "bed.double.fill", "cup.and.saucer.fill",
        "brain.head.profile.fill"
    ]

    private let colors = [
        ("blue", Color.blue), ("purple", Color.purple),
        ("green", Color.green), ("orange", Color.orange),
        ("pink", Color.pink), ("red", Color.red),
        ("mint", Color.mint), ("indigo", Color.indigo)
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nom de l'habitude", text: $title)
                        .focused($titleFocused)
                }

                Section("Icône") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? currentColor.opacity(0.15) : Color(.tertiarySystemGroupedBackground))
                                    .foregroundStyle(selectedIcon == icon ? currentColor : .secondary)
                                    .clipShape(.rect(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Couleur") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(colors, id: \.0) { name, color in
                            Button {
                                selectedColor = name
                            } label: {
                                Circle()
                                    .fill(color)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if selectedColor == name {
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

                Section("Fréquence") {
                    Picker("Fréquence", selection: $frequency) {
                        ForEach(HabitFrequency.allCases, id: \.self) { freq in
                            Text(freq.label).tag(freq)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Nouvelle Habitude")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") {
                        let habit = HabitItem(
                            title: title.trimmingCharacters(in: .whitespaces),
                            icon: selectedIcon,
                            color: selectedColor,
                            frequency: frequency
                        )
                        modelContext.insert(habit)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .bold()
                }
            }
            .onAppear { titleFocused = true }
        }
    }

    private var currentColor: Color {
        colors.first(where: { $0.0 == selectedColor })?.1 ?? .blue
    }
}
