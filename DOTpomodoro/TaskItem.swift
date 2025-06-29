import Foundation
import SwiftData

@Model
class TaskItem {
    var title: String
    var isDone: Bool
    var priority: TaskPriority
    var createdAt: Date
    var completedAt: Date?
    var estimatedPomodoros: Int
    var actualPomodoros: Int
    var tags: [String]

    init(title: String, isDone: Bool = false, priority: TaskPriority = .medium) {
        self.title = title
        self.isDone = isDone
        self.priority = priority
        self.createdAt = Date()
        self.completedAt = nil
        self.estimatedPomodoros = 1
        self.actualPomodoros = 0
        self.tags = []
    }
    
    func complete() {
        isDone = true
        completedAt = Date()
    }
}

enum TaskPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var color: String {
        switch self {
        case .low: return "4A90E2"
        case .medium: return "F5A623"
        case .high: return "F07167"
        case .urgent: return "D0021B"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .urgent: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}

