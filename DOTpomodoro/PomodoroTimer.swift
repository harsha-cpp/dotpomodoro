import SwiftUI
import Combine
import AVFoundation
import UserNotifications
import SwiftData

@MainActor
final class PomodoroTimer: ObservableObject {
    static let defaultDuration: TimeInterval = 25 * 60
    private static let tick = 1.0

    @Published var remaining: TimeInterval
    @Published var isRunning = false
    @Published var isPaused = false
    @Published private(set) var completedSessions = 0
    @Published var workDuration: TimeInterval = defaultDuration
    @Published var breakDuration: TimeInterval = 5 * 60
    @Published var longBreakDuration: TimeInterval = 15 * 60
    @Published var isBreakTime = false
    @Published var autoStartBreaks = true
    @Published var autoStartWork = true
    @Published var sessionsUntilLongBreak = 4
    @Published var notificationsEnabled = true
    @Published var currentTask: TaskItem?
    @Published var currentSession: PomodoroSession?
    
    // Session tracking for master session stats
    @Published var masterSessionStartTime: Date?
    @Published var masterSessionWorkSessions = 0
    @Published var masterSessionBreakSessions = 0
    @Published var masterSessionTotalFocusTime: TimeInterval = 0
    
    // SwiftData context for saving sessions
    var modelContext: ModelContext?
    
    private var cancellable: AnyCancellable?
    private var player: AVAudioPlayer?
    private var notificationCancellable: AnyCancellable?
    private var workSessionsCompleted = 0
    private var sessionStartTime: Date?
    
    // Persistence keys
    private let userDefaults = UserDefaults.standard
    private let remainingKey = "pomodoroRemaining"
    private let isRunningKey = "pomodoroIsRunning"
    private let isBreakTimeKey = "pomodoroIsBreakTime"
    private let workDurationKey = "pomodoroWorkDuration"
    private let breakDurationKey = "pomodoroBreakDuration"
    private let longBreakDurationKey = "pomodoroLongBreakDuration"
    private let autoStartBreaksKey = "pomodoroAutoStartBreaks"
    private let autoStartWorkKey = "pomodoroAutoStartWork"
    private let sessionsUntilLongBreakKey = "pomodoroSessionsUntilLongBreak"
    private let notificationsEnabledKey = "pomodoroNotificationsEnabled"
    private let completedSessionsKey = "pomodoroCompletedSessions"
    private let workSessionsCompletedKey = "pomodoroWorkSessionsCompleted"
    private let lastSessionDateKey = "pomodoroLastSessionDate"

    init() {
        // Load persisted values
        let workDurationValue = userDefaults.double(forKey: workDurationKey) > 0 ? 
            userDefaults.double(forKey: workDurationKey) : Self.defaultDuration
        self.workDuration = workDurationValue
        
        let breakDurationValue = userDefaults.double(forKey: breakDurationKey) > 0 ? 
            userDefaults.double(forKey: breakDurationKey) : 5 * 60
        self.breakDuration = breakDurationValue
        
        let longBreakDurationValue = userDefaults.double(forKey: longBreakDurationKey) > 0 ? 
            userDefaults.double(forKey: longBreakDurationKey) : 15 * 60
        self.longBreakDuration = longBreakDurationValue
        self.autoStartBreaks = userDefaults.object(forKey: autoStartBreaksKey) != nil ? 
            userDefaults.bool(forKey: autoStartBreaksKey) : true
        self.autoStartWork = userDefaults.object(forKey: autoStartWorkKey) != nil ? 
            userDefaults.bool(forKey: autoStartWorkKey) : true
        let sessionsUntilLongBreakValue = userDefaults.integer(forKey: sessionsUntilLongBreakKey) > 0 ? 
            userDefaults.integer(forKey: sessionsUntilLongBreakKey) : 4
        self.sessionsUntilLongBreak = sessionsUntilLongBreakValue
        self.notificationsEnabled = userDefaults.object(forKey: notificationsEnabledKey) != nil ? 
            userDefaults.bool(forKey: notificationsEnabledKey) : true
        
        self.completedSessions = userDefaults.integer(forKey: completedSessionsKey)
        let workSessionsCompletedValue = userDefaults.integer(forKey: workSessionsCompletedKey)
        self.workSessionsCompleted = workSessionsCompletedValue
        
        // Always start fresh with focus time when no active session
        // Quick breaks and standalone sessions should not persist across app restarts
        self.isBreakTime = false
        self.remaining = workDurationValue
        
        // Check if we should reset daily stats
        resetDailyStatsIfNeeded()
        
        // Request notification permissions
        requestNotificationPermissions()
        
        // Listen for toggle timer notifications
        notificationCancellable = NotificationCenter.default
            .publisher(for: .toggleTimer)
            .sink { [weak self] _ in
                self?.toggle()
            }
    }
    
