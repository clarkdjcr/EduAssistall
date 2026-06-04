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
    case lessonPlan   = "lessonPlan"
    case lessonDay    = "lessonDay"

    var icon: String {
        switch self {
        case .learningPath: return "map.fill"
        case .contentItem:  return "doc.text.fill"
        case .quiz:         return "checkmark.square.fill"
        case .lessonPlan:   return "doc.append.fill"
        case .lessonDay:    return "calendar.badge.clock"
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
    var teacherId: String?
    var targetStudentIds: [String]?
    var parentRecommendationId: String?
    var dayNumber: Int?
    var lessonPlanText: String?

    enum CodingKeys: String, CodingKey {
        case id
        case studentId
        case type
        case title
        case rationale
        case suggestedBy
        case status
        case reviewedBy
        case reviewedAt
        case createdAt
        case teacherId
        case targetStudentIds
        case parentRecommendationId
        case dayNumber
        case lessonPlanText
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        studentId = try c.decode(String.self, forKey: .studentId)
        type = try c.decode(RecommendationType.self, forKey: .type)
        title = try c.decode(String.self, forKey: .title)
        rationale = try c.decode(String.self, forKey: .rationale)
        suggestedBy = try c.decodeIfPresent(String.self, forKey: .suggestedBy) ?? "ai"
        status = try c.decode(RecommendationStatus.self, forKey: .status)
        reviewedBy = try c.decodeIfPresent(String.self, forKey: .reviewedBy)
        reviewedAt = try c.decodeIfPresent(Date.self, forKey: .reviewedAt)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        teacherId = try c.decodeIfPresent(String.self, forKey: .teacherId)
        targetStudentIds = try c.decodeIfPresent([String].self, forKey: .targetStudentIds)
        parentRecommendationId = try c.decodeIfPresent(String.self, forKey: .parentRecommendationId)
        dayNumber = try c.decodeIfPresent(Int.self, forKey: .dayNumber)
        lessonPlanText = try c.decodeIfPresent(String.self, forKey: .lessonPlanText)
    }

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
        self.teacherId = nil
        self.targetStudentIds = nil
        self.parentRecommendationId = nil
        self.dayNumber = nil
        self.lessonPlanText = nil
    }
}
