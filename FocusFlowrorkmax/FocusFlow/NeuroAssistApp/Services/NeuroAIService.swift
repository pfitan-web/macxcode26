import Foundation
import SwiftData

@MainActor
struct NeuroAIService {
    let modelContext: ModelContext

    func refreshInsights(
        tasks: [NeuroTask],
        moods: [MoodEntry],
        focusSessions: [FocusSession],
        routines: [Routine]
    ) -> AIInsightSnapshot {
        let snapshot = Self.buildInsightSnapshot(
            tasks: tasks,
            moods: moods,
            focusSessions: focusSessions,
            routines: routines
        )
        modelContext.insert(snapshot)
        return snapshot
    }

    func analyzeBrainDump(
        _ dump: BrainDump,
        existingTasks: [NeuroTask],
        existingRoutines: [Routine],
        existingSuggestions: [AISuggestion]
    ) async -> [AISuggestion] {
        let generated = Self.generateSuggestions(
            from: dump.content,
            existingTasks: existingTasks,
            existingRoutines: existingRoutines,
            existingSuggestions: existingSuggestions
        )

        for suggestion in generated {
            modelContext.insert(suggestion)
        }

        if !generated.isEmpty {
            dump.isProcessed = true
        }

        return generated
    }

    func decomposeTask(_ task: NeuroTask) async {
        guard task.subtasks.isEmpty else { return }

        let steps = Self.makeStepPlan(from: [task.title, task.taskDescription].filter { !$0.isEmpty }.joined(separator: ". "))

        for (index, step) in steps.enumerated() {
            let subtask = SubTask(title: step.title, orderIndex: index)
            task.subtasks.append(subtask)
        }
    }

    static func applySuggestion(_ suggestion: AISuggestion, to modelContext: ModelContext) {
        switch suggestion.kind {
        case .task:
            let task = NeuroTask(
                title: suggestion.title,
                taskDescription: suggestion.suggestionDescription,
                priority: suggestion.taskPriority,
                category: suggestion.taskCategory,
                estimatedMinutes: suggestion.estimatedMinutes
            )

            for (index, step) in suggestion.steps.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated() {
                task.subtasks.append(SubTask(title: step.title, orderIndex: index))
            }

            modelContext.insert(task)
        case .routine:
            let routine = Routine(
                title: suggestion.title,
                icon: "sparkles",
                color: "orange",
                timeOfDay: suggestion.routineTime
            )

            for (index, step) in suggestion.steps.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated() {
                routine.steps.append(RoutineStep(title: step.title, orderIndex: index, estimatedMinutes: step.estimatedMinutes))
            }

            modelContext.insert(routine)
        }

        suggestion.status = .accepted
    }

