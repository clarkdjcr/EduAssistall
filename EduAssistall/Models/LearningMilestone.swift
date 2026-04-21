import Foundation

enum MilestoneType: String, Codable {
    case contentCompleted  = "content_completed"
    case quizPassed        = "quiz_passed"
    case pathCompleted     = "path_completed"
    case topicMastered     = "topic_mastered"

    var verb: String {
        switch self {
        case .contentCompleted: return "completed"
        case .quizPassed:       return "passed a quiz on"
        case .pathCompleted:    return "finished the learning path"
        case .topicMastered:    return "mastered"
        }
    }
}

/// A notable learning achievement stored cross-session for companion context (FR-002).
/// Stored at learningMilestones/{studentId}/milestones/{milestoneId}.
struct LearningMilestone: Codable, Identifiable {
    var id: String
    var studentId: String
    var type: MilestoneType
    var title: String       // e.g. "Intro to Fractions", "Algebra Basics Path"
    var subject: String
    var achievedAt: Date

    /// Human-readable summary injected into the AI system prompt.
    var companionSummary: String {
        "\(type.verb) \"\(title)\" (\(subject))"
    }
}