    private func resetDailyStatsIfNeeded() {
        let lastSessionDate = userDefaults.object(forKey: lastSessionDateKey) as? Date
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastDate = lastSessionDate {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            if lastDay < today {
                // Reset daily counters
                completedSessions = 0
                workSessionsCompleted = 0
                userDefaults.set(0, forKey: completedSessionsKey)
                userDefaults.set(0, forKey: workSessionsCompletedKey)
            }
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        isPaused = false
        
        // Capture session start time for precise timing
        sessionStartTime = Date()
        
        // Initialize master session tracking if this is the first start
        if masterSessionStartTime == nil {
            masterSessionStartTime = Date()
        }
        
        // Play start sound
        SoundManager.shared.playStartSound()
        
        // Create new session if needed
        if currentSession == nil {
            let sessionType: SessionType = isBreakTime ? 
                (shouldUseLongBreak() ? .longBreak : .shortBreak) : .work
            currentSession = PomodoroSession(
                duration: remaining,
                sessionType: sessionType,
                taskId: currentTask?.persistentModelID.storeIdentifier,
                taskTitle: currentTask?.title
            )
        }
        
        cancellable = Timer.publish(every: Self.tick, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tickHandler() }
        
        saveState()
    }

    func pause() {
        isRunning = false
        isPaused = true
        cancellable?.cancel()
        sessionStartTime = nil // Clear timing reference
        saveState()
    }

    func toggle() {
        isRunning ? pause() : start()
    }

    func reset() {
        pause()
        
        // Save interrupted session if exists
        if let session = currentSession {
            session.interrupt()
            if let context = modelContext {
                context.insert(session)
                try? context.save()
            }
        }
        currentSession = nil
        sessionStartTime = nil // Clear timing reference
        
        // If we were in a work session and resetting, play complete sound
        if !isBreakTime {
            SoundManager.shared.playCompleteSound()
        }
        
        remaining = isBreakTime ? (shouldUseLongBreak() ? longBreakDuration : breakDuration) : workDuration
        isPaused = false
        saveState()
    }
    
    func skipBreak() {
        guard isBreakTime else { return }
        
        // Complete current break session
        currentSession?.complete()
        if let session = currentSession, let context = modelContext {
            context.insert(session)
            try? context.save()
        }
        
        // Track break session for master session
        masterSessionBreakSessions += 1
        
        // Skip to work session
        isBreakTime = false
        remaining = workDuration
        
        // Create new work session
        currentSession = PomodoroSession(
            duration: remaining,
            sessionType: .work,
            taskId: currentTask?.persistentModelID.storeIdentifier,
            taskTitle: currentTask?.title
        )
        
        saveState()
    }
    
    func endMasterSession() -> (workSessions: Int, breakSessions: Int, totalFocusTime: TimeInterval, duration: TimeInterval) {
        let sessionDuration = masterSessionStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let stats = (
            workSessions: masterSessionWorkSessions,
            breakSessions: masterSessionBreakSessions,
            totalFocusTime: masterSessionTotalFocusTime,
            duration: sessionDuration
        )
        
        // Save any current session before ending
        if let session = currentSession {
            session.interrupt()
            if let context = modelContext {
                context.insert(session)
                try? context.save()
            }
        }
        
        // Stop timer immediately if running
        if isRunning {
            pause()
        }
        
        // Reset ALL state to fresh/idle
        masterSessionStartTime = nil
        masterSessionWorkSessions = 0
        masterSessionBreakSessions = 0
        masterSessionTotalFocusTime = 0
        currentSession = nil
        sessionStartTime = nil
        isBreakTime = false
        remaining = workDuration
        isPaused = false
        isRunning = false
        
        saveState()
        
        return stats
    }
    
    func setCurrentTask(_ task: TaskItem?) {
        currentTask = task
        if let session = currentSession, session.sessionType == .work {
            session.taskId = task?.persistentModelID.storeIdentifier
            session.taskTitle = task?.title
        }
    }

    func setDurations(work: TimeInterval, break: TimeInterval, longBreak: TimeInterval? = nil) {
        workDuration = work
        breakDuration = `break`
        if let longBreak = longBreak {
            longBreakDuration = longBreak
        }
        
        // Reset to appropriate duration if not currently running
        if !isRunning {
            isBreakTime = false
            remaining = workDuration
            isPaused = false
        }
        
        saveSettings()
    }
    
    func setAutoStart(breaks: Bool, work: Bool) {
        autoStartBreaks = breaks
        autoStartWork = work
        saveSettings()
    }
    
    func setNotifications(enabled: Bool) {
        notificationsEnabled = enabled
        saveSettings()
    }
    
    func setQuickBreak(minutes: Int) {
        // Save current session if running
        if let session = currentSession {
            session.interrupt()
            if let context = modelContext {
                context.insert(session)
                try? context.save()
            }
        }
        
        // Set quick break mode
        isBreakTime = true
        let quickBreakDuration = TimeInterval(minutes * 60)
        remaining = quickBreakDuration
        isPaused = false
        
        // Create a quick break session with the correct duration
        currentSession = PomodoroSession(
            duration: quickBreakDuration,
            sessionType: .shortBreak
        )
        
        // Play start sound and begin
        SoundManager.shared.playStartSound()
        isRunning = true
        isPaused = false
        sessionStartTime = Date() // Set timing reference for quick break
        
        cancellable = Timer.publish(every: Self.tick, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tickHandler() }
        
        // Don't save break state for quick breaks - they should be temporary
        // Only save running state and remaining time
        userDefaults.set(remaining, forKey: remainingKey)
        userDefaults.set(isRunning, forKey: isRunningKey)
    }
    
    private func shouldUseLongBreak() -> Bool {
        return workSessionsCompleted > 0 && workSessionsCompleted % sessionsUntilLongBreak == 0
    }

    private func tickHandler() {
        guard let startTime = sessionStartTime else {
            // Fallback to simple tick if no start time
            if remaining > 0 {
                remaining -= Self.tick
                saveState()
            } else {
                sessionCompleted()
            }
            return
        }
        
        // Calculate precise remaining time based on actual elapsed time
        // Use the current session's duration if available, otherwise use defaults
        let currentDuration: TimeInterval
        if let session = currentSession {
            currentDuration = session.duration
        } else {
            currentDuration = isBreakTime ? 
                (shouldUseLongBreak() ? longBreakDuration : breakDuration) : workDuration
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        let newRemaining = max(0, currentDuration - elapsedTime)
        
        // Only update if change is significant (avoid micro-updates)
        if abs(remaining - newRemaining) >= 0.1 {
            remaining = newRemaining
            saveState()
        }
        
        // Check if session should complete (with small tolerance for precision)
        if newRemaining <= 0.1 {
            sessionCompleted()
        }
    }

    private func sessionCompleted() {
        // Complete current session
        currentSession?.complete()
        
        // Save the completed session to SwiftData
        if let session = currentSession, let context = modelContext {
            context.insert(session)
            try? context.save()
            
            // Clean up old completed tasks periodically
            cleanupOldTasks(context: context)
        }
        
        // Clear timing reference for the completed session
        sessionStartTime = nil
        
        if !isBreakTime {
            // Work session completed - play level up sound
            SoundManager.shared.playCompleteSound()
            
            completedSessions += 1
            workSessionsCompleted += 1
            
            // Track master session stats
            masterSessionWorkSessions += 1
            if let session = currentSession {
                masterSessionTotalFocusTime += session.actualDuration
            }
            
            // Update task pomodoro count
            currentTask?.actualPomodoros += 1
            
            // Start break
            isBreakTime = true
            remaining = shouldUseLongBreak() ? longBreakDuration : breakDuration
            
            if autoStartBreaks {
                // Continue running into break
                let sessionType: SessionType = shouldUseLongBreak() ? .longBreak : .shortBreak
                currentSession = PomodoroSession(duration: remaining, sessionType: sessionType)
                sessionStartTime = Date() // Set new timing reference for auto-started break
            } else {
                pause()
                currentSession = nil
            }
        } else {
            // Break completed - play level up sound for starting new work session
            SoundManager.shared.playCompleteSound()
            
            // Track master session stats
            masterSessionBreakSessions += 1
            
            // Break completed, start work
            isBreakTime = false
            remaining = workDuration
            
            if autoStartWork {
                // Continue running into work
                currentSession = PomodoroSession(
                    duration: remaining,
                    sessionType: .work,
                    taskId: currentTask?.persistentModelID.storeIdentifier,
                    taskTitle: currentTask?.title
                )
                sessionStartTime = Date() // Set new timing reference for auto-started work
            } else {
                pause()
                currentSession = nil
            }
        }
        
        saveState()
        saveSettings()
        sendNotification()
        
        // Update last session date
        userDefaults.set(Date(), forKey: lastSessionDateKey)
    }
    
    private func sendNotification() {
        // Only send notifications if enabled
        guard notificationsEnabled else { return }
        
        let notificationCenter = UNUserNotificationCenter.current()
        let notificationId = "pomodoro-session-complete-\(Date().timeIntervalSince1970)"
        
        let content = UNMutableNotificationContent()
        if isBreakTime {
            content.title = "Work Session Complete! 🍅"
            content.body = shouldUseLongBreak() ? 
                "Time for a long break! You've earned it." : 
                "Time for a short break. Stretch and relax."
            content.sound = .default
        } else {
            content.title = "Break Time Over! ⚡"
            content.body = "Ready to get back to work?"
            content.sound = .default
        }
        
        // Show notification immediately with precise timing
        let immediateRequest = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: nil // Shows immediately
        )
        
        // Add the notification
        notificationCenter.add(immediateRequest) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
        
        // Schedule auto-removal after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationId])
            notificationCenter.removeDeliveredNotifications(withIdentifiers: [notificationId])
        }
    }


    
    private func saveState() {
        userDefaults.set(remaining, forKey: remainingKey)
        userDefaults.set(isRunning, forKey: isRunningKey)
        userDefaults.set(isBreakTime, forKey: isBreakTimeKey)
        userDefaults.set(completedSessions, forKey: completedSessionsKey)
        userDefaults.set(workSessionsCompleted, forKey: workSessionsCompletedKey)
    }
    
