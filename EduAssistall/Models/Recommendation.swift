import Foundation

enum RecommendationStatus: String, Codable {
    case pending
    case approved
    case rejected
}

enum RecommendationType: String, Codable {
    case learningPath = "learningPath"
    case contentItem  = "contentItem"
    case quiz         = "quiz"

    var icon: String {
        switch self {
        case .learningPath: return "map.fill"
        case .contentItem:  return "doc.text.fill"
        case .quiz:         return "checkmark.square.fill"
        }
    }
}

struct Recommendation: Codable, Identifiable {
    var id: String
    var studentId: String
    var type: RecommendationType
    var title: String
    var rationale: String       // AI's explanation of why this is recommended
    var suggestedBy: String     // "ai"
    var status: RecommendationStatus
    var reviewedBy: String?     // uid of teacher/parent who acted on it
    var reviewedAt: Date?
    var createdAt: Date

    init(studentId: String, type: RecommendationType, title: String, rationale: String) {
        self.id = UUID().uuidString
        self.studentId = studentId
        self.type = type
        self.title = title
        self.rationale = rationale
        self.suggestedBy = "ai"
        self.status = .pending
        self.reviewedBy = nil
        self.reviewedAt = nil
        self.createdAt = Date()
    }
}
