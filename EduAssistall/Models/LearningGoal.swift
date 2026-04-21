import Foundation

enum GoalStatus: String, Codable, CaseIterable {
    case inProgress
    case completed
    case abandoned

    var displayName: String {
        switch self {
        case .inProgress: return "In Progress"
        case .completed:  return "Completed"
        case .abandoned:  return "Abandoned"
        }
    }
}

struct LearningGoal: Codable, Identifiable {
    var id: String
    var studentId: String
    var title: String
    var notes: String
    var subject: String?
    var targetDate: Date?
    var status: GoalStatus
    var createdAt: Date

    init(studentId: String, title: String, notes: String = "", subject: String? = nil, targetDate: Date? = nil) {
        self.id = UUID().uuidString
        self.studentId = studentId
        self.title = title
        self.notes = notes
        self.subject = subject
        self.targetDate = targetDate
        self.status = .inProgress
        self.createdAt = Date()
    }
}