    private static func buildInsightSnapshot(
        tasks: [NeuroTask],
        moods: [MoodEntry],
        focusSessions: [FocusSession],
        routines: [Routine]
    ) -> AIInsightSnapshot {
        let calendar = Calendar.current
        let periodDays = 21
        let now = Date()
        let cutoff = calendar.date(byAdding: .day, value: -periodDays, to: now) ?? now

        let relevantTasks = tasks.filter { task in
            if task.createdAt >= cutoff { return true }
            if let dueDate = task.dueDate, dueDate >= cutoff { return true }
            if let completedAt = task.completedAt, completedAt >= cutoff { return true }
            return false
        }

        let completedTasks = relevantTasks.filter { task in
            guard task.isCompleted else { return false }
            guard let completedAt = task.completedAt else { return true }
            return completedAt >= cutoff
        }

        let completionRate = relevantTasks.isEmpty ? 0 : Double(completedTasks.count) / Double(relevantTasks.count)

        let overdueTasks = tasks.filter { task in
            guard !task.isCompleted, let dueDate = task.dueDate else { return false }
            return dueDate < now
        }
        let overdueRate = relevantTasks.isEmpty ? 0 : Double(overdueTasks.count) / Double(relevantTasks.count)

        let bestTimeOfDay = strongestTimeOfDay(from: completedTasks)
        let bestMood = strongestMood(from: moods, completedTasks: completedTasks, cutoff: cutoff)
        let bestEnergy = strongestEnergy(from: moods, completedTasks: completedTasks, cutoff: cutoff)
        let recommendedFocus = recommendedFocus(from: focusSessions, fallbackEnergy: bestEnergy, cutoff: cutoff)

        let recentRoutineCompletions = routines.reduce(0) { partialResult, routine in
            partialResult + routine.completions.filter { $0.completedAt >= cutoff }.count
        }

        let completionPercent = Int((completionRate * 100).rounded())
        let overduePercent = Int((overdueRate * 100).rounded())
        let summary = "Tu termines environ \(completionPercent)% de tes tâches sur les \(periodDays) derniers jours. Ton meilleur créneau semble être le \(bestTimeOfDay.label.lowercased()), surtout quand ton énergie est \(bestEnergy.label.lowercased()). Le mode \(recommendedFocus.type.label.lowercased()) de \(recommendedFocus.minutes) min paraît le plus efficace. \(recentRoutineCompletions > 0 ? "Tes routines soutiennent déjà cette dynamique." : "Ajouter plus de routines pourrait stabiliser ton rythme.") \(overduePercent > 0 ? "Environ \(overduePercent)% des tâches récentes restent en retard." : "Très peu de tâches récentes restent en retard.")"

        return AIInsightSnapshot(
            periodDays: periodDays,
            completionRate: completionRate,
            overdueRate: overdueRate,
            bestMood: bestMood,
            bestEnergy: bestEnergy,
            bestTimeOfDay: bestTimeOfDay,
            recommendedFocusType: recommendedFocus.type,
            recommendedFocusMinutes: recommendedFocus.minutes,
            summary: summary
        )
    }

    private static func strongestMood(
        from moods: [MoodEntry],
        completedTasks: [NeuroTask],
        cutoff: Date
    ) -> MoodLevel {
        let calendar = Calendar.current
        let relevantMoods = moods.filter { $0.createdAt >= cutoff }
        guard !relevantMoods.isEmpty else { return .okay }

        let scored = relevantMoods.map { mood -> (MoodLevel, Int) in
            let taskCount = completedTasks.filter { task in
                guard let completedAt = task.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: mood.createdAt)
            }.count
            return (mood.mood, taskCount)
        }

