import Foundation
import SwiftData

@Model
class PomodoroSession {
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var sessionType: SessionType
    var taskId: String?
    var taskTitle: String?
    var wasCompleted: Bool
    var wasInterrupted: Bool
    
    init(duration: TimeInterval, sessionType: SessionType, taskId: String? = nil, taskTitle: String? = nil) {
        self.startTime = Date()
        self.endTime = nil
        self.duration = duration
        self.sessionType = sessionType
        self.taskId = taskId
        self.taskTitle = taskTitle
        self.wasCompleted = false
        self.wasInterrupted = false
    }
    
    func complete() {
        endTime = Date()
        wasCompleted = true
    }
    
    func interrupt() {
        endTime = Date()
        wasInterrupted = true
    }
    
    var actualDuration: TimeInterval {
        guard let endTime = endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }
}

enum SessionType: String, CaseIterable, Codable {
    case work = "Work"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    
    var emoji: String {
        switch self {
        case .work: return "🍅"
        case .shortBreak: return "☕️"
        case .longBreak: return "🌴"
        }
    }
}

@Model
class TaskCompletion {
    var completedAt: Date
    var taskTitle: String
    var taskPriority: String
    var pomodorosSpent: Int
    
    init(taskTitle: String, taskPriority: String, pomodorosSpent: Int = 0) {
        self.completedAt = Date()
        self.taskTitle = taskTitle
        self.taskPriority = taskPriority
        self.pomodorosSpent = pomodorosSpent
    }
}

@Model
class ProductivityStats {
    var date: Date
    var completedWorkSessions: Int
    var completedBreakSessions: Int
    var totalFocusTime: TimeInterval
    var completedTasks: Int
    var streakDays: Int
    
    init(date: Date = Date()) {
        self.date = Calendar.current.startOfDay(for: date)
        self.completedWorkSessions = 0
        self.completedBreakSessions = 0
        self.totalFocusTime = 0
        self.completedTasks = 0
        self.streakDays = 0
    }
    
    func addSession(_ session: PomodoroSession) {
        if session.wasCompleted {
            switch session.sessionType {
            case .work:
                completedWorkSessions += 1
                totalFocusTime += session.actualDuration
            case .shortBreak, .longBreak:
                completedBreakSessions += 1
            }
        }
    }
    
    func addCompletedTask() {
        completedTasks += 1
    }
} 