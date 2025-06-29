import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var context
    @Query private var sessions: [PomodoroSession]
    @Query private var tasks: [TaskItem]
    @Query private var stats: [ProductivityStats]
    @Query private var taskCompletions: [TaskCompletion]
    @EnvironmentObject private var timer: PomodoroTimer
    
    @State private var selectedTimeRange = TimeRange.week
    @State private var selectedTaskTimeRange = TimeRange.week
    
    private let primaryColor = Color(hex: "F07167")
    private let textColor = Color(hex: "FDFCDC")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .font(.title2)
                            .foregroundColor(primaryColor)
                        
                        Text("Productivity Stats")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                    }
                    
                    Text("Track your focus journey")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                
                // Today's Overview
                VStack(spacing: 16) {
                    HStack {
                        Text("Today's Progress")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        
                        Text("Today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                        StatCard(
                            title: "Pomodoros",
                            value: "\(todayStats.completedWorkSessions)",
                            subtitle: "sessions",
                            icon: "flame.fill",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Focus Time",
                            value: formatTime(todayStats.totalFocusTime),
                            subtitle: formatTimeSubtitle(todayStats.totalFocusTime),
                            icon: "clock.fill",
                            color: primaryColor
                        )
                        
                        ComingSoonStatCard(
                            title: "Tasks Done",
                            subtitle: "coming soon",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                // Time Range Chart
                VStack(spacing: 16) {
                    HStack {
                        Text("\(selectedTimeRange.rawValue) Overview")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        // Time range picker
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    
                    Chart(chartData) { data in
                        BarMark(
                            x: .value("Period", data.day),
                            y: .value("Hours", data.hours)
                        )
                        .foregroundStyle(primaryColor.gradient)
                        .cornerRadius(4)
                        .annotation(position: .top) {
                            if data.hours > 0 {
                                Text(String(format: "%.1fh", data.hours))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .opacity(0.8)
                            }
                        }
                    }
                    .frame(height: 150)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let hours = value.as(Double.self) {
                                    Text(String(format: "%.1f", hours))
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                Text(value.as(String.self) ?? "")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal, 20)
                
                // Streak Counter
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .font(.title)
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Streak")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("\(currentStreak) days")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(primaryColor)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Best Streak")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(bestStreak) days")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    // Streak visualization
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { index in
                            let dayData = last7Days[safe: index]
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(dayData?.sessions ?? 0 > 0 ? primaryColor : Color.gray.opacity(0.3))
                                .frame(height: 30)
                                .overlay(
                                    Text("\(dayData?.sessions ?? 0)")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(dayData?.sessions ?? 0 > 0 ? .white : .gray)
                                )
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal, 20)
                
                // Task Completion Chart - Coming Soon
                VStack(spacing: 16) {
                    HStack {
                        Text("Task Completion")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                    
                    // Coming soon placeholder
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("Coming Soon")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Task tracking and completion charts will be available in the next update")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.5))
                )
                .padding(.horizontal, 20)
                
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Computed Properties
    
    private var todayStats: (completedWorkSessions: Int, totalFocusTime: TimeInterval, completedTasks: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Calculate from actual sessions
        let todaySessions = sessions.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: today) && session.wasCompleted
        }
        
        let workSessions = todaySessions.filter { $0.sessionType == .work }
        let totalFocusTime = workSessions.reduce(0) { $0 + $1.actualDuration }
        
        // Calculate completed tasks today using TaskCompletion records
        let completedTasksToday = taskCompletions.filter { completion in
            calendar.isDate(completion.completedAt, inSameDayAs: today)
        }.count
        
        return (completedWorkSessions: workSessions.count, totalFocusTime: totalFocusTime, completedTasks: completedTasksToday)
    }
    
    private var chartData: [WeeklyDataPoint] {
        switch selectedTimeRange {
        case .week:
            return weeklyData
        case .month:
            return monthlyData
        case .year:
            return yearlyData
        }
    }
    
    private var taskChartData: [WeeklyDataPoint] {
        switch selectedTaskTimeRange {
        case .week:
            return weeklyTaskData
        case .month:
            return monthlyTaskData
        case .year:
            return yearlyTaskData
        }
    }
    
    private var weeklyData: [WeeklyDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        var data: [WeeklyDataPoint] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let dayStart = calendar.startOfDay(for: date)
                let daySessionsData = sessions.filter { session in
                    calendar.isDate(session.startTime, inSameDayAs: dayStart) && 
                    session.wasCompleted && 
                    session.sessionType == .work
                }
                
                let daySessionsCount = daySessionsData.count
                let dayHours = daySessionsData.reduce(0) { $0 + $1.actualDuration } / 3600.0
                
                let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
                data.append(WeeklyDataPoint(day: dayName, sessions: daySessionsCount, hours: dayHours))
            }
        }
        
        return data.reversed()
    }
    
    private var monthlyData: [WeeklyDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        var data: [WeeklyDataPoint] = []
        
        // Get last 4 weeks
        for i in 0..<4 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: today) ?? today
            let weekStartDay = calendar.dateInterval(of: .weekOfYear, for: weekStart)?.start ?? weekStart
            
            let weekSessionsData = sessions.filter { session in
                if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStartDay) {
                    return weekInterval.contains(session.startTime) && 
                           session.wasCompleted && 
                           session.sessionType == .work
                }
                return false
            }
            
            let weekSessionsCount = weekSessionsData.count
            let weekHours = weekSessionsData.reduce(0) { $0 + $1.actualDuration } / 3600.0
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let weekLabel = formatter.string(from: weekStartDay)
            
            data.append(WeeklyDataPoint(day: weekLabel, sessions: weekSessionsCount, hours: weekHours))
        }
        
        return data.reversed()
    }
    
    private var yearlyData: [WeeklyDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        var data: [WeeklyDataPoint] = []
        
        // Get last 12 months
        for i in 0..<12 {
            if let monthStart = calendar.date(byAdding: .month, value: -i, to: today) {
                let monthStartDay = calendar.dateInterval(of: .month, for: monthStart)?.start ?? monthStart
                
                let monthSessionsData = sessions.filter { session in
                    if let monthInterval = calendar.dateInterval(of: .month, for: monthStartDay) {
                        return monthInterval.contains(session.startTime) && 
                               session.wasCompleted && 
                               session.sessionType == .work
                    }
                    return false
                }
                
                let monthSessionsCount = monthSessionsData.count
                let monthHours = monthSessionsData.reduce(0) { $0 + $1.actualDuration } / 3600.0
                
                let monthName = calendar.shortMonthSymbols[calendar.component(.month, from: monthStartDay) - 1]
                data.append(WeeklyDataPoint(day: monthName, sessions: monthSessionsCount, hours: monthHours))
            }
        }
        
        return data.reversed()
    }
    
    private var weeklyTaskData: [WeeklyDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        var data: [WeeklyDataPoint] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let dayStart = calendar.startOfDay(for: date)
                let dayTasks = taskCompletions.filter { completion in
                    calendar.isDate(completion.completedAt, inSameDayAs: dayStart)
                }.count
                
                let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
                data.append(WeeklyDataPoint(day: dayName, sessions: dayTasks))
            }
        }
        
        return data.reversed()
    }
    
    private var monthlyTaskData: [WeeklyDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        var data: [WeeklyDataPoint] = []
        
        // Get last 4 weeks
        for i in 0..<4 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: today) ?? today
            let weekStartDay = calendar.dateInterval(of: .weekOfYear, for: weekStart)?.start ?? weekStart
            
            let weekTasks = taskCompletions.filter { completion in
                if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStartDay) {
                    return weekInterval.contains(completion.completedAt)
                }
                return false
            }.count
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let weekLabel = formatter.string(from: weekStartDay)
            
            data.append(WeeklyDataPoint(day: weekLabel, sessions: weekTasks))
        }
        
        return data.reversed()
    }
    
    private var yearlyTaskData: [WeeklyDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        var data: [WeeklyDataPoint] = []
        
        // Get last 12 months
        for i in 0..<12 {
            if let monthStart = calendar.date(byAdding: .month, value: -i, to: today) {
                let monthStartDay = calendar.dateInterval(of: .month, for: monthStart)?.start ?? monthStart
                
                let monthTasks = taskCompletions.filter { completion in
                    if let monthInterval = calendar.dateInterval(of: .month, for: monthStartDay) {
                        return monthInterval.contains(completion.completedAt)
                    }
                    return false
                }.count
                
                let monthName = calendar.shortMonthSymbols[calendar.component(.month, from: monthStartDay) - 1]
                data.append(WeeklyDataPoint(day: monthName, sessions: monthTasks))
            }
        }
        
        return data.reversed()
    }
    
    private var last7Days: [DayData] {
        let calendar = Calendar.current
        let today = Date()
        var data: [DayData] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let dayStart = calendar.startOfDay(for: date)
                let daySessions = sessions.filter { session in
                    calendar.isDate(session.startTime, inSameDayAs: dayStart) && 
                    session.wasCompleted && 
                    session.sessionType == .work
                }.count
                
                data.append(DayData(date: dayStart, sessions: daySessions))
            }
        }
        
        return data.reversed()
    }
    
    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        while true {
            let dayStart = calendar.startOfDay(for: currentDate)
            let hasSessions = sessions.contains { session in
                calendar.isDate(session.startTime, inSameDayAs: dayStart) && 
                session.wasCompleted && 
                session.sessionType == .work
            }
            
            if hasSessions {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    private var bestStreak: Int {
        // Calculate the actual best streak from historical session data
        let calendar = Calendar.current
        
        // Get all unique dates with completed work sessions, sorted chronologically
        let sessionDates = Set(sessions.compactMap { session -> Date? in
            guard session.wasCompleted && session.sessionType == .work else { return nil }
            return calendar.startOfDay(for: session.startTime)
        }).sorted()
        
        guard !sessionDates.isEmpty else { return 0 }
        
        var maxStreak = 1
        var currentStreakCount = 1
        
        // Check consecutive days
        for i in 1..<sessionDates.count {
            let previousDate = sessionDates[i-1]
            let currentDate = sessionDates[i]
            
            // Check if current date is exactly one day after previous date
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDate),
               calendar.isDate(nextDay, inSameDayAs: currentDate) {
                currentStreakCount += 1
                maxStreak = max(maxStreak, currentStreakCount)
            } else {
                currentStreakCount = 1
            }
        }
        
        return maxStreak
    }
    

    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return String(format: "%.1f", Double(timeInterval) / 3600.0)
        } else {
            return "\(minutes)"
        }
    }
    
    private func formatTimeSubtitle(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        
        if hours > 0 {
            return "hours"
        } else {
            return "minutes"
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

struct ComingSoonStatCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color.opacity(0.6))
            
            Text("Coming Soon")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.5))
        )
    }
}

