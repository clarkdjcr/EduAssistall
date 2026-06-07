import Foundation

enum AssignmentType: String, Codable, CaseIterable {
    case homework       = "homework"
    case quiz           = "quiz"
    case groupActivity  = "groupActivity"
    case finalExam      = "finalExam"

    var displayName: String {
        switch self {
        case .homework:      return "Homework"
        case .quiz:          return "Quizzes"
        case .groupActivity: return "Group Activities"
        case .finalExam:     return "Final Exam"
        }
    }

    var icon: String {
        switch self {
        case .homework:      return "pencil.circle.fill"
        case .quiz:          return "checkmark.square.fill"
        case .groupActivity: return "person.3.fill"
        case .finalExam:     return "doc.text.fill"
        }
    }

    var color: String {
        switch self {
        case .homework:      return "blue"
        case .quiz:          return "orange"
        case .groupActivity: return "green"
        case .finalExam:     return "purple"
        }
    }
}

struct RubricItem: Codable, Identifiable {
    var id: String
    var criterion: String
    var maxPoints: Int
    var description: String

    init(criterion: String, maxPoints: Int, description: String = "") {
        self.id = UUID().uuidString
        self.criterion = criterion
        self.maxPoints = maxPoints
        self.description = description
    }
}

struct GradingCriteria: Codable, Identifiable {
    var id: String
    var teacherId: String
    var title: String
    var assignmentType: AssignmentType
    var rubricItems: [RubricItem]
    var createdAt: Date

    var totalPoints: Int { rubricItems.reduce(0) { $0 + $1.maxPoints } }

    init(teacherId: String, title: String, type: AssignmentType, rubric: [RubricItem] = []) {
        self.id = UUID().uuidString
        self.teacherId = teacherId
        self.title = title
        self.assignmentType = type
        self.rubricItems = rubric
        self.createdAt = Date()
    }
}

struct GradeWeights: Codable, Identifiable {
    var id: String           // equals teacherId
    var teacherId: String
    var homework: Double
    var quizzes: Double
    var groupActivities: Double
    var finalExam: Double

    var total: Double { homework + quizzes + groupActivities + finalExam }
    var isValid: Bool { abs(total - 100.0) < 0.01 }

    static func defaultWeights(teacherId: String) -> GradeWeights {
        GradeWeights(id: teacherId, teacherId: teacherId,
                     homework: 40, quizzes: 30, groupActivities: 20, finalExam: 10)
    }
}
