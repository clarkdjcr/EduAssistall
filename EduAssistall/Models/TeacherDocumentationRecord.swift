import Foundation

enum TeacherDocumentationCategory: String, Codable, CaseIterable, Identifiable {
    case behavior
    case distraction
    case academicConcern
    case parentContact
    case intervention
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .behavior:        return "Behavior"
        case .distraction:     return "Phone / Distraction"
        case .academicConcern: return "Academic Concern"
        case .parentContact:   return "Parent Contact"
        case .intervention:    return "Intervention"
        case .other:           return "Other"
        }
    }
}

enum TeacherDocumentationFollowUpStatus: String, Codable, CaseIterable, Identifiable {
    case none
    case needsFollowUp
    case contactedHome
    case referredToAdmin
    case resolved

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none:            return "No Follow-Up"
        case .needsFollowUp:   return "Needs Follow-Up"
        case .contactedHome:   return "Contacted Home"
        case .referredToAdmin: return "Referred to Admin"
        case .resolved:        return "Resolved"
        }
    }
}

struct TeacherDocumentationRecord: Identifiable, Codable, Sendable {
    var id: String
    var teacherId: String
    var teacherName: String
    var studentId: String?
    var studentName: String
    var studentEmail: String?
    var category: TeacherDocumentationCategory
    var occurredAt: Date
    var location: String
    var objectiveSummary: String
    var teacherAction: String
    var studentResponse: String
    var nextStep: String
    var followUpStatus: TeacherDocumentationFollowUpStatus
    var adminReadySummary: String
    var createdAt: Date
    var updatedAt: Date

    nonisolated init(
        id: String = UUID().uuidString,
        teacherId: String,
        teacherName: String,
        studentId: String? = nil,
        studentName: String,
        studentEmail: String? = nil,
        category: TeacherDocumentationCategory,
        occurredAt: Date = Date(),
        location: String,
        objectiveSummary: String,
        teacherAction: String,
        studentResponse: String,
        nextStep: String,
        followUpStatus: TeacherDocumentationFollowUpStatus,
        adminReadySummary: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.teacherId = teacherId
        self.teacherName = teacherName
        self.studentId = studentId
        self.studentName = studentName
        self.studentEmail = studentEmail
        self.category = category
        self.occurredAt = occurredAt
        self.location = location
        self.objectiveSummary = objectiveSummary
        self.teacherAction = teacherAction
        self.studentResponse = studentResponse
        self.nextStep = nextStep
        self.followUpStatus = followUpStatus
        self.adminReadySummary = adminReadySummary
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
