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

// FR-003: Four companion interaction modes.
enum InteractionMode: String, Codable, CaseIterable, Identifiable {
    case guidedDiscovery   = "guided_discovery"
    case coCreation        = "co_creation"
    case reflectiveCoaching = "reflective_coaching"
    case silentSupport     = "silent_support"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .guidedDiscovery:    return "Guided Discovery"
        case .coCreation:         return "Co-Creation"
        case .reflectiveCoaching: return "Reflective Coaching"
        case .silentSupport:      return "Silent Support"
        }
    }

    var description: String {
        switch self {
        case .guidedDiscovery:
            return "I'll ask questions to help you find the answer yourself."
        case .coCreation:
            return "We'll build on ideas together as partners."
        case .reflectiveCoaching:
            return "I'll help you reflect on your thinking and learning process."
        case .silentSupport:
            return "I'll stay in the background and only help when you ask."
        }
    }
}

// FR-203: Teacher-configurable AI response style per student.
enum ResponseStyle: String, Codable, CaseIterable, Identifiable {
    case standard
    case encouraging
    case formal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard:    return "Standard"
        case .encouraging: return "Encouraging"
        case .formal:      return "Formal & Academic"
        }
    }

    var description: String {
        switch self {
        case .standard:    return "Balanced, clear, and conversational."
        case .encouraging: return "Extra warm and motivating tone."
        case .formal:      return "Precise and academic language."
        }
    }
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

    // FR-003: Interaction mode fields.
    // defaultInteractionMode and allowedInteractionModes are set by the educator.
    // currentInteractionMode is set by the student (must be within the allowed list).
    var defaultInteractionMode: InteractionMode
    var allowedInteractionModes: [InteractionMode]
    var currentInteractionMode: InteractionMode

    // FR-203: Response style set by educator via ClassroomConfigView.
    var responseStyle: ResponseStyle

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
        self.defaultInteractionMode = .guidedDiscovery
        self.allowedInteractionModes = InteractionMode.allCases
        self.currentInteractionMode = .guidedDiscovery
        self.responseStyle = .standard
    }
}