struct SessionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(
        filter: #Predicate<PomodoroSession> { $0.wasCompleted },
        sort: [SortDescriptor(\PomodoroSession.startTime, order: .reverse)]
    ) private var sessions: [PomodoroSession]
    
    private let primaryColor = Color(hex: "F07167")
    
    var body: some View {
        NavigationView {
            List {
                ForEach(groupedSessions.keys.sorted(by: >), id: \.self) { date in
                    Section(header: Text(formatDate(date))) {
                        ForEach(groupedSessions[date] ?? [], id: \.startTime) { session in
                            SessionRowView(session: session, primaryColor: primaryColor)
                        }
                    }
                }
            }
            .navigationTitle("Session History")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 600)
    }
    
    private var groupedSessions: [Date: [PomodoroSession]] {
        Dictionary(grouping: sessions) { session in
            Calendar.current.startOfDay(for: session.startTime)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct SessionRowView: View {
    let session: PomodoroSession
    let primaryColor: Color
    
    var body: some View {
        HStack {
            Text(session.sessionType.emoji)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.sessionType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let taskTitle = session.taskTitle {
                    Text(taskTitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(session.actualDuration))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(primaryColor)
                
                Text(formatStartTime(session.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        return "\(minutes)m"
    }
    
    private func formatStartTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Data Models

struct WeeklyDataPoint: Identifiable {
    let id = UUID()
    let day: String
    let sessions: Int
    let hours: Double
    
    init(day: String, sessions: Int, hours: Double = 0) {
        self.day = day
        self.sessions = sessions
        self.hours = hours
    }
}

struct DayData {
    let date: Date
    let sessions: Int
}

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 