    private func saveSettings() {
        userDefaults.set(workDuration, forKey: workDurationKey)
        userDefaults.set(breakDuration, forKey: breakDurationKey)
        userDefaults.set(longBreakDuration, forKey: longBreakDurationKey)
        userDefaults.set(autoStartBreaks, forKey: autoStartBreaksKey)
        userDefaults.set(autoStartWork, forKey: autoStartWorkKey)
        userDefaults.set(sessionsUntilLongBreak, forKey: sessionsUntilLongBreakKey)
        userDefaults.set(notificationsEnabled, forKey: notificationsEnabledKey)
    }

    var timeString: String {
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progress: Double {
        let currentDuration = isBreakTime ? 
            (shouldUseLongBreak() ? longBreakDuration : breakDuration) : workDuration
        let elapsed = currentDuration - remaining
        return elapsed / currentDuration
    }
    
    var sessionTypeEmoji: String {
        if isBreakTime {
            // Check if this is a quick break (break without active master session)
            if masterSessionStartTime == nil {
                return "🧘"
            }
            return shouldUseLongBreak() ? "🌴" : "☕️"
        } else {
            return "🍅"
        }
    }
    
    var sessionTypeText: String {
        if isBreakTime {
            // Check if this is a quick break (break without active master session)
            if masterSessionStartTime == nil {
                return "Quick Break"
            }
            return shouldUseLongBreak() ? "Long Break" : "Short Break"
        } else {
            return "Focus Time"
        }
    }
    
    var focusSessionsText: String {
        let minutes = Int(workDuration) / 60
        return "\(masterSessionWorkSessions)×\(minutes) Mins"
    }
    
    // Clean up completed tasks older than 24 hours
    private func cleanupOldTasks(context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        let cutoffDate = calendar.date(byAdding: .hour, value: -24, to: now) ?? now
        
        do {
            // Fetch completed tasks older than 24 hours
            let descriptor = FetchDescriptor<TaskItem>(
                predicate: #Predicate<TaskItem> { task in
                    task.isDone && task.completedAt != nil && task.completedAt! < cutoffDate
                }
            )
            
            let oldTasks = try context.fetch(descriptor)
            
            // Delete old completed tasks
            for task in oldTasks {
                // Clear from current task if it matches
                if let currentTaskId = currentTask?.persistentModelID,
                   task.persistentModelID == currentTaskId {
                    currentTask = nil
                }
                context.delete(task)
            }
            
            if !oldTasks.isEmpty {
                try context.save()
                print("Timer: Cleaned up \(oldTasks.count) completed tasks older than 24 hours")
            }
        } catch {
            print("Timer: Error cleaning up old tasks: \(error)")
        }
    }
}

