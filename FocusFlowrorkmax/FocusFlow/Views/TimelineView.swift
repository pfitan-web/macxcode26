import SwiftUI
import SwiftData

nonisolated enum PlanningMode: String, CaseIterable, Sendable {
    case jour = "Jour"
    case semaine = "Semaine"
    case mois = "Mois"
}

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NeuroTask.scheduledStart) private var allTasks: [NeuroTask]
    @State private var selectedDate: Date = Date()
    @State private var showAddTask = false
    @State private var planningMode: PlanningMode = .jour

    private let frLocale = Locale(identifier: "fr_FR")

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mode", selection: $planningMode) {
                    ForEach(PlanningMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                switch planningMode {
                case .jour:
                    dayView
                case .semaine:
                    weekView
                case .mois:
                    monthView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Planning")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddTask = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation { selectedDate = Date() }
                    } label: {
                        Text("Aujourd'hui")
                            .font(.subheadline.bold())
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskSheet()
            }
        }
    }

    // MARK: - Day View

    private var dayView: some View {
        VStack(spacing: 0) {
            datePickerStrip
                .background(Color(.systemBackground))

            ScrollView {
                VStack(spacing: 0) {
                    timelineGrid
                }
                .padding(.bottom, 100)
            }
        }
    }

    private var datePickerStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(-3..<11, id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    let isToday = Calendar.current.isDateInToday(date)

                    Button {
                        withAnimation(.snappy) { selectedDate = date }
                    } label: {
                        VStack(spacing: 4) {
                            Text(date.formatted(.dateTime.weekday(.abbreviated).locale(frLocale)))
                                .font(.caption2)
                                .foregroundStyle(isSelected ? .white : .secondary)

                            Text(date.formatted(.dateTime.day().locale(frLocale)))
                                .font(.title3.bold())
                                .foregroundStyle(isSelected ? .white : .primary)

                            if isToday && !isSelected {
                                Circle()
                                    .fill(.indigo)
                                    .frame(width: 5, height: 5)
                            } else {
                                Circle()
                                    .fill(.clear)
                                    .frame(width: 5, height: 5)
                            }
                        }
                        .frame(width: 48, height: 72)
                        .background(isSelected ? .indigo : Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .contentMargins(.horizontal, 0)
    }

    private var timelineGrid: some View {
        VStack(spacing: 0) {
            ForEach(Array(6...23), id: \.self) { hour in
                HStack(alignment: .top, spacing: 12) {
                    Text(String(format: "%02d:00", hour))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .trailing)
                        .padding(.top, -4)

                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(.separator).opacity(0.3))
                            .frame(height: 0.5)

                        let hourTasks = tasksForHour(hour, on: selectedDate)
                        if hourTasks.isEmpty {
                            Color.clear
                                .frame(height: 60)
                        } else {
                            VStack(spacing: 4) {
                                ForEach(hourTasks, id: \.id) { task in
                                    TimeBlockCard(task: task)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            let unscheduled = tasksForDate(selectedDate).filter { $0.scheduledStart == nil }
            if !unscheduled.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Non planifiées")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 24)

                    ForEach(unscheduled, id: \.id) { task in
                        TaskRowCompact(task: task)
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
    }

    // MARK: - Week View

    private var weekView: some View {
        VStack(spacing: 0) {
            weekNavigationHeader
                .background(Color(.systemBackground))

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(weekDays, id: \.self) { date in
                        let dayTasks = tasksForDate(date)
                        let isToday = Calendar.current.isDateInToday(date)

                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 10) {
                                VStack(spacing: 2) {
                                    Text(date.formatted(.dateTime.weekday(.abbreviated).locale(frLocale)))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .textCase(.uppercase)
                                    Text(date.formatted(.dateTime.day().locale(frLocale)))
                                        .font(.title3.bold())
                                        .foregroundStyle(isToday ? .white : .primary)
                                        .frame(width: 36, height: 36)
                                        .background(isToday ? .indigo : .clear)
                                        .clipShape(Circle())
                                }
                                .frame(width: 44)

                                if dayTasks.isEmpty {
                                    Text("Aucune tâche")
                                        .font(.subheadline)
                                        .foregroundStyle(.tertiary)
                                        .padding(.vertical, 16)
                                } else {
                                    VStack(spacing: 6) {
                                        ForEach(dayTasks, id: \.id) { task in
                                            WeekTaskRow(task: task)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)

                            Divider()
                                .padding(.leading, 70)
                        }
                    }
                }
                .padding(.bottom, 100)
            }
        }
    }

    private var weekNavigationHeader: some View {
        HStack {
            Button {
                withAnimation { selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.bold())
            }

            Spacer()

            let start = startOfWeek(for: selectedDate)
            let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start
            Text("\(start.formatted(.dateTime.day().month(.abbreviated).locale(frLocale))) - \(end.formatted(.dateTime.day().month(.abbreviated).locale(frLocale)))")
                .font(.headline)

            Spacer()

            Button {
                withAnimation { selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.bold())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var weekDays: [Date] {
        let start = startOfWeek(for: selectedDate)
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }
    }

    // MARK: - Month View

    private var monthView: some View {
        VStack(spacing: 0) {
            monthNavigationHeader
                .background(Color(.systemBackground))

            ScrollView {
                VStack(spacing: 4) {
                    monthCalendarGrid
                    monthTasksList
                }
                .padding(.bottom, 100)
            }
        }
    }

    private var monthNavigationHeader: some View {
        HStack {
            Button {
                withAnimation { selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.bold())
            }

            Spacer()

            Text(selectedDate.formatted(.dateTime.month(.wide).year().locale(frLocale)))
                .font(.headline)
                .textCase(nil)

            Spacer()

            Button {
                withAnimation { selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.bold())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var monthCalendarGrid: some View {
        let calendar = Calendar(identifier: .gregorian)
        let days = generateMonthDays(for: selectedDate)
        let weekdaySymbols = calendar.veryShortStandaloneWeekdaySymbols

        return VStack(spacing: 4) {
            HStack(spacing: 0) {
                ForEach(reorderedWeekdaySymbols(weekdaySymbols), id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                ForEach(days, id: \.self) { date in
                    if let date {
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        let isToday = calendar.isDateInToday(date)
                        let taskCount = tasksForDate(date).count

                        Button {
                            withAnimation(.snappy) { selectedDate = date }
                        } label: {
                            VStack(spacing: 2) {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.subheadline)
                                    .fontWeight(isToday ? .bold : .regular)
                                    .foregroundStyle(isSelected ? .white : isToday ? .indigo : .primary)

                                if taskCount > 0 {
                                    HStack(spacing: 2) {
                                        ForEach(0..<min(taskCount, 3), id: \.self) { _ in
                                            Circle()
                                                .fill(isSelected ? .white : .indigo)
                                                .frame(width: 4, height: 4)
                                        }
                                    }
                                } else {
                                    Color.clear.frame(height: 4)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(isSelected ? .indigo : .clear)
                            .clipShape(.rect(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
        .padding(.horizontal, 16)
    }

    private var monthTasksList: some View {
        let dayTasks = tasksForDate(selectedDate)

        return VStack(alignment: .leading, spacing: 8) {
            Text(selectedDate.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(frLocale)))
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            if dayTasks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("Aucune tâche ce jour")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 16))
                .padding(.horizontal, 16)
            } else {
                VStack(spacing: 1) {
                    ForEach(dayTasks, id: \.id) { task in
                        TaskRowCompact(task: task)
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 16))
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Helpers

    private func tasksForDate(_ date: Date) -> [NeuroTask] {
        let calendar = Calendar.current
        return allTasks.filter { task in
            if let start = task.scheduledStart { return calendar.isDate(start, inSameDayAs: date) }
            if let due = task.dueDate { return calendar.isDate(due, inSameDayAs: date) }
            return false
        }
    }

    private func tasksForHour(_ hour: Int, on date: Date) -> [NeuroTask] {
        let calendar = Calendar.current
        return tasksForDate(date).filter { task in
            guard let start = task.scheduledStart else { return false }
            return calendar.component(.hour, from: start) == hour
        }
    }

    private func startOfWeek(for date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    private func generateMonthDays(for date: Date) -> [Date?] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2

        guard let range = calendar.range(of: .day, in: .month, for: date),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))
        else { return [] }

        var weekday = calendar.component(.weekday, from: firstOfMonth)
        weekday = (weekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: weekday)

        for day in range {
            if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(dayDate)
            }
        }

        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private func reorderedWeekdaySymbols(_ symbols: [String]) -> [String] {
        let shifted = Array(symbols[1...]) + [symbols[0]]
        return shifted
    }
}

struct WeekTaskRow: View {
    let task: NeuroTask
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(task.category.color)
                .frame(width: 3, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)
                    .lineLimit(1)

                if let start = task.scheduledStart {
                    Text(start, format: .dateTime.hour().minute())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                withAnimation(.snappy) {
                    task.isCompleted.toggle()
                    task.completedAt = task.isCompleted ? Date() : nil
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(task.category.color.opacity(0.06))
        .clipShape(.rect(cornerRadius: 8))
    }
}

struct TimeBlockCard: View {
    let task: NeuroTask
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(task.category.color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)

                HStack(spacing: 8) {
                    if let start = task.scheduledStart, let end = task.scheduledEnd {
                        Text("\(start, format: .dateTime.hour().minute()) - \(end, format: .dateTime.hour().minute())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(task.category.label)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(task.category.color.opacity(0.12))
                        .foregroundStyle(task.category.color)
                        .clipShape(Capsule())
                }
            }

            Spacer()

            Button {
                withAnimation(.snappy) {
                    task.isCompleted.toggle()
                    task.completedAt = task.isCompleted ? Date() : nil
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
        }
        .padding(12)
        .background(task.category.color.opacity(0.06))
        .clipShape(.rect(cornerRadius: 12))
        .sensoryFeedback(.success, trigger: task.isCompleted)
    }
}
