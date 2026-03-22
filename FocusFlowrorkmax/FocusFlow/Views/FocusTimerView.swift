import SwiftUI
import SwiftData

struct FocusTimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<FocusSession> { $0.isCompleted }, sort: \FocusSession.startedAt, order: .reverse) private var recentSessions: [FocusSession]
    @Query(sort: \AIInsightSnapshot.createdAt, order: .reverse) private var insights: [AIInsightSnapshot]
    @State private var selectedType: FocusType = .pomodoro
    @State private var selectedSound: AmbientSound = .none
    @State private var isRunning = false
    @State private var timeRemaining: Int = 25 * 60
    @State private var totalTime: Int = 25 * 60
    @State private var timer: Timer?
    @State private var currentSession: FocusSession?
    @State private var completedPomodoros: Int = 0
    @State private var showCompleted = false

    private var progress: Double {
        guard totalTime > 0 else { return 0 }
        return 1.0 - (Double(timeRemaining) / Double(totalTime))
    }

    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    if !isRunning {
                        adaptiveRecommendationCard
                        focusTypePicker
                    }

                    timerCircle

                    if !isRunning {
                        soundSelector
                    }

                    controlButtons

                    if !recentSessions.isEmpty {
                        sessionHistory
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Focus")
            .sensoryFeedback(.success, trigger: showCompleted)
        }
    }

    private var adaptiveRecommendationCard: some View {
        Group {
            if let latestInsight = insights.first {
                Button {
                    withAnimation(.snappy) {
                        selectedType = latestInsight.recommendedFocusType
                        timeRemaining = latestInsight.recommendedFocusMinutes * 60
                        totalTime = latestInsight.recommendedFocusMinutes * 60
                    }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(.indigo.opacity(0.14))
                                .frame(width: 44, height: 44)
                            Image(systemName: latestInsight.recommendedFocusType.icon)
                                .foregroundStyle(.indigo)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Mode conseillé aujourd'hui")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(latestInsight.recommendedFocusType.label) · \(latestInsight.recommendedFocusMinutes) min")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }

                        Spacer()

                        Image(systemName: "arrow.down.left.and.arrow.up.right")
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

    private var focusTypePicker: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FocusType.allCases, id: \.self) { type in
                        Button {
                            withAnimation(.snappy) {
                                selectedType = type
                                let recommendedMinutes = recommendedMinutes(for: type)
                                timeRemaining = recommendedMinutes * 60
                                totalTime = recommendedMinutes * 60
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: type.icon)
                                    .font(.title3)
                                Text(type.label)
                                    .font(.caption.weight(.medium))
                                Text("\(recommendedMinutes(for: type)) min")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 80, height: 80)
                            .background(selectedType == type ? type.color.opacity(0.15) : Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(selectedType == type ? type.color : .primary)
                            .clipShape(.rect(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedType == type ? type.color : .clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .contentMargins(.horizontal, 0)
        }
    }

    private var timerCircle: some View {
        ZStack {
            Circle()
                .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 12)
                .frame(width: 260, height: 260)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(selectedType.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            VStack(spacing: 8) {
                Text(timeString)
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .monospacedDigit()

                Text(selectedType.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if completedPomodoros > 0 {
                    HStack(spacing: 4) {
                        ForEach(0..<min(completedPomodoros, 4), id: \.self) { _ in
                            Circle()
                                .fill(selectedType.color)
                                .frame(width: 8, height: 8)
                        }
                        if completedPomodoros > 4 {
                            Text("+\(completedPomodoros - 4)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var soundSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Son d'ambiance")
                .font(.subheadline.bold())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AmbientSound.allCases, id: \.self) { sound in
                        Button {
                            withAnimation(.snappy) { selectedSound = sound }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: sound.icon)
                                    .font(.body)
                                Text(sound.label)
                                    .font(.caption2)
                            }
                            .frame(width: 64, height: 52)
                            .background(selectedSound == sound ? .indigo.opacity(0.15) : Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(selectedSound == sound ? .indigo : .primary)
                            .clipShape(.rect(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .contentMargins(.horizontal, 0)
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 24) {
            if isRunning {
                Button {
                    stopTimer()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .frame(width: 64, height: 64)
                        .background(Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(.red)
                        .clipShape(Circle())
                }
            }

            Button {
                if isRunning {
                    pauseTimer()
                } else {
                    startTimer()
                }
            } label: {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.title)
                    .frame(width: 80, height: 80)
                    .background(selectedType.color)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
                    .shadow(color: selectedType.color.opacity(0.3), radius: 12, y: 4)
            }

            if isRunning {
                Button {
                    skipTimer()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .frame(width: 64, height: 64)
                        .background(Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(.secondary)
                        .clipShape(Circle())
                }
            }
        }
    }

    private var sessionHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sessions récentes")
                .font(.subheadline.bold())

            ForEach(Array(recentSessions.prefix(5)), id: \.id) { session in
                HStack(spacing: 12) {
                    Image(systemName: session.focusType.icon)
                        .font(.body)
                        .foregroundStyle(session.focusType.color)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.focusType.label)
                            .font(.subheadline)
                        Text(session.startedAt, format: .dateTime.weekday(.abbreviated).hour().minute())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(session.actualMinutes) min")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))
            }
        }
    }

    private func startTimer() {
        isRunning = true
        if currentSession == nil {
            let session = FocusSession(
                focusType: selectedType,
                ambientSound: selectedSound
            )
            modelContext.insert(session)
            currentSession = session
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    completeSession()
                }
            }
        }
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func stopTimer() {
        pauseTimer()
        if let session = currentSession {
            session.actualMinutes = (totalTime - timeRemaining) / 60
            session.isCompleted = true
            session.endedAt = Date()
        }
        currentSession = nil
        let recommendedMinutes = recommendedMinutes(for: selectedType)
        timeRemaining = recommendedMinutes * 60
        totalTime = recommendedMinutes * 60
    }

    private func skipTimer() {
        completeSession()
    }

    private func completeSession() {
        pauseTimer()

        if let session = currentSession {
            session.actualMinutes = session.durationMinutes
            session.isCompleted = true
            session.endedAt = Date()
        }

        if selectedType == .pomodoro || selectedType == .deepWork {
            completedPomodoros += 1
        }

        showCompleted = true
        currentSession = nil

        if selectedType == .pomodoro || selectedType == .deepWork {
            let nextType: FocusType = completedPomodoros % 4 == 0 ? .longBreak : .shortBreak
            selectedType = nextType
            let recommendedMinutes = recommendedMinutes(for: nextType)
            timeRemaining = recommendedMinutes * 60
            totalTime = recommendedMinutes * 60
        } else {
            selectedType = .pomodoro
            let recommendedMinutes = recommendedMinutes(for: .pomodoro)
            timeRemaining = recommendedMinutes * 60
            totalTime = recommendedMinutes * 60
        }
    }

    private func recommendedMinutes(for type: FocusType) -> Int {
        if let latestInsight = insights.first, latestInsight.recommendedFocusType == type {
            return latestInsight.recommendedFocusMinutes
        }
        return type.defaultMinutes
    }
}