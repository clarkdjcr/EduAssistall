import Foundation

enum CompletionStatus: String, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed

    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .completed:  return "Completed"
        }
    }
}

struct StudentProgress: Codable, Identifiable {
    var id: String               // "\(studentId)_\(contentItemId)"
    var studentId: String
    var contentItemId: String
    var status: CompletionStatus
    var completionPercent: Int   // 0–100
    var timeSpentMinutes: Int
    var completedAt: Date?
    var updatedAt: Date

    init(studentId: String, contentItemId: String) {
        self.id = "\(studentId)_\(contentItemId)"
        self.studentId = studentId
        self.contentItemId = contentItemId
        self.status = .notStarted
        self.completionPercent = 0
        self.timeSpentMinutes = 0
        self.completedAt = nil
        self.updatedAt = Date()
    }

    mutating func markComplete() {
        status = .completed
        completionPercent = 100
        completedAt = Date()
        updatedAt = Date()
    }
}
