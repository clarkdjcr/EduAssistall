import Foundation

enum LearningStyle: String, Codable, CaseIterable {
    case visual
    case auditory
    case kinesthetic
    case readWrite = "read_write"

    var displayName: String {
        switch self {
        case .visual: return "Visual"
        case .auditory: return "Auditory"
        case .kinesthetic: return "Kinesthetic"
        case .readWrite: return "Read/Write"
        }
    }
}

enum RTITier: Int, Codable {
    case tier1 = 1  // Universal / on-track
    case tier2 = 2  // Targeted support
    case tier3 = 3  // Intensive support
}

struct LearningProfile: Codable, Identifiable {
    var id: String              // Same as studentId
    var studentId: String
    var learningStyle: LearningStyle?
    var grade: String           // e.g., "6", "10", "K"
    var interests: [String]
    var rtiTier: RTITier
    var assessmentCompleted: Bool
    var strengths: [String]
    var challenges: [String]
    var updatedAt: Date

    init(studentId: String) {
        self.id = studentId
        self.studentId = studentId
        self.learningStyle = nil
        self.grade = ""
        self.interests = []
        self.rtiTier = .tier1
        self.assessmentCompleted = false
        self.strengths = []
        self.challenges = []
        self.updatedAt = Date()
    }
}
