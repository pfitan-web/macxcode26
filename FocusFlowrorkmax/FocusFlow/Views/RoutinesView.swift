import SwiftUI
import SwiftData

struct RoutinesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Routine.createdAt) private var routines: [Routine]
    @State private var showAddRoutine = false
    @State private var selectedRoutine: Routine?

    var body: some View {
        NavigationStack {
            ScrollView {
                if routines.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 16) {
                        todaySection
                        allRoutinesSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddRoutine = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAddRoutine) {
                AddRoutineSheet()
            }
            .sheet(item: $selectedRoutine) { routine in
                RoutineDetailSheet(routine: routine)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)

            Image(systemName: "repeat.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.indigo.opacity(0.4))

            Text("Aucune routine")
                .font(.title3.bold())

            Text("Créez des routines pour structurer\nvotre journée étape par étape.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showAddRoutine = true
            } label: {
                Label("Créer une routine", systemImage: "plus")
                    .font(.body.bold())
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }

    private var todaySection: some View {
        let pending = routines.filter { !$0.isCompletedToday() }

        return Group {
            if !pending.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("À faire aujourd'hui")
                        .font(.title3.bold())
                        .padding(.top, 8)

                    ForEach(pending, id: \.id) { routine in
                        Button { selectedRoutine = routine } label: {
                            RoutineCardLarge(routine: routine)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var allRoutinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Toutes les routines")
                .font(.title3.bold())

            ForEach(routines, id: \.id) { routine in
                Button { selectedRoutine = routine } label: {
                    RoutineRow(routine: routine)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct RoutineCardLarge: View {
    let routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(routine.routineColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: routine.icon)
                        .font(.title3)
                        .foregroundStyle(routine.routineColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Label(routine.timeOfDay.label, systemImage: routine.timeOfDay.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if routine.currentStreak > 0 {
                    Text("\(routine.currentStreak)🔥")
                        .font(.subheadline.bold())
                }
            }

            let progress = routine.todayProgress()
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.tertiarySystemFill))
                            .frame(height: 6)
                        Capsule()
                            .fill(routine.routineColor)
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)

                HStack {
                    let completed = routine.steps.filter { step in
                        let calendar = Calendar.current
                        guard let todayCompletion = routine.completions.first(where: { calendar.isDateInToday($0.completedAt) }) else { return false }
                        return todayCompletion.completedStepIDs.contains(step.id.uuidString)
                    }.count
                    Text("\(completed)/\(routine.steps.count) étapes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Commencer")
                        .font(.caption.bold())
                        .foregroundStyle(routine.routineColor)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }
}

struct RoutineRow: View {
    let routine: Routine

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(routine.routineColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: routine.icon)
                    .font(.body)
                    .foregroundStyle(routine.routineColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(routine.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Text("\(routine.steps.count) étapes · \(routine.timeOfDay.label)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if routine.isCompletedToday() {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
    }
}