        return scored.max { lhs, rhs in
            if lhs.1 == rhs.1 {
                return lhs.0.rawValue < rhs.0.rawValue
            }
            return lhs.1 < rhs.1
        }?.0 ?? .okay
    }

    private static func strongestEnergy(
        from moods: [MoodEntry],
        completedTasks: [NeuroTask],
        cutoff: Date
    ) -> EnergyLevel {
        let calendar = Calendar.current
        let relevantMoods = moods.filter { $0.createdAt >= cutoff }
        guard !relevantMoods.isEmpty else { return .moderate }

        let scored = relevantMoods.map { mood -> (EnergyLevel, Int) in
            let taskCount = completedTasks.filter { task in
                guard let completedAt = task.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: mood.createdAt)
            }.count
            return (mood.energy, taskCount)
        }

        return scored.max { lhs, rhs in
            if lhs.1 == rhs.1 {
                return lhs.0.rawValue < rhs.0.rawValue
            }
            return lhs.1 < rhs.1
        }?.0 ?? .moderate
    }

    private static func strongestTimeOfDay(from tasks: [NeuroTask]) -> DayMoment {
        let moments = tasks.compactMap { task -> DayMoment? in
            if let completedAt = task.completedAt {
                return dayMoment(for: completedAt)
            }
            if let scheduledStart = task.scheduledStart {
                return dayMoment(for: scheduledStart)
            }
            return nil
        }

        guard !moments.isEmpty else { return DayMoment.morning }

        let counts: [DayMoment: Int] = Dictionary(grouping: moments, by: { $0 }).mapValues(\.count)
        return counts.max { lhs, rhs in lhs.value < rhs.value }?.key ?? DayMoment.morning
    }

    private static func recommendedFocus(
        from focusSessions: [FocusSession],
        fallbackEnergy: EnergyLevel,
        cutoff: Date
    ) -> (type: FocusType, minutes: Int) {
        let candidateSessions = focusSessions.filter {
            $0.isCompleted && $0.startedAt >= cutoff && ($0.focusType == .pomodoro || $0.focusType == .deepWork)
        }

        guard !candidateSessions.isEmpty else {
            switch fallbackEnergy {
            case .high, .overflowing:
                return (.deepWork, 50)
            case .moderate:
                return (.pomodoro, 30)
            case .depleted, .low:
                return (.pomodoro, 20)
            }
        }

        let grouped = Dictionary(grouping: candidateSessions, by: { $0.focusType })
        let best = grouped.max { lhs, rhs in
            averageFocusScore(lhs.value) < averageFocusScore(rhs.value)
        }

        let focusType = best?.key ?? .pomodoro
        let averageMinutes = best?.value.map(\.actualMinutes).reduce(0, +) ?? focusType.defaultMinutes
        let sessionCount = max(best?.value.count ?? 1, 1)
        let rawMinutes = averageMinutes / sessionCount
        let roundedMinutes = max(15, min(90, Int((Double(rawMinutes) / 5.0).rounded() * 5.0)))
        return (focusType, roundedMinutes)
    }

    private static func averageFocusScore(_ sessions: [FocusSession]) -> Double {
        guard !sessions.isEmpty else { return 0 }
        let values = sessions.map { Double($0.actualMinutes) / Double(max($0.durationMinutes, 1)) }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func generateSuggestions(
        from text: String,
        existingTasks: [NeuroTask],
        existingRoutines: [Routine],
        existingSuggestions: [AISuggestion]
    ) -> [AISuggestion] {
        let fragments = normalizedFragments(from: text)
        let existingTaskTitles = Set(existingTasks.map { $0.title.folding(options: .diacriticInsensitive, locale: .current).lowercased() })
        let existingRoutineTitles = Set(existingRoutines.map { $0.title.folding(options: .diacriticInsensitive, locale: .current).lowercased() })
        let existingSuggestionTitles = Set(existingSuggestions.filter { $0.status == .pending }.map { $0.title.folding(options: .diacriticInsensitive, locale: .current).lowercased() })

        return fragments.compactMap { fragment in
            let title = suggestionTitle(from: fragment)
            let normalizedTitle = title.folding(options: .diacriticInsensitive, locale: .current).lowercased()
            let isRoutine = looksLikeRoutine(fragment)

            if existingSuggestionTitles.contains(normalizedTitle) { return nil }
            if isRoutine, existingRoutineTitles.contains(normalizedTitle) { return nil }
            if !isRoutine, existingTaskTitles.contains(normalizedTitle) { return nil }

            let steps = makeStepPlan(from: fragment)
            let description = isRoutine
                ? "Routine proposée à partir de ton brain dump pour rendre l'enchaînement plus simple à lancer."
                : "Tâche structurée à partir de ton brain dump pour limiter la friction au démarrage."

            let suggestion = AISuggestion(
                kind: isRoutine ? .routine : .task,
                title: title,
                suggestionDescription: description,
                sourceText: fragment,
                taskCategory: inferredCategory(from: fragment),
                taskPriority: inferredPriority(from: fragment),
                routineTime: inferredRoutineTime(from: fragment),
                estimatedMinutes: max(10, steps.reduce(0) { $0 + $1.estimatedMinutes })
            )

            suggestion.steps = steps.enumerated().map { index, step in
                AISuggestionStep(title: step.title, orderIndex: index, estimatedMinutes: step.estimatedMinutes)
            }
            return suggestion
        }
    }

    private static func normalizedFragments(from text: String) -> [String] {
        let baseFragments = text
            .replacingOccurrences(of: "•", with: "\n")
            .components(separatedBy: CharacterSet.newlines)
            .flatMap { line in
                line.components(separatedBy: ";")
            }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return baseFragments.isEmpty ? [text.trimmingCharacters(in: .whitespacesAndNewlines)] : baseFragments
    }

    private static func looksLikeRoutine(_ text: String) -> Bool {
        let lowered = text.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        let routineKeywords = ["routine", "matin", "soir", "chaque", "quotid", "avant de dormir", "reveil", "tous les jours"]
        return routineKeywords.contains { lowered.contains($0) } || lowered.contains(":")
    }

    private static func suggestionTitle(from text: String) -> String {
        let components = text.components(separatedBy: ":")
        if let first = components.first?.trimmingCharacters(in: .whitespacesAndNewlines), !first.isEmpty {
            return first.prefix(1).uppercased() + first.dropFirst()
        }

        let words = text.split(separator: " ").prefix(6)
        let title = words.joined(separator: " ")
        if title.isEmpty {
            return "Nouvelle idée"
        }
        return title.prefix(1).uppercased() + title.dropFirst()
    }

    private static func makeStepPlan(from text: String) -> [(title: String, estimatedMinutes: Int)] {
        let separators = [":", ",", " puis ", " et ", "->"]
        var workingText = text

        if let colonIndex = workingText.firstIndex(of: ":") {
            workingText = String(workingText[workingText.index(after: colonIndex)...])
        }

        for separator in separators {
            workingText = workingText.replacingOccurrences(of: separator, with: "|")
        }

        let directSteps = workingText
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if directSteps.count >= 2 {
            return directSteps.map { step in
                (title: normalizedStepTitle(step), estimatedMinutes: inferredStepMinutes(from: step))
            }
        }

        let lowered = text.folding(options: .diacriticInsensitive, locale: .current).lowercased()

        if lowered.contains("mail") || lowered.contains("email") {
            return [
                ("Relire le contexte", 5),
                ("Rédiger le message", 10),
                ("Vérifier puis envoyer", 5)
            ]
        }

        if lowered.contains("course") || lowered.contains("achat") {
            return [
                ("Lister ce qu'il faut", 5),
                ("Préparer le trajet ou le panier", 10),
                ("Faire puis ranger les achats", 15)
            ]
        }

        if looksLikeRoutine(text) {
            return [
                ("Préparer le nécessaire", 5),
                ("Enchaîner les étapes une par une", 15),
                ("Clore la routine et ranger", 5)
            ]
        }

        return [
            ("Clarifier le résultat attendu", 5),
            ("Commencer par la première action simple", 10),
            ("Finaliser puis vérifier", 5)
        ]
    }

    private static func normalizedStepTitle(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Étape" }
        return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
    }

    private static func inferredStepMinutes(from text: String) -> Int {
        let lowered = text.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        if lowered.contains("douche") || lowered.contains("lire") || lowered.contains("ranger") { return 10 }
        if lowered.contains("preparer") || lowered.contains("préparer") { return 5 }
        return 5
    }

    private static func inferredCategory(from text: String) -> TaskCategory {
        let lowered = text.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        if lowered.contains("mail") || lowered.contains("appel") || lowered.contains("reunion") { return .work }
        if lowered.contains("sport") || lowered.contains("douche") || lowered.contains("eau") || lowered.contains("medoc") { return .health }
        if lowered.contains("papier") || lowered.contains("facture") || lowered.contains("admin") { return .admin }
        if lowered.contains("course") || lowered.contains("achat") || lowered.contains("magasin") { return .errands }
        if lowered.contains("ecrire") || lowered.contains("dessin") || lowered.contains("creer") { return .creative }
        return .personal
    }

    private static func inferredPriority(from text: String) -> TaskPriority {
        let lowered = text.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        if lowered.contains("urgent") || lowered.contains("vite") || lowered.contains("aujourd") { return .high }
        if lowered.contains("important") { return .high }
        if lowered.contains("plus tard") || lowered.contains("quand je peux") { return .low }
        return .medium
    }

    private static func inferredRoutineTime(from text: String) -> RoutineTime {
        let lowered = text.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        if lowered.contains("matin") || lowered.contains("reveil") || lowered.contains("réveil") { return RoutineTime.morning }
        if lowered.contains("apres-midi") || lowered.contains("après-midi") { return RoutineTime.afternoon }
        if lowered.contains("soir") { return RoutineTime.evening }
        if lowered.contains("nuit") || lowered.contains("dormir") { return RoutineTime.night }
        return RoutineTime.custom
    }

    private static func dayMoment(for date: Date) -> DayMoment {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12:
            return DayMoment.morning
        case 12..<18:
            return DayMoment.afternoon
        case 18..<22:
            return DayMoment.evening
        default:
            return DayMoment.night
        }
    }
}