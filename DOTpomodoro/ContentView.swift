import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var timer: PomodoroTimer
    @Query(sort: [SortDescriptor(\TaskItem.createdAt, order: .reverse)]) private var tasks: [TaskItem]
    @Environment(\.modelContext) private var context
    @State private var newTask = ""
    @State private var selectedPriority = TaskPriority.medium
    @State private var showingSessionStats = false
    @State private var sessionStats: (workSessions: Int, breakSessions: Int, totalFocusTime: TimeInterval, duration: TimeInterval)?
    
    private var sortedTasks: [TaskItem] {
        tasks.sorted { lhs, rhs in
            // First sort by completion status
            if lhs.isDone != rhs.isDone {
                return !lhs.isDone && rhs.isDone
            }
            
            // Then sort by priority
            if lhs.priority.sortOrder != rhs.priority.sortOrder {
                return lhs.priority.sortOrder < rhs.priority.sortOrder
            }
            
            // Finally sort by creation date (newest first)
            return lhs.createdAt > rhs.createdAt
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Timer
            VStack(spacing: 6) {
                Text(timer.timeString)
                    .font(.system(size: 64, weight: .semibold, design: .rounded))
                    .foregroundColor(Color("Accent") ?? .blue)
                
                HStack(spacing: 8) {
                    Text(timer.sessionTypeEmoji)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(timer.sessionTypeText)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if let currentTask = timer.currentTask {
                            Text(currentTask.title)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("No active task")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 20).fill(Color("Surface") ?? Color.gray.opacity(0.1)))

            // Task List
            List {
                ForEach(sortedTasks) { task in
                    HStack {
                        Button(action: {
                            if !task.isDone {
                                task.complete()
                                
                                // Create a TaskCompletion record for persistent stats
                                let completion = TaskCompletion(
                                    taskTitle: task.title,
                                    taskPriority: task.priority.rawValue,
                                    pomodorosSpent: task.actualPomodoros
                                )
                                context.insert(completion)
                                
                                // Clear from timer if it's the current task
                                if timer.currentTask?.persistentModelID == task.persistentModelID {
                                    timer.setCurrentTask(nil)
                                }
                            } else {
                                // Allow unchecking completed tasks (unless they're about to auto-delete)
                                task.isDone = false
                                task.completedAt = nil
                                
                                // Remove the TaskCompletion record if unchecking
                                let taskTitle = task.title
                                if let taskCompletionToRemove = try? context.fetch(
                                    FetchDescriptor<TaskCompletion>(
                                        predicate: #Predicate<TaskCompletion> { completion in
                                            completion.taskTitle == taskTitle
                                        }
                                    )
                                ).last {
                                    context.delete(taskCompletionToRemove)
                                }
                            }
                            try? context.save()
                        }) {
                            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isDone ? .green : Color(hex: task.priority.color))
                        }
                        .buttonStyle(.plain)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .strikethrough(task.isDone)
                                .foregroundColor(task.isDone ? .secondary : .primary)
                            
                            HStack(spacing: 8) {
                                // Priority indicator (only for incomplete tasks)
                                if !task.isDone {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color(hex: task.priority.color))
                                            .frame(width: 6, height: 6)
                                        Text(task.priority.rawValue)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // Pomodoro count
                                if task.actualPomodoros > 0 {
                                    HStack(spacing: 2) {
                                        Image(systemName: "timer")
                                            .font(.caption2)
                                        Text("\(task.actualPomodoros)")
                                            .font(.caption2)
                                    }
                                    .foregroundColor(.secondary)
                                }
                                
                                // Auto-delete timer for completed tasks
                                if task.isDone, let completedAt = task.completedAt {
                                    let timeLeft = timeUntilAutoDelete(completedAt: completedAt)
                                    if timeLeft.hours > 0 || timeLeft.minutes > 0 {
                                        HStack(spacing: 2) {
                                            Image(systemName: "clock")
                                                .font(.caption2)
                                            Text(timeLeft.hours > 0 ? "\(timeLeft.hours)h \(timeLeft.minutes)m" : "\(timeLeft.minutes)m")
                                                .font(.caption2)
                                        }
                                        .foregroundColor(.orange)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                        
                        Spacer()
                        
                        // Set as current task button
                        if !task.isDone && timer.currentTask?.persistentModelID != task.persistentModelID {
                            Button(action: { timer.setCurrentTask(task) }) {
                                Image(systemName: "play.circle")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Current task indicator
                        if timer.currentTask?.persistentModelID == task.persistentModelID {
                            Image(systemName: "play.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .onDelete { indexes in
                    for index in indexes {
                        let task = sortedTasks[index]
                        
                        // Only allow deletion of incomplete tasks
                        // Completed tasks should auto-delete after 24 hours
                        if !task.isDone {
                            // Clear from timer if it's the current task
                            if timer.currentTask?.persistentModelID == task.persistentModelID {
                                timer.setCurrentTask(nil)
                            }
                            context.delete(task)
                        }
                    }
                    try? context.save()
                }
            }
            .listStyle(.plain)

            // Add Task
            VStack(spacing: 8) {
                HStack {
                    TextField("New task…", text: $newTask)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(Color(hex: priority.color))
                                    .frame(width: 8, height: 8)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                    
                    Button("Add") {
                        guard !newTask.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let task = TaskItem(title: newTask, priority: selectedPriority)
                        context.insert(task)
                        newTask = ""
                        selectedPriority = .medium
                        try? context.save()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // Auto-cleanup info
                HStack {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Completed tasks auto-delete after 24 hours • Swipe incomplete tasks to delete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }

            // Buttons
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Button(timer.isRunning ? "Pause" : (timer.isPaused ? "Resume" : "Start")) {
                        timer.isRunning ? timer.pause() : timer.start()
                    }
                    .keyboardShortcut(.space, modifiers: [])

                    Button("Reset") {
                        timer.reset()
                    }
                    .tint(.orange)
                    
                    // Skip Break button (only shows during break time)
                    if timer.isBreakTime && (timer.isRunning || timer.isPaused) {
                        Button("Skip Break") {
                            timer.skipBreak()
                        }
                        .tint(.blue)
                    }
                }
                .buttonStyle(.borderedProminent)
                
                // Master Stop Session button (only shows when session is active)
                if timer.masterSessionStartTime != nil {
                    Button(action: {
                        let stats = timer.endMasterSession()
                        sessionStats = stats
                        showingSessionStats = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.circle.fill")
                            Text("End Session")
                        }
                    }
                    .keyboardShortcut("s", modifiers: [.shift])
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.large)
                }
            }

            // Focus Sessions Counter (instead of streak)
            HStack {
                Image(systemName: "flame.fill").foregroundColor(.orange)
                Text(timer.focusSessionsText)
            }
            .font(.subheadline)
        }
        .padding()
        .fontDesign(.rounded)
        .frame(minWidth: 400, minHeight: 600)
        .background(Color("Background") ?? Color.gray.opacity(0.05))
        .onAppear {
            // Inject modelContext into timer if not already set
            if timer.modelContext == nil {
                timer.modelContext = context
            }
        }
        .overlay {
            if showingSessionStats, let stats = sessionStats {
                // Background overlay
                Rectangle()
                    .fill(Color.black.opacity(0.4))
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showingSessionStats = false
                            sessionStats = nil
                        }
                    }
                
                // Centered card
                SessionStatsView(
                    workSessions: stats.workSessions,
                    breakSessions: stats.breakSessions,
                    totalFocusTime: stats.totalFocusTime,
                    sessionDuration: stats.duration,
                    onDismiss: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showingSessionStats = false
                            sessionStats = nil
                        }
                    }
                )
                .scaleEffect(showingSessionStats ? 1.0 : 0.8)
                .opacity(showingSessionStats ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingSessionStats)
            }
        }
    }
    
    // Helper function to calculate time until auto-delete
    private func timeUntilAutoDelete(completedAt: Date) -> (hours: Int, minutes: Int) {
        let calendar = Calendar.current
        let now = Date()
        let deleteAt = calendar.date(byAdding: .hour, value: 24, to: completedAt) ?? completedAt
        let timeInterval = deleteAt.timeIntervalSince(now)
        
        guard timeInterval > 0 else { return (0, 0) }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        return (hours, minutes)
    }
}



#Preview {
    ContentView()
        .environmentObject(PomodoroTimer())
}